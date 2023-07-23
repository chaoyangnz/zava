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
const lookupClass = @import("./method_area.zig").lookupClass;

test "createObject" {
    std.testing.log_level = .debug;

    const class = @import("./method_area.zig").lookupClass(NULL, "Calendar");
    const object = createObject(class);
    std.log.info("{}", .{object});
}

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
// Object
pub const heap_allocator = arena.allocator();

pub fn createObject(class: *const Class) *Object {
    const slots = make(Value, class.instanceVars, heap_allocator);
    var i: usize = 0;
    for (class.fields) |field| {
        if (i >= slots.len) break;
        if (!field.hasAccessFlag(.STATIC)) {
            slots[i] = defaultValue(field.descriptor);
            i += 1;
        }
    }
    var object = new(Object, .{ .header = .{
        .hashCode = undefined,
        .class = class,
    }, .slots = slots }, heap_allocator);
    const hashCode: i64 = @intCast(@intFromPtr(object));
    object.header.hashCode = @truncate(hashCode);
    return object;
}

pub fn newObject(name: string) Reference {
    const class = lookupClass(NULL, name);
    return .{ .ptr = createObject(class) };
}
