const std = @import("std");

const string = @import("./util.zig").string;
const jsize = @import("./util.zig").jsize;
const jcount = @import("./util.zig").jcount;
const setInstanceVar = @import("./util.zig").setInstanceVar;

const char = @import("./type.zig").char;
const Type = @import("./type.zig").Type;
const Class = @import("./type.zig").Class;
const Value = @import("./type.zig").Value;
const NULL = @import("./type.zig").NULL;
const Object = @import("./type.zig").Object;
const Reference = @import("./type.zig").Reference;
const ArrayRef = @import("./type.zig").ArrayRef;
const JavaLangString = @import("./type.zig").JavaLangString;
const JavaLangClass = @import("./type.zig").JavaLangClass;
const JavaLangThread = @import("./type.zig").JavaLangThread;

const resolveClass = @import("./method_area.zig").resolveClass;

const Thread = @import("./engine.zig").Thread;

const vm_make = @import("./vm.zig").vm_make;
const vm_allocator = @import("./vm.zig").vm_allocator;

test "createObject" {
    std.testing.log_level = .debug;

    const class = @import("./method_area.zig").resolveClass(null, "Calendar");
    const object = createObject(class);
    std.log.info("{}", .{object});
}

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
// Object
const heap_allocator = arena.allocator();

/// allocate a slice of elements in heap
pub fn make(comptime T: type, capacity: usize) []T {
    return switch (T) {
        u8 => heap_allocator.allocSentinel(T, capacity, 0) catch unreachable,
        else => heap_allocator.alloc(T, capacity) catch unreachable,
    };
}

/// allocate a single object in heap
pub fn new(comptime T: type, value: T) *T {
    var ptr = heap_allocator.create(T) catch unreachable;
    ptr.* = value;
    return ptr;
}

pub fn free(comptime T: type, ptr: T) void {
    switch (@typeInfo(T)) {
        .Pointer => |p| {
            // builtin.Type.Pointer{ .size = builtin.Type.Pointer.Size.Slice, .is_const = true, .is_volatile = false, .alignment = 1, .address_space = builtin.AddressSpace.generic, .child = u8, .is_allowzero = false, .sentinel = null }
            // builtin.Type.Pointer{ .size = builtin.Type.Pointer.Size.One, .is_const = false, .is_volatile = false, .alignment = 1, .address_space = builtin.AddressSpace.generic, .child = u8, .is_allowzero = false, .sentinel = null }
            if (p.size == .One) {
                heap_allocator.destroy(ptr);
            } else if (p.size == .Slice) {
                heap_allocator.free(ptr);
            } else {
                unreachable;
            }
        },
        else => unreachable,
    }
}

fn createObject(class: *const Class) *Object {
    // backtrace super classes and find instance vars
    var clazz = class;
    var count: usize = 0;
    while (true) {
        count += clazz.instanceVars;
        if (std.mem.eql(u8, clazz.superClass, "")) {
            break;
        }
        clazz = resolveClass(class, clazz.superClass);
    }

    // create object slots
    const slots = make(Value, count);

    // set default values
    clazz = class;
    var i: usize = 0;
    while (true) {
        for (clazz.fields) |field| {
            if (!field.accessFlags.static) {
                std.debug.assert(field.slot < count);
                const slot: usize = field.slot;
                slots[i + slot] = Type.defaultValue(field.descriptor);
            }
        }
        i += clazz.instanceVars;
        if (std.mem.eql(u8, clazz.superClass, "")) {
            break;
        }
        clazz = resolveClass(class, clazz.superClass);
    }

    var object = new(Object, .{
        .header = .{
            .hashCode = undefined,
            .class = class,
        },
        .slots = slots,
        .internal = .{},
    });
    const hashCode: i64 = @intCast(@intFromPtr(object));
    object.header.hashCode = @truncate(hashCode);
    return object;
}

fn createArray(class: *const Class, len: u32) *Object {
    const slots = make(Value, len);
    for (0..len) |i| {
        slots[i] = Type.defaultValue(class.componentType);
    }
    var array = new(Object, .{
        .header = .{
            .hashCode = undefined,
            .class = class,
        },
        .slots = slots,
        .internal = .{},
    });
    const hashCode: i64 = @intCast(@intFromPtr(array));
    array.header.hashCode = @truncate(hashCode);
    return array;
}

pub fn newObject(definingClass: ?*const Class, name: string) Reference {
    const class = resolveClass(definingClass, name);
    return .{ .ptr = createObject(class) };
}

/// new 1-dimentional array
pub fn newArray(definingClass: ?*const Class, name: string, count: u32) Reference {
    const class = resolveClass(definingClass, name);

    return .{ .ptr = createArray(class, count) };
}

/// new multi-dimentional array
pub fn newArrayN(definingClass: ?*const Class, name: string, counts: []const u32) Reference {
    const count = counts[0];
    const class = resolveClass(definingClass, name);

    if (counts.len != class.dimensions) {
        unreachable;
    }

    const arrayref: Reference = .{ .ptr = createArray(class, count) };

    if (class.dimensions == 1) return arrayref;

    // create sub arrays
    for (0..count) |i| {
        arrayref.object().slots[i] = .{ .ref = newArrayN(definingClass, class.componentType, counts[1..]) };
    }

    return arrayref;
}

/// create java.lang.String
pub fn newJavaLangString(definingClass: ?*const Class, bytes: string) JavaLangString {
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

    const values = newArray(definingClass, "[C", jcount(chars.items.len));

    for (0..chars.items.len) |i| {
        values.set(jsize(i), .{ .char = chars.items[i] });
    }

    std.debug.assert(javaLangString.ptr.?.slots.len == 2);

    setInstanceVar(javaLangString, "value", "[C", .{ .ref = values });
    setInstanceVar(javaLangString, "hash", "I", .{ .int = javaLangString.ptr.?.header.hashCode });

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
                const buffer = vm_make(u8, len);
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
            const buffer = vm_make(u8, len);
            _ = std.unicode.utf8Encode(codepoint, buffer) catch unreachable;
            for (0..buffer.len) |j| {
                str.append(buffer[j]) catch unreachable;
            }
        }
    }
    return str.toOwnedSlice() catch unreachable;
}

pub fn newJavaLangClass(definingClass: ?*const Class, name: string) JavaLangClass {
    const javaLangClass = newObject(definingClass, "java/lang/Class");
    setInstanceVar(javaLangClass, "name", "Ljava/lang/String;", .{ .ref = newJavaLangString(definingClass, name) });

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

pub fn newJavaLangThread(definingClass: ?*const Class, thread: *const Thread) JavaLangThread {
    const javaLangThread = newObject(definingClass, "java/lang/Thread");

    const threadGroup = newObject(definingClass, "java/lang/ThreadGroup");
    setInstanceVar(threadGroup, "name", "Ljava/lang/String;", .{ .ref = newJavaLangString(definingClass, "main") });

    setInstanceVar(javaLangThread, "name", "Ljava/lang/String;", .{ .ref = newJavaLangString(definingClass, thread.name) });
    setInstanceVar(javaLangThread, "tid", "J", .{ .long = @intCast(thread.id) });
    setInstanceVar(javaLangThread, "group", "Ljava/lang/ThreadGroup;", .{ .ref = threadGroup });
    setInstanceVar(javaLangThread, "priority", "I", .{ .int = 1 });

    return javaLangThread;
}
