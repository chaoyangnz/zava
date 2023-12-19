const std = @import("std");
const Endian = @import("./vm.zig").Endian;
const U1 = u8;
const U2 = u16;
const U4 = u32;

test "ClassFile" {
    std.testing.log_level = .debug;
    const dir = std.fs.cwd().openDir("src/classes", .{}) catch unreachable;
    const file = dir.openFile("Base62.class", .{}) catch unreachable;
    defer file.close();

    var reader = Reader.open(file.reader());
    defer reader.close();

    const class = reader.read();
    class.debug();
}

test "CharacterDataLatin1" {
    std.testing.log_level = .debug;
    const dir = std.fs.cwd().openDir("jdk/java/lang", .{}) catch unreachable;
    const file = dir.openFile("CharacterDataLatin1.class", .{}) catch unreachable;
    defer file.close();

    var reader = Reader.open(file.reader());
    defer reader.close();

    const class = reader.read();
    class.debug();
}

pub const Reader = struct {
    bytecode: []const U1,
    pos: U4 = 0,
    areana: std.heap.ArenaAllocator,
    // once constant pool is initialised
    constantPool: []ConstantInfo = undefined,

    const Self = @This();

    /// reader owns the bytes when it is from std.io.Reader
    pub fn open(reader: anytype) Reader {
        var areana = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        const bytecode = reader.readAllAlloc(areana.allocator(), 1024 * 1024 * 10) catch unreachable;
        return .{ .areana = areana, .bytecode = bytecode };
    }

    /// reader own the bytes if this consturctor is used.
    /// the bytes were uninitialsised.
    /// the caller must initialise the bytes afterwards.
    /// !! HACK: As bytecode is const, the caller has to use @constCast to remove const and assign new value.
    pub fn new(n: usize) Reader {
        const areana = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        var reader: Reader = .{ .areana = areana, .bytecode = undefined };
        reader.bytecode = reader.make(U1, n);
        return reader;
    }

    /// once reader is closed, the slices in the read classfile will be reclaimed as well.
    pub fn close(self: *Self) void {
        self.areana.deinit();
    }

    pub fn read(self: *Self) ClassFile {
        const magic = self.read1s(4)[0..4].*;
        const minorVersion = self.read2();
        const majorVersion = self.read2();
        const constantPoolCount = self.read2();
        const constantPool = self.make(ConstantInfo, constantPoolCount);
        var i: usize = 1;
        while (i < constantPoolCount) {
            const constantInfo = ConstantInfo.read(self);
            constantPool[i] = constantInfo;
            switch (constantInfo) {
                .long, .double => {
                    constantPool[i + 1] = constantInfo;
                    i += 2;
                },
                else => i += 1,
            }
        }
        self.constantPool = constantPool;
        const accessFlags = self.read2();
        const thisClass = self.read2();
        const superClass = self.read2();
        const interfaceCount = self.read2();
        const interfaces = self.reads(U2, interfaceCount, Reader.read2);
        const fieldsCount = self.read2();
        const fields = self.reads(FieldInfo, fieldsCount, FieldInfo.read);
        const methodsCount = self.read2();
        const methods = self.reads(MethodInfo, methodsCount, MethodInfo.read);
        const attributeCount = self.read2();
        const attributes = self.reads(AttributeInfo, attributeCount, AttributeInfo.read);
        return .{
            .magic = magic,
            .minorVersion = minorVersion,
            .majorVersion = majorVersion,
            .constantPoolCount = constantPoolCount,
            .constantPool = constantPool,
            .accessFlags = accessFlags,
            .thisClass = thisClass,
            .superClass = superClass,
            .interfaceCount = interfaceCount,
            .interfaces = interfaces,
            .fieldsCount = fieldsCount,
            .fields = fields,
            .methodsCount = methodsCount,
            .methods = methods,
            .attributeCount = attributeCount,
            .attributes = attributes,
        };
    }

    fn peek1(self: *const Self) U1 {
        const byte = self.bytecode[self.pos];
        return byte;
    }

    fn peek2(self: *const Self) U2 {
        return Endian.Big.load(U2, self.bytecode[self.pos .. self.pos + 2]);
    }

    fn peek4(self: *const Self) U4 {
        return Endian.Big.load(U4, self.bytecode[self.pos .. self.pos + 4]);
    }

    fn read1(self: *Self) U1 {
        const v = self.peek1();
        self.pos += 1;
        return v;
    }

    fn read2(self: *Self) U2 {
        const v = self.peek2();
        self.pos += 2;
        return v;
    }

    fn read4(self: *Self) U4 {
        const v = self.peek4();
        self.pos += 4;
        return v;
    }

    /// read a slice provided with an item readFn
    fn reads(self: *Self, comptime T: type, size: usize, readFn: *const fn (reader: *Reader) T) []T {
        const slice = self.make(T, size);
        for (0..size) |i| {
            slice[i] = readFn(self);
        }
        return slice;
    }

    fn read1s(self: *Self, length: U4) []U1 {
        return self.reads(U1, length, Reader.read1);
    }

    fn lookup(self: *const Self, comptime T: type, index: usize) T {
        const constantInfo = self.constantPool[index];

        return switch (constantInfo) {
            inline else => |c| if (@TypeOf(c) == T) c else unreachable,
        };
    }

    fn make(self: *Self, comptime T: type, size: usize) []T {
        return self.areana.allocator().alloc(T, size) catch unreachable;
    }
};

