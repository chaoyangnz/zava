const std = @import("std");

pub const string = []const u8;

test "endian" {
    std.testing.log_level = .debug;

    const bytes = &[_]u8{ 0x1, 0x2, 0x3, 0x4 };

    try std.testing.expectEqual(@as(i8, 0x01), Endian.Big.load(i8, bytes));
    try std.testing.expectEqual(@as(u8, 0x01), Endian.Big.load(u8, bytes));
    try std.testing.expectEqual(@as(i16, 0x0102), Endian.Big.load(i16, bytes));
    try std.testing.expectEqual(@as(u16, 0x0102), Endian.Big.load(u16, bytes));
    try std.testing.expectEqual(@as(i32, 0x01020304), Endian.Big.load(i32, bytes));
    try std.testing.expectEqual(@as(u32, 0x01020304), Endian.Big.load(u32, bytes));

    try std.testing.expectEqual(@as(i8, 0x01), Endian.Little.load(i8, bytes));
    try std.testing.expectEqual(@as(u8, 0x01), Endian.Little.load(u8, bytes));
    try std.testing.expectEqual(@as(i16, 0x0201), Endian.Little.load(i16, bytes));
    try std.testing.expectEqual(@as(u16, 0x0201), Endian.Little.load(u16, bytes));
    try std.testing.expectEqual(@as(i32, 0x04030201), Endian.Little.load(i32, bytes));
    try std.testing.expectEqual(@as(u32, 0x04030201), Endian.Little.load(u32, bytes));
}

pub const Endian = enum {
    Little,
    Big,

    pub fn load(this: Endian, comptime T: type, bytes: []const u8) T {
        switch (this) {
            .Big => {
                return switch (T) {
                    u8, i8 => @bitCast(bytes[0]),
                    u16, i16 => @bitCast(@as(u16, bytes[0]) << 8 | @as(u16, bytes[1])),
                    u32, i32 => @bitCast(@as(u32, bytes[0]) << 24 | @as(u32, bytes[1]) << 16 | @as(u32, bytes[2]) << 8 | @as(u32, bytes[3])),
                    else => unreachable,
                };
            },
            .Little => {
                return switch (T) {
                    u8, i8 => @bitCast(bytes[0]),
                    u16, i16 => @bitCast(@as(u16, bytes[1]) << 8 | @as(u16, bytes[0])),
                    u32, i32 => @bitCast(@as(u32, bytes[3]) << 24 | @as(u32, bytes[2]) << 16 | @as(u32, bytes[1]) << 8 | @as(u32, bytes[0])),
                    else => unreachable,
                };
            },
        }
    }
};

pub fn icast(n: anytype, comptime T: type) T {
    const N = @TypeOf(n);
    const nt = @typeInfo(N).Int;
    const tt = @typeInfo(T).Int;

    if (nt.signedness == tt.signedness) {
        return if (nt.bits <= tt.bits) n else @truncate(n);
    }

    if (nt.signedness == .signed and tt.signedness == .unsigned) {
        if (nt.bits <= tt.bits) { // i8 -> u16
            // +01101010 -> 0000000 01101010
            // -11101010 -> 0000000 11101010
            return @intCast(n);
        } else { // i16 -> u8
            // +01101010 1011101 -> 1011101
            // -11101010 1011101 -> 1011101
            std.log.warn("cast will truncate and signedness may not reserved, use @intCast if you are use it can fit", .{});
            const UN = @Type(std.builtin.Type.Int{ .signedness = .unsigned, .bits = nt.bits });
            const un: UN = @bitCast(n);
            return @truncate(un);
        }
    }

    if (nt.signedness == .unsigned and tt.signedness == .signed) {
        if (nt.bits <= tt.bits) { // u8 -> i16
            // equivlant to @as(T, n)
            // 01101010 -> +0000000 01101010
            // 11101010 -> +0000000 11101010
            return @intCast(n);
        } else { // u16 -> i8
            // 01101010 1011101 -> -1011101
            // 11101010 1011101 -> -1011101
            std.log.warn("cast will truncate, use @intCast if you are use it can fit", .{});
            const UT = @Type(std.builtin.Type.Int{ .signedness = .unsigned, .bits = tt.bits });
            const ut: UT = @intCast(n);
            return @truncate(ut);
        }
    }
}

test "cast" {
    std.testing.log_level = .debug;

    std.log.info("{}", .{@typeInfo(u32)});
}

/// create a bounded slice, the max length is known at runtime.
/// It is not supposed to be resized.
pub fn make(comptime T: type, capacity: usize, allocator: std.mem.Allocator) []T {
    return allocator.alloc(T, capacity) catch unreachable;
}

pub fn clone(str: string, allocator: std.mem.Allocator) string {
    const newstr = allocator.alloc(u8, str.len) catch unreachable;
    @memcpy(newstr, str);
    return newstr;
}

pub fn new(comptime T: type, value: T, allocator: std.mem.Allocator) *T {
    const slice = allocator.alloc(T, 1) catch unreachable;
    var ptr = &slice[0];
    ptr.* = value;
    return ptr;
}

// -------------- VM internal memory allocator ------------

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
// vm internal structure allocation, like Thread, Frame, ClassFile etc.
pub const vm_allocator = arena.allocator();

/// concat strings and create a new one
/// the caller owns the memory
pub fn concat(strings: []const string) string {
    return std.mem.concat(vm_allocator, u8, strings) catch unreachable;
}
