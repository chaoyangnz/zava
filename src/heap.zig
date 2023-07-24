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
    const slots = make(Value, @intCast(class.instanceVars), heap_allocator);
    var i: usize = 0;
    for (class.fields) |field| {
        if (i >= slots.len) break;
        if (!field.hasAccessFlag(.STATIC)) {
            slots[i] = defaultValue(field.descriptor);
            i += 1;
        }
    }
    var object = new(Object, .{
        .header = .{
            .hashCode = undefined,
            .class = class,
        },
        .slots = slots,
    }, heap_allocator);
    const hashCode: i64 = @intCast(@intFromPtr(object));
    object.header.hashCode = @truncate(hashCode);
    return object;
}

fn createArray(class: *const Class, len: i32) *Object {
    const slots = make(Value, @intCast(len), heap_allocator);
    for (0..len) |i| {
        slots[i] = defaultValue(class.componentType);
    }
    var array = new(Object, .{
        .header = .{
            .hashCode = undefined,
            .class = class,
        },
        .slots = slots,
    }, heap_allocator);
    const hashCode: i64 = @intCast(@intFromPtr(array));
    array.header.hashCode = @truncate(hashCode);
    return array;
}

pub fn newObject(definingClass: ?*const Class, name: string) Reference {
    const class = resolveClass(definingClass, name);
    return .{ .ptr = createObject(class) };
}

pub fn newArray(definingClass: *const Class, name: string, counts: []i32) Reference {
    const count = counts[0];
    const class = resolveClass(definingClass, name);

    if (counts.len != class.dimensions) {
        unreachable;
    }

    const arrayref = .{ .ptr = createArray(class, count) };

    if (class.dimensions == 1) return arrayref;

    // create sub arrays
    for (0..count) |i| {
        arrayref.object().slots[i] = newArray(definingClass, class.componentType, counts[1..]);
    }

    return arrayref;
}
