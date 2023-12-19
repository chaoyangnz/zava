const std = @import("std");

const string = @import("./vm.zig").string;
const size16 = @import("./vm.zig").size16;
const size32 = @import("./vm.zig").size32;
const encoding = @import("./vm.zig").encoding;
const naming = @import("./vm.zig").naming;
const vm_stash = @import("./vm.zig").vm_stash;
const mem = @import("./mem.zig");

const byte = @import("./type.zig").byte;
const char = @import("./type.zig").char;
const short = @import("./type.zig").short;
const int = @import("./type.zig").int;
const long = @import("./type.zig").long;
const float = @import("./type.zig").float;
const double = @import("./type.zig").double;
const boolean = @import("./type.zig").boolean;
const Class = @import("./type.zig").Class;
const Field = @import("./type.zig").Field;
const Method = @import("./type.zig").Method;
const Value = @import("./type.zig").Value;
const defaultValue = @import("./type.zig").defaultValue;
const isType = @import("./type.zig").isType;
const NULL = @import("./type.zig").NULL;
const Object = @import("./type.zig").Object;
const Reference = @import("./type.zig").Reference;
const ArrayRef = @import("./type.zig").ArrayRef;
const JavaLangString = @import("./type.zig").JavaLangString;
const JavaLangClass = @import("./type.zig").JavaLangClass;
const JavaLangThread = @import("./type.zig").JavaLangThread;
const JavaLangReflectField = @import("./type.zig").JavaLangReflectField;
const JavaLangReflectConstructor = @import("./type.zig").JavaLangReflectConstructor;

const resolveClass = @import("./method_area.zig").resolveClass;
const resolveField = @import("./method_area.zig").resolveField;
const resolveStaticField = @import("./method_area.zig").resolveStaticField;
const intern = @import("./method_area.zig").intern;

const Thread = @import("./engine.zig").Thread;

test "createObject" {
    std.testing.log_level = .debug;

    const class = @import("./method_area.zig").resolveClass(null, "Calendar");
    const object = createObject(class);
    std.log.info("{}", .{object});
}

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
// heap
const heap_stash: mem.Stash = .{ .allocator = arena.allocator() };

fn createObject(class: *const Class) *Object {
    // backtrace super classes and find instance vars
    var clazz = class;
    var count: usize = 0;
    while (true) {
        count += clazz.instance_vars;
        if (std.mem.eql(u8, clazz.super_class, "")) {
            break;
        }
        clazz = resolveClass(class, clazz.super_class);
    }

    // create object slots
    const slots = heap_stash.make(Value, count);

    // set default values
    clazz = class;
    var i: usize = 0;
    while (true) {
        for (clazz.fields) |field| {
            if (!field.access_flags.static) {
                std.debug.assert(field.slot < count);
                const slot: usize = field.slot;
                slots[i + slot] = defaultValue(field.descriptor);
            }
        }
        i += clazz.instance_vars;
        if (std.mem.eql(u8, clazz.super_class, "")) {
            break;
        }
        clazz = resolveClass(class, clazz.super_class);
    }

    var object = heap_stash.new(Object, .{
        .header = .{
            .hash_code = undefined,
            .class = class,
        },
        .slots = slots,
        .internal = .{},
    });
    const hashCode: i64 = @intCast(@intFromPtr(object));
    object.header.hash_code = @truncate(hashCode);
    return object;
}

fn createArray(class: *const Class, len: u32) *Object {
    const slots = heap_stash.make(Value, len);
    for (0..len) |i| {
        slots[i] = defaultValue(class.component_type);
    }
    var array = heap_stash.new(Object, .{
        .header = .{
            .hash_code = undefined,
            .class = class,
        },
        .slots = slots,
        .internal = .{},
    });
    const hashCode: i64 = @intCast(@intFromPtr(array));
    array.header.hash_code = @truncate(hashCode);
    return array;
}

pub fn newObject(definingClass: ?*const Class, name: string) Reference {
    const class = resolveClass(definingClass, name);
    return .{ .ptr = createObject(class) };
}

