const std = @import("std");
const Endian = @import("./shared.zig").Endian;
const string = @import("./shared.zig").string;
const Value = @import("./type.zig").Value;
const NULL = @import("./type.zig").NULL;
const JavaLangThrowable = @import("./type.zig").JavaLangThrowable;
const Class = @import("./type.zig").Class;
const Method = @import("./type.zig").Method;
const Constant = @import("./type.zig").Constant;
const fetch = @import("./instruction.zig").fetch;
const Instruction = @import("./instruction.zig").Instruction;
const Context = @import("./instruction.zig").Context;
const vm_allocator = @import("./shared.zig").vm_allocator;
const make = @import("./shared.zig").make;
const call = @import("./native.zig").call;
const newObject = @import("./heap.zig").newObject;

threadlocal var thread: *Thread = undefined;

pub fn attach(t: *Thread) void {
    thread = t;
}

pub fn current() *Thread {
    return thread;
}

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

    fn depth(this: *This) usize {
        return this.stack.items.len;
    }

    pub fn indent(this: *This) string {
        var str = vm_allocator.alloc(u8, this.depth() * 4) catch unreachable;
        for (0..this.depth() * 4) |i| {
            str[i] = ' ';
        }
        return str;
    }

    /// active frame: top in the stack
    fn active(this: *This) ?*Frame {
        if (this.depth() == 0) return null;
        return &this.stack.items[this.stack.items.len - 1];
    }

    /// pop is supposed to be ONLY called when return and throw
    fn pop(this: *This) void {
        if (this.depth() == 0) return;
        _ = this.stack.pop();
    }

    fn push(this: *This, frame: Frame) void {
        if (this.depth() >= MAX_CALL_STACK) {
            std.debug.panic("Max. call stack exceeded", .{});
        }
        return this.stack.append(frame) catch unreachable;
    }

    const This = @This();

    pub fn invoke(this: *This, class: *const Class, method: *const Method, args: []Value) void {
        if (method.hasAccessFlag(.NATIVE)) {
            std.log.info("{s}    🔸{s}.{s}{s}", .{ this.indent(), class.name, method.name, method.descriptor });
            const ret = call(class.name, method.name, method.descriptor, args);
            this.stepOut(.{ .ret = ret }, true);
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
                .offset = 1,
            });
            std.log.info("{s}🔹{s}.{s}{s}", .{ this.indent(), class.name, method.name, method.descriptor });
            this.stepIn(this.active().?);
        }
    }

    fn stepIn(this: *This, frame: *Frame) void {
        const bytecode = frame.method.code;
        while (frame.pc < frame.method.code.len) {
            const pc = frame.pc;

            const instruction = fetch(bytecode[pc]);
            this.interpret(frame, instruction);

            // after exec instruction
            if (frame.result) |result| {
                return this.stepOut(result, false);
            }

            // normal next rather than jump
            if (pc == frame.pc) {
                frame.pc += instruction.length;
            }
            // reset offset
            frame.offset = 1;
        }
        // supposed to be never reach here
        @panic("run out of code: either return not found or no exception thrown");
    }

    /// always exec the top frame in the call stack until no frame in stack
    /// return out of method or throw out of a method
    /// NOTE: this is not intended to be called within an instruction
    fn stepOut(this: *This, result: Result, native: bool) void {
        if (!native) {
            this.pop();
        }
        var top = this.active();
        if (top == null) {
            std.debug.print("thread {d} has no frame left, exit", .{this.id});
            this.result = result;
            return;
        }
        var caller = top.?;

        ///////// ??????????????????????????
        // std.log.info("{s} {s}", .{ this.indent(), caller.method.name });
        // std.log.info("{s} {s}", .{ this.indent(), caller.class.name });

        switch (result) {
            .ret => |ret| if (ret) |v| caller.push(v),
            .exception => caller.result = result,
        }
    }

    /// interpret an instruction
    fn interpret(this: *This, frame: *Frame, instruction: Instruction) void {
        defer finally_blk: {
            // finally
            // TODO
            break :finally_blk;
        }
        defer catch_blk: {
            // catch exception
            if (frame.result == null) break :catch_blk;

            const result = frame.result.?;

            const throwable: ?JavaLangThrowable = switch (result) {
                .exception => |exception| exception,
                else => null,
            };

            if (throwable == null) break :catch_blk;

            const e = throwable.?;

            var caught = false;
            var handlePc: u32 = undefined;
            for (frame.method.exceptions) |exception| {
                if (frame.pc >= exception.startPc and frame.pc < exception.endPc) {
                    if (exception.catchType == 0) { // catch-all
                        caught = true;
                        handlePc = exception.handlePc;
                        break;
                    } else {
                        const caughtType = frame.class.constant(exception.catchType).classref.ref.?;
                        if (caughtType.isAssignableFrom(e.class())) {
                            caught = true;
                            handlePc = exception.handlePc;
                            break;
                        }
                    }
                }
            }

            if (caught) {
                std.debug.print("\n{s}💧Exception caught: {s} at {s}", .{ " ", e.class().name, frame.method.name });
                frame.pc = handlePc;
                frame.clear();
                frame.push(.{ .ref = e });
                frame.result = null; // clear caught
            }
        }

        std.log.info("{s}{d:0>3}: {s}", .{ this.indent(), frame.pc, instruction.mnemonic });
        instruction.interpret(.{ .t = this, .f = frame, .c = frame.class, .m = frame.method });
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
    pc: u32,
    // long and double will occupy two variable indexes. Must follow!! because local variables are operated by index
    localVars: []Value,
    // operand stack
    // As per jvms, a value of type `long` or `double` contributes two units to the indices and a value of any other type contributes one unit
    // But here we use long and double only use one unit. There is not any violation, because operand stack is never operated by index
    stack: Stack,
    // operand offset: internal use only. For an instruction, initially it always starts from the byte after opcode of pc.
    // Each time read an operand, it advanced.
    offset: u32,

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

    /// load local var
    pub fn load(this: *This, index: u32) Value {
        return this.localVars[index];
    }

    /// store local var
    pub fn store(this: *This, index: u32, value: Value) void {
        this.localVars[index] = value;
    }

    pub fn next(this: *This, offset: i32) void {
        const sum = @addWithOverflow(@as(i33, this.pc), @as(i33, offset));
        if (sum[1] > 0) {
            unreachable;
        }
        this.pc = @intCast(sum[0]);
    }

    pub fn immidiate(this: *This, comptime T: type) T {
        const size = @bitSizeOf(T) / 8;
        const v = Endian.Big.load(T, this.method.code[this.pc + this.offset .. this.pc + this.offset + size]);
        this.offset += size;
        return v;
    }

    pub fn padding(this: *This) void {
        for (0..4) |i| {
            const pos = this.offset + i;
            if (pos % 4 == 0) {
                this.offset = @intCast(pos);
                break;
            }
        }
    }

    pub fn return_(this: *This, ret: ?Value) void {
        this.result = .{ .ret = ret };
    }

    pub fn throw(this: *This, exception: JavaLangThrowable) void {
        this.result = .{ .exception = exception };
    }

    pub fn vm_throw(this: *This, name: string) void {
        this.result = .{ .exception = newObject(null, name) };
    }

    const This = @This();
};
