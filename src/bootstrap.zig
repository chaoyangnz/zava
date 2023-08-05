const std = @import("std");
const string = @import("./util.zig").string;

const Value = @import("./type.zig").Value;
const NULL = @import("./type.zig").NULL;

const resolveClass = @import("./method_area.zig").resolveClass;

const Thread = @import("./engine.zig").Thread;
const attach = @import("./engine.zig").attach;

const vm_make = @import("./vm.zig").vm_make;
const vm_new = @import("./vm.zig").vm_new;

pub fn bootstrap(mainClass: string) void {
    std.debug.assert(@bitSizeOf(usize) >= 32);
    var thread = vm_new(Thread, .{
        .id = std.Thread.getCurrentId(),
        .name = "main",
    });

    attach(thread);

    const systemClass = resolveClass(null, "java/lang/System");
    const initializeSystemClass = systemClass.method("initializeSystemClass", "()V", true);
    thread.invoke(systemClass, initializeSystemClass.?, vm_make(Value, 0));

    // const systemClassLoader = resolveClass(null, "java/lang/ClassLoader");
    // const getSystemClassLoader = systemClass.method("getSystemClassLoader", "()Ljava/lang/ClassLoader;", true);
    // thread.invoke(systemClassLoader, getSystemClassLoader, make(Value, 0, vm_allocator));

    const class = resolveClass(null, mainClass);
    const method = class.method("main", "([Ljava/lang/String;)V", true);
    if (method == null) {
        std.debug.panic("main method not found", .{});
    }

    var args = vm_make(Value, 1);
    args[0] = .{ .ref = NULL };
    thread.invoke(class, method.?, args);
}
