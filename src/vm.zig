pub const std = @import("std");

// -------------- VM internal/off-heap memory allocator ------------

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
// vm internal structure allocation, like Thread, Frame, ClassFile etc.
pub const vm_allocator = arena.allocator();

/// allocate a slice of elements
pub fn vm_make(comptime T: type, capacity: usize) []T {
    return vm_allocator.alloc(T, capacity) catch unreachable;
}

pub fn vm_new(comptime T: type, value: T) *T {
    var ptr = vm_allocator.create(T) catch unreachable;
    ptr.* = value;
    return ptr;
}

pub fn vm_free(ptr: anytype) void {
    switch (@typeInfo(@TypeOf(ptr))) {
        .Pointer => |p| {
            // builtin.Type.Pointer{ .size = builtin.Type.Pointer.Size.Slice, .is_const = true, .is_volatile = false, .alignment = 1, .address_space = builtin.AddressSpace.generic, .child = u8, .is_allowzero = false, .sentinel = null }
            // builtin.Type.Pointer{ .size = builtin.Type.Pointer.Size.One, .is_const = false, .is_volatile = false, .alignment = 1, .address_space = builtin.AddressSpace.generic, .child = u8, .is_allowzero = false, .sentinel = null }
            if (p.size == .One) {
                vm_allocator.destroy(ptr);
            } else if (p.size == .Slice) {
                vm_allocator.free(ptr);
            } else {
                unreachable;
            }
        },
        else => unreachable,
    }
}

// -------------- strings ------------

pub const string = []const u8;

pub const strings = struct {
    pub fn equals(str1: []const u8, str2: []const u8) bool {
        return std.mem.eql(u8, str1, str2);
    }

    /// concat multiple strings.
    /// the caller owns the memory
    /// deinit with `defer vm_free(..)`
    pub fn concat(slices: []const string) string {
        return std.mem.concat(vm_allocator, u8, slices) catch unreachable;
    }
};

/// Endian
/// Java is using Big Endian
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

