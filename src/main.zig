const std = @import("std");
const bootstrap = @import("./bootstrap.zig").bootstrap;

const hellworld = @embedFile("./HelloWorld.class");
const calendar = @embedFile("./Calendar.class");

pub fn main() !void {
    bootstrap("HelloWorld");
}
