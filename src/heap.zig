const std = @import("std");
const string = @import("./shared.zig").string;

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

// vm internal structure allocation, like Thread, Frame, ClassFile etc.
pub const vm_allocator = arena.allocator();

// Class, Method, Field etc/
pub const method_area_allocator = arena.allocator();

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

/// concat two strings and create a new one
/// if this concatation is not going to be longer lifetime than a call stack, then preferrable shared.zig#concat(..)
pub fn concat(str1: string, str2: string) string {
    var str = vm_allocator.alloc(u8, str1.len + str2.len);
    @memcpy(str[0..str1.len], str1);
    @memcpy(str[str1.len..str.len], str2);
    return str;
}

pub fn clone(str: string, allocator: std.mem.Allocator) string {
    const newstr = allocator.alloc(u8, str.len) catch unreachable;
    @memcpy(newstr, str);
    return newstr;
}
