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

    pub fn class(this: This) *const Class {
        return this.object().header.class;
    }

    pub fn get(this: This, index: i32) Value {
        const i: u32 = @bitCast(index);
        return this.object().slots[i];
    }

    pub fn set(this: This, index: i32, value: Value) void {
        const i: u32 = @bitCast(index);
        this.object().slots[i] = value;
    }
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
    returnAddress: returnAddress,
    ref: Reference,

    const This = @This();

    /// int compatible
    pub fn as(this: This, comptime T: type) T {
        return switch (this) {
            .byte, .boolean => |t| if (T == byte or T == boolean or T == short or T == int or T == long) t else unreachable,
            .short => |t| if (T == short or T == int or T == long) @as(T, t) else unreachable,
            .int => |t| if (T == int or T == long) @as(T, t) else unreachable,
            else => |t| if (@TypeOf(t) == T) t else unreachable,
        };
    }
};

pub const Object = struct {
    header: Header,
    slots: []Value,

    const Header = struct {
        hashCode: int,
        class: *const Class,
    };

    pub fn len(this: @This()) i32 {
        const length: u32 = @truncate(this.slots.len);
        return @bitCast(length);
    }
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

/// B	            byte	signed byte
/// C	            char	Unicode character code point in the Basic Multilingual Plane, encoded with UTF-16
/// D	            double	double-precision floating-point value
/// F	            float	single-precision floating-point value
/// I	            int	integer
/// J	            long	long integer
/// LClassName;	    reference	an instance of class ClassName
/// S	            short	signed short
/// Z	            boolean	true or false
/// [	            reference	one array dimension
pub fn defaultValue(descriptor: []const u8) Value {
    const ch = descriptor[0];
    return switch (ch) {
        'B' => .{ .byte = 0 },
        'C' => .{ .char = 0 },
        'D' => .{ .double = 0.0 },
        'F' => .{ .float = 0.0 },
        'I' => .{ .int = 0 },
        'J' => .{ .long = 0.0 },
        'S' => .{ .short = 0.0 },
        'Z' => .{ .boolean = 0 },
        'L', '[' => .{ .ref = NULL },
        else => unreachable,
    };
}

pub fn is(descriptor: []const u8, comptime T: type) bool {
    const ch = descriptor[0];
    return switch (ch) {
        'B' => T == byte,
        'C' => T == char,
        'D' => T == double,
        'F' => T == float,
        'I' => T == int,
        'J' => T == long,
        'S' => T == short,
        'Z' => T == boolean,
        'L' => T == ObjectRef,
        '[' => T == ArrayRef,
        else => unreachable,
    };
}
