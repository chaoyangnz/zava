const std = @import("std");
const string = @import("./shared.zig").string;
const vm_allocator = @import("./shared.zig").vm_allocator;
const Class = @import("./type.zig").Class;
const Reference = @import("./type.zig").Reference;
const Value = @import("./type.zig").Value;
const newObject = @import("./heap.zig").newObject;
const newArray = @import("./heap.zig").newArray;
const current = @import("./engine.zig").current;

/// create java.lang.String
pub fn newJavaLangString(definingClass: *const Class, bytes: string) Reference {
    const javaLangString = newObject(definingClass, "java/lang/String");
    const class = javaLangString.class();

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

    const values = newArray(definingClass, "[C", &[_]i32{@intCast(chars.items.len)});

    for (0..chars.items.len) |i| {
        values.set(@intCast(i), .{ .char = chars.items[i] });
    }

    const valueField = class.field("value", "[C", false);
    if (valueField == null) {
        unreachable;
    }
    javaLangString.set(valueField.?.slot, .{ .ref = values });

    // const init = class.method("<init>", "([C)V", false);
    // if (init == null) {
    //     unreachable;
    // }
    // var args = [_]Value{.{ .ref = values }};
    // current().invoke(class, init.?, &args);

    return javaLangString;
}
