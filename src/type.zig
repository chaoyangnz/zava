const std = @import("std");

const string = @import("./util.zig").string;
const jsize = @import("./util.zig").jsize;

const concat = @import("./heap.zig").concat;

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
    pub fn get(this: This, index: u16) Value {
        // const i: u32 = @intCast(index);
        return this.object().slots[index];
    }

    /// set instance var or array element
    pub fn set(this: This, index: u16, value: Value) void {
        // const i: u32 = @intCast(index);
        this.object().slots[index] = value;
    }

    pub fn len(this: This) u16 {
        return jsize(this.object().slots.len);
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
                .boolean => |t| .{ .boolean = t },
                // when in boolean array, vm store as byte array; elsewhere, store as int.
                .byte, .int => |t| .{ .boolean = if (t == 0) 0 else 1 },
                else => unreachable,
            },
            byte => switch (this) {
                .byte => |t| .{ .byte = t },
                .boolean => |t| .{ .byte = @intCast(t) },
                else => unreachable,
            },
            short => switch (this) {
                .byte, .short => |t| .{ .short = t },
                else => unreachable,
            },
            int => switch (this) {
                .byte, .short, .int => |t| .{ .int = t },
                .boolean => |t| .{ .int = @intCast(t) },
                else => unreachable,
            },
            long => switch (this) {
                .byte, .short, .int, .long => |t| .{ .long = t },
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
    header: Header,
    slots: []Value,
    internal: struct {
        stackTrace: Reference = undefined, // For java.lang.Throwable only: throwable.stackTrace populated by fillInStackTrace
        class: *const Class = undefined, // For java.lang.Class only
    },

    const Header = struct {
        hashCode: int,
        class: *const Class,
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
pub const JavaLangReflectField = ObjectRef;
pub const JavaLangReflectConstructor = ObjectRef;

// ------------- Type system ----------------------

/// each type has a descriptor which is the binary name used in VM.
/// class type has an additional name which is the name in Java language.
pub const Type = union(enum) {
    byte: Byte,
    short: Short,
    char: Char,
    int: Int,
    long: Long,
    float: Float,
    double: Double,
    boolean: Boolean,
    class: Class,

    // pub fn of(descriptor: string) @This() {
    //     _ = descriptor;
    // }

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

    pub fn isPrimitive(descriptor: []const u8) bool {
        if (descriptor.len > 1) return false;
        const ch = descriptor[0];
        return switch (ch) {
            'B', 'C', 'D', 'F', 'I', 'J', 'S', 'Z' => true,
            else => false,
        };
    }

    pub fn name(descriptor: []const u8) []const u8 {
        const ch = descriptor[0];
        return switch (ch) {
            'B', 'C', 'D', 'F', 'I', 'J', 'S', 'Z', '[' => descriptor,
            'L' => descriptor[1 .. descriptor.len - 1],
            else => unreachable,
        };
    }
};

const Byte = struct { name: string = "B", descriptor: string = "B" };
const Short = struct { name: string = "S", descriptor: string = "S" };
const Char = struct { name: string = "C", descriptor: string = "C" };
const Int = struct { name: string = "I", descriptor: string = "I" };
const Long = struct { name: string = "J", descriptor: string = "J" };
const Float = struct { name: string = "F", descriptor: string = "F" };
const Double = struct { name: string = "D", descriptor: string = "D" };
const Boolean = struct { name: string = "Z", descriptor: string = "Z" };

pub const Class = struct {
    name: string,
    descriptor: string,
    accessFlags: AccessFlags.Class,
    superClass: string,
    interfaces: []string,
    constantPool: []Constant,

    /// non-array class
    fields: []Field,
    methods: []Method,

    instanceVars: u16,
    staticVars: []Value,
    sourceFile: string,

    isArray: bool,

    /// array class
    componentType: string,
    elementType: string,
    dimensions: usize,

    // status flags
    defined: bool = false,
    linked: bool = false,

    // internals
    object: ?*Object = null, // JavaLangClass

    const This = @This();

    pub fn constant(this: *const This, index: usize) Constant {
        return this.constantPool[index];
    }

    pub fn field(this: *const This, name: string, descriptor: string, static: bool) ?*const Field {
        for (this.fields) |*f| {
            if (f.accessFlags.static == static and
                std.mem.eql(u8, f.name, name) and
                std.mem.eql(u8, f.descriptor, descriptor)) return f;
        }
        return null;
    }

    pub fn method(this: *const This, name: string, descriptor: string, static: bool) ?*const Method {
        for (this.methods) |*m| {
            if (m.accessFlags.static == static and
                std.mem.eql(u8, m.name, name) and
                std.mem.eql(u8, m.descriptor, descriptor)) return m;
        }
        return null;
    }

    /// get static var
    pub fn get(this: This, index: i32) Value {
        const i: u32 = @bitCast(index);
        return this.staticVars[i];
    }

    /// set static var
    pub fn set(this: This, index: i32, value: Value) void {
        const i: u32 = @bitCast(index);
        this.staticVars[i] = value;
    }

    pub fn debug(this: *const This) void {
        const print = std.log.info;
        print("==== Class =====", .{});
        print("name: {s}", .{this.name});
        print("accessFlags: {x:0>4}", .{this.accessFlags});
        print("superClass: {s}", .{this.superClass});
        for (this.interfaces) |interface| {
            print("interface: {s}", .{interface});
        }
        if (this.isArray) {
            print("componentType: {s}", .{this.componentType});
            print("elementType: {s}", .{this.elementType});
        } else {
            for (1..this.constantPool.len) |i| {
                switch (this.constantPool[i]) {
                    inline else => |t| print("{d} -> {}", .{ i, t }),
                }
            }
            for (this.fields) |f| {
                print("{d}/{d} {s}: {s} {s} ", .{ f.index, f.slot, f.name, f.descriptor, if (f.accessFlags.static) "<static>" else "" });
            }
            print("static vars: {d}", .{this.staticVars.len});
            print("instance vars: {d}", .{this.instanceVars});
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
    accessFlags: AccessFlags.Field,
    name: string,
    descriptor: string,
    index: u16, // field index
    slot: u16, // slot index
};

pub const Method = struct {
    // class: *Class = undefined,
    accessFlags: AccessFlags.Method,
    name: string,
    descriptor: string,

    maxStack: u16,
    maxLocals: u16,
    // attributes
    code: []const u8,
    exceptions: []ExceptionHandler,
    localVars: []LocalVariable,
    lineNumbers: []LineNumber,

    parameterDescriptors: []string,
    returnDescriptor: string,

    pub const LocalVariable = struct {
        startPc: u16,
        length: u16,
        index: u16,
        name: string,
        descriptor: string,
    };

    pub const LineNumber = struct {
        startPc: u16,
        lineNumber: u32,
    };

    pub const ExceptionHandler = struct {
        startPc: u16,
        endPc: u16,
        handlePc: u16,
        catchType: u16, // index of constant pool: ClassRef
    };

    const This = @This();

    pub fn debug(this: *const This) void {
        const print = std.log.info;
        print("#{s}: {s}", .{ this.name, this.descriptor });
        print("\t params: {d} return: {s}", .{ this.parameterDescriptors.len, this.returnDescriptor });
        print("\t code: {d}", .{this.code.len});
        print("\t maxStack: {d}", .{this.maxStack});
        print("\t maxLocals: {d}", .{this.maxLocals});
        print("\t exceptions: {d}", .{this.exceptions.len});
        print("\t lineNumbers: {d}", .{this.lineNumbers.len});
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
        referenceKind: u8,
        referenceIndex: u16,
    };

    const InvokeDynamic = struct {
        bootstrapMethod: string,
        name: string,
        descriptor: string,
    };
};
