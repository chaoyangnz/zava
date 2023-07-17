const std = @import("std");

// vm internal structure allocation, like Thread, Frame, ClassFile etc.
pub const vm_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator).allocator();

// Class, Method, Field etc/
pub const method_area_allocator = std.heap.HeapAllocator.allocator();

// Object
pub const heap_allocator = std.heap.HeapAllocator.allocator();

pub fn BoundedSlice(comptime T: type) type {
    return struct {
        fn initCapacity(allocator: std.mem.Allocator, capacity: usize) []T {
            return allocator.alloc(T, capacity) catch unreachable;
        }
    };
}

test "xx" {
    const arr = [_]u8{ 0x01, 0x02, 0x03, 0x04 };
    const ptr = &arr;
    const i = 0;
    const j = b();
    const slice = arr[i..j];

    std.log.warn("{} \n {} \n {} \n {} \n {} \n {} \n {} \n {}", .{
        @TypeOf(arr),
        @TypeOf(ptr),
        @TypeOf(slice),
        @TypeOf(&slice),
        slice[0..d()].len,
        @TypeOf(slice.ptr),
        @TypeOf(slice.ptr[0..c()]),
        @TypeOf(slice.ptr[0]),
    });
}

fn b() usize {
    return 3;
}

fn c() usize {
    return 2;
}

fn d() usize {
    return 4;
}
