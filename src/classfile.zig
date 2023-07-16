const std = @import("std");

const Stream = struct {
    bytecode: []u8,
    pos: u32 = 0,
    allocator: std.mem.Allocator = undefined,

    const This = @This();

    fn read(this: This) u8 {
        const byte = this.bytecode[this.pos];
        this.pos += 1;
        return byte;
    }

    fn peek(this: This) u8 {
        const byte = this.bytecode[this.pos];
        return byte;
    }

    fn readN(this: This, length: u32) []u8 {
        const bytes = this.bytecode[0..length];
        this.pos = length;
        return bytes;
    }

    fn read2(this: This) u16 {
        const byte0: u16 = this.bytecode[0];
        const byte1: u16 = this.bytecode[1];
        this.pos += 2;
        return byte0 << 8 | byte1; // big endian
    }

    fn read4(this: This) u16 {
        const byte0: u16 = this.bytecode[0];
        const byte1: u16 = this.bytecode[1];
        const byte2: u16 = this.bytecode[2];
        const byte3: u16 = this.bytecode[3];
        this.pos += 4;
        return byte0 << 24 | byte1 << 16 | byte2 << 8 | byte3; // big endian
    }

    fn readAs(this: This, comptime T: type) T {
        return @bitCast(this.readN(@sizeOf(T)));
    }

    fn make(this: This, comptime T: type, size: usize) []T {
        return std.ArrayList(T).initCapacity(this.allocator, size).items;
    }
};

const ClassFile = struct {
    magic: u32,
    minorVersion: u16,
    majorVersion: u16,
    constantPoolCount: u16,
    constantPool: []ConstantInfo,
    accessFlags: u16,
    thisClass: u16,
    superClass: u16,
    interfaceCount: u16,
    interfaces: []u16,
    fieldsCount: u16,
    fields: []FieldInfo,
    methodsCount: u16,
    methods: []MethodInfo,
    attributeCount: u16,
    attributes: []AttributeInfo,

    const This = @This();
    fn init(stream: Stream) This {
        const magic = stream.read4();
        _ = magic;
        const minorVersion = stream.read2();
        _ = minorVersion;
        const majorVersion = stream.read2();
        _ = majorVersion;
        const constantPoolCount = stream.read2();
        const constantPool = stream.make(ConstantInfo, constantPoolCount);
        for (1..constantPoolCount) |i| {
            constantPool[i] = ConstantInfo.init(stream);
        }
    }
};

const ConstantTag = enum(u8) {
    class,
    fieldref,
    methodref,
    interfaceMethodref,
    string,
    integer,
    float,
    long,
    double,
    nameAndType,
    utf8,
    methodType,
    invokeDynamic,
};

const ConstantInfo = union(ConstantTag) {
    class: ClassInfo,
    fieldref: FieldrefInfo,
    methodref: MethodrefInfo,
    interfaceMethodref: InterfaceMethodrefInfo,
    string: StringInfo,
    integer: IntegerInfo,
    float: FloatInfo,
    long: LongInfo,
    double: DoubleInfo,
    nameAndType: NameAndTypeInfo,
    utf8: Utf8Info,
    methodType: MethodTypeInfo,
    invokeDynamic: InvokeDynamicInfo,

    const This = @This();

    fn init(stream: Stream) This {
        const tag: ConstantTag = @enumFromInt(stream.peek());

        return switch (tag) {
            .class => .{ .class = stream.readAs(ClassInfo) },
            .fieldref => .{ .fieldref = stream.readAs(FieldrefInfo) },
            .methodref => .{ .methodref = stream.readAs(MethodrefInfo) },
            .interfaceMethodref => .{ .interfaceMethodref = stream.readAs(InterfaceMethodrefInfo) },
            .string => .{ .string = stream.readAs(StringInfo) },
            .integer => .{ .integer = stream.readAs(IntegerInfo) },
            .float => .{ .float = stream.readAs(FloatInfo) },
            .long => .{ .long = stream.readAs(LongInfo) },
            .double => .{ .double = stream.readAs(DoubleInfo) },
            .nameAndType => .{ .nameAndType = stream.readAs(NameAndTypeInfo) },
            .utf8 => .{ .utf8 = stream.readAs(Utf8Info) },
            .methodType => .{ .methodType = stream.readAs(MethodTypeInfo) },
            .invokeDynamic => .{ .invokeDynamic = stream.readAs(InvokeDynamicInfo) },
        };
    }

    const ClassInfo = packed struct {
        tag: u8,
        nameIndex: u16,
    };

    const FieldrefInfo = packed struct {
        tag: u8,
        classIndex: u16,
        nameAndTypeIndex: u16,
    };

    const MethodrefInfo = packed struct {
        tag: u8,
        classIndex: u16,
        nameAndTypeIndex: u16,
    };

    const InterfaceMethodrefInfo = packed struct {
        tag: u8,
        classIndex: u16,
        nameAndTypeIndex: u16,
    };

    const StringInfo = packed struct {
        tag: u8,
        stringIndex: u16,
    };

    const IntegerInfo = packed struct {
        tag: u8,
        bytes: u32,
    };

    const FloatInfo = packed struct {
        tag: u8,
        bytes: u32,
    };

    const LongInfo = packed struct {
        tag: u8,
        highBytes: u32,
        lowBytes: u32,
    };

    const DoubleInfo = packed struct {
        tag: u8,
        highBytes: u32,
        lowBytes: u32,
    };

    const NameAndTypeInfo = packed struct {
        tag: u8,
        nameIndex: u16,
        descriptorIndex: u16,
    };

    const Utf8Info = packed struct {
        tag: u8,
        length: u16,
        bytes: []u8, //u16 length
    };

    const MethodHandleInfo = packed struct {
        tag: u8,
        referenceKind: u8,
        referenceIndex: u16,
    };

    const MethodTypeInfo = packed struct {
        tag: u8,
        descriptorIndex: u16,
    };

    const InvokeDynamicInfo = packed struct {
        tag: u8,
        bootstrapMethodAttrIndex: u16,
        nameAndTypeIndex: u16,
    };
};

