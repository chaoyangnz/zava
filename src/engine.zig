const std = @import("std");
const Endian = @import("./shared.zig").Endian;
const string = @import("./shared.zig").string;
const Value = @import("./value.zig").Value;
const ObjectRef = @import("./value.zig").ObjectRef;
const Method = @import("./type.zig").Method;
const Constant = @import("./type.zig").Constant;
const Instruction = @import("./instruction.zig").Instruction;
const Context = @import("./instruction.zig").Context;
const vm_allocator = @import("./heap.zig").vm_allocator;
const make = @import("./heap.zig").make;
const native = @import("./native.zig");

pub const Thread = struct {
    id: u64,
    name: string,
    stack: Stack = Stack.initCapacity(vm_allocator, MAX_CALL_STACK),

    daemon: bool = false,

    status: Status = undefined,

    // last frame return value
    result: ?Result,

    const Status = enum { started, sleeping, parking, waiting, interrupted };
    const MAX_CALL_STACK = 512;

    const Stack = std.ArrayList(Frame);

    /// active frame: top in the stack
    fn active(this: *This) ?Frame {
        if (this.stack.items.len == 0) return null;
        return this.stack.getLast();
    }

    /// pop is supposed to be ONLY called when return and throw
    fn pop(this: *This) void {
        if (this.stack.items.len == 0) return;
        _ = this.stack.pop();
    }

    fn push(this: *This, frame: Frame) void {
        if (this.stack.items.len >= MAX_CALL_STACK) {
            std.debug.panic("Max. call stack exceeded");
        }
        return this.stack.append(frame) catch unreachable;
    }

    const This = @This();

    pub fn invoke(this: *This, method: *const Method, args: []Value) void {
        if (method.hasAccessFlag(.NATIVE)) {
            const ret = native.call(this.method.class.name, this.method.name, args);
            this.stepOut(null, .{ .returnValue = ret });
        } else {
            // execute java method
            const frame = Frame.init(method, args);
            this.push(frame);
            this.stepIn(frame);
        }
    }

    fn stepIn(this: *This, frame: Frame) void {
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
            if (pc == this.pc) { // not jump
                frame.pc += instruction.length;
            }
        }
        // supposed to be never reach here
        @panic("either return not found or no exception thrown");
    }

    /// always exec the top frame in the call stack until no frame in stack
    /// return out of method or throw out of a method
    /// NOTE: this is not intended to be called within an instruction
    fn stepOut(this: *This, frame: ?Frame, result: Result) void {
        if (frame) {
            this.pop();
        }
        if (this.active()) |caller| {
            switch (result) {
                .returnValue => |v| caller.push(v),
                .exception => caller.result = result,
            }
            this.stepIn(caller);
        } else {
            std.debug.print("thread {d} has no frame left, exit", .{this.id});
            this.result = result;
        }
    }
};

const Result = union(enum) {
    returns: ?Value,
    exception: ObjectRef,
};

const Frame = struct {
    method: *Method = undefined,
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

    result: ?Result,

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
        Endian.Big.load(T, this.method.code[this.pc + this.offset .. this.pc + this.offset + size]);
        this.offset += size;
    }

    pub fn return_(this: *This, ret: ?Value) void {
        this.result = .{ .returns = ret };
    }

    pub fn throw(this: *This, exception: ObjectRef) void {
        this.result = .{ .exception = exception };
    }

    const This = @This();
    fn init(method: *const Method, args: []Value) This {
        const frame: This = .{
            .method = method,
            .pc = 0,
            .localVars = make(Value, method.maxLocals, vm_allocator),
            .stack = Stack.initCapacity(vm_allocator, method.maxStack),
            .pos = 0,
        };

        var i = 0;
        for (args) |arg| {
            frame.localVars[i] = arg;
            switch (arg) {
                .long, .double => i += 2,
                else => i += 1,
            }
        }
    }

    /// interpret an instruction
    fn interpret(this: *This, instruction: Instruction) void {
        defer {
            // finally
            // TODO
        }
        defer {
            // catch exception
            if (this.exception) |e| {
                var caught = false;
                var handlePc = undefined;
                for (this.method.exceptions) |exception| {
                    if (this.pc >= exception.startPc and this.pc < exception.endPc) {
                        if (exception.catchType == 0) { // catch-all
                            caught = true;
                            handlePc = exception.handlePc;
                            break;
                        } else {
                            const caughtType = this.method.class.constant(exception.catchType).as(Constant.ClassRef).ref;
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
                    this.push(e);
                    this.exception = null; // clear caught
                }
            }
        }

        instruction.interpret(.{ .t = undefined, .f = this, .c = this.method.class, .m = this.method });
    }
};
