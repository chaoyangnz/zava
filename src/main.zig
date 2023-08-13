const std = @import("std");
const bootstrap = @import("./bootstrap.zig").bootstrap;

var logFile: std.fs.File = undefined;

pub fn main() !void {
    logFile = std.fs.cwd().createFile("zava.log", .{ .read = true }) catch unreachable;
    defer logFile.close();

    bootstrap();
}

pub const std_options = struct {
    pub const log_level = .info;
    pub const logFn = log;
};

fn log(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    _ = level;

    switch (scope) {
        .instruction => logFile.writer().print(format, args) catch return,
        .console => std.debug.print(format ++ "\n", args),
        else => logFile.writer().print("\n" ++ format, args) catch return,
    }
}
