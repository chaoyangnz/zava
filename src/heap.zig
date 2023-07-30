const std = @import("std");
const string = @import("./shared.zig").string;
const Value = @import("./type.zig").Value;
const Object = @import("./type.zig").Object;
const Reference = @import("./type.zig").Reference;
const NULL = @import("./type.zig").NULL;
const defaultValue = @import("./type.zig").Type.defaultValue;
const Class = @import("./type.zig").Class;
const make = @import("./shared.zig").make;
const new = @import("./shared.zig").new;
const resolveClass = @import("./method_area.zig").resolveClass;

test "createObject" {
    std.testing.log_level = .debug;

    const class = @import("./method_area.zig").resolveClass(null, "Calendar");
    const object = createObject(class);
    std.log.info("{}", .{object});
}

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
// Object
pub const heap_allocator = arena.allocator();

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
    const slots = make(Value, count, heap_allocator);

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
    }, heap_allocator);
    const hashCode: i64 = @intCast(@intFromPtr(object));
    object.header.hashCode = @truncate(hashCode);
    return object;
}

fn createArray(class: *const Class, len: u32) *Object {
    const slots = make(Value, len, heap_allocator);
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
    }, heap_allocator);
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
