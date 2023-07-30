const std = @import("std");
const Endian = @import("./shared.zig").Endian;
const string = @import("./shared.zig").string;
const Value = @import("./type.zig").Value;
const NULL = @import("./type.zig").NULL;
const JavaLangThrowable = @import("./type.zig").JavaLangThrowable;
const Class = @import("./type.zig").Class;
const Method = @import("./type.zig").Method;
const Constant = @import("./type.zig").Constant;
const Instruction = @import("./instruction.zig").Instruction;
const interpret = @import("./instruction.zig").interpret;
const vm_allocator = @import("./shared.zig").vm_allocator;
const make = @import("./shared.zig").make;
const call = @import("./native.zig").call;
const newObject = @import("./heap.zig").newObject;
const new = @import("./shared.zig").new;
const toString = @import("./intrinsic.zig").toString;
const getInstanceVar = @import("./vm.zig").getInstanceVar;
const jsize = @import("./shared.zig").jsize;

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

    const Stack = std.ArrayList(*Frame);

    pub fn depth(this: *const This) usize {
        return this.stack.items.len;
    }

    pub fn indent(this: *const This) string {
        var str = vm_allocator.alloc(u8, this.depth() * 4) catch unreachable;
        for (0..this.depth() * 4) |i| {
            str[i] = ' ';
        }
        return str;
    }

    /// active frame: top in the stack
    pub fn active(this: *This) ?*Frame {
        if (this.depth() == 0) return null;
        return this.stack.items[this.stack.items.len - 1];
    }

    /// pop is supposed to be ONLY called when return and throw
    fn pop(this: *This) void {
        if (this.depth() == 0) return;
        _ = this.stack.pop();
    }

    fn push(this: *This, frame: *Frame) void {
        if (this.depth() >= MAX_CALL_STACK) {
            std.debug.panic("Max. call stack exceeded", .{});
        }
        return this.stack.append(frame) catch unreachable;
    }

    const This = @This();

    pub fn invoke(this: *This, class: *const Class, method: *const Method, args: []Value) void {
        if (method.accessFlags.native) {
            std.log.info("{s}  🔸{s}.{s}{s}", .{ this.indent(), class.name, method.name, method.descriptor });
            const ret = call(.{ .t = this, .c = class, .m = method, .a = args });
            this.stepOut(.{ .ret = ret }, true);
        } else {
            std.log.info("{s}  🔹{s}.{s}{s}", .{ this.indent(), class.name, method.name, method.descriptor });
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
            this.push(new(Frame, .{
                .class = class,
                .method = method,
                .pc = 0,
                .localVars = localVars,
                .stack = Frame.Stack.initCapacity(vm_allocator, method.maxStack) catch unreachable,
                .offset = 1,
            }, vm_allocator));

            this.stepIn(class, method, this.active().?);
        }
    }

    fn stepIn(this: *This, class: *const Class, method: *const Method, frame: *Frame) void {
        while (frame.pc < method.code.len) {
            const pc = frame.pc;

            const instruction = interpret(.{ .t = this, .f = frame, .c = class, .m = method });

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
        if (top) |caller| {
            switch (result) {
                .ret => |ret| if (ret) |v| caller.push(v),
                .exception => caller.result = result,
            }
        } else {
            this.result = result;
            switch (result) {
                .ret => |v| {
                    if (v != null) {
                        std.log.info("{s}  thread {d} has no frame left, exit with return value {}", .{ this.indent(), this.id, v.? });
                    }
                },
                .exception => |e| {
                    std.log.warn("Uncaught exception thrown: {s}", .{e.class().name});

                    printStackTrace(e);
                },
            }
        }
    }
};

fn printStackTrace(exception: JavaLangThrowable) void {
    const stackTrace = exception.object().internal.stackTrace;
    if (!stackTrace.isNull()) {
        for (0..stackTrace.len()) |i| {
            const stackTraceElement = stackTrace.get(jsize(i)).ref;
            const className = getInstanceVar(stackTraceElement, "declaringClass", "Ljava/lang/String;").ref;
            const methodName = getInstanceVar(stackTraceElement, "methodName", "Ljava/lang/String;").ref;
            const pc = getInstanceVar(stackTraceElement, "lineNumber", "I").int;
            std.log.info("at {s}.{s} {d}", .{ toString(className), toString(methodName), pc });
        }
    }
}

const Result = union(enum) {
    // null represents void
    ret: ?Value,
    exception: JavaLangThrowable,
};

pub const Frame = struct {
    class: *const Class,
    method: *const Method,
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
    pub fn load(this: *This, index: u16) Value {
        return this.localVars[index];
    }

    /// store local var
    pub fn store(this: *This, index: u16, value: Value) void {
        this.localVars[index] = value;
    }

    pub fn next(this: *This, offset: i32) void {
        const sum = @addWithOverflow(@as(i33, this.pc), @as(i33, offset));
        if (sum[1] > 0) {
            unreachable;
        }
        this.pc = @intCast(sum[0]);
    }

    pub fn return_(this: *This, ret: ?Value) void {
        this.result = .{ .ret = ret };
    }

    pub fn throw(this: *This, exception: JavaLangThrowable) void {
        std.log.info("🔥 throw {s}", .{exception.class().name});
        printStackTrace(exception);
        this.result = .{ .exception = exception };
    }

    pub fn vm_throw(this: *This, name: string) void {
        std.log.info("{s}  🔥 vm throw {s}", .{ current().indent(), name });
        this.result = .{ .exception = newObject(null, name) };
    }

    const This = @This();
};
