const std = @import("std");
const string = @import("./vm.zig").string;
const vm_stash = @import("./vm.zig").vm_stash;
const size32 = @import("./vm.zig").size32;
const system = @import("./vm.zig").system;

const Value = @import("./type.zig").Value;

const resolveClass = @import("./method_area.zig").resolveClass;

const Thread = @import("./engine.zig").Thread;
const attach = @import("./engine.zig").attach;
const newArray = @import("./heap.zig").newArray;
const getJavaLangString = @import("./heap.zig").getJavaLangString;

pub fn bootstrap() void {
    // the host machine must be at least 32 bits
    std.debug.assert(@bitSizeOf(usize) >= 32);

    var thread = vm_stash.new(Thread, .{
        .id = std.Thread.getCurrentId(),
        .name = "main",
    });

    attach(thread);

    const systemClass = resolveClass(null, "java/lang/System");
    const initializeSystemClass = systemClass.method("initializeSystemClass", "()V", true);
    thread.invoke(systemClass, initializeSystemClass.?, &.{});

    // const systemClassLoader = resolveClass(null, "java/lang/ClassLoader");
    // const getSystemClassLoader = systemClass.method("getSystemClassLoader", "()Ljava/lang/ClassLoader;", true);
    // thread.invoke(systemClassLoader, getSystemClassLoader, make(Value, 0, vm_allocator));

    const process_args: [][]const u8 = std.process.argsAlloc(vm_stash.allocator) catch unreachable;
    defer vm_stash.free(process_args);

    std.debug.assert(process_args.len >= 1);

    if (process_args.len == 1) {
        system.out.print("Usage: zava [-options] class [args...]\n", .{});
        return;
    }

    const mainClass: string = process_args[1];
    const class = resolveClass(null, mainClass);
    const method = class.method("main", "([Ljava/lang/String;)V", true);
    if (method == null) {
        std.debug.panic("main method not found", .{});
    }

    const len = process_args.len - 2;
    var args = newArray(class, "[Ljava/lang/String;", size32(len));
    for (0..len) |i| {
        args.set(size32(i), .{ .ref = getJavaLangString(class, process_args[i + 2]) });
    }

    thread.invoke(class, method.?, &[_]Value{.{ .ref = args }});
}
