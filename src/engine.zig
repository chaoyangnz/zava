const std = @import("std");

const Endian = @import("./vm.zig").Endian;
const string = @import("./vm.zig").string;
const size16 = @import("./vm.zig").size16;
const vm_stash = @import("./vm.zig").vm_stash;
const mem = @import("./mem.zig");

const Value = @import("./type.zig").Value;
const NULL = @import("./type.zig").NULL;
const Class = @import("./type.zig").Class;
const Method = @import("./type.zig").Method;
const JavaLangThrowable = @import("./type.zig").JavaLangThrowable;

const Instruction = @import("./instruction.zig").Instruction;
const interpret = @import("./instruction.zig").interpret;

const native = @import("./native.zig");

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
    stack: Stack = vm_stash.list(*Frame),

    daemon: bool = false,

    status: Status = undefined,

    // last frame return value
    result: ?Result = null,

    const Stack = mem.Stash.List(*Frame);
    const Status = enum { started, sleeping, parking, waiting, interrupted };

    pub fn depth(this: *const This) usize {
        return this.stack.len();
    }

    pub fn indent(this: *const This) string {
        var str = vm_stash.make(u8, this.depth() * 4);
        for (0..this.depth() * 4) |i| {
            str[i] = ' ';
        }
        return str;
    }

    /// active frame: top in the stack
    pub fn active(this: *This) ?*Frame {
        return this.stack.peek();
    }

    /// pop is supposed to be ONLY called when return and throw
    fn pop(this: *This) void {
        const frame = this.stack.pop();
        if (frame == null) return;
        frame.?.deinit();
    }

    fn push(this: *This, frame: *Frame) void {
        if (this.depth() >= MAX_CALL_STACK) {
            std.debug.panic("Max. call stack exceeded", .{});
        }
        return this.stack.push(frame);
    }

    const This = @This();

    pub fn invoke(this: *This, class: *const Class, method: *const Method, args: []const Value) void {
        const is_native = method.access_flags.native;

        // prepare context
        const frame = if (is_native) this.active().? else vm_stash.new(Frame, .{
            .class = class,
            .method = method,
            .pc = 0,
            .local_vars = vm_stash.make(Value, method.max_locals),
            .stack = vm_stash.bounded_list(Value, method.max_stack),
            .offset = 1,
        });
        const context = .{ .t = this, .c = class, .m = method, .f = frame };
        const icon = if (is_native) "🔸" else "🔹";
        std.log.info("{s}  {s}{s}.{s}{s}", .{ this.indent(), icon, class.name, method.name, method.descriptor });

        // call it
        if (!is_native) this.push(frame);
        const callFn: CallFn = if (is_native) native.call else call;
        const result = callFn(context, args);
        if (!is_native) this.pop();

        // end current thread or continue the caller frame if any
        // always exec the top frame in the call stack until no frame in stack
        // return out of method or throw out of a method
        var top = this.active();
        if (top) |caller| {
            // pass return or exception to the caller
            // the caller is still in the stack, so the caller will continue the execution
            switch (result) {
                .@"return" => |ret| if (ret) |v| caller.push(v),
                .exception => caller.result = result,
            }
        } else {
            // it is time to end current thread
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
        vm_stash.free(this);
    }
};

/// Java method call
/// intended to be called by Thread only
fn call(ctx: Context, args: []const Value) Result {
    // put args to local vars
    var i: usize = 0;
    for (args) |arg| {
        ctx.f.local_vars[i] = arg;
        switch (arg) {
            .long, .double => i += 2,
            else => i += 1,
        }
    }

    while (ctx.f.pc < ctx.m.code.len) {
        const pc = ctx.f.pc;

        // if (breakpoint(ctx, "java/lang/String", "bytes", "[b", 0)) {
        //     noop();
        // }

        const instruction = interpret(ctx);

        // after exec instruction
        if (ctx.f.result) |result| {
            return result;
        }

        // normal next rather than jump
        if (pc == ctx.f.pc) {
            ctx.f.pc += instruction.length;
        }
        // reset offset
        ctx.f.offset = 1;
    }
    // supposed to be never reach here
    @panic("run out of code: either return not found or no exception thrown");
}

