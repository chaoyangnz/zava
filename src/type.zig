const std = @import("std");

const string = @import("./vm.zig").string;
const strings = @import("./vm.zig").strings;
const size32 = @import("./vm.zig").size32;
const size16 = @import("./vm.zig").size16;

// ------------- Value system ----------------------

pub const byte = i8;
pub const short = i16;
pub const char = u16;
pub const int = i32;
pub const long = i64;
pub const float = f32;
pub const double = f64;
pub const boolean = u1; // for boolean array, store as byte array. For other instruction, regarded as int
pub const returnAddress = u32;

pub const Reference = struct {
    ptr: ?*Object,

    const This = @This();
    pub fn isNull(this: This) bool {
        return this.ptr == null;
    }

    pub fn nonNull(this: This) bool {
        return this.ptr != null;
    }

    pub fn equals(this: This, that: This) bool {
        return this.ptr == that.ptr;
    }

    /// assert reference is non-null
    pub fn object(this: This) *Object {
        if (this.ptr) |ptr| {
            return ptr;
        } else {
            unreachable;
        }
    }

    pub fn class(this: This) *const Class {
        return this.object().header.class;
    }

    /// get instance var or array element
    /// Max instance vars are 2^16
    /// Max array items are 2^32
    pub fn get(this: This, index: u32) Value {
        // const i: u32 = @intCast(index);
        return this.object().slots[index];
    }

    /// set instance var or array element
    /// Max instance vars are 2^16
    /// Max array items are 2^32
    pub fn set(this: This, index: u32, value: Value) void {
        // const i: u32 = @intCast(index);
        this.object().slots[index] = value;
    }

    pub fn len(this: This) u16 {
        return size16(this.object().slots.len);
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
    pub fn as(this: This, comptime T: type) Value {
        return switch (T) {
            boolean => switch (this) {
                .boolean => this,
                // when in boolean array, vm store as byte array; elsewhere, store as int.
                inline .byte, .int => |t| .{ .boolean = if (t == 0) 0 else 1 },
                else => unreachable,
            },
            byte => switch (this) {
                .boolean => |t| .{ .byte = @intCast(t) },
                .byte => this,
                else => unreachable,
            },
            short => switch (this) {
                .byte => |t| .{ .short = t },
                .short => this,
                else => unreachable,
            },
            int => switch (this) {
                .boolean => |t| .{ .int = @intCast(t) },
                inline .byte, .short => |t| .{ .int = t },
                .int => this,
                else => unreachable,
            },
            long => switch (this) {
                inline .byte, .short, .int => |t| .{ .long = t },
                .long => this,
                else => unreachable,
            },
            else => switch (this) {
                inline else => |t| if (@TypeOf(t) == T) this else {
                    std.debug.panic("assert failed: {} as {}", .{ @TypeOf(t), T });
                },
            },
        };
    }
};

pub const Object = struct {
    header: struct {
        hash_code: int,
        class: *const Class,
    },
    slots: []Value,
    internal: struct {
        // For java.lang.Throwable only: throwable.stackTrace populated by fillInStackTrace
        stack_trace: Reference = undefined,
        /// For java.lang.Class only
        /// - undefined for NON javaLangClass objects
        /// - null for primitives javaLangClass
        /// - non-null for any class javaLangClass
        class: ?*const Class = undefined,
    },
};

pub const NULL: Reference = .{ .ptr = null };
pub const TRUE: boolean = 1;
pub const FALSE: boolean = 0;

pub const ObjectRef = Reference;
pub const ArrayRef = Reference;
///// alias
pub const JavaLangClass = ObjectRef;
pub const JavaLangString = ObjectRef;
pub const JavaLangThread = ObjectRef;
pub const JavaLangThrowable = ObjectRef;
pub const JavaLangClassLoader = ObjectRef;
pub const JavaLangReflectField = ObjectRef;
pub const JavaLangReflectConstructor = ObjectRef;

// ------------- Type system ----------------------

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

pub fn isType(descriptor: []const u8, comptime T: type) bool {
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

pub fn isPrimitiveType(descriptor: []const u8) bool {
    if (descriptor.len > 1) return false;
    const ch = descriptor[0];
    return switch (ch) {
        'B', 'C', 'D', 'F', 'I', 'J', 'S', 'Z' => true,
        else => false,
    };
}

pub const Class = struct {
    name: string,
    descriptor: string,
    access_flags: AccessFlags.Class,
    super_class: string,
    interfaces: []const string,
    constants: []Constant,

    /// non-array class
    fields: []Field,
    methods: []Method,

    instance_vars: u16,
    static_vars: []Value,
    source_file: string,

    is_array: bool,

    /// array class
    component_type: string,
    element_type: string,
    dimensions: usize,

    // status flags
    defined: bool = false,
    linked: bool = false,

    // internals
    object: ?*Object = null, // JavaLangClass

    const This = @This();

    pub fn constant(this: *const This, index: usize) Constant {
        return this.constants[index];
    }

    pub fn field(this: *const This, name: string, descriptor: string, static: bool) ?*const Field {
        for (this.fields) |*f| {
            if (f.access_flags.static == static and
                strings.equals(f.name, name) and
                strings.equals(f.descriptor, descriptor)) return f;
        }
        return null;
    }

    pub fn method(this: *const This, name: string, descriptor: string, static: bool) ?*const Method {
        for (this.methods) |*m| {
            if (m.access_flags.static == static and
                strings.equals(m.name, name) and
                strings.equals(m.descriptor, descriptor)) return m;
        }
        return null;
    }

    /// get static var
    pub fn get(this: This, index: i32) Value {
        const i = size32(index);
        return this.static_vars[i];
    }

    /// set static var
    pub fn set(this: This, index: i32, value: Value) void {
        const i = size32(index);
        this.static_vars[i] = value;
    }

    pub fn debug(this: *const This) void {
        const print = std.log.info;
        print("==== Class =====", .{});
        print("name: {s}", .{this.name});
        print("accessFlags: {x:0>4}", .{this.access_flags.raw});
        print("superClass: {s}", .{this.super_class});
        for (this.interfaces) |interface| {
            print("interface: {s}", .{interface});
        }
        if (this.is_array) {
            print("componentType: {s}", .{this.component_type});
            print("elementType: {s}", .{this.element_type});
        } else {
            for (1..this.constants.len) |i| {
                switch (this.constants[i]) {
                    inline else => |t| print("{d} -> {}", .{ i, t }),
                }
            }
            for (this.fields) |f| {
                print("{d}/{d} {s}: {s} {s} ", .{ f.index, f.slot, f.name, f.descriptor, if (f.access_flags.static) "<static>" else "" });
            }
            print("static vars: {d}", .{this.static_vars.len});
            print("instance vars: {d}", .{this.instance_vars});
            for (this.methods) |m| {
                m.debug();
            }
            print("================\n\n", .{});
        }
    }
};

pub const AccessFlags = struct {
    pub const Class = struct { raw: u16, public: bool, final: bool, super: bool, interface: bool, abstract: bool, synthetic: bool, annotation: bool, @"enum": bool };

    pub const Field = struct { raw: u16, public: bool, private: bool, protected: bool, static: bool, final: bool, @"volatile": bool, transient: bool, synthetic: bool, @"enum": bool };

    pub const Method = struct { raw: u16, public: bool, private: bool, protected: bool, static: bool, final: bool, synchronized: bool, bridge: bool, varargs: bool, native: bool, abstract: bool, strict: bool, synthetic: bool };
};

pub const Field = struct {
    // class: *Class = undefined,
    access_flags: AccessFlags.Field,
    name: string,
    descriptor: string,
    index: u16, // field index
    slot: u16, // slot index
};

pub const Method = struct {
    // class: *Class = undefined,
    access_flags: AccessFlags.Method,
    name: string,
    descriptor: string,

    max_stack: u16,
    max_locals: u16,
    // attributes
    code: []const u8,
    exceptions: []ExceptionHandler,
    local_vars: []LocalVariable,
    line_numbers: []LineNumber,

    parameter_descriptors: []string,
    return_descriptor: string,

    pub const LocalVariable = struct {
        start_pc: u16,
        length: u16,
        index: u16,
        name: string,
        descriptor: string,
    };

    pub const LineNumber = struct {
        start_pc: u16,
        line_number: u32,
    };

    pub const ExceptionHandler = struct {
        start_pc: u16,
        end_pc: u16,
        handle_pc: u16,
        catch_type: u16, // index of constant pool: ClassRef
    };

    const This = @This();

    pub fn debug(this: *const This) void {
        const print = std.log.info;
        print("#{s}: {s}", .{ this.name, this.descriptor });
        print("\t params: {d} return: {s}", .{ this.parameter_descriptors.len, this.return_descriptor });
        print("\t code: {d}", .{this.code.len});
        print("\t maxStack: {d}", .{this.max_stack});
        print("\t maxLocals: {d}", .{this.max_locals});
        print("\t exceptions: {d}", .{this.exceptions.len});
        print("\t lineNumbers: {d}", .{this.line_numbers.len});
    }
};

pub const Constant = union(enum) {
    classref: ClassRef,
    fieldref: FieldRef,
    methodref: MethodRef,
    interfaceMethodref: InterfaceMethodRef,
    string: String,
    utf8: Utf8,
    integer: Integer,
    long: Constant.Long,
    float: Constant.Float,
    double: Constant.Double,
    nameAndType: NameAndType,
    methodType: MethodType,
    methodHandle: MethodHandle,
    invokeDynamic: InvokeDynamic,

    const ClassRef = struct {
        /// class name, not descriptor
        class: string,
        // ref: ?*const Class = null,
    };

    const FieldRef = struct {
        /// class name, not descriptor
        class: string,
        name: string,
        descriptor: string,
        // ref: ?*const Field = null,
    };

    const MethodRef = struct {
        /// class name, not descriptor
        class: string,
        name: string,
        descriptor: string,
        // ref: ?*const Method = null,
    };

    const InterfaceMethodRef = struct {
        class: string,
        name: string,
        descriptor: string,
        // ref: ?*const Method = null,
    };

    const String = struct { value: string };

    const Utf8 = struct { value: string };

    const Integer = struct {
        value: i32,
    };

    const Long = struct {
        value: i64,
    };

    const Float = struct {
        value: f32,
    };

    const Double = struct {
        value: f64,
    };

    const NameAndType = struct {
        name: string,
        descriptor: string,
    };

    const MethodType = struct {
        descriptor: string,
    };

    const MethodHandle = struct {
        reference_kind: u8,
        reference_index: u16,
    };

    const InvokeDynamic = struct {
        bootstrap_method: string,
        name: string,
        descriptor: string,
    };
};
