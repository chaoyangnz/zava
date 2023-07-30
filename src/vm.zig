//// high-level APIs in VM
///
const std = @import("std");
const string = @import("./shared.zig").string;
const Class = @import("./type.zig").Class;
const Method = @import("./type.zig").Method;
const Value = @import("./type.zig").Value;
const Reference = @import("./type.zig").Reference;
const resolveClass = @import("./method_area.zig").resolveClass;
const resolveField = @import("./method_area.zig").resolveField;
const current = @import("./engine.zig").current;
const make = @import("./shared.zig").make;
const vm_allocator = @import("./shared.zig").vm_allocator;

/// invoke method by name and signature.
/// the invoked method is just the specified method without virtual / overridding
pub fn invoke(definingClass: ?*const Class, class: string, name: string, descriptor: string, args: []Value, static: bool) void {
    const c = resolveClass(definingClass, class);
    const m = c.method(name, descriptor, static);
    current().invoke(c, m, args);
}

/// construct method args
pub fn arguments(method: *const Method) []Value {
    const len = if (method.accessFlags.static) method.parameterDescriptors.len else method.parameterDescriptors.len + 1;
    return make(Value, len, vm_allocator);
}

/// check if `class` is a subclass of `this`
pub fn isAssignableFrom(class: *const Class, subclass: *const Class) bool {
    if (class == subclass) return true;

    if (class.accessFlags.interface) {
        var c = subclass;
        if (c == class) return true;
        for (c.interfaces) |interface| {
            if (isAssignableFrom(class, resolveClass(c, interface))) {
                return true;
            }
        }
        if (std.mem.eql(u8, c.superClass, "")) {
            return false;
        }
        return isAssignableFrom(class, resolveClass(c, c.superClass));
    } else if (class.isArray) {
        if (subclass.isArray) {
            // covariant
            return isAssignableFrom(resolveClass(class, class.componentType), resolveClass(subclass, subclass.componentType));
        }
    } else {
        var c = subclass;
        if (c == class) {
            return true;
        }
        if (std.mem.eql(u8, c.superClass, "")) {
            return false;
        }

        return isAssignableFrom(class, resolveClass(c, c.superClass));
    }

    return false;
}

pub fn setInstanceVar(reference: Reference, name: string, descriptor: string, value: Value) void {
    const resolvedField = resolveField(reference.class(), reference.class().name, name, descriptor);
    reference.set(resolvedField.field.slot, value);
}

pub fn getInstanceVar(reference: Reference, name: string, descriptor: string) Value {
    const resolvedField = resolveField(reference.class(), reference.class().name, name, descriptor);
    return reference.get(resolvedField.field.slot);
}
