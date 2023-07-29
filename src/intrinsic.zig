const std = @import("std");
const string = @import("./shared.zig").string;
const vm_allocator = @import("./shared.zig").vm_allocator;
const Class = @import("./type.zig").Class;
const Reference = @import("./type.zig").Reference;
const JavaLangString = @import("./type.zig").JavaLangString;
const JavaLangClass = @import("./type.zig").JavaLangClass;
const ArrayRef = @import("./type.zig").ArrayRef;
const Value = @import("./type.zig").Value;
const char = @import("./type.zig").char;
const NULL = @import("./type.zig").NULL;
const newObject = @import("./heap.zig").newObject;
const newArray = @import("./heap.zig").newArray;
const current = @import("./engine.zig").current;
const make = @import("./shared.zig").make;
const jsize = @import("./shared.zig").jsize;
const jcount = @import("./shared.zig").jcount;

/// create java.lang.String
pub fn newJavaLangString(definingClass: ?*const Class, bytes: string) Reference {
    const javaLangString = newObject(definingClass, "java/lang/String");

    var chars = std.ArrayList(u16).init(vm_allocator);
    defer chars.deinit();

    const codepoints = std.unicode.Utf8View.init(bytes) catch unreachable;
    var iterator = codepoints.iterator();
    while (iterator.nextCodepoint()) |codepoint| {
        if (codepoint <= 0xFFFF) {
            chars.append(@intCast(codepoint)) catch unreachable;
        } else {
            //	H = (S - 10000) / 400 + D800
            //	L = (S - 10000) % 400 + DC00
            const highSurrogate: u16 = @intCast((codepoint - 0x10000) / 0x400 + 0xD800);
            const lowSurrogate: u16 = @intCast((codepoint - 0x10000) % 0x400 + 0xDC00);
            chars.append(highSurrogate) catch unreachable;
            chars.append(lowSurrogate) catch unreachable;
        }
    }

    const counts = make(u32, 1, vm_allocator);
    counts[0] = jcount(chars.items.len);
    const values = newArray(definingClass, "[C", counts);

    for (0..chars.items.len) |i| {
        values.set(jsize(i), .{ .char = chars.items[i] });
    }

    std.debug.assert(javaLangString.ptr.?.slots.len == 2);

    javaLangString.set(0, .{ .ref = values });
    javaLangString.set(1, .{ .int = javaLangString.ptr.?.header.hashCode });

    // const class = javaLangString.class();
    // const init = class.method("<init>", "([C)V", false);
    // if (init == null) {
    //     unreachable;
    // }
    // var args = make(Value, 2, vm_allocator);
    // args[0] = .{ .ref = javaLangString };
    // args[1] = .{ .ref = values };

    // current().invoke(class, init.?, args);

    return javaLangString;
}

pub fn toString(javaLangString: JavaLangString) string {
    std.debug.assert(!javaLangString.isNull());
    std.debug.assert(std.mem.eql(u8, javaLangString.class().name, "java/lang/String"));

    const values = javaLangString.get(0).as(ArrayRef).ref.object().slots;
    var str = std.ArrayList(u8).init(vm_allocator);
    for (0..values.len) |i| {
        const ch = values[i].as(char).char;
        if (ch >= 0xD800 and ch <= 0xDBFF) {
            const highSurrogate = ch;
            if (i + 1 < values.len and values[i + 1].as(char).char >= 0xDC00 and values[i + 1].as(char).char <= 0xDFFF) {
                const lowSurrogate = values[i + 1].as(char).char;
                const codepoint: u21 = 0x1000 + (highSurrogate - 0xD800) * 0x400 + (lowSurrogate - 0xDC00);
                const len = std.unicode.utf8CodepointSequenceLength(codepoint) catch unreachable;
                const buffer = make(u8, len, vm_allocator);
                _ = std.unicode.utf8Encode(codepoint, buffer) catch unreachable;
                for (0..buffer.len) |j| {
                    str.append(buffer[j]) catch unreachable;
                }
            } else {
                std.debug.panic("Illegal UTF-16 string: only high surrogate", .{});
            }
        } else if (ch >= 0xDC00 and ch <= 0xDFFF) {
            std.debug.panic("Illegal UTF-16 string: only low surrogate", .{});
        } else {
            const codepoint: u21 = ch;
            const len = std.unicode.utf8CodepointSequenceLength(codepoint) catch unreachable;
            const buffer = make(u8, len, vm_allocator);
            _ = std.unicode.utf8Encode(codepoint, buffer) catch unreachable;
            for (0..buffer.len) |j| {
                str.append(buffer[j]) catch unreachable;
            }
        }
    }
    return str.toOwnedSlice() catch unreachable;
}

pub fn newJavaLangClass(definingClass: ?*const Class, name: string) Reference {
    const javaLangClass = newObject(definingClass, "java/lang/Class");

    const nameField = javaLangClass.class().field("name", "Ljava/lang/String;", false);
    javaLangClass.set(nameField.?.slot, .{ .ref = newJavaLangString(definingClass, name) });

    // const class = javaLangClass.class();
    // const init = class.method("<init>", "(Ljava/lang/ClassLoader;)V", false);
    // var args = make(Value, 2, vm_allocator);
    // args[0] = .{ .ref = javaLangClass };
    // args[1] = .{ .ref = values };

    // if (init == null) {
    //     unreachable;
    // }

    return javaLangClass;
}