const FieldInfo = struct {
    accessFlags: u16,
    nameIndex: u16,
    descriptorIndex: u16,
    attributeCount: u16,
    attributes: []AttributeInfo,
};

const MethodInfo = struct {
    accessFlags: u16,
    nameIndex: u16,
    descriptorIndex: u16,
    attributeCount: u16,
    attributes: []AttributeInfo,
};

const AttributeInfo = union(enum) {
    code: CodeAttribute,
    lineNumberTable: LineNumberTableAttribute,
    localVariableTable: LocalVariableTableAttribute,
    sourceFile: SourceFileAttribute,
    runtimeVisibleAnnotations: RuntimeVisibleAnnotationsAttribute,

    const CodeAttribute = struct {
        attributeNameIndex: u16,
        attributeLength: u32,
        maxStack: u16,
        maxLocals: u16,
        codeLength: u32,
        code: []u8, //u32 code_length
        exceptionTableLength: u16,
        exceptionTable: []ExceptionTableEntry, //u16 exception_table_length
        attributesCount: u16,
        attributes: []AttributeInfo, //u16 attributes_count

        const ExceptionTableEntry = struct {
            startPc: u16,
            endPc: u16,
            handlerPc: u16,
            catchType: u16,
        };
    };

    const LineNumberTableAttribute = struct {
        attributeNameIndex: u16,
        attributeLength: u32,
        lineNumberTableLength: u16,
        lineNumberTable: []LineNumberTableEntry,

        const LineNumberTableEntry = struct {
            startPc: u16,
            lineNumber: u16,
        };
    };

    const LocalVariableTableAttribute = struct {
        attributeNameIndex: u16,
        attributeLength: u32,
        localVariableTableLength: u16,
        localVariableTable: []LocalVariableTableEntry,

        const LocalVariableTableEntry = struct {
            startPc: u16,
            length: u16,
            nameIndex: u16,
            descriptorIndex: u16,
            index: u16,
        };
    };

    const SourceFileAttribute = struct {
        attributeNameIndex: u16,
        attributeLength: u32,
        sourceFileIndex: u16,
    };

    const RuntimeVisibleAnnotationsAttribute = struct {
        attributeNameIndex: u16,
        attributeLength: u16,
        numAnnotations: u16,
        annotations: []Annotation,

        const Annotation = struct {
            typeIndex: u16,
            elementValuePairs: []struct {
                element_name_index: u16,
                value: ElementValue,
            },
        };

        const ElementValue = struct {
            tag: u8,
            const_value_index: u16,
            enum_const_value: struct {
                type_name_index: u16,
                const_name_index: u16,
            },
            class_info_index: u16,
            array_value: struct {
                num_values: u16,
                values: []ElementValue,
            },
        };
    };
};
