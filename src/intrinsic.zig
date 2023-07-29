const std = @import("std");
const string = @import("./shared.zig").string;
const vm_allocator = @import("./shared.zig").vm_allocator;
const Class = @import("./type.zig").Class;
const Reference = @import("./type.zig").Reference;
const Value = @import("./type.zig").Value;
const NULL = @import("./type.zig").NULL;
const newObject = @import("./heap.zig").newObject;
const newArray = @import("./heap.zig").newArray;
const current = @import("./engine.zig").current;
const make = @import("./shared.zig").make;
const jsize = @import("./shared.zig").jsize;
const jcount = @import("./shared.zig").jcount;

/// create java.lang.String
pub fn newJavaLangString(definingClass: *const Class, bytes: string) Reference {
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

pub fn newJavaLangClass(definingClass: *const Class, name: string) Reference {
    _ = name;
    const javaLangClass = newObject(definingClass, "java/lang/Class");

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