/// new 1-dimentional array
pub fn newArray(definingClass: ?*const Class, name: string, len: u32) Reference {
    std.debug.assert(name[0] == '[');
    const class = resolveClass(definingClass, name);

    return .{ .ptr = createArray(class, len) };
}

/// new multi-dimentional array
pub fn newArrayN(definingClass: ?*const Class, name: string, lens: []const u32) Reference {
    const len = lens[0];
    const class = resolveClass(definingClass, name);

    if (lens.len != class.dimensions) {
        unreachable;
    }

    const arrayref: Reference = .{ .ptr = createArray(class, len) };

    if (class.dimensions == 1) return arrayref;

    // create sub arrays
    for (0..len) |i| {
        arrayref.object().slots[i] = .{ .ref = newArrayN(definingClass, class.component_type, lens[1..]) };
    }

    return arrayref;
}

var string_pool = heap_stash.string_map(*Object);
const JavaLangStringFactory = *fn () JavaLangString;

/// get JavaLangString from bytes and intern as well
pub fn getJavaLangString(definingClass: ?*const Class, str: string) JavaLangString {
    if (string_pool.contains(str)) {
        return .{ .ptr = string_pool.get(str).? };
    }

    const javaLangString = newJavaLangString(definingClass, str);

    string_pool.put(intern(str), javaLangString.object()) catch unreachable;
    return javaLangString;
}

pub fn internString(javaLangString: JavaLangString) JavaLangString {
    const str = toString(javaLangString);
    defer vm_stash.free(str);
    if (string_pool.contains(str)) {
        return .{ .ptr = string_pool.get(str).? };
    }
    string_pool.put(intern(str), javaLangString.object()) catch unreachable;
    return javaLangString;
}

/// create a new java.lang.String
/// str bytes is modified UTF-8 bytes which is typically from
/// - Constant_UTF8
/// - vm string literal which is typically ASCII, and equivlant to modified UTF-8
fn newJavaLangString(definingClass: ?*const Class, str: string) JavaLangString {
    const javaLangString = newObject(definingClass, "java/lang/String");

    var chars = encoding.decode(str);
    defer vm_stash.free(chars);
    const values = newArray(definingClass, "[C", size32(chars.len));

    for (0..chars.len) |j| {
        values.set(size16(j), .{ .char = chars[j] });
    }

    std.debug.assert(javaLangString.ptr.?.slots.len == 2);

    setInstanceVar(javaLangString, "value", "[C", .{ .ref = values });
    setInstanceVar(javaLangString, "hash", "I", .{ .int = javaLangString.ptr.?.header.hash_code });

    return javaLangString;
}

pub fn toString(javaLangString: JavaLangString) string {
    std.debug.assert(!javaLangString.isNull());
    std.debug.assert(std.mem.eql(u8, javaLangString.class().name, "java/lang/String"));

    const values = javaLangString.get(0).as(ArrayRef).ref.object().slots;
    var chars = vm_stash.list(u16);
    defer chars.deinit();

    for (values) |value| {
        chars.push(value.as(char).char);
    }

    return encoding.encode(chars.items());
}

// java.lang.Class objects
var class_cache = heap_stash.map(*const Class, *Object);
// primitive Class objects: int.class, float.class ...
var primitives_cache = heap_stash.string_map(*Object);

