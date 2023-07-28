const std = @import("std");
const string = @import("./shared.zig").string;
const new = @import("./shared.zig").new;
const vm_allocator = @import("./shared.zig").vm_allocator;
const Value = @import("./type.zig").Value;
const NULL = @import("./type.zig").NULL;
const resolveClass = @import("./method_area.zig").resolveClass;
const Thread = @import("./engine.zig").Thread;
const attach = @import("./engine.zig").attach;

pub fn bootstrap(mainClass: string) void {
    var thread = new(Thread, .{
        .id = std.Thread.getCurrentId(),
        .name = "main",
    }, vm_allocator);

    attach(thread);

    const class = resolveClass(null, mainClass);
    const method = class.method("main", "([Ljava/lang/String;)V", true);
    if (method == null) {
        std.debug.panic("main method not found", .{});
    }

    var args = [_]Value{.{ .ref = NULL }};
    thread.invoke(class, method.?, &args);
}
