const std = @import("std");
const value = @import("./value.zig");
const Value = value.Value;
const NULL = value.NULL;
const string = @import("./shared.zig").string;
const concat = @import("./heap.zig").concat;

const Type = union(enum) {
    byte: Byte,
    short: Short,
    char: Char,
    int: Int,
    long: Long,
    float: Float,
    double: Double,
    boolean: Boolean,
    class: Class,

    const This = @This();

    pub fn as(this: *This, comptime T: type) T {
        switch (this) {
            inline else => |t| if (@TypeOf(t) == T) t else unreachable,
        }
    }

    pub fn is(this: *This, comptime T: type) bool {
        switch (this) {
            inline else => |t| @TypeOf(t) == T,
        }
    }

    /// binary name
    pub fn name(this: *This) string {
        return switch (this) {
            .class => |cls| if (!cls.isArray) concat(&[_]string{ "L", cls.name, ";" }) else cls.name,
            inline else => |t| t.name,
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

    instanceVars: usize,
    staticVars: []Value,
    sourceFile: string,

    // derived
    // instanceVarFields: []Field,
    // staticVarFields: []Field,

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

    pub fn method(this: *const This, name: string, descriptor: string) ?Method {
        for (this.methods) |m| {
            if (std.mem.eql(u8, m.name, name) and std.mem.eql(u8, m.descriptor, descriptor)) {
                return m;
            }
        }
        return null;
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
                print("{d} {s}: {s}", .{ f.index, f.name, f.descriptor });
            }
            for (this.methods) |m| {
                print("#{s}: {s}", .{ m.name, m.descriptor });
                print("\t params: {d} return: {s}", .{ m.parameterDescriptors.len, m.returnDescriptor });
                print("\t code: {d}", .{m.code.len});
                print("\t maxStack: {d}", .{m.maxStack});
                print("\t maxLocals: {d}", .{m.maxLocals});
                print("\t exceptions: {d}", .{m.exceptions.len});
                print("\t lineNumbers: {d}", .{m.lineNumbers.len});
            }
            print("static vars: {d}", .{this.staticVars.len});
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
    index: usize, // slot index

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
        startPc: u32,
        endPc: u32,
        handlePc: u32,
        catchType: u32, // index of constant pool: ClassRef
    };

    const This = @This();
    pub fn hasAccessFlag(this: *This, flag: AccessFlag.Method) bool {
        return this.accessFlags & @intFromEnum(flag) != 0;
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
        // class name, not descriptor
        class: string,
        ref: ?*const Class = null,
    };

    const FieldRef = struct {
        // class name, not descriptor
        class: string,
        name: string,
        descriptor: string,
        ref: ?*const Field = null,
    };

    const MethodRef = struct {
        // class name, not descriptor
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

    const This = @This();
    pub fn as(this: *This, comptime T: type) T {
        switch (this) {
            inline else => |t| if (@TypeOf(t) == T) t else unreachable,
        }
    }
};

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
pub fn defaultValue(descriptor: string) Value {
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