pub const ClassFile = struct {
    magic: [4]U1,
    minorVersion: U2,
    majorVersion: U2,
    constantPoolCount: U2,
    constantPool: []ConstantInfo,
    accessFlags: U2,
    thisClass: U2,
    superClass: U2,
    interfaceCount: U2,
    interfaces: []U2,
    fieldsCount: U2,
    fields: []FieldInfo,
    methodsCount: U2,
    methods: []MethodInfo,
    attributeCount: U2,
    attributes: []AttributeInfo,

    const Self = @This();

    pub fn debug(self: *const Self) void {
        const print = std.log.info;
        print("==== ClassFile =====", .{});
        print("magic: {s}", .{std.fmt.fmtSliceHexLower(&self.magic)});
        print("majorVersion: {d}", .{self.majorVersion});
        print("minorVersion: {d}", .{self.minorVersion});
        print("constantPoolCount: {d}", .{self.constantPoolCount});
        for (1..self.constantPool.len) |i| {
            switch (self.constantPool[i]) {
                inline else => |t| print("{d} -> {}", .{ i, t }),
            }
        }
        for (self.methods) |m| {
            print("#{s}: {s}", .{ self.constantPool[m.nameIndex].utf8.bytes, self.constantPool[m.descriptorIndex].utf8.bytes });
            for (m.attributes) |attribute| {
                switch (attribute) {
                    inline else => |a| print("\t {}", .{a}),
                }
            }
        }
        print("================\n\n", .{});
    }
};

