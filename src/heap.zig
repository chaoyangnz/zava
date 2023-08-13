const std = @import("std");

const string = @import("./vm.zig").string;
const jsize = @import("./vm.zig").jsize;
const jlen = @import("./vm.zig").jlen;
const encoding = @import("./vm.zig").encoding;
const naming = @import("./vm.zig").naming;
const vm_make = @import("./vm.zig").vm_make;
const vm_free = @import("./vm.zig").vm_free;
const vm_allocator = @import("./vm.zig").vm_allocator;

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
const resolveMethod = @import("./method_area.zig").resolveMethod;
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
                slots[i + slot] = defaultValue(field.descriptor);
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
        slots[i] = defaultValue(class.componentType);
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
        arrayref.object().slots[i] = .{ .ref = newArrayN(definingClass, class.componentType, lens[1..]) };
    }

    return arrayref;
}

var stringPool = std.StringHashMap(*Object).init(heap_allocator);
const JavaLangStringFactory = *fn () JavaLangString;

/// get JavaLangString from bytes and intern as well
pub fn getJavaLangString(definingClass: ?*const Class, str: string) JavaLangString {
    if (stringPool.contains(str)) {
        return .{ .ptr = stringPool.get(str).? };
    }

    const javaLangString = newJavaLangString(definingClass, str);

    stringPool.put(intern(str), javaLangString.object()) catch unreachable;
    return javaLangString;
}

pub fn internString(javaLangString: JavaLangString) JavaLangString {
    const str = toString(javaLangString);
    defer vm_free(str);
    if (stringPool.contains(str)) {
        return .{ .ptr = stringPool.get(str).? };
    }
    stringPool.put(intern(str), javaLangString.object()) catch unreachable;
    return javaLangString;
}

/// create a new java.lang.String
/// str bytes is modified UTF-8 bytes which is typically from
/// - Constant_UTF8
/// - vm string literal which is typically ASCII, and equivlant to modified UTF-8
fn newJavaLangString(definingClass: ?*const Class, str: string) JavaLangString {
    const javaLangString = newObject(definingClass, "java/lang/String");

    var chars = encoding.decode(str);
    defer vm_free(chars);
    const values = newArray(definingClass, "[C", jlen(chars.len));

    for (0..chars.len) |j| {
        values.set(jsize(j), .{ .char = chars[j] });
    }

    std.debug.assert(javaLangString.ptr.?.slots.len == 2);

    setInstanceVar(javaLangString, "value", "[C", .{ .ref = values });
    setInstanceVar(javaLangString, "hash", "I", .{ .int = javaLangString.ptr.?.header.hashCode });

    return javaLangString;
}

pub fn toString(javaLangString: JavaLangString) string {
    std.debug.assert(!javaLangString.isNull());
    std.debug.assert(std.mem.eql(u8, javaLangString.class().name, "java/lang/String"));

    const values = javaLangString.get(0).as(ArrayRef).ref.object().slots;
    var chars = std.ArrayList(u16).init(vm_allocator);
    defer chars.deinit();

    for (values) |value| {
        chars.append(value.as(char).char) catch unreachable;
    }

    return encoding.encode(chars.items);
}

var classCache = std.AutoHashMap(*const Class, *Object).init(heap_allocator);
var primitivesCache = std.StringHashMap(*Object).init(heap_allocator);

