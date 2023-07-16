const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const list = std.ArrayList(u8).initCapacity(allocator, 100);

    const slice = list.items;

    std.debug.print("{d}", .{slice.len});
}
