const std = @import("std");
const string = @import("./shared.zig").string;
const Value = @import("./value.zig").Value;
const NULL = @import("./value.zig").NULL;
const lookupClass = @import("./method_area.zig").lookupClass;
const Thread = @import("./engine.zig").Thread;

pub fn bootstrap(mainClass: string) void {
    const class = lookupClass(NULL, mainClass);
    const method = class.method("main", "([Ljava/lang/String;)V");
    if (method == null) {
        std.debug.panic("main method not found", .{});
    }

    var thread: Thread = .{
        .id = std.Thread.getCurrentId(),
        .name = "main",
    };
    var args = [_]Value{.{ .ref = NULL }};
    thread.invoke(class, method.?, &args);
}