pub fn getJavaLangClass(definingClass: ?*const Class, descriptor: string) JavaLangClass {
    if (isType(descriptor, byte)) {
        if (primitives_cache.contains("B")) {
            return .{ .ptr = primitives_cache.get("B").? };
        }
        const javaLangClass = newJavaLangClass(definingClass, descriptor);
        javaLangClass.object().internal.class = null;
        primitives_cache.put("B", javaLangClass.object()) catch unreachable;
        return javaLangClass;
    }
    if (isType(descriptor, char)) {
        if (primitives_cache.contains("C")) {
            return .{ .ptr = primitives_cache.get("C").? };
        }
        const javaLangClass = newJavaLangClass(definingClass, descriptor);
        javaLangClass.object().internal.class = null;
        primitives_cache.put("C", javaLangClass.object()) catch unreachable;
        return javaLangClass;
    }
    if (isType(descriptor, short)) {
        if (primitives_cache.contains("S")) {
            return .{ .ptr = primitives_cache.get("S").? };
        }
        const javaLangClass = newJavaLangClass(definingClass, descriptor);
        javaLangClass.object().internal.class = null;
        primitives_cache.put("S", javaLangClass.object()) catch unreachable;
        return javaLangClass;
    }
    if (isType(descriptor, int)) {
        if (primitives_cache.contains("I")) {
            return .{ .ptr = primitives_cache.get("I").? };
        }
        const javaLangClass = newJavaLangClass(definingClass, descriptor);
        javaLangClass.object().internal.class = null;
        primitives_cache.put("I", javaLangClass.object()) catch unreachable;
        return javaLangClass;
    }
    if (isType(descriptor, long)) {
        if (primitives_cache.contains("J")) {
            return .{ .ptr = primitives_cache.get("J").? };
        }
        const javaLangClass = newJavaLangClass(definingClass, descriptor);
        javaLangClass.object().internal.class = null;
        primitives_cache.put("J", javaLangClass.object()) catch unreachable;
        return javaLangClass;
    }
    if (isType(descriptor, float)) {
        if (primitives_cache.contains("F")) {
            return .{ .ptr = primitives_cache.get("F").? };
        }
        const javaLangClass = newJavaLangClass(definingClass, descriptor);
        javaLangClass.object().internal.class = null;
        primitives_cache.put("F", javaLangClass.object()) catch unreachable;
        return javaLangClass;
    }
    if (isType(descriptor, double)) {
        if (primitives_cache.contains("D")) {
            return .{ .ptr = primitives_cache.get("D").? };
        }
        const javaLangClass = newJavaLangClass(definingClass, descriptor);
        javaLangClass.object().internal.class = null;
        primitives_cache.put("D", javaLangClass.object()) catch unreachable;
        return javaLangClass;
    }
    if (isType(descriptor, boolean)) {
        if (primitives_cache.contains("Z")) {
            return .{ .ptr = primitives_cache.get("Z").? };
        }
        const javaLangClass = newJavaLangClass(definingClass, descriptor);
        javaLangClass.object().internal.class = null;
        primitives_cache.put("Z", javaLangClass.object()) catch unreachable;
        return javaLangClass;
    }

    const class = resolveClass(definingClass, naming.name(descriptor));
    if (class_cache.contains(class)) {
        return .{ .ptr = class_cache.get(class).? };
    }
    const javaLangClass = newJavaLangClass(definingClass, descriptor);
    javaLangClass.object().internal.class = class;
    class_cache.put(class, javaLangClass.object()) catch unreachable;

    return javaLangClass;
}

fn newJavaLangClass(definingClass: ?*const Class, descriptor: string) JavaLangClass {
    const javaLangClass = newObject(definingClass, "java/lang/Class");
    setInstanceVar(javaLangClass, "name", "Ljava/lang/String;", .{ .ref = getJavaLangString(definingClass, naming.jname(descriptor)) });

    return javaLangClass;
}

/// TODO caching
pub fn newJavaLangThread(definingClass: ?*const Class, thread: *const Thread) JavaLangThread {
    const javaLangThread = newObject(definingClass, "java/lang/Thread");

    const threadGroup = newObject(definingClass, "java/lang/ThreadGroup");
    setInstanceVar(threadGroup, "name", "Ljava/lang/String;", .{ .ref = getJavaLangString(definingClass, "main") });

    setInstanceVar(javaLangThread, "name", "Ljava/lang/String;", .{ .ref = getJavaLangString(definingClass, thread.name) });
    setInstanceVar(javaLangThread, "tid", "J", .{ .long = @intCast(thread.id) });
    setInstanceVar(javaLangThread, "group", "Ljava/lang/ThreadGroup;", .{ .ref = threadGroup });
    setInstanceVar(javaLangThread, "priority", "I", .{ .int = 1 });

    return javaLangThread;
}

