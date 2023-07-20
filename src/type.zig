const value = @import("./value.zig");
const Value = value.Value;
const JavaLangClass = value.JavaLangClass;
const string = @import("./shared.zig").string;

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
    fn class(this: *const This) JavaLangClass {
        return switch (this) {
            inline else => |t| t.class,
        };
    }

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
};

const Byte = struct { class: JavaLangClass };
const Short = struct { class: JavaLangClass };
const Char = struct { class: JavaLangClass };
const Int = struct { class: JavaLangClass };
const Long = struct { class: JavaLangClass };
const Float = struct { class: JavaLangClass };
const Double = struct { class: JavaLangClass };
const Boolean = struct { class: JavaLangClass };

pub const Class = struct {
    name: string,
    accessFlags: u16,
    superClass: string,
    interfaces: []string,
    constantPool: []Constant,

    /// non-array class
    fields: []Field,
    methods: []Method,

    // derived
    instanceVarFields: []Field,
    staticVarFields: []Field,

    isArray: bool,

    /// array class
    componentType: string,
    elementType: string,
    dimensions: u32,

    staticVars: []Value,

    sourceFile: string,

    // status flags
    defined: bool,
    linked: bool,

    // initialised:

    class: JavaLangClass,

    const This = @This();
    pub fn hasAccessFlag(this: *This, flag: AccessFlag.Class) bool {
        return this.accessFlags & @intFromEnum(flag) != 0;
    }

    pub fn isArray(this: *This) bool {
        return this.name[0] == '[';
    }

    pub fn constant(this: *This, index: usize) Constant {
        return this.constantPool[index];
    }

    pub fn method(this: *This, index: usize) Field {
        return this.methods[index];
    }
};

pub const AccessFlag = enum(u16) {
    PUBLIC = 0x0001,
    PRIVATE = 0x0002,
    PROTECTED = 0x0004,
    STATIC = 0x0008,
    FINAL = 0x0010,
    SYNCHRONIZED = 0x0020,
    SUPER = 0x0020,
    VOLATILE = 0x0040,
    BRIDGE = 0x0040,
    TRANSIENT = 0x0080,
    VARARGS = 0x0080,
    NATIVE = 0x0100,
    INTERFACE = 0x0200,
    ABSTRACT = 0x0400,
    STRICT = 0x0800,
    SYNTHETIC = 0x1000,
    ANNOTATION = 0x2000,
    ENUM = 0x4000,

    const Class = enum(u16) {};

    const Field = enum(u16) {
        PUBLIC = @intFromEnum(AccessFlag.PUBLIC),
        PRIVATE = @intFromEnum(AccessFlag.PRIVATE),
        PROTECTED = @intFromEnum(AccessFlag.PROTECTED),
        STATIC = @intFromEnum(AccessFlag.STATIC),
        FINAL = @intFromEnum(AccessFlag.FINAL),
        VOLATILE = @intFromEnum(AccessFlag.VOLATILE),
        TRANSIENT = @intFromEnum(AccessFlag.TRANSIENT),
        SYNTHETIC = @intFromEnum(AccessFlag.SYNTHETIC),
        ENUM = @intFromEnum(AccessFlag.ENUM),
    };

    const Method = enum(u16) {
        PUBLIC = @intFromEnum(AccessFlag.PUBLIC),
        PRIVATE = @intFromEnum(AccessFlag.PRIVATE),
        PROTECTED = @intFromEnum(AccessFlag.PROTECTED),
        STATIC = @intFromEnum(AccessFlag.STATIC),
        FINAL = @intFromEnum(AccessFlag.FINAL),
        SYNCHRONIZED = @intFromEnum(AccessFlag.SYNCHRONIZED),
        BRIDGE = @intFromEnum(AccessFlag.BRIDGE),
        VARARGS = @intFromEnum(AccessFlag.VARARGS),
        NATIVE = @intFromEnum(AccessFlag.NATIVE),
        ABSTRACT = @intFromEnum(AccessFlag.ABSTRACT),
        STRICT = @intFromEnum(AccessFlag.STRICT),
        SYNTHETIC = @intFromEnum(AccessFlag.SYNTHETIC),
    };
};

pub const Field = struct {
    class: *Class,
    accessFlags: u16,
    name: string,
    descriptor: string,
    index: u32, // slot index

    const This = @This();
    pub fn hasAccessFlag(this: This, flag: AccessFlag.Field) bool {
        return this.accessFlags & @intFromEnum(flag) != 0;
    }
};

pub const Method = struct {
    class: *Class,
    accessFlags: u16,
    name: string,
    descriptor: string,

    maxStack: u32,
    maxLocals: u32,
    // attributes
    code: []u8,
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
    class: ClassRef,
    fieldref: FieldRef,
    methodref: MethodRef,
    interfaceMethodRef: InterfaceMethodRef,
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
        class: string,
        ref: *Class,
    };

    const FieldRef = struct {
        class: string,
        name: string,
        descriptor: string,
        ref: *Field,
    };

    const MethodRef = struct {
        class: string,
        name: string,
        descriptor: string,
        ref: *Method,
    };

    const InterfaceMethodRef = struct {
        class: string,
        name: string,
        descriptor: string,
        ref: *Method,
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
