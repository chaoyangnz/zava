const std = @import("std");

const Endian = @import("./vm.zig").Endian;
const string = @import("./vm.zig").string;
const jsize = @import("./vm.zig").jsize;
const vm_make = @import("./vm.zig").vm_make;
const vm_new = @import("./vm.zig").vm_new;
const vm_free = @import("./vm.zig").vm_free;
const vm_allocator = @import("./vm.zig").vm_allocator;

const Value = @import("./type.zig").Value;
const NULL = @import("./type.zig").NULL;
const Class = @import("./type.zig").Class;
const Method = @import("./type.zig").Method;
const JavaLangThrowable = @import("./type.zig").JavaLangThrowable;

const Instruction = @import("./instruction.zig").Instruction;
const interpret = @import("./instruction.zig").interpret;

const call = @import("./native.zig").call;

const newObject = @import("./heap.zig").newObject;
const toString = @import("./heap.zig").toString;
const getInstanceVar = @import("./heap.zig").getInstanceVar;

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
        const frame = this.stack.pop();
        frame.deinit();
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
            // we know it is impossible to invoke a native method from top.
            const value = call(.{ .t = this, .c = class, .m = method, .f = this.active().? }, args);
            this.stepOut(.{ .@"return" = value }, true);
        } else {
            std.log.info("{s}  🔹{s}.{s}{s}", .{ this.indent(), class.name, method.name, method.descriptor });
            // execute java method
            const localVars = vm_make(Value, method.maxLocals);
            // put args to local vars
            var i: usize = 0;
            for (args) |arg| {
                localVars[i] = arg;
                switch (arg) {
                    .long, .double => i += 2,
                    else => i += 1,
                }
            }
            this.push(vm_new(Frame, .{
                .class = class,
                .method = method,
                .pc = 0,
                .localVars = localVars,
                .stack = Frame.Stack.initCapacity(vm_allocator, method.maxStack) catch unreachable,
                .offset = 1,
            }));

            this.stepIn(class, method, this.active().?);
        }
    }

    fn stepIn(this: *This, class: *const Class, method: *const Method, frame: *Frame) void {
        while (frame.pc < method.code.len) {
            const pc = frame.pc;

            if (std.mem.eql(u8, class.name, "HelloWorld") and
                std.mem.eql(u8, method.name, "main") and
                std.mem.eql(u8, method.descriptor, "([Ljava/lang/String;)V") and
                frame.pc == 3)
            {
                std.log.info("breakpoint {s}.{s}#{d}", .{ class.name, method.name, frame.pc });

                // 4
                // std.log.debug("{s}", .{toString(frame.stack.items[frame.stack.items.len - 1].ref)});

                // 19
                // std.log.debug("{d}", .{frame.stack.items[frame.stack.items.len - 1].int});

                //0
                // std.log.debug("0x{x:0>8} {d}", .{ frame.localVars[1].int, frame.localVars[2].int });
                // const values = getInstanceVar(frame.localVars[0].ref, "value", "[C").ref;
                // std.log.debug("{d}", .{values.len()});
                // for (values.object().slots) |value| {
                //     std.log.debug("0x{x:0>4}", .{value.char});
                // }
            }

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
                .@"return" => |ret| if (ret) |v| caller.push(v),
                .exception => caller.result = result,
            }
        } else {
            this.result = result;
            switch (result) {
                .@"return" => |v| {
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

    pub fn deinit(this: *This) void {
        for (this.stack.items) |frame| {
            frame.deinit();
        }
        this.stack.deinit();
        vm_free(this);
    }
};

fn printStackTrace(exception: JavaLangThrowable) void {
    const stackTrace = exception.object().internal.stackTrace;
    if (!stackTrace.isNull()) {
        const detailMessage = getInstanceVar(exception, "detailMessage", "Ljava/lang/String;").ref;
        if (!detailMessage.isNull()) {
            std.log.info("Exception: {s}", .{toString(detailMessage)});
        }
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
    @"return": ?Value,
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

    /// load local var at index
    pub fn load(this: *This, index: u16) Value {
        return this.localVars[index];
    }

    /// store local var at index
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

    pub fn @"return"(this: *This, value: ?Value) void {
        this.result = .{ .@"return" = value };
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

    pub fn deinit(this: *This) void {
        this.stack.deinit();
        vm_free(this.localVars);
        vm_free(this);
    }

    const This = @This();
};

pub const Context = struct {
    t: *Thread,
    f: *Frame,
    c: *const Class,
    m: *const Method,

    const This = @This();
    pub fn immidiate(this: *const This, comptime T: type) T {
        const size = @bitSizeOf(T) / 8;
        const v = Endian.Big.load(T, this.m.code[this.f.pc + this.f.offset .. this.f.pc + this.f.offset + size]);
        this.f.offset += size;
        return v;
    }

    pub fn padding(this: *const This) void {
        for (0..4) |i| {
            const pos = this.f.pc + this.f.offset + i;
            if (pos % 4 == 0) {
                this.f.offset += @intCast(i);
                break;
            }
        }
    }
};