const ConstantTag = enum(U1) {
    class = 7,
    fieldref = 9,
    methodref = 10,
    interfaceMethodref = 11,
    string = 8,
    integer = 3,
    float = 4,
    long = 5,
    double = 6,
    nameAndType = 12,
    utf8 = 1,
    methodHandle = 15,
    methodType = 16,
    invokeDynamic = 18,
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
    methodHandle: MethodHandleInfo,
    methodType: MethodTypeInfo,
    invokeDynamic: InvokeDynamicInfo,

    const Self = @This();
    fn read(reader: *Reader) Self {
        const tag: ConstantTag = @enumFromInt(reader.peek1());

        return switch (tag) {
            .class => .{ .class = ClassInfo.read(reader) },
            .fieldref => .{ .fieldref = FieldrefInfo.read(reader) },
            .methodref => .{ .methodref = MethodrefInfo.read(reader) },
            .interfaceMethodref => .{ .interfaceMethodref = InterfaceMethodrefInfo.read(reader) },
            .string => .{ .string = StringInfo.read(reader) },
            .integer => .{ .integer = IntegerInfo.read(reader) },
            .float => .{ .float = FloatInfo.read(reader) },
            .long => .{ .long = LongInfo.read(reader) },
            .double => .{ .double = DoubleInfo.read(reader) },
            .nameAndType => .{ .nameAndType = NameAndTypeInfo.read(reader) },
            .utf8 => .{ .utf8 = Utf8Info.read(reader) },
            .methodType => .{ .methodType = MethodTypeInfo.read(reader) },
            .methodHandle => .{ .methodHandle = MethodHandleInfo.read(reader) },
            .invokeDynamic => .{ .invokeDynamic = InvokeDynamicInfo.read(reader) },
        };
    }

    pub fn as(self: Self, comptime T: type) T {
        return switch (self) {
            inline else => |t| if (@TypeOf(t) == T) t else std.debug.panic("{} {}", .{ self, T }),
        };
    }

    const ClassInfo = packed struct {
        tag: U1,
        nameIndex: U2,

        fn read(reader: *Reader) @This() {
            return .{ .tag = reader.read1(), .nameIndex = reader.read2() };
        }
    };

    const FieldrefInfo = packed struct {
        tag: U1,
        classIndex: U2,
        nameAndTypeIndex: U2,

        fn read(reader: *Reader) @This() {
            return .{ .tag = reader.read1(), .classIndex = reader.read2(), .nameAndTypeIndex = reader.read2() };
        }
    };

    const MethodrefInfo = packed struct {
        tag: U1,
        classIndex: U2,
        nameAndTypeIndex: U2,

        fn read(reader: *Reader) @This() {
            return .{ .tag = reader.read1(), .classIndex = reader.read2(), .nameAndTypeIndex = reader.read2() };
        }
    };

    const InterfaceMethodrefInfo = packed struct {
        tag: U1,
        classIndex: U2,
        nameAndTypeIndex: U2,

        fn read(reader: *Reader) @This() {
            return .{ .tag = reader.read1(), .classIndex = reader.read2(), .nameAndTypeIndex = reader.read2() };
        }
    };

    const StringInfo = packed struct {
        tag: U1,
        stringIndex: U2,

        fn read(reader: *Reader) @This() {
            return .{ .tag = reader.read1(), .stringIndex = reader.read2() };
        }
    };

    const IntegerInfo = packed struct {
        tag: U1,
        bytes: U4,

        fn read(reader: *Reader) @This() {
            return .{ .tag = reader.read1(), .bytes = reader.read4() };
        }

        pub fn value(self: *const @This()) i32 {
            return @bitCast(self.bytes);
        }
    };

    const FloatInfo = packed struct {
        tag: U1,
        bytes: U4,

        fn read(reader: *Reader) @This() {
            return .{ .tag = reader.read1(), .bytes = reader.read4() };
        }

        pub fn value(self: *const @This()) f32 {
            return @bitCast(self.bytes);
        }
    };

    const LongInfo = packed struct {
        tag: U1,
        highBytes: U4,
        lowBytes: U4,

        fn read(reader: *Reader) @This() {
            return .{ .tag = reader.read1(), .highBytes = reader.read4(), .lowBytes = reader.read4() };
        }

        pub fn value(self: *const @This()) i64 {
            const hi: u64 = self.highBytes;
            const lo: u64 = self.lowBytes;
            return @bitCast(hi << 32 | lo);
        }
    };

    const DoubleInfo = packed struct {
        tag: U1,
        highBytes: U4,
        lowBytes: U4,

        fn read(reader: *Reader) @This() {
            return .{
                .tag = reader.read1(),
                .highBytes = reader.read4(),
                .lowBytes = reader.read4(),
            };
        }

        pub fn value(self: *const @This()) f64 {
            const hi: u64 = self.highBytes;
            const lo: u64 = self.lowBytes;
            return @bitCast(hi << 32 | lo);
        }
    };

    const NameAndTypeInfo = packed struct {
        tag: U1,
        nameIndex: U2,
        descriptorIndex: U2,

        fn read(reader: *Reader) @This() {
            return .{ .tag = reader.read1(), .nameIndex = reader.read2(), .descriptorIndex = reader.read2() };
        }
    };

    const Utf8Info = struct {
        tag: U1,
        length: U2,
        bytes: []U1, //U2 length

        fn read(reader: *Reader) @This() {
            const tag = reader.read1();
            const length = reader.read2();
            return .{ .tag = tag, .length = length, .bytes = reader.read1s(length) };
        }
    };

    const MethodHandleInfo = packed struct {
        tag: U1,
        referenceKind: U1,
        referenceIndex: U2,

        fn read(reader: *Reader) @This() {
            return .{ .tag = reader.read1(), .referenceKind = reader.read1(), .referenceIndex = reader.read2() };
        }
    };

    const MethodTypeInfo = packed struct {
        tag: U1,
        descriptorIndex: U2,

        fn read(reader: *Reader) @This() {
            return .{ .tag = reader.read1(), .descriptorIndex = reader.read2() };
        }
    };

    const InvokeDynamicInfo = packed struct {
        tag: U1,
        bootstrapMethodAttrIndex: U2,
        nameAndTypeIndex: U2,

        fn read(reader: *Reader) @This() {
            return .{ .tag = reader.read1(), .bootstrapMethodAttrIndex = reader.read2(), .nameAndTypeIndex = reader.read2() };
        }
    };
};

