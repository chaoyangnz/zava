const Class = @import("./type.zig").Class;

pub const byte = i8;
pub const short = i16;
pub const char = u16;
pub const int = i32;
pub const long = i64;
pub const float = f32;
pub const double = f64;
pub const boolean = u8; // for boolean array, store as byte array. For other instruction, regarded as int

pub const Reference = struct {
    ptr: ?*Object,
};

pub const Value = union(enum) {
    byte: byte,
    short: short,
    char: char,
    int: int,
    long: long,
    float: float,
    double: double,
    boolean: boolean,
    Reference: Reference,

    const This = @This();
    fn unwrap(this: *This, comptime T: type) T {
        switch (this) {
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

pub const ObjectReference = Reference;
pub const ArrayReference = Reference;
/////
pub const JavaLangClass = ObjectReference;
pub const JavaLangThread = ObjectReference;
