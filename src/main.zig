const std = @import("std");
const bootstrap = @import("./bootstrap.zig").bootstrap;

// const hellworld = @embedFile("./HelloWorld.class");
// const calendar = @embedFile("./Calendar.class");

var logFile: std.fs.File = undefined;

pub fn main() !void {
    logFile = std.fs.cwd().createFile("zava.log", .{ .read = true }) catch unreachable;
    defer logFile.close();

    bootstrap("HelloWorld");
}

pub const std_options = struct {
    pub const log_level = .debug;
    pub const logFn = vmLogFn;
};

pub fn vmLogFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    _ = level;
    const scope_prefix = switch (scope) {
        .instruction => "",
        else => "\n",
    };

    logFile.writer().print(scope_prefix ++ format, args) catch return;
}