const FieldInfo = struct {
    accessFlags: U2,
    nameIndex: U2,
    descriptorIndex: U2,
    attributeCount: U2,
    attributes: []AttributeInfo,

    const Self = @This();
    fn read(reader: *Reader) Self {
        const accessFlags = reader.read2();
        const nameIndex = reader.read2();
        const descriptorIndex = reader.read2();
        const attributeCount = reader.read2();
        const attributes = reader.reads(AttributeInfo, attributeCount, AttributeInfo.read);
        return .{ .accessFlags = accessFlags, .nameIndex = nameIndex, .descriptorIndex = descriptorIndex, .attributeCount = attributeCount, .attributes = attributes };
    }
};

const MethodInfo = struct {
    accessFlags: U2,
    nameIndex: U2,
    descriptorIndex: U2,
    attributeCount: U2,
    attributes: []AttributeInfo,

    const Self = @This();
    fn read(reader: *Reader) Self {
        const accessFlags = reader.read2();
        const nameIndex = reader.read2();
        const descriptorIndex = reader.read2();
        const attributeCount = reader.read2();
        const attributes = reader.reads(AttributeInfo, attributeCount, AttributeInfo.read);
        return .{ .accessFlags = accessFlags, .nameIndex = nameIndex, .descriptorIndex = descriptorIndex, .attributeCount = attributeCount, .attributes = attributes };
    }
};

