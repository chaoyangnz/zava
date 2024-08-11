const std = @import("std");

// a stash is a memory region to manage allocation.
pub const Stash = struct {
    allocator: std.mem.Allocator,

    /// create an instance in heap
    pub fn new(self: Stash, comptime T: type, value: T) *T {
        const ptr = self.allocator.create(T) catch unreachable;
        ptr.* = value;
        return ptr;
    }

    /// create a slice of instances in heap
    pub fn make(self: Stash, comptime T: type, n: usize) []T {
        const slice = self.allocator.alloc(T, n) catch unreachable;
        return slice;
    }

    pub fn clone(self: Stash, comptime T: type, slice: []const T) []const T {
        const new_slice = self.make(T, slice.len);
        @memcpy(new_slice, slice);
        return new_slice;
    }

    pub fn free(self: Stash, ptr: anytype) void {
        switch (@typeInfo(@TypeOf(ptr))) {
            .Pointer => |p| {
                // builtin.Type.Pointer{ .size = builtin.Type.Pointer.Size.Slice, .is_const = true, .is_volatile = false, .alignment = 1, .address_space = builtin.AddressSpace.generic, .child = u8, .is_allowzero = false, .sentinel = null }
                // builtin.Type.Pointer{ .size = builtin.Type.Pointer.Size.One, .is_const = false, .is_volatile = false, .alignment = 1, .address_space = builtin.AddressSpace.generic, .child = u8, .is_allowzero = false, .sentinel = null }
                if (p.size == .One) {
                    self.allocator.destroy(ptr);
                } else if (p.size == .Slice) {
                    self.allocator.free(ptr);
                } else {
                    unreachable;
                }
            },
            else => unreachable,
        }
    }

    pub fn list(self: Stash, comptime T: type) List(T) {
        return .{
            .list = std.ArrayList(T).init(self.allocator),
        };
    }

    pub const string_buffer = string_list;
    pub const string_builder = string_list;
    pub fn string_list(self: Stash) List(u8) {
        return self.list(u8);
    }

    /// prefer #make()
    pub fn bounded_list(self: Stash, comptime T: type, capacity: usize) List(T) {
        return .{
            .list = std.ArrayList(T).initCapacity(self.allocator, capacity) catch unreachable,
        };
    }

    pub fn string_map(self: Stash, comptime V: type) std.StringHashMap(V) {
        return std.StringHashMap(V).init(self.allocator);
    }

    pub fn map(self: Stash, comptime K: type, comptime V: type) std.AutoHashMap(K, V) {
        return std.AutoHashMap(K, V).init(self.allocator);
    }

    /// a list in heap, backed by array list
    pub fn List(comptime T: type) type {
        return struct {
            list: std.ArrayList(T),

            const Self = @This();
            pub fn push(self: *Self, item: T) void {
                self.list.append(item) catch unreachable;
            }

            pub fn pop(self: *Self) ?T {
                return self.list.popOrNull();
            }

            pub fn len(self: Self) usize {
                return self.list.items.len;
            }

            pub fn peek(self: Self) ?T {
                if (self.len() == 0) return null;
                return self.list.items[self.list.items.len - 1];
            }

            pub fn items(self: Self) []T {
                return self.list.items;
            }

            pub fn get(self: Self, index: usize) T {
                return self.list.items[index];
            }

            pub fn clear(self: *Self) void {
                return self.list.clearRetainingCapacity();
            }

            pub fn deinit(self: *Self) void {
                self.list.deinit();
            }

            /// to owned slice and deinit the backed array list
            pub fn slice(self: *Self) []T {
                return self.list.toOwnedSlice() catch unreachable;
            }
        };
    }
};
