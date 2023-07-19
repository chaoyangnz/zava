const std = @import("std");
const Endian = @import("./shared.zig").Endian;
const string = @import("./shared.zig").string;
const JavaLangThread = @import("./value.zig").JavaLangThread;
const Value = @import("./value.zig").Value;
const ObjectRef = @import("./value.zig").ObjectRef;
const Method = @import("./type.zig").Method;
const Constant = @import("./type.zig").Constant;
const Instruction = @import("./instruction.zig").Instruction;
const Context = @import("./instruction.zig").Context;
const vm_allocator = @import("./heap.zig").vm_allocator;
const BoundedSlice = @import("./heap.zig").BoundedSlice;

pub const Thread = struct {
    id: u64,
    name: string,
    stack: Stack = Stack.initCapacity(vm_allocator, MAX_CALL_STACK),

    daemon: bool = false,

    status: Status = undefined,

    thread: JavaLangThread,

    // last frame return value
    returnValue: ?Value = null,
    exception: ?ObjectRef = null,

    const Status = enum { started, sleeping, parking, waiting, interrupted };
    const MAX_CALL_STACK = 512;

    const Stack = std.ArrayList(Frame);
    fn top(this: *This) ?Frame {
        if (this.stack.items.len == 0) return null;
        return this.stack.getLast();
    }

    /// pop is supposed to be ONLY called when return and throw
    fn pop(this: *This) void {
        if (this.stack.items.len == 0) return;
        _ = this.stack.pop();
    }

    fn push(this: *This, frame: Frame) void {
        return this.stack.append(frame) catch unreachable;
    }

    const This = @This();

    pub fn invoke(this: *This, method: Method, args: []Value) void {
        const frame = Frame.init(method, args);
        this.push(frame);
        this.exec();
    }

    /// always exec the top frame in the call stack
    pub fn run(this: *This) void {
        while (this.top()) |f| {
            this.exec(f);
        }
    }

    fn exec(this: *This, f: Frame) void {
        if (!f.method.hasAccessFlag(.NATIVE)) {
            const bytecode = f.method.code;
            while (f.pc < f.method.code.len) {
                const pc = f.pc;
                f.offset = 0;
                const opcode = bytecode[pc];
                const instruction = Instruction.registery[opcode];
                this.interpret(instruction, .{ .t = this, .f = f, .c = f.method.class, .m = f.method });

                // after exec instruction
                if (f.returnValue) |ret| {
                    this.return_(ret);
                    return;
                }
                if (f.exception) |ex| {
                    // throw out of method
                    this.throw(ex);
                    return;
                }
                if (pc == f.pc) { // not jump
                    f.pc += instruction.length;
                }
            }
            // supposed to be never reach here
            @panic("either return not found or no exception thrown");
        } else {
            // TODO native
        }
    }

    /// return out of method
    /// NOTE: this is not intended to be called within an instruction
    fn return_(this: *This, value: ?Value) void {
        if (value) |v| {
            if (this.top()) |caller| {
                caller.push(v);
                this.pop();
            } else {
                this.returnValue = v;
            }
        }
    }

    /// throw out of a method
    /// NOTE: this is not intended to be called within an instruction
    fn throw(this: *This, exception: ObjectRef) void {
        this.pop();
        if (this.top()) |caller| {
            caller.exception = exception;
        } else {
            this.uncaughtException = exception;
        }
    }

    fn interpret(this: *This, instruction: Instruction, ctx: Context) void {
        _ = this;
        defer {
            // catch exception
            if (ctx.f.exception != null) |e| {
                var caught = false;
                var handlePc = undefined;
                for (ctx.f.method.exceptions) |exception| {
                    if (ctx.f.pc >= exception.startPc and ctx.f.pc < exception.endPc) {
                        if (exception.catchType == 0) { // catch-all
                            caught = true;
                            handlePc = exception.handlePc;
                            break;
                        } else {
                            const caughtType = ctx.f.method.class.constant(exception.catchType).as(Constant.ClassRef).ref;
                            if (caughtType.isAssignableFrom(e.class())) {
                                caught = true;
                                handlePc = exception.handlePc;
                                break;
                            }
                        }
                    }
                }

                if (caught) {
                    std.debug.print("\n{s}💧Exception caught: {s} at {s}", .{ " ", e.class().name, ctx.f.method.name });
                    ctx.f.pc = handlePc;
                    ctx.f.clear();
                    ctx.f.push(e);
                    ctx.f.exception = null; // clear caught
                }
            }
            // finally
            // TODO
        }
        instruction.interpret(ctx);
    }
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

    returnValue: ?Value = null,
    exception: ?ObjectRef = null,

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

    pub fn return_(this: *This, ret: Value) void {
        this.returnValue = ret;
    }

    pub fn throw(this: *This, exception: ObjectRef) void {
        this.exception = exception;
    }

    const This = @This();
    fn init(method: *const Method, args: []Value) This {
        const frame: This = .{
            .method = method,
            .pc = 0,
            .localVars = BoundedSlice(Value).initCapacity(vm_allocator, method.maxLocals),
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
};
