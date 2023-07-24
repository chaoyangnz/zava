const std = @import("std");
const string = @import("./shared.zig").string;
const concat = @import("./heap.zig").concat;

// ------------- Value system ----------------------

pub const byte = i8;
pub const short = i16;
pub const char = u16;
pub const int = i32;
pub const long = i64;
pub const float = f32;
pub const double = f64;
pub const boolean = i1; // for boolean array, store as byte array. For other instruction, regarded as int
pub const returnAddress = u32;

pub const Reference = struct {
    ptr: ?*Object,

    const This = @This();
    pub fn isNull(this: This) bool {
        return this.ptr == null;
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
    pub fn get(this: This, index: i32) Value {
        const i: u32 = @intCast(index);
        return this.object().slots[i];
    }

    /// set instance var or array element
    pub fn set(this: This, index: i32, value: Value) void {
        const i: u32 = @intCast(index);
        this.object().slots[i] = value;
    }

    pub fn len(this: This) i32 {
        return @intCast(this.object().slots.len);
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
                .byte, .boolean => |t| .{ .boolean = t },
                else => unreachable,
            },
            byte => switch (this) {
                .byte, .boolean => |t| .{ .byte = t },
                else => unreachable,
            },
            short => switch (this) {
                .byte, .boolean, .short => |t| .{ .short = t },
                else => unreachable,
            },
            int => switch (this) {
                .byte, .boolean, .short, .int => |t| .{ .int = t },
                else => unreachable,
            },
            long => switch (this) {
                .byte, .boolean, .short, .int, .long => |t| .{ .long = t },
                else => unreachable,
            },
            else => this,
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
    accessFlags: u16,
    superClass: string,
    interfaces: []string,
    constantPool: []Constant,

    /// non-array class
    fields: []Field,
    methods: []Method,

    instanceVars: i32,
    staticVars: []Value,
    sourceFile: string,

    isArray: bool,

    /// array class
    componentType: string,
    elementType: string,
    dimensions: u32,

    // status flags
    defined: bool = false,
    linked: bool = false,

    const This = @This();
    pub fn hasAccessFlag(this: *const This, flag: AccessFlag.Class) bool {
        return this.accessFlags & @intFromEnum(flag) != 0;
    }

    pub fn constant(this: *const This, index: usize) Constant {
        return this.constantPool[index];
    }

    pub fn field(this: *const This, name: string, descriptor: string, static: bool) ?*const Field {
        for (this.fields) |*f| {
            if (f.hasAccessFlag(.STATIC) == static and
                std.mem.eql(u8, f.name, name) and
                std.mem.eql(u8, f.descriptor, descriptor)) return f;
        }
        return null;
    }

    pub fn method(this: *const This, name: string, descriptor: string, static: bool) ?*const Method {
        for (this.methods) |*m| {
            if (m.hasAccessFlag(.STATIC) == static and
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

    /// check if `class` is a subclass of `this`
    pub fn isAssignableFrom(this: *const This, class: *const Class) bool {
        _ = this;
        _ = class;
        return false;
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
                print("{d}/{d} {s}: {s} {s} ", .{ f.index, f.slot, f.name, f.descriptor, if (f.hasAccessFlag(.STATIC)) "<static>" else "" });
            }
            print("static vars: {d}", .{this.staticVars.len});
            for (this.methods) |m| {
                m.debug();
            }
            print("================\n\n", .{});
        }
    }
};

pub const AccessFlag = struct {
    pub const Class = enum(u16) {
        PUBLIC = 0x0001,
        FINAL = 0x0010,
        SUPER = 0x0020,
        INTERFACE = 0x0200,
        ABSTRACT = 0x0400,
        SYNTHETIC = 0x1000,
        ANNOTATION = 0x2000,
        ENUM = 0x4000,
    };

    pub const Field = enum(u16) {
        PUBLIC = 0x0001,
        PRIVATE = 0x0002,
        PROTECTED = 0x0004,
        STATIC = 0x0008,
        FINAL = 0x0010,
        VOLATILE = 0x0040,
        TRANSIENT = 0x0080,
        SYNTHETIC = 0x1000,
        ENUM = 0x4000,
    };

    pub const Method = enum(u16) {
        PUBLIC = 0x0001,
        PRIVATE = 0x0002,
        PROTECTED = 0x0004,
        STATIC = 0x0008,
        FINAL = 0x0010,
        SYNCHRONIZED = 0x0020,
        BRIDGE = 0x0040,
        VARARGS = 0x0080,
        NATIVE = 0x0100,
        ABSTRACT = 0x0400,
        STRICT = 0x0800,
        SYNTHETIC = 0x1000,
    };
};

pub const Field = struct {
    // class: *Class = undefined,
    accessFlags: u16,
    name: string,
    descriptor: string,
    index: i32, // field index
    slot: i32, // slot index

    const This = @This();
    pub fn hasAccessFlag(this: This, flag: AccessFlag.Field) bool {
        return this.accessFlags & @intFromEnum(flag) != 0;
    }
};

pub const Method = struct {
    // class: *Class = undefined,
    accessFlags: u16,
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
    pub fn hasAccessFlag(this: *const This, flag: AccessFlag.Method) bool {
        return this.accessFlags & @intFromEnum(flag) != 0;
    }

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
        ref: ?*const Class = null,
    };

    const FieldRef = struct {
        /// class name, not descriptor
        class: string,
        name: string,
        descriptor: string,
        ref: ?*const Field = null,
    };

    const MethodRef = struct {
        /// class name, not descriptor
        class: string,
        name: string,
        descriptor: string,
        ref: ?*const Method = null,
    };

    const InterfaceMethodRef = struct {
        class: string,
        name: string,
        descriptor: string,
        ref: ?*const Method = null,
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
