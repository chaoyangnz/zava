const std = @import("std");
const Endian = @import("./shared.zig").Endian;
const string = @import("./shared.zig").string;
const JavaLangThread = @import("./value.zig").JavaLangThread;
const Value = @import("./value.zig").Value;
const Method = @import("./type.zig").Method;
const Instruction = @import("./instruction.zig").Instruction;
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
    returnValue: ?Value,

    const Status = enum { started, sleeping, parking, waiting, interrupted };
    const MAX_CALL_STACK = 512;

    const Stack = std.ArrayList(Frame);
    fn pop(this: *This) Frame {
        return this.stack.pop();
    }

    fn push(this: *This, frame: Frame) void {
        return this.stack.append(frame) catch unreachable;
    }

    const This = @This();

    fn invokeMethod(this: *This, method: *const Method, args: []Value) Value {
        if (!method.isNative) {
            const f = Frame.init(method, args);
            this.stack.append(f);
            const bytecode = f.method.code;
            while (f.pc < f.method.code.len) {
                const pc = f.pc;
                f.offset = 0;
                const opcode = bytecode[pc];
                const instruction = Instruction.registery[opcode];
                // TODO try-catch-finally
                instruction.interpret(this, f, f.method.class, f.method);
                if (pc == f.pc) { // not jump
                    f.pc += instruction.length;
                }
            }
            _ = this.stack.pop();
        } else {
            // TODO native
        }
    }

    pub fn throw(this: *This, exception: string, message: string) void {
        _ = message;
        _ = exception;
        _ = this;
    }
};

const Frame = struct {
    method: *Method = undefined,
    // if this this is current this, the pc is for the pc of this thread;
    // otherwise, it is a snapshot one since the last time
    pc: u32,
    // long and double will occupy two variable indexes. Must follow!! because local variables are operated by index
    localVars: []Value,
    // operand stack
    // As per jvms, a value of type `long` or `double` contributes two units to the indices and a value of any other type contributes one unit
    // But here we use long and double only use one unit. There is not any violation, because operand stack is never operated by index
    stack: Stack,
    // operand offset: internal use only. For an instruction, initially it always starts from pc.
    // Each time read an operand, it advanced.
    offset: u32,

    const Stack = std.ArrayList(Value);
    pub fn pop(this: *This) Value {
        return this.stack.pop();
    }

    pub fn push(this: *This, value: Value) void {
        return this.stack.append(value) catch unreachable;
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
