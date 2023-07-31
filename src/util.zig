//// high-level APIs in VM
///
const std = @import("std");
const Class = @import("./type.zig").Class;
const Method = @import("./type.zig").Method;
const Value = @import("./type.zig").Value;
const Reference = @import("./type.zig").Reference;

const resolveClass = @import("./method_area.zig").resolveClass;
const resolveField = @import("./method_area.zig").resolveField;

const current = @import("./engine.zig").current;

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

/// Java classfile using u16 as max count.
/// max fields, methods, constants, max pc offset etc.
pub fn jsize(n: anytype) u16 {
    return switch (@TypeOf(n)) {
        i8, i16 => {
            std.debug.assert(n >= 0);
            return @intCast(n);
        },
        i32 => {
            std.debug.assert(n >= 0 and n <= 0x0FFFF);
            return @intCast(n);
        },
        usize => {
            std.debug.assert(n <= 0xFFFF);
            return @intCast(n);
        },
        else => unreachable,
    };
}

/// Java language using u32 as max count.
/// array max length, code max length etc.
pub fn jcount(n: anytype) u32 {
    return switch (@TypeOf(n)) {
        i8, i16, i32 => {
            std.debug.assert(n >= 0);
            return @intCast(n);
        },
        usize => {
            std.debug.assert(n <= 0xFFFF);
            return @intCast(n);
        },
        else => unreachable,
    };
}

/// invoke method by name and signature.
/// the invoked method is just the specified method without virtual / overridding
pub fn invoke(definingClass: ?*const Class, class: string, name: string, descriptor: string, args: []Value, static: bool) void {
    const c = resolveClass(definingClass, class);
    const m = c.method(name, descriptor, static);
    current().invoke(c, m, args);
}

/// check if `class` is a subclass of `this`
pub fn isAssignableFrom(class: *const Class, subclass: *const Class) bool {
    if (class == subclass) return true;

    if (class.accessFlags.interface) {
        var c = subclass;
        if (c == class) return true;
        for (c.interfaces) |interface| {
            if (isAssignableFrom(class, resolveClass(c, interface))) {
                return true;
            }
        }
        if (std.mem.eql(u8, c.superClass, "")) {
            return false;
        }
        return isAssignableFrom(class, resolveClass(c, c.superClass));
    } else if (class.isArray) {
        if (subclass.isArray) {
            // covariant
            return isAssignableFrom(resolveClass(class, class.componentType), resolveClass(subclass, subclass.componentType));
        }
    } else {
        var c = subclass;
        if (c == class) {
            return true;
        }
        if (std.mem.eql(u8, c.superClass, "")) {
            return false;
        }

        return isAssignableFrom(class, resolveClass(c, c.superClass));
    }

    return false;
}

pub fn setInstanceVar(reference: Reference, name: string, descriptor: string, value: Value) void {
    const resolvedField = resolveField(reference.class(), reference.class().name, name, descriptor);
    reference.set(resolvedField.field.slot, value);
}

pub fn getInstanceVar(reference: Reference, name: string, descriptor: string) Value {
    const resolvedField = resolveField(reference.class(), reference.class().name, name, descriptor);
    return reference.get(resolvedField.field.slot);
}
