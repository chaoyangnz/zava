const std = @import("std");
const Endian = @import("./shared.zig").Endian;
const string = @import("./shared.zig").string;
const Value = @import("./value.zig").Value;
const JavaLangThrowable = @import("./value.zig").JavaLangThrowable;
const Class = @import("./type.zig").Class;
const Method = @import("./type.zig").Method;
const Constant = @import("./type.zig").Constant;
const Instruction = @import("./instruction.zig").Instruction;
const Context = @import("./instruction.zig").Context;
const vm_allocator = @import("./shared.zig").vm_allocator;
const make = @import("./shared.zig").make;
const call = @import("./native.zig").call;

const MAX_CALL_STACK = 512;

pub const Thread = struct {
    id: u64,
    name: string,
    stack: Stack = Stack.init(vm_allocator),

    daemon: bool = false,

    status: Status = undefined,

    // last frame return value
    result: ?Result = null,

    const Status = enum { started, sleeping, parking, waiting, interrupted };

    const Stack = std.ArrayList(Frame);

    /// active frame: top in the stack
    fn active(this: *This) ?*Frame {
        if (this.stack.items.len == 0) return null;
        return &this.stack.items[this.stack.items.len - 1];
    }

    /// pop is supposed to be ONLY called when return and throw
    fn pop(this: *This) void {
        if (this.stack.items.len == 0) return;
        _ = this.stack.pop();
    }

    fn push(this: *This, frame: Frame) void {
        if (this.stack.items.len >= MAX_CALL_STACK) {
            std.debug.panic("Max. call stack exceeded", .{});
        }
        return this.stack.append(frame) catch unreachable;
    }

    const This = @This();

    pub fn invoke(this: *This, class: *const Class, method: *const Method, args: []Value) void {
        std.log.info("{s}.{s}{s}", .{ class.name, method.name, method.descriptor });
        if (method.hasAccessFlag(.NATIVE)) {
            const ret = call(class.name, method.name, args);
            this.stepOut(null, .{ .ret = ret });
        } else {
            // execute java method
            const localVars = make(Value, method.maxLocals, vm_allocator);
            var i: usize = 0;
            for (args) |arg| {
                localVars[i] = arg;
                switch (arg) {
                    .long, .double => i += 2,
                    else => i += 1,
                }
            }
            this.push(.{
                .class = class,
                .method = method,
                .pc = 0,
                .localVars = localVars,
                .stack = Frame.Stack.initCapacity(vm_allocator, method.maxStack) catch unreachable,
                .offset = 0,
            });
            this.stepIn(this.active().?);
        }
    }

    fn stepIn(this: *This, frame: *Frame) void {
        const bytecode = frame.method.code;
        while (frame.pc < frame.method.code.len) {
            const pc = frame.pc;
            frame.offset = 0;

            const instruction = Instruction.fetch(bytecode, pc);
            frame.interpret(instruction);

            // after exec instruction
            if (frame.result) |result| {
                this.stepOut(frame, result);
            }
            if (pc == frame.pc) { // not jump
                frame.pc += instruction.length;
            }
        }
        // supposed to be never reach here
        @panic("either return not found or no exception thrown");
    }

    /// always exec the top frame in the call stack until no frame in stack
    /// return out of method or throw out of a method
    /// NOTE: this is not intended to be called within an instruction
    fn stepOut(this: *This, frame: ?*Frame, result: Result) void {
        if (frame != null) {
            this.pop();
        }
        var top = this.active();
        if (top == null) {
            std.debug.print("thread {d} has no frame left, exit", .{this.id});
            this.result = result;
            return;
        }
        var caller = top.?;
        switch (result) {
            .ret => |ret| if (ret) |v| caller.push(v),
            .exception => caller.result = result,
        }
        this.stepIn(caller);
    }
};

const Result = union(enum) {
    // null represents void
    ret: ?Value,
    exception: JavaLangThrowable,
};

pub const Frame = struct {
    class: *const Class = undefined,
    method: *const Method = undefined,
    // if this this is current this, the pc is for the pc of this thread;
    // otherwise, it is a snapshot one since the last time
    pc: u32 = 0,
    // long and double will occupy two variable indexes. Must follow!! because local variables are operated by index
    localVars: []Value,
    // operand stack
    // As per jvms, a value of type `long` or `double` contributes two units to the indices and a value of any other type contributes one unit
    // But here we use long and double only use one unit. There is not any violation, because operand stack is never operated by index
    stack: Stack,
    // operand offset: internal use only. For an instruction, initially it always starts from pc.
    // Each time read an operand, it advanced.
    offset: u32 = 0,

    result: ?Result = null,

    const Stack = std.ArrayList(Value);
    pub fn pop(this: *This) Value {
        return this.stack.pop();
    }

    pub fn push(this: *This, value: Value) void {
        return this.stack.append(value) catch unreachable;
    }

    pub fn clear(this: *This) void {
        return this.stack.clearRetainingCapacity();
    }

    pub fn loadVar(this: *This, index: u32) Value {
        return this.localVars[index];
    }

    pub fn storeVar(this: *This, index: u32, value: Value) void {
        this.localVars[index] = value;
    }

    pub fn immidiate(this: *This, comptime T: type) T {
        const size = @bitSizeOf(T) / 8;
        const v = Endian.Big.load(T, this.method.code[this.pc + this.offset .. this.pc + this.offset + size]);
        this.offset += size;
        return v;
    }

    pub fn return_(this: *This, ret: ?Value) void {
        this.result = .{ .returns = ret };
    }

    pub fn throw(this: *This, exception: JavaLangThrowable) void {
        this.result = .{ .exception = exception };
    }

    const This = @This();

    /// interpret an instruction
    fn interpret(this: *This, instruction: Instruction) void {
        defer finally_blk: {
            // finally
            // TODO
            break :finally_blk;
        }
        defer catch_blk: {
            // catch exception
            if (this.result == null) break :catch_blk;

            const result = this.result.?;

            const throwable: ?JavaLangThrowable = switch (result) {
                .exception => |exception| exception,
                else => null,
            };

            if (throwable == null) break :catch_blk;

            const e = throwable.?;

            var caught = false;
            var handlePc: u32 = undefined;
            for (this.method.exceptions) |exception| {
                if (this.pc >= exception.startPc and this.pc < exception.endPc) {
                    if (exception.catchType == 0) { // catch-all
                        caught = true;
                        handlePc = exception.handlePc;
                        break;
                    } else {
                        const caughtType = this.class.constant(exception.catchType).classref.ref.?;
                        if (caughtType.isAssignableFrom(e.class())) {
                            caught = true;
                            handlePc = exception.handlePc;
                            break;
                        }
                    }
                }
            }

            if (caught) {
                std.debug.print("\n{s}💧Exception caught: {s} at {s}", .{ " ", e.class().name, this.method.name });
                this.pc = handlePc;
                this.clear();
                this.push(.{ .ref = e });
                this.result = null; // clear caught
            }
        }

        std.log.info("\t {d:0>3}: {s}", .{ this.pc, instruction.mnemonic });
        instruction.interpret(.{ .t = undefined, .f = this, .c = this.class, .m = this.method });
    }
};