/// convert Java modified UTF-8 bytes from/to Java char (u16)
/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-4.html#jvms-4.4.7
pub const UTF8 = struct {
    /// modified utf8 -> ucs2 (char)
    /// the caller owns the memory
    pub fn encode(chars: []u16) []const u8 {
        var str = std.ArrayList(u8).init(vm_allocator);
        defer str.deinit();

        // decode Java chars to Java modified UTF-8 bytes
        var i: usize = 0;
        while (i < chars.len) {
            var ch = chars[i];
            if (ch == 0x0000) {
                str.append(0b11000000) catch unreachable;
                str.append(0b10000000) catch unreachable;
                i += 1;
            } else if (ch >= 0x01 and ch <= 0x7F) {
                str.append(@truncate(ch)) catch unreachable;
                i += 1;
            } else if (ch >= 0x0080 and ch <= 0x07FF) {
                const x = (0b110 << 5) + ((ch >> 6) & 0x1F);
                const y = (0x10 << 6) + (ch & 0x3F);
                str.append(@truncate(x)) catch unreachable;
                str.append(@truncate(y)) catch unreachable;
                i += 1;
            } else if (ch >= 0x0800 and ch <= 0xFFFF) {
                const x = (0b1110 << 4) + ((ch >> 12) & 0xF);
                const y = (0b10 << 6) + ((ch >> 6) & 0x3F);
                const z = (0b10 << 6) + (ch & 0x3F);
                str.append(@truncate(x)) catch unreachable;
                str.append(@truncate(y)) catch unreachable;
                str.append(@truncate(z)) catch unreachable;
                i += 1;
            } else {
                if (ch >= 0xD800 and ch <= 0xDBFF) {
                    const highSurrogate = ch;

                    std.debug.assert(i <= chars.len - 2);
                    ch = chars[i + 1];
                    if (ch >= 0xDC00 and ch <= 0xDFFF) {
                        const lowSurrogate = ch;
                        const codepoint: u32 = (@as(u32, highSurrogate) << 16) + lowSurrogate;
                        const u = 0b11101101;
                        const v = (0b1010 << 4) + ((codepoint >> 16) & 0x0F);
                        const w = (0b10 << 6) + ((codepoint >> 10) & 0x3F);
                        str.append(@truncate(u)) catch unreachable;
                        str.append(@truncate(v)) catch unreachable;
                        str.append(@truncate(w)) catch unreachable;
                        const x = 0b11101101;
                        const y = (0b1011 << 4) + ((codepoint >> 6) & 0x0F);
                        const z = (0b10 << 6) + (codepoint & 0x3F);
                        str.append(@truncate(x)) catch unreachable;
                        str.append(@truncate(y)) catch unreachable;
                        str.append(@truncate(z)) catch unreachable;
                    } else {
                        std.debug.panic("malformed UES16: issing low surrogate", .{});
                    }
                    i += 2;
                }
            }
        }

        return str.toOwnedSlice() catch unreachable;
    }

    /// ucs2 (char) -> modified utf8
    /// the caller owns the memory
    pub fn decode(bytes: []const u8) []u16 {
        var chars = std.ArrayList(u16).init(vm_allocator);
        defer chars.deinit();

        // encode Java modified UTF-8 bytes to Java chars
        // https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-4.html#jvms-4.4.7
        var i: usize = 0;
        while (i < bytes.len) {
            var x: u16 = bytes[i];
            var y: u16 = undefined;
            var z: u16 = undefined;
            var u: u32 = undefined;
            var v: u32 = undefined;
            var w: u32 = undefined;
            var ch: u16 = undefined;
            if (x >= 0x01 and x <= 0x7F) {
                ch = x;
                std.debug.assert(ch >= 0x0001 and ch <= 0x007F);
                chars.append(ch) catch unreachable;
                i += 1;
            } else if ((x >> 5) == 0b110) {
                std.debug.assert(i <= bytes.len - 2);
                y = bytes[i + 1];
                std.debug.assert((y >> 6) == 0b10);
                ch = ((x & 0x1F) << 6) + (y & 0x3F);
                std.debug.assert(ch == 0x0000 or (ch >= 0x0080 and ch <= 0x07FF));
                chars.append(ch) catch unreachable;
                i += 2;
            } else if ((x >> 4) == 0b1110) {
                std.debug.assert(i <= bytes.len - 3);
                y = bytes[i + 1];
                std.debug.assert((y >> 6) == 0b10);
                z = bytes[i + 2];
                std.debug.assert((z >> 6) == 0b10);
                ch = ((x & 0x0F) << 12) + ((y & 0x3F) << 6) + (z & 0x3F);
                std.debug.assert(ch >= 0x0800 and ch <= 0xFFFF);
                chars.append(ch) catch unreachable;
                i += 3;
            } else if (x == 0b11101101) {
                std.debug.assert(i <= bytes.len - 6);
                u = bytes[i];
                v = bytes[i + 1];
                std.debug.assert((v >> 4) == 0b1010);
                w = bytes[i + 2];
                std.debug.assert((w >> 6) == 0b10);
                x = bytes[i + 3];
                std.debug.assert(x == 0b11101101);
                y = bytes[i + 4];
                std.debug.assert((y >> 4) == 0b1011);
                z = bytes[i + 5];
                std.debug.assert((y >> 6) == 0b10);
                const codepoint: u32 = 0x10000 + ((v & 0x0F) << 16) + ((w & 0x3F) << 10) + ((y & 0x0F) << 6) + (z & 0x3F);
                const highSurrogate: u16 = @truncate(codepoint >> 16);
                const lowSurrogate: u16 = @truncate(codepoint);
                chars.append(highSurrogate) catch unreachable;
                chars.append(lowSurrogate) catch unreachable;
                i += 6;
            }
        }

        return chars.toOwnedSlice() catch unreachable;
    }
};

test "utf8" {
    std.testing.log_level = .debug;

    // String a = "abc安装\uD841\uDF31"; // abc安装𠜱
    const bytes = &[_]u8{
        // a b c
        0x61, 0x62, 0x63,
        // 安
        0xe5, 0xae,
        // 装
        0x89,
        0xe8,
        //𠜱
        0xa3, 0x85,
        0xed, 0xa1, 0x81,
        0xed, 0xbc, 0xb1,
    };

    const chars = UTF8.decode(bytes);

    for (chars) |ch| {
        std.log.info("{x:0>4}", .{ch});
    }
    try std.testing.expectEqualSlices(u16, &[_]u16{
        // a b c
        0x0061, 0x0062, 0x0063,
        // 安装
        0x5B89, 0x88C5,
        //𠜱
        0xD841,
        0xDF31,
    }, chars);

    const utf8Bytes = UTF8.encode(chars);

    try std.testing.expectEqualSlices(u8, bytes, utf8Bytes);

    std.log.info("{x:0>8}", .{65536});
}

