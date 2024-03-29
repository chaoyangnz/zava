pub const std = @import("std");
const mem = @import("./mem.zig");

/// -------------- VM internal/off-heap memory allocator ------------
// vm internal structure allocation, like Thread, Frame, ClassFile etc.
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
pub const vm_stash: mem.Stash = .{ .allocator = arena.allocator() };

/// -------------- strings ------------
pub const string = []const u8;

pub const strings = struct {
    pub fn equals(str1: []const u8, str2: []const u8) bool {
        return std.mem.eql(u8, str1, str2);
    }

    /// concat multiple strings.
    /// the caller owns the memory
    /// deinit with `defer vm_stash.free(..)`
    pub fn concat(slices: []const string) string {
        return std.mem.concat(vm_stash.allocator, u8, slices) catch unreachable;
    }
};

/// Endian
/// Java is using Big Endian
pub const Endian = enum {
    Little,
    Big,

    pub fn load(self: Endian, comptime T: type, bytes: []const u8) T {
        switch (self) {
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
pub fn size16(n: anytype) u16 {
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
pub fn size32(n: anytype) u32 {
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
pub const encoding = struct {
    /// modified utf8 -> ucs2 (char)
    /// encode Java modified UTF-8 bytes to Java chars
    /// the caller owns the memory
    pub fn encode(chars: []u16) []const u8 {
        var str = std.ArrayList(u8).init(vm_stash.allocator);
        defer str.deinit();

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

    /// modified utf8 -> ucs2 (char)
    /// decode Java modified UTF-8 bytes to Java chars
    /// the caller owns the memory
    pub fn decode(bytes: []const u8) []u16 {
        var chars = std.ArrayList(u16).init(vm_stash.allocator);
        defer chars.deinit();

        var i: usize = 0;
        while (i < bytes.len) {
            var x: u16 = bytes[i];
            var y: u16 = undefined;
            var z: u16 = undefined;

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
                const u: u32 = bytes[i];
                _ = u;
                const v: u32 = bytes[i + 1];
                std.debug.assert((v >> 4) == 0b1010);
                const w: u32 = bytes[i + 2];
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

test "encoding" {
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

    const chars = encoding.decode(bytes);

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

    const utf8Bytes = encoding.encode(chars);

    try std.testing.expectEqualSlices(u8, bytes, utf8Bytes);

    std.log.info("{x:0>8}", .{65536});
}

pub const naming = struct {
    /// convert java name to a descriptor
    pub fn descriptor(_jname: []const u8) []const u8 {
        if (strings.equals(_jname, "byte")) return "B";
        if (strings.equals(_jname, "char")) return "C";
        if (strings.equals(_jname, "short")) return "S";
        if (strings.equals(_jname, "int")) return "I";
        if (strings.equals(_jname, "long")) return "J";
        if (strings.equals(_jname, "float")) return "F";
        if (strings.equals(_jname, "double")) return "D";
        if (strings.equals(_jname, "boolean")) return "Z";
        if (_jname[0] == '[') return _jname;

        const desc = vm_stash.make(u8, _jname.len + 2);
        desc[0] = 'L';
        for (0.._jname.len) |i| {
            const ch = _jname[i];
            desc[i + 1] = if (ch == '.') '/' else ch;
        }
        desc[_jname.len + 1] = ';';
        return desc;
    }

    // vm binary name
    pub fn name(_descriptor: []const u8) []const u8 {
        const ch = _descriptor[0];
        return switch (ch) {
            'B', 'C', 'D', 'F', 'I', 'J', 'S', 'Z', '[' => _descriptor,
            'L' => _descriptor[1 .. _descriptor.len - 1],
            else => unreachable,
        };
    }

    // java lang spec name
    pub fn jname(_descriptor: []const u8) []const u8 {
        const ch = _descriptor[0];
        return switch (ch) {
            'B' => "byte",
            'C' => "char",
            'D' => "double",
            'F' => "float",
            'I' => "int",
            'J' => "long",
            'S' => "short",
            'Z' => "boolean",
            '[' => _descriptor,
            'L' => blk: {
                const slice = _descriptor[1 .. _descriptor.len - 1];
                const _jname = vm_stash.make(u8, slice.len);
                for (0..slice.len) |i| {
                    const c = slice[i];
                    _jname[i] = if (c == '/') '.' else c;
                }
                break :blk _jname;
            },
            else => unreachable,
        };
    }
};

test "name" {
    std.testing.log_level = .debug;
    try std.testing.expectEqualSlices(u8, "B", naming.descriptor("byte"));
    try std.testing.expectEqualSlices(u8, "C", naming.descriptor("char"));
    try std.testing.expectEqualSlices(u8, "S", naming.descriptor("short"));
    try std.testing.expectEqualSlices(u8, "I", naming.descriptor("int"));
    try std.testing.expectEqualSlices(u8, "J", naming.descriptor("long"));
    try std.testing.expectEqualSlices(u8, "F", naming.descriptor("float"));
    try std.testing.expectEqualSlices(u8, "D", naming.descriptor("double"));
    try std.testing.expectEqualSlices(u8, "Z", naming.descriptor("boolean"));
    try std.testing.expectEqualSlices(u8, "Ljava/lang/InterruptedException;", naming.descriptor("java.lang.InterruptedException"));

    try std.testing.expectEqualSlices(u8, "B", naming.name("B"));
    try std.testing.expectEqualSlices(u8, "C", naming.name("C"));
    try std.testing.expectEqualSlices(u8, "S", naming.name("S"));
    try std.testing.expectEqualSlices(u8, "I", naming.name("I"));
    try std.testing.expectEqualSlices(u8, "J", naming.name("J"));
    try std.testing.expectEqualSlices(u8, "F", naming.name("F"));
    try std.testing.expectEqualSlices(u8, "D", naming.name("D"));
    try std.testing.expectEqualSlices(u8, "Z", naming.name("Z"));
    try std.testing.expectEqualSlices(u8, "java/lang/InterruptedException", naming.name("Ljava/lang/InterruptedException;"));

    try std.testing.expectEqualSlices(u8, "byte", naming.jname("B"));
    try std.testing.expectEqualSlices(u8, "char", naming.jname("C"));
    try std.testing.expectEqualSlices(u8, "short", naming.jname("S"));
    try std.testing.expectEqualSlices(u8, "int", naming.jname("I"));
    try std.testing.expectEqualSlices(u8, "long", naming.jname("J"));
    try std.testing.expectEqualSlices(u8, "float", naming.jname("F"));
    try std.testing.expectEqualSlices(u8, "double", naming.jname("D"));
    try std.testing.expectEqualSlices(u8, "boolean", naming.jname("Z"));
    try std.testing.expectEqualSlices(u8, "java.lang.InterruptedException", naming.jname("Ljava/lang/InterruptedException;"));
}

pub const system = struct {
    /// application console: stdout/stderr/stdin
    pub const stdout = std.io.getStdOut().writer();
    pub const stderr = std.io.getStdErr().writer();
    pub const out = struct {
        pub fn print(comptime format: []const u8, args: anytype) void {
            stdout.print(format, args) catch return;
        }
    };
    pub const err = struct {
        pub fn print(comptime format: []const u8, args: anytype) void {
            stderr.print(format, args) catch return;
        }
    };

    /// assertion
    pub fn assert(ok: bool, comptime format: []const u8, args: anytype) void {
        if (!ok) {
            std.log.warn(format, args);
            unreachable;
        }
    }

    pub fn panic(comptime format: []const u8, args: anytype) void {
        std.debug.panic(format, args);
    }

    pub fn init() void {
        log_file = std.fs.cwd().createFile("zava.log", .{ .read = true }) catch unreachable;
    }

    pub fn deinit() void {
        log_file.close();
    }

    /// logging
    var log_file: std.fs.File = undefined;

    pub const log = std.log;

    /// custom log fn
    pub fn logFn(
        comptime level: std.log.Level,
        comptime scope: @TypeOf(.EnumLiteral),
        comptime format: []const u8,
        args: anytype,
    ) void {
        _ = level;

        switch (scope) {
            .console => out.print(format ++ "\n", args),
            .instruction => log_file.writer().print(format, args) catch return,
            else => log_file.writer().print("\n" ++ format, args) catch return,
        }
    }
};
