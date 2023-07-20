const std = @import("std");

const A = struct {
    a: i16,
    b: []u8,
    c: u8,
};

pub const log_level: std.log.Level = .debug;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const list = std.ArrayList(u8).initCapacity(allocator, 100);

    const slice = list.items;

    std.debug.print("{d}", .{slice.len});

    const a: A = .{ .a = 16 };

    std.log.err("{}", .{a});
}