fn printStackTrace(exception: JavaLangThrowable) void {
    const log = std.log.scoped(.console);
    const stack_trace = exception.object().internal.stack_trace;
    if (!stack_trace.isNull()) {
        const detailMessage = getInstanceVar(exception, "detailMessage", "Ljava/lang/String;").ref;
        if (!detailMessage.isNull()) {
            log.warn("Exception: {s}", .{toString(detailMessage)});
        }
        for (0..stack_trace.len()) |i| {
            const stackTraceElement = stack_trace.get(size16(i)).ref;
            const className = getInstanceVar(stackTraceElement, "declaringClass", "Ljava/lang/String;").ref;
            const methodName = getInstanceVar(stackTraceElement, "methodName", "Ljava/lang/String;").ref;
            const pc = getInstanceVar(stackTraceElement, "lineNumber", "I").int;
            log.warn("    at {s}.{s} #{d}", .{ toString(className), toString(methodName), pc });
        }
    }
}

pub const CallFn = *const fn (ctx: Context, args: []const Value) Result;

pub const Result = union(enum) {
    // null represents void
    @"return": ?Value,
    exception: JavaLangThrowable,
};

pub const Context = struct {
    t: *Thread,
    f: *Frame,
    // assert f.class == c and f.method = m
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

pub const Frame = struct {
    class: *const Class,
    method: *const Method,
    // if this this is current this, the pc is for the pc of this thread;
    // otherwise, it is a snapshot one since the last time
    pc: u32,
    // long and double will occupy two variable indexes. Must follow!! because local variables are operated by index
    local_vars: []Value,
    // operand stack
    // As per jvms, a value of type `long` or `double` contributes two units to the indices and a value of any other type contributes one unit
    // But here we use long and double only use one unit. There is not any violation, because operand stack is never operated by index
    stack: Stack,
    // operand offset: internal use only. For an instruction, initially it always starts from the byte after opcode of pc.
    // Each time read an operand, it advanced.
    offset: u32,

    result: ?Result = null,

    const Stack = mem.Stash.List(Value);
    pub fn pop(this: *This) Value {
        return this.stack.pop().?;
    }

    pub fn push(this: *This, value: Value) void {
        return this.stack.push(value);
    }

    pub fn clear(this: *This) void {
        return this.stack.clear();
    }

    /// load local var at index
    pub fn load(this: *This, index: u16) Value {
        return this.local_vars[index];
    }

    /// store local var at index
    pub fn store(this: *This, index: u16, value: Value) void {
        this.local_vars[index] = value;
    }

    /// next pc with offset
    pub fn next(this: *This, offset: i32) void {
        const sum = @addWithOverflow(@as(i33, this.pc), @as(i33, offset));
        if (sum[1] > 0) {
            unreachable;
        }
        this.pc = @intCast(sum[0]);
    }

    /// put return result
    pub fn @"return"(this: *This, value: ?Value) void {
        this.result = .{ .@"return" = value };
    }

    /// put exception result
    pub fn throw(this: *This, exception: JavaLangThrowable) void {
        std.log.info("🔥 throw {s}", .{exception.class().name});
        // printStackTrace(exception);
        this.result = .{ .exception = exception };
    }

    /// put exception result thrown by vm rather than Java code
    pub fn vm_throw(this: *This, name: string) void {
        std.log.info("{s}  🔥 vm throw {s}", .{ current().indent(), name });
        this.result = .{ .exception = newObject(null, name) };
    }

    pub fn deinit(this: *This) void {
        this.stack.deinit();
        vm_stash.free(this.local_vars);
        vm_stash.free(this);
    }

    const This = @This();
};

fn breakpoint(ctx: Context, class: string, method: string, descriptor: string, pc: u32) bool {
    if (std.mem.eql(u8, ctx.c.name, class) and
        std.mem.eql(u8, ctx.m.name, method) and
        std.mem.eql(u8, ctx.m.descriptor, descriptor) and
        ctx.f.pc == pc)
    {
        std.log.debug("breakpoint {s}.{s}#{d}", .{ ctx.c.name, ctx.m.name, ctx.f.pc });
        for (ctx.f.local_vars, 0..) |local, i| {
            std.log.debug(comptime "var{d}: {}", .{ i, local });
        }
        return true;
    }
    return false;
}

inline fn noop() void {}