pub const Name = struct {
    pub fn descriptor(jname: []const u8) []const u8 {
        if (std.mem.eql(u8, jname, "byte")) {
            return "B";
        }
        if (std.mem.eql(u8, jname, "char")) {
            return "C";
        }
        if (std.mem.eql(u8, jname, "short")) {
            return "S";
        }
        if (std.mem.eql(u8, jname, "int")) {
            return "I";
        }
        if (std.mem.eql(u8, jname, "long")) {
            return "J";
        }
        if (std.mem.eql(u8, jname, "float")) {
            return "F";
        }
        if (std.mem.eql(u8, jname, "double")) {
            return "D";
        }
        if (std.mem.eql(u8, jname, "boolean")) {
            return "Z";
        }
        if (jname[0] == '[') {
            return jname;
        }
        const desc = vm_make(u8, jname.len + 2);
        desc[0] = 'L';
        for (0..jname.len) |i| {
            const ch = jname[i];
            desc[i + 1] = if (ch == '.') '/' else ch;
        }
        desc[jname.len + 1] = ';';
        return desc;
    }

    pub fn name(desc: []const u8) []const u8 {
        const ch = desc[0];
        return switch (ch) {
            'B', 'C', 'D', 'F', 'I', 'J', 'S', 'Z', '[' => desc,
            'L' => desc[1 .. desc.len - 1],
            else => unreachable,
        };
    }

    pub fn java_name(desc: []const u8) []const u8 {
        const ch = desc[0];
        return switch (ch) {
            'B' => "byte",
            'C' => "char",
            'D' => "double",
            'F' => "float",
            'I' => "int",
            'J' => "long",
            'S' => "short",
            'Z' => "boolean",
            '[' => desc,
            'L' => blk: {
                const slice = desc[1 .. desc.len - 1];
                const jname = vm_make(u8, slice.len);
                for (0..slice.len) |i| {
                    const c = slice[i];
                    jname[i] = if (c == '/') '.' else c;
                }
                break :blk jname;
            },
            else => unreachable,
        };
    }
};

test "name" {
    std.testing.log_level = .debug;
    try std.testing.expectEqualSlices(u8, "B", Name.descriptor("byte"));
    try std.testing.expectEqualSlices(u8, "C", Name.descriptor("char"));
    try std.testing.expectEqualSlices(u8, "S", Name.descriptor("short"));
    try std.testing.expectEqualSlices(u8, "I", Name.descriptor("int"));
    try std.testing.expectEqualSlices(u8, "J", Name.descriptor("long"));
    try std.testing.expectEqualSlices(u8, "F", Name.descriptor("float"));
    try std.testing.expectEqualSlices(u8, "D", Name.descriptor("double"));
    try std.testing.expectEqualSlices(u8, "Z", Name.descriptor("boolean"));
    try std.testing.expectEqualSlices(u8, "Ljava/lang/InterruptedException;", Name.descriptor("java.lang.InterruptedException"));

    try std.testing.expectEqualSlices(u8, "B", Name.name("B"));
    try std.testing.expectEqualSlices(u8, "C", Name.name("C"));
    try std.testing.expectEqualSlices(u8, "S", Name.name("S"));
    try std.testing.expectEqualSlices(u8, "I", Name.name("I"));
    try std.testing.expectEqualSlices(u8, "J", Name.name("J"));
    try std.testing.expectEqualSlices(u8, "F", Name.name("F"));
    try std.testing.expectEqualSlices(u8, "D", Name.name("D"));
    try std.testing.expectEqualSlices(u8, "Z", Name.name("Z"));
    try std.testing.expectEqualSlices(u8, "java/lang/InterruptedException", Name.name("Ljava/lang/InterruptedException;"));

    try std.testing.expectEqualSlices(u8, "byte", Name.java_name("B"));
    try std.testing.expectEqualSlices(u8, "char", Name.java_name("C"));
    try std.testing.expectEqualSlices(u8, "short", Name.java_name("S"));
    try std.testing.expectEqualSlices(u8, "int", Name.java_name("I"));
    try std.testing.expectEqualSlices(u8, "long", Name.java_name("J"));
    try std.testing.expectEqualSlices(u8, "float", Name.java_name("F"));
    try std.testing.expectEqualSlices(u8, "double", Name.java_name("D"));
    try std.testing.expectEqualSlices(u8, "boolean", Name.java_name("Z"));
    try std.testing.expectEqualSlices(u8, "java.lang.InterruptedException", Name.java_name("Ljava/lang/InterruptedException;"));
}
