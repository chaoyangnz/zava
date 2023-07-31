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

const vm_allocator = @import("./vm.zig").vm_allocator;
const vm_make = @import("./vm.zig").vm_make;

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

pub fn setStaticVar(class: *const Class, name: string, descriptor: string, value: Value) void {
    const field = class.field(name, descriptor, true).?;
    class.set(field.slot, value);
}

pub fn getStaticVar(class: *const Class, name: string, descriptor: string) Value {
    const field = class.field(name, descriptor, true).?;
    return class.get(field.slot);
}

/// convert java modified UTF-8 bytes to java char
/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-4.html#jvms-4.4.7
pub fn mutf8(bytes: []const u8) []const u16 {
    var t: usize = 0;
    var s: usize = 0;
    const chars = vm_make(u16, bytes.len);
    while (s < bytes.len) {
        const b1 = bytes[s] & 0xFF;
        s += 1;
        std.debug.assert((b1 >> 4) >= 0);
        if ((b1 >> 4) <= 7) {
            chars[t] = b1;
            t += 1;
        } else if ((b1 >> 4) >= 8 and (b1 >> 4) <= 11) {
            std.debug.panic("malformed utf8", .{});
        } else if ((b1 >> 4) >= 12 and (b1 >> 4) <= 13) {
            std.debug.assert(s < bytes.len);
            const b2 = bytes[s] & 0xFF;
            s += 1;
            std.debug.assert(b2 & 0xC0 == 0x80);
            chars[t] = (b1 & 0x1F) << 6 | (b2 & 0x3F);
            t += 1;
        } else if ((b1 >> 4) == 14) {
            std.debug.assert(s < bytes.len);
            const b2 = bytes[s] & 0xFF;
            s += 1;
            std.debug.assert((b2 & 0xC0) == 0x80);
            std.debug.assert(s < bytes.len);
            const b3 = bytes[s] & 0xFF;
            s += 1;
            std.debug.assert((b3 & 0xC0) == 0x80);
            chars[t] = ((@as(u16, b1) & 0x0F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F);
            t += 1;
        } else {
            std.debug.panic("malformed utf8", .{});
        }
    }
    return chars;
}

test "muft8" {
    std.testing.log_level = .debug;
    const dir = std.fs.cwd();
    const file = dir.openFile("CharacterDataLatin1.class.bin", .{}) catch unreachable;
    const bytes = file.reader().readAllAlloc(vm_allocator, 1024 * 1024 * 10) catch unreachable;
    const chars = mutf8(bytes);
    for (chars) |ch| {
        std.log.info("{x:0>4}", .{ch});
    }
}
