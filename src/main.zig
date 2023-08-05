const std = @import("std");
const bootstrap = @import("./bootstrap.zig").bootstrap;

// const hellworld = @embedFile("./HelloWorld.class");
// const calendar = @embedFile("./Calendar.class");

pub const log_level: std.log.Level = .info;

var logFile: std.fs.File = undefined;

pub fn main() !void {
    logFile = std.fs.cwd().openFile("zava.log", .{ .mode = .read_write }) catch unreachable;
    defer logFile.close();

    bootstrap("HelloWorld");
}

pub const std_options = struct {
    // Set the log level to info
    pub const log_level = .info;

    // Define logFn to override the std implementation
    pub const logFn = myLogFn;
};

pub fn myLogFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    // Ignore all non-error logging from sources other than
    // .my_project, .nice_library and the default
    const scope_prefix = "(" ++ switch (scope) {
        .my_project, .nice_library, std.log.default_log_scope => @tagName(scope),
        else => if (@intFromEnum(level) <= @intFromEnum(std.log.Level.err))
            @tagName(scope)
        else
            return,
    } ++ "): ";

    const prefix = "zava [" ++ comptime level.asText() ++ "] " ++ scope_prefix;

    logFile.writer().print(prefix ++ format ++ "\n", args) catch return;
}