const AttributeInfo = union(enum) {
    code: CodeAttribute,
    lineNumberTable: LineNumberTableAttribute,
    localVariableTable: LocalVariableTableAttribute,
    sourceFile: SourceFileAttribute,
    runtimeVisibleAnnotations: RuntimeVisibleAnnotationsAttribute,
    unsupported: UnsupportedAttribute,

    const Self = @This();
    fn read(reader: *Reader) Self {
        const attributeNameIndex = reader.peek2();
        const name = reader.lookup(ConstantInfo.Utf8Info, attributeNameIndex).bytes;
        if (std.mem.eql(U1, name, "Code")) {
            return .{ .code = CodeAttribute.read(reader) };
        }
        if (std.mem.eql(U1, name, "LineNumberTable")) {
            return .{ .lineNumberTable = LineNumberTableAttribute.read(reader) };
        }
        if (std.mem.eql(U1, name, "LocalVariableTable")) {
            return .{ .localVariableTable = LocalVariableTableAttribute.read(reader) };
        }
        if (std.mem.eql(U1, name, "SourceFile")) {
            return .{ .sourceFile = SourceFileAttribute.read(reader) };
        }
        // if (std.mem.eql(U1, name, "RuntimeVisibleAnnotations")) {
        //     return .{ .runtimeVisibleAnnotations = RuntimeVisibleAnnotationsAttribute.read(reader) };
        // }
        // std.log.debug("Unsupported attribute {s}", .{name});
        return .{ .unsupported = UnsupportedAttribute.read(reader) };
    }

    const UnsupportedAttribute = struct {
        attributeNameIndex: U2,
        attributeLength: U4,
        raw: []U1,

        fn read(reader: *Reader) @This() {
            const attributeNameIndex = reader.read2();
            const attributeLength = reader.read4();
            return .{ .attributeNameIndex = attributeNameIndex, .attributeLength = attributeLength, .raw = reader.read1s(attributeLength) };
        }
    };

    const CodeAttribute = struct {
        attributeNameIndex: U2,
        attributeLength: U4,
        maxStack: U2,
        maxLocals: U2,
        codeLength: U4,
        code: []U1, //U4 code_length
        exceptionTableLength: U2,
        exceptionTable: []ExceptionTableEntry, //U2 exception_table_length
        attributesCount: U2,
        attributes: []AttributeInfo, //U2 attributes_count

        const ExceptionTableEntry = packed struct {
            startPc: U2,
            endPc: U2,
            handlerPc: U2,
            catchType: U2,

            fn read(reader: *Reader) @This() {
                return .{ .startPc = reader.read2(), .endPc = reader.read2(), .handlerPc = reader.read2(), .catchType = reader.read2() };
            }
        };

        fn read(reader: *Reader) @This() {
            const attributeNameIndex = reader.read2();
            const attributeLength = reader.read4();
            const maxStack = reader.read2();
            const maxLocals = reader.read2();
            const codeLength = reader.read4();
            const code = reader.read1s(codeLength);
            const exceptionTableLength = reader.read2();
            const exceptionTable = reader.reads(ExceptionTableEntry, exceptionTableLength, ExceptionTableEntry.read);
            const attributesCount = reader.read2();
            const attributes = reader.reads(AttributeInfo, attributesCount, AttributeInfo.read);
            return .{ .attributeNameIndex = attributeNameIndex, .attributeLength = attributeLength, .maxStack = maxStack, .maxLocals = maxLocals, .codeLength = codeLength, .code = code, .exceptionTableLength = exceptionTableLength, .exceptionTable = exceptionTable, .attributesCount = attributesCount, .attributes = attributes };
        }
    };

    const LineNumberTableAttribute = struct {
        attributeNameIndex: U2,
        attributeLength: U4,
        lineNumberTableLength: U2,
        lineNumberTable: []LineNumberTableEntry,

        const LineNumberTableEntry = packed struct {
            startPc: U2,
            lineNumber: U2,

            fn read(reader: *Reader) @This() {
                return .{ .startPc = reader.read2(), .lineNumber = reader.read2() };
            }
        };

        fn read(reader: *Reader) @This() {
            const attributeNameIndex = reader.read2();
            const attributeLength = reader.read4();
            const lineNumberTableLength = reader.read2();
            const lineNumberTable = reader.reads(LineNumberTableEntry, lineNumberTableLength, LineNumberTableEntry.read);
            return .{ .attributeNameIndex = attributeNameIndex, .attributeLength = attributeLength, .lineNumberTableLength = lineNumberTableLength, .lineNumberTable = lineNumberTable };
        }
    };

    const LocalVariableTableAttribute = struct {
        attributeNameIndex: U2,
        attributeLength: U4,
        localVariableTableLength: U2,
        localVariableTable: []LocalVariableTableEntry,

        const LocalVariableTableEntry = packed struct {
            startPc: U2,
            length: U2,
            nameIndex: U2,
            descriptorIndex: U2,
            index: U2,

            fn read(reader: *Reader) @This() {
                return .{ .startPc = reader.read2(), .length = reader.read2(), .nameIndex = reader.read2(), .descriptorIndex = reader.read2(), .index = reader.read2() };
            }
        };

        fn read(reader: *Reader) @This() {
            const attributeNameIndex = reader.read2();
            const attributeLength = reader.read4();
            const localVariableTableLength = reader.read2();
            const localVariableTable = reader.reads(LocalVariableTableEntry, localVariableTableLength, LocalVariableTableEntry.read);
            return .{ .attributeNameIndex = attributeNameIndex, .attributeLength = attributeLength, .localVariableTableLength = localVariableTableLength, .localVariableTable = localVariableTable };
        }
    };

    const SourceFileAttribute = packed struct {
        attributeNameIndex: U2,
        attributeLength: U4,
        sourceFileIndex: U2,

        fn read(reader: *Reader) @This() {
            return .{ .attributeNameIndex = reader.read2(), .attributeLength = reader.read4(), .sourceFileIndex = reader.read2() };
        }
    };

    const RuntimeVisibleAnnotationsAttribute = struct {
        attributeNameIndex: U2,
        attributeLength: U2,
        numAnnotations: U2,
        annotations: []Annotation,

        const Annotation = struct {
            typeIndex: U2,
            elementValuePairs: []ElementValuePair,
        };

        const ElementValuePair = struct {
            element_name_index: U2,
            value: ElementValue,
        };

        const ElementValue = struct {
            tag: U1,
            const_value_index: U2,
            enum_const_value: struct {
                type_name_index: U2,
                const_name_index: U2,
            },
            class_info_index: U2,
            array_value: struct {
                num_values: U2,
                values: []ElementValue,
            },
        };

        fn read(reader: *Reader) @This() {
            _ = reader;
            unreachable;
        }
    };
};
