const std = @import("std");

const string = @import("./util.zig").string;
const jsize = @import("./util.zig").jsize;
const jcount = @import("./util.zig").jcount;
const mutf8 = @import("./util.zig").mutf8;
const setInstanceVar = @import("./util.zig").setInstanceVar;

const byte = @import("./type.zig").byte;
const char = @import("./type.zig").char;
const short = @import("./type.zig").short;
const int = @import("./type.zig").int;
const long = @import("./type.zig").long;
const float = @import("./type.zig").float;
const double = @import("./type.zig").double;
const boolean = @import("./type.zig").boolean;
const Type = @import("./type.zig").Type;
const Class = @import("./type.zig").Class;
const Field = @import("./type.zig").Field;
const Value = @import("./type.zig").Value;
const NULL = @import("./type.zig").NULL;
const Object = @import("./type.zig").Object;
const Reference = @import("./type.zig").Reference;
const ArrayRef = @import("./type.zig").ArrayRef;
const JavaLangString = @import("./type.zig").JavaLangString;
const JavaLangClass = @import("./type.zig").JavaLangClass;
const JavaLangThread = @import("./type.zig").JavaLangThread;
const JavaLangReflectField = @import("./type.zig").JavaLangReflectField;

const resolveClass = @import("./method_area.zig").resolveClass;
const intern = @import("./method_area.zig").intern;

const Thread = @import("./engine.zig").Thread;

const vm_make = @import("./vm.zig").vm_make;
const vm_free = @import("./vm.zig").vm_free;
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
    return heap_allocator.alloc(T, capacity) catch unreachable;
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

var stringPool = std.StringHashMap(JavaLangString).init(heap_allocator);