pub fn newJavaLangReflectField(definingClass: ?*const Class, javaLangClass: JavaLangClass, field: *const Field) JavaLangReflectField {
    const f = newObject(definingClass, "java/lang/reflect/Field");
    setInstanceVar(f, "clazz", "Ljava/lang/Class;", .{ .ref = javaLangClass });
    setInstanceVar(f, "name", "Ljava/lang/String;", .{ .ref = getJavaLangString(definingClass, field.name) });
    setInstanceVar(f, "type", "Ljava/lang/Class;", .{ .ref = getJavaLangClass(definingClass, field.descriptor) });
    setInstanceVar(f, "modifiers", "I", .{ .int = field.access_flags.raw });
    setInstanceVar(f, "slot", "I", .{ .int = field.slot });
    setInstanceVar(f, "signature", "Ljava/lang/String;", .{ .ref = getJavaLangString(definingClass, field.descriptor) });

    // TODO
    const annotations = newArray(definingClass, "[B", 0);
    setInstanceVar(f, "annotations", "[B", .{ .ref = annotations });

    return f;
}

pub fn newJavaLangReflectConstructor(definingClass: ?*const Class, javaLangClass: JavaLangClass, method: *const Method) JavaLangReflectConstructor {
    const ctor = newObject(definingClass, "java/lang/reflect/Constructor");
    setInstanceVar(ctor, "clazz", "Ljava/lang/Class;", .{ .ref = javaLangClass });
    setInstanceVar(ctor, "signature", "Ljava/lang/String;", .{ .ref = getJavaLangString(definingClass, method.descriptor) });

    const parameterTypes = newArray(definingClass, "[Ljava/lang/Class;", size32(method.parameter_descriptors.len));
    for (0..method.parameter_descriptors.len) |i| {
        parameterTypes.set(@intCast(i), .{ .ref = getJavaLangClass(definingClass, method.parameter_descriptors[i]) });
    }
    setInstanceVar(ctor, "parameterTypes", "[Ljava/lang/Class;", .{ .ref = parameterTypes });
    // TODO
    const exceptionTypes = newArray(definingClass, "[Ljava/lang/Class;", 0);
    setInstanceVar(ctor, "exceptionTypes", "[Ljava/lang/Class;", .{ .ref = exceptionTypes });

    setInstanceVar(ctor, "modifiers", "I", .{ .int = @intCast(method.access_flags.raw) });
    // TODO
    setInstanceVar(ctor, "slot", "I", .{ .int = 0 });

    // TODO
    const annotations = newArray(definingClass, "[B", 0);
    setInstanceVar(ctor, "annotations", "[B", .{ .ref = annotations });

    // TODO
    const parameterAnnotations = newArray(definingClass, "[B", 0);
    setInstanceVar(ctor, "parameterAnnotations", "[B", .{ .ref = parameterAnnotations });

    return ctor;
}

pub fn setInstanceVar(reference: Reference, name: string, descriptor: string, value: Value) void {
    const resolvedField = resolveField(reference.class(), reference.class().name, name, descriptor);
    reference.set(resolvedField.slot, value);
}

pub fn getInstanceVar(reference: Reference, name: string, descriptor: string) Value {
    const resolvedField = resolveField(reference.class(), reference.class().name, name, descriptor);
    return reference.get(resolvedField.slot);
}

pub fn setStaticVar(class: *const Class, name: string, descriptor: string, value: Value) void {
    const resolvedField = resolveStaticField(class, name, descriptor);
    resolvedField.class.set(resolvedField.slot, value);
}

pub fn getStaticVar(class: *const Class, name: string, descriptor: string) Value {
    const resolvedField = resolveStaticField(class, name, descriptor);
    return resolvedField.class.get(resolvedField.slot);
}
