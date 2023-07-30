pub const std = @import("std");
const string = @import("./util.zig").string;

// -------------- VM internal memory allocator ------------

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
// vm internal structure allocation, like Thread, Frame, ClassFile etc.
pub const vm_allocator = arena.allocator();

/// concat strings and create a new one
/// the caller owns the memory
pub fn concat(strings: []const string) string {
    return std.mem.concat(vm_allocator, u8, strings) catch unreachable;
}

/// allocate a slice of elements
pub fn vm_make(comptime T: type, capacity: usize) []T {
    return switch (T) {
        u8 => vm_allocator.allocSentinel(T, capacity, 0) catch unreachable,
        else => vm_allocator.alloc(T, capacity) catch unreachable,
    };
}

pub fn vm_new(comptime T: type, value: T) *T {
    var ptr = vm_allocator.create(T) catch unreachable;
    ptr.* = value;
    return ptr;
}

pub fn vm_free(comptime T: type, ptr: T) void {
    switch (@typeInfo(T)) {
        .Pointer => |p| {
            // builtin.Type.Pointer{ .size = builtin.Type.Pointer.Size.Slice, .is_const = true, .is_volatile = false, .alignment = 1, .address_space = builtin.AddressSpace.generic, .child = u8, .is_allowzero = false, .sentinel = null }
            // builtin.Type.Pointer{ .size = builtin.Type.Pointer.Size.One, .is_const = false, .is_volatile = false, .alignment = 1, .address_space = builtin.AddressSpace.generic, .child = u8, .is_allowzero = false, .sentinel = null }
            if (p.size == .One) {
                vm_allocator.destroy(ptr);
            } else if (p.size == .Slice) {
                vm_allocator.free(ptr);
            } else {
                unreachable;
            }
        },
        else => unreachable,
    }
}

pub fn foo(comptime T: type) void {
    std.testing.log_level = .debug;
    std.log.debug("{}", .{@typeInfo(T)});
}

test "xxx" {
    foo([]const u8);
    foo(*u8);
}