/// create java.lang.String
pub fn newJavaLangString(definingClass: ?*const Class, bytes: string) JavaLangString {
    const javaLangString = newObject(definingClass, "java/lang/String");

    // var chars = std.ArrayList(u16).init(vm_allocator);
    // defer chars.deinit();

    // const codepoints = std.unicode.Utf8View.init(bytes) catch |e| {
    //     std.log.err("{}", .{e});
    //     unreachable;
    // };
    // var iterator = codepoints.iterator();
    // while (iterator.nextCodepoint()) |codepoint| {
    //     if (codepoint <= 0xFFFF) {
    //         chars.append(@intCast(codepoint)) catch unreachable;
    //     } else {
    //         //	H = (S - 10000) / 400 + D800
    //         //	L = (S - 10000) % 400 + DC00
    //         const highSurrogate: u16 = @intCast((codepoint - 0x10000) / 0x400 + 0xD800);
    //         const lowSurrogate: u16 = @intCast((codepoint - 0x10000) % 0x400 + 0xDC00);
    //         chars.append(highSurrogate) catch unreachable;
    //         chars.append(lowSurrogate) catch unreachable;
    //     }
    // }

    const chars = mutf8(bytes);

    const values = newArray(definingClass, "[C", jcount(chars.len));

    for (0..chars.len) |i| {
        values.set(jsize(i), .{ .char = chars[i] });
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

    return internString(javaLangString);
}

pub fn internString(javaLangString: JavaLangString) JavaLangString {
    const str = toString(javaLangString);
    defer vm_free(str);
    if (stringPool.contains(str)) {
        return stringPool.get(str).?;
    }
    stringPool.put(intern(str), javaLangString) catch unreachable;
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

var classCache = std.AutoHashMap(*const Class, *Object).init(heap_allocator);
var primitivesCache = std.StringHashMap(*Object).init(heap_allocator);

pub fn getJavaLangClass(definingClass: ?*const Class, descriptor: string) JavaLangClass {
    if (Type.is(descriptor, byte)) {
        if (primitivesCache.contains("B")) {
            return .{ .ptr = primitivesCache.get("B").? };
        }
        const javaLangClass = newJavaLangClass(definingClass, descriptor);
        primitivesCache.put("B", javaLangClass.object()) catch unreachable;
        return javaLangClass;
    }
    if (Type.is(descriptor, char)) {
        if (primitivesCache.contains("C")) {
            return .{ .ptr = primitivesCache.get("C").? };
        }
        const javaLangClass = newJavaLangClass(definingClass, descriptor);
        primitivesCache.put("C", javaLangClass.object()) catch unreachable;
        return javaLangClass;
    }
    if (Type.is(descriptor, short)) {
        if (primitivesCache.contains("S")) {
            return .{ .ptr = primitivesCache.get("S").? };
        }
        const javaLangClass = newJavaLangClass(definingClass, descriptor);
        primitivesCache.put("S", javaLangClass.object()) catch unreachable;
        return javaLangClass;
    }
    if (Type.is(descriptor, int)) {
        if (primitivesCache.contains("I")) {
            return .{ .ptr = primitivesCache.get("I").? };
        }
        const javaLangClass = newJavaLangClass(definingClass, descriptor);
        primitivesCache.put("I", javaLangClass.object()) catch unreachable;
        return javaLangClass;
    }
    if (Type.is(descriptor, long)) {
        if (primitivesCache.contains("J")) {
            return .{ .ptr = primitivesCache.get("J").? };
        }
        const javaLangClass = newJavaLangClass(definingClass, descriptor);
        primitivesCache.put("J", javaLangClass.object()) catch unreachable;
        return javaLangClass;
    }
    if (Type.is(descriptor, float)) {
        if (primitivesCache.contains("F")) {
            return .{ .ptr = primitivesCache.get("F").? };
        }
        const javaLangClass = newJavaLangClass(definingClass, descriptor);
        primitivesCache.put("F", javaLangClass.object()) catch unreachable;
        return javaLangClass;
    }
    if (Type.is(descriptor, double)) {
        if (primitivesCache.contains("D")) {
            return .{ .ptr = primitivesCache.get("D").? };
        }
        const javaLangClass = newJavaLangClass(definingClass, descriptor);
        primitivesCache.put("D", javaLangClass.object()) catch unreachable;
        return javaLangClass;
    }
    if (Type.is(descriptor, boolean)) {
        if (primitivesCache.contains("Z")) {
            return .{ .ptr = primitivesCache.get("Z").? };
        }
        const javaLangClass = newJavaLangClass(definingClass, descriptor);
        primitivesCache.put("Z", javaLangClass.object()) catch unreachable;
        return javaLangClass;
    }

    const class = resolveClass(definingClass, Type.name(descriptor));
    if (classCache.contains(class)) {
        return .{ .ptr = classCache.get(class).? };
    }
    const javaLangClass = newJavaLangClass(definingClass, descriptor);
    javaLangClass.object().internal.class = class;
    classCache.put(class, javaLangClass.object()) catch unreachable;

    return javaLangClass;
}

fn newJavaLangClass(definingClass: ?*const Class, descriptor: string) JavaLangClass {
    const javaLangClass = newObject(definingClass, "java/lang/Class");
    setInstanceVar(javaLangClass, "name", "Ljava/lang/String;", .{ .ref = newJavaLangString(definingClass, descriptor) });

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

pub fn newJavaLangReflectField(definingClass: ?*const Class, javaLangClass: JavaLangClass, field: *const Field) JavaLangReflectField {
    const f = newObject(definingClass, "java/lang/reflect/Field");
    setInstanceVar(f, "clazz", "Ljava/lang/Class;", .{ .ref = javaLangClass });
    setInstanceVar(f, "name", "Ljava/lang/String;", .{ .ref = newJavaLangString(definingClass, field.name) });
    setInstanceVar(f, "type", "Ljava/lang/Class;", .{ .ref = getJavaLangClass(definingClass, field.descriptor) });
    setInstanceVar(f, "modifiers", "I", .{ .int = field.accessFlags.raw });
    setInstanceVar(f, "slot", "I", .{ .int = field.slot });
    setInstanceVar(f, "signature", "Ljava/lang/String;", .{ .ref = newJavaLangString(definingClass, field.descriptor) });

    const annotations = newArray(definingClass, "[B", 0);
    setInstanceVar(f, "annotations", "[B", .{ .ref = annotations });

    return f;
}
