const std = @import("std");
const bootstrap = @import("./bootstrap.zig").bootstrap;
const system = @import("./vm.zig").system;

pub fn main() !void {
    system.init();
    defer system.deinit();

    bootstrap();
}

pub const std_options = .{ .log_level = .info, .logFn = system.logFn };
