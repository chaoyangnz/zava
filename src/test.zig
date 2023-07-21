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
    _ = allocator;

    const a = [_]u8{ 1, 2, 3 }; // [3]u8
    std.log.warn("{}", .{@TypeOf(a)});

    const b = "123"; // *[3:0]u8
    std.log.warn("{}", .{@TypeOf(b)});

    const p1 = &a;
    std.log.warn("{}", .{@TypeOf(p1)});
    const p2 = b;
    std.log.warn("{}", .{@TypeOf(p2)});

    const s1: []const u8 = &a; // *const [3]u8
    std.log.warn("{}", .{@TypeOf(s1)});
    const s2: []const u8 = b; // *const [3:0]u8
    std.log.warn("{}", .{@TypeOf(s2)});

    const a1 = a[0..1]; // [2]u8
    std.log.warn("{}", .{@TypeOf(a1)});

    var a11 = a[0..1]; // *const [2]u8
    std.log.warn("{}", .{@TypeOf(a11)});

    var i: u8 = 0;
    const a3 = a[i..1]; // []u8
    std.log.warn("{}", .{@TypeOf(a3)});

    var a33 = a[i..1]; // []const u8
    std.log.warn("{}", .{@TypeOf(a33)});
}
