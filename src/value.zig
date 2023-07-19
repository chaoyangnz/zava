const Class = @import("./type.zig").Class;

pub const byte = i8;
pub const short = i16;
pub const char = u16;
pub const int = i32;
pub const long = i64;
pub const float = f32;
pub const double = f64;
pub const boolean = i8; // for boolean array, store as byte array. For other instruction, regarded as int
pub const returnAddress = u32;

pub const Reference = struct {
    ptr: ?*Object,

    const This = @This();
    pub fn isNull(this: This) bool {
        return this.ptr == null;
    }

    fn object(this: This) *Object {
        if (this.ptr) |ptr| {
            return ptr;
        } else {
            unreachable;
        }
    }

    pub fn class(this: This) Class {
        return this.object().header.class;
    }

    pub fn get(this: This, index: i32) Value {
        return this.object().slots[index];
    }

    pub fn set(this: This, index: i32, value: Value) void {
        this.object().slots[index] = value;
    }

    pub fn len(this: *This) u32 {
        return this.slots.len;
    }
};

/// try T <- n
pub fn intComaptible(n: anytype, comptime T: type) bool {
    const N = @TypeOf(n);
    switch (T) {
        byte => N == byte,
        short => N == byte or N == short,
        int => N = byte or N == short or N == int or N == boolean, // boolean can be comaptible to int
        long => N = byte or N == short or N == int or N == long,
        else => false,
    }
}

pub const Value = union(enum) {
    byte: byte,
    short: short,
    char: char,
    int: int,
    long: long,
    float: float,
    double: double,
    boolean: boolean,
    returnAddress: returnAddress,
    ref: Reference,
    void: void,

    const This = @This();
    pub fn as(this: *This, comptime T: type) T {
        switch (this) {
            byte, short, int, long => |t| if (intComaptible(t, comptime T)) t else unreachable,
            inline else => |t| if (@TypeOf(t) == T) t else unreachable,
        }
    }
};

pub const Object = struct {
    header: Header,
    slots: []Value,

    const Header = struct {
        hashCode: int,
        class: *Class,
    };
};

pub const NULL: Reference = .{ .ptr = null };

pub const ObjectRef = Reference;
pub const ArrayRef = Reference;
/////
pub const JavaLangClass = ObjectRef;
pub const JavaLangString = ObjectRef;
pub const JavaLangThread = ObjectRef;
pub const JavaLangThrowable = ObjectRef;
pub const JavaLangClassLoader = ObjectRef;
pub const JavaLangReflectConstructor = ObjectRef;
