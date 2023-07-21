const std = @import("std");
const string = @import("./shared.zig").string;

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

// vm internal structure allocation, like Thread, Frame, ClassFile etc.
pub const vm_allocator = arena.allocator();

// Class, Method, Field etc/
pub const method_area_allocator = arena.allocator();

pub const string_allocator = arena.allocator();

// Object
pub const heap_allocator = arena.allocator();

fn BoundedSlice(comptime T: type) type {
    return struct {
        fn initCapacity(allocator: std.mem.Allocator, capacity: usize) []T {
            return allocator.alloc(T, capacity) catch unreachable;
        }
    };
}

/// create a bounded slice, the max length is known at runtime.
/// It is not supposed to be resized.
pub fn make(comptime T: type, capacity: usize, allocator: std.mem.Allocator) []T {
    return BoundedSlice(T).initCapacity(allocator, capacity);
}

/// concat strings and create a new one
/// the caller owns the memory
pub fn concat(strings: []string) string {
    return std.mem.concat(vm_allocator, string, strings) catch unreachable;
}

pub fn clone(str: string, allocator: std.mem.Allocator) string {
    const newstr = allocator.alloc(u8, str.len) catch unreachable;
    @memcpy(newstr, str);
    return newstr;
}
