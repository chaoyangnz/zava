const std = @import("std");
const bootstrap = @import("./bootstrap.zig").bootstrap;

// const hellworld = @embedFile("./HelloWorld.class");
// const calendar = @embedFile("./Calendar.class");

pub const log_level: std.log.Level = .info;

pub fn main() !void {
    bootstrap("HelloWorld");
}