pub fn getJavaLangClass(definingClass: ?*const Class, descriptor: string) JavaLangClass {
    if (isType(descriptor, byte)) {
        if (primitivesCache.contains("B")) {
            return .{ .ptr = primitivesCache.get("B").? };
        }
        const javaLangClass = newJavaLangClass(definingClass, descriptor);
        javaLangClass.object().internal.class = null;
        primitivesCache.put("B", javaLangClass.object()) catch unreachable;
        return javaLangClass;
    }
    if (isType(descriptor, char)) {
        if (primitivesCache.contains("C")) {
            return .{ .ptr = primitivesCache.get("C").? };
        }
        const javaLangClass = newJavaLangClass(definingClass, descriptor);
        javaLangClass.object().internal.class = null;
        primitivesCache.put("C", javaLangClass.object()) catch unreachable;
        return javaLangClass;
    }
    if (isType(descriptor, short)) {
        if (primitivesCache.contains("S")) {
            return .{ .ptr = primitivesCache.get("S").? };
        }
        const javaLangClass = newJavaLangClass(definingClass, descriptor);
        javaLangClass.object().internal.class = null;
        primitivesCache.put("S", javaLangClass.object()) catch unreachable;
        return javaLangClass;
    }
    if (isType(descriptor, int)) {
        if (primitivesCache.contains("I")) {
            return .{ .ptr = primitivesCache.get("I").? };
        }
        const javaLangClass = newJavaLangClass(definingClass, descriptor);
        javaLangClass.object().internal.class = null;
        primitivesCache.put("I", javaLangClass.object()) catch unreachable;
        return javaLangClass;
    }
    if (isType(descriptor, long)) {
        if (primitivesCache.contains("J")) {
            return .{ .ptr = primitivesCache.get("J").? };
        }
        const javaLangClass = newJavaLangClass(definingClass, descriptor);
        javaLangClass.object().internal.class = null;
        primitivesCache.put("J", javaLangClass.object()) catch unreachable;
        return javaLangClass;
    }
    if (isType(descriptor, float)) {
        if (primitivesCache.contains("F")) {
            return .{ .ptr = primitivesCache.get("F").? };
        }
        const javaLangClass = newJavaLangClass(definingClass, descriptor);
        javaLangClass.object().internal.class = null;
        primitivesCache.put("F", javaLangClass.object()) catch unreachable;
        return javaLangClass;
    }
    if (isType(descriptor, double)) {
        if (primitivesCache.contains("D")) {
            return .{ .ptr = primitivesCache.get("D").? };
        }
        const javaLangClass = newJavaLangClass(definingClass, descriptor);
        javaLangClass.object().internal.class = null;
        primitivesCache.put("D", javaLangClass.object()) catch unreachable;
        return javaLangClass;
    }
    if (isType(descriptor, boolean)) {
        if (primitivesCache.contains("Z")) {
            return .{ .ptr = primitivesCache.get("Z").? };
        }
        const javaLangClass = newJavaLangClass(definingClass, descriptor);
        javaLangClass.object().internal.class = null;
        primitivesCache.put("Z", javaLangClass.object()) catch unreachable;
        return javaLangClass;
    }

    const class = resolveClass(definingClass, naming.name(descriptor));
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
    setInstanceVar(javaLangClass, "name", "Ljava/lang/String;", .{ .ref = getJavaLangString(definingClass, naming.jname(descriptor)) });

    return javaLangClass;
}

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
    setInstanceVar(f, "modifiers", "I", .{ .int = field.accessFlags.raw });
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

    const parameterTypes = newArray(definingClass, "[Ljava/lang/Class;", jlen(method.parameterDescriptors.len));
    for (0..method.parameterDescriptors.len) |i| {
        parameterTypes.set(@intCast(i), .{ .ref = getJavaLangClass(definingClass, method.parameterDescriptors[i]) });
    }
    setInstanceVar(ctor, "parameterTypes", "[Ljava/lang/Class;", .{ .ref = parameterTypes });
    // TODO
    const exceptionTypes = newArray(definingClass, "[Ljava/lang/Class;", 0);
    setInstanceVar(ctor, "exceptionTypes", "[Ljava/lang/Class;", .{ .ref = exceptionTypes });

    setInstanceVar(ctor, "modifiers", "I", .{ .int = @intCast(method.accessFlags.raw) });
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
    reference.set(resolvedField.field.slot, value);
}

pub fn getInstanceVar(reference: Reference, name: string, descriptor: string) Value {
    const resolvedField = resolveField(reference.class(), reference.class().name, name, descriptor);
    return reference.get(resolvedField.field.slot);
}

pub fn setStaticVar(class: *const Class, name: string, descriptor: string, value: Value) void {
    const resolvedField = resolveStaticField(class, name, descriptor);
    resolvedField.class.set(resolvedField.field.slot, value);
}

pub fn getStaticVar(class: *const Class, name: string, descriptor: string) Value {
    const resolvedField = resolveStaticField(class, name, descriptor);
    return resolvedField.class.get(resolvedField.field.slot);
}
