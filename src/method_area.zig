const std = @import("std");
const string = @import("./shared.zig").string;
const Class = @import("./type.zig").Class;
const Constant = @import("./type.zig").Constant;
const Field = @import("./type.zig").Field;
const Method = @import("./type.zig").Method;
const AccessFlags = @import("./type.zig").AccessFlag;
const Type = @import("./type.zig").Type;
const Value = @import("./type.zig").Value;
const Object = @import("./type.zig").Object;
const NULL = @import("./type.zig").NULL;
const JavaLangString = @import("./type.zig").JavaLangString;
const JavaLangClassLorder = @import("./type.zig").JavaLangClassLoader;
const ClassFile = @import("./classfile.zig").ClassFile;
const Reader = @import("./classfile.zig").Reader;
const Endian = @import("./shared.zig").Endian;
const make = @import("./shared.zig").make;
const clone = @import("./shared.zig").clone;
const concat = @import("./shared.zig").concat;

test "deriveClass" {
    std.testing.log_level = .debug;

    var reader = loadClass("Base62");
    defer reader.close();
    const class = deriveClass(reader.read());
    class.debug();
}

test "deriveArray" {
    std.testing.log_level = .debug;

    const array = deriveArray("[[Ljava/lang/String;");
    array.debug();
}

test "lookupClass" {
    std.testing.log_level = .debug;

    const class = lookupClass(NULL, "Calendar");
    const class1 = lookupClass(NULL, "Calendar");
    // class.debug();
    try std.testing.expect(class == class1);
    class.debug();
    const method = class.method("main", "([Ljava/lang/String;)V");
    method.?.debug();
}

test "intern" {
    std.testing.log_level = .debug;
    var areana = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer areana.deinit();

    const str1 = intern("abc");
    const str2 = intern(&[_]u8{ 'a', 'b', 'c' });
    const str3 = intern("xyzabc123"[3..6]);
    const str = try areana.allocator().alloc(u8, 6);
    @memcpy(str, "abcdef");
    const str4 = intern(str[0..3]);
    try std.testing.expect(std.mem.eql(u8, str1, str2));
    try std.testing.expect(std.mem.eql(u8, str1, str3));
    try std.testing.expect(std.mem.eql(u8, str2, str3));
    try std.testing.expect(std.mem.eql(u8, str1, str4));

    try std.testing.expect(str1.ptr == str2.ptr);
    try std.testing.expect(str1.ptr == str3.ptr);
    try std.testing.expect(str2.ptr == str3.ptr);
    try std.testing.expect(str1.ptr == str4.ptr);

    for (0..3) |i| {
        try std.testing.expect(&str1[i] == &str2[i]);
        try std.testing.expect(&str1[i] == &str3[i]);
        try std.testing.expect(&str2[i] == &str3[i]);
        try std.testing.expect(&str1[i] == &str4[i]);
    }
}

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

// Class, Method, Field etc/
pub const method_area_allocator = arena.allocator();

pub const string_allocator = arena.allocator();

pub const classpath: []string = [_]string{"."};

/// string pool
var stringPool = std.StringHashMap(void).init(method_area_allocator);

pub fn intern(str: []const u8) string {
    if (!stringPool.contains(str)) {
        const key = clone(str, string_allocator);
        stringPool.put(key, void{}) catch unreachable;
    }
    return stringPool.getKey(str).?;
}

/// class pool
const ClassloaderScope = std.StringHashMap(Class);
var classPool = std.AutoHashMap(?*Object, ClassloaderScope).init(method_area_allocator);

pub fn lookupClass(classloader: JavaLangClassLorder, name: string) *const Class {
    // TODO parent delegation
    if (!classPool.contains(classloader.ptr)) {
        classPool.put(classloader.ptr, ClassloaderScope.init(method_area_allocator)) catch unreachable;
    }
    var classloaderScope = classPool.getPtr(classloader.ptr).?;
    if (!classloaderScope.contains(name)) {
        classloaderScope.put(name, createClass(classloader, name)) catch unreachable;
    }
    return classloaderScope.getPtr(name).?;
}

/// create a class or array class
fn createClass(classloader: JavaLangClassLorder, name: string) Class {
    if (name[0] != '[') {
        var reader = if (classloader.isNull()) loadClass(name) else loadClassUd(classloader, name);
        defer reader.close();
        return deriveClass(reader.read());
    } else {
        return deriveArray(name);
    }
}

/// class loaders
/// bootstrap class loader loads a class from class path.
fn loadClass(name: string) Reader {
    const fileName = concat(&[_]string{ name, ".class" });
    const dir = std.fs.cwd().openDir("src", .{}) catch unreachable;
    const file = dir.openFile(fileName, .{}) catch unreachable;
    defer file.close();

    return Reader.open(file.reader());
}

/// user defined class loader loads a class from class path, network or somewhere else
fn loadClassUd(classloader: JavaLangClassLorder, name: string) Reader {
    _ = name;
    _ = classloader;
    std.debug.panic("User defined classloader is not implemented", .{});
}

// derive a class representation in vm from class file
// all the slices in Class will be in method area
// once the whole class is put into class pool (backed by method area), then the deep Class memory is in method area.
fn deriveClass(classfile: ClassFile) Class {
    var constantPool = make(Constant, classfile.constantPool.len, method_area_allocator);
    for (1..constantPool.len) |i| {
        const constantInfo = classfile.constantPool[i];
        constantPool[i] = switch (constantInfo) {
            .class => |c| .{ .classref = .{ .class = Helpers.utf8(classfile, c.nameIndex) } },
            .fieldref => |c| blk: {
                const nt = Helpers.nameAndType(classfile, c.nameAndTypeIndex);
                break :blk .{ .fieldref = .{
                    .class = Helpers.class(classfile, c.classIndex),
                    .name = nt[0],
                    .descriptor = nt[1],
                } };
            },
            .methodref => |c| blk: {
                const nt = Helpers.nameAndType(classfile, c.nameAndTypeIndex);
                break :blk .{ .methodref = .{
                    .class = Helpers.class(classfile, c.classIndex),
                    .name = nt[0],
                    .descriptor = nt[1],
                } };
            },
            .interfaceMethodref => |c| blk: {
                const nt = Helpers.nameAndType(classfile, c.nameAndTypeIndex);
                break :blk .{ .interfaceMethodref = .{
                    .class = Helpers.class(classfile, c.classIndex),
                    .name = nt[0],
                    .descriptor = nt[1],
                } };
            },
            .string => |c| .{ .string = .{ .value = Helpers.utf8(classfile, c.stringIndex) } },
            .utf8 => |_| .{ .utf8 = .{ .value = Helpers.utf8(classfile, i) } },
            .integer => |c| .{ .integer = .{ .value = c.value() } },
            .long => |c| .{ .long = .{ .value = c.value() } },
            .float => |c| .{ .float = .{ .value = c.value() } },
            .double => |c| .{ .double = .{ .value = c.value() } },
            .nameAndType => |c| .{ .nameAndType = .{
                .name = Helpers.utf8(classfile, c.nameIndex),
                .descriptor = Helpers.utf8(classfile, c.descriptorIndex),
            } },
            .methodType => |c| .{ .methodType = .{
                .descriptor = Helpers.utf8(classfile, c.descriptorIndex),
            } },
            else => |t| {
                std.debug.panic("Unsupported constant {}", .{t});
            },
        };
    }
    const fields = make(Field, classfile.fields.len, method_area_allocator);
    var staticVarsCount: usize = 0;
    var instanceVarsCount: usize = 0;
    for (0..fields.len) |i| {
        const fieldInfo = classfile.fields[i];
        var field: Field = .{
            .accessFlags = fieldInfo.accessFlags,
            .name = Helpers.utf8(classfile, fieldInfo.nameIndex),
            .descriptor = Helpers.utf8(classfile, fieldInfo.descriptorIndex),
            .index = i,
            .slot = undefined,
        };
        if (field.hasAccessFlag(.STATIC)) {
            field.slot = staticVarsCount;
            staticVarsCount += 1;
        } else {
            field.slot = instanceVarsCount;
            instanceVarsCount += 1;
        }

        fields[i] = field;
    }

    // static variable default values
    const staticVars = make(Value, staticVarsCount, method_area_allocator);
    for (fields) |field| {
        if (field.hasAccessFlag(.STATIC)) {
            staticVars[field.slot] = Type.defaultValue(field.descriptor);
        }
    }

    const methods = make(Method, classfile.methods.len, method_area_allocator);
    for (0..methods.len) |i| {
        const methodInfo = classfile.methods[i];
        var method: Method = .{
            .accessFlags = methodInfo.accessFlags,
            .name = Helpers.utf8(classfile, methodInfo.nameIndex),
            .descriptor = Helpers.utf8(classfile, methodInfo.descriptorIndex),
            .maxStack = undefined,
            .maxLocals = undefined,
            .code = undefined,
            .exceptions = undefined,
            .localVars = undefined,
            .lineNumbers = undefined,
            .parameterDescriptors = undefined,
            .returnDescriptor = undefined,
        };

        for (methodInfo.attributes) |attribute| {
            switch (attribute) {
                .code => |a| {
                    method.maxStack = a.maxStack;
                    method.maxLocals = a.maxLocals;
                    method.code = clone(a.code, method_area_allocator);
                    const exceptions = make(Method.ExceptionHandler, a.exceptionTable.len, method_area_allocator);
                    method.exceptions = exceptions;
                    for (0..exceptions.len) |j| {
                        const exceptionTableEntry = a.exceptionTable[j];
                        exceptions[j] = .{
                            .startPc = exceptionTableEntry.startPc,
                            .endPc = exceptionTableEntry.endPc,
                            .handlePc = exceptionTableEntry.handlerPc,
                            .catchType = exceptionTableEntry.catchType,
                        };
                    }

                    for (a.attributes) |codeAttribute| {
                        switch (codeAttribute) {
                            .localVariableTable => |lvt| {
                                const localVars = make(Method.LocalVariable, lvt.localVariableTable.len, method_area_allocator);
                                method.localVars = localVars;
                                for (0..localVars.len) |k| {
                                    const localVariableTableEntry = lvt.localVariableTable[k];
                                    localVars[k] = .{
                                        .startPc = localVariableTableEntry.startPc,
                                        .length = localVariableTableEntry.length,
                                        .index = localVariableTableEntry.index,
                                        .name = Helpers.utf8(classfile, localVariableTableEntry.nameIndex),
                                        .descriptor = Helpers.utf8(classfile, localVariableTableEntry.descriptorIndex),
                                    };
                                }
                            },
                            .lineNumberTable => |lnt| {
                                const lineNumbers = make(Method.LineNumber, lnt.lineNumberTable.len, method_area_allocator);
                                method.lineNumbers = lineNumbers;
                                for (0..lineNumbers.len) |k| {
                                    const lineNumberTableEntry = lnt.lineNumberTable[k];
                                    lineNumbers[k] = .{
                                        .startPc = lineNumberTableEntry.startPc,
                                        .lineNumber = lineNumberTableEntry.lineNumber,
                                    };
                                }
                            },
                            else => {},
                        }
                    }
                },
                else => unreachable,
            }
        }

        // parse parameters and return descriptors
        var chunks = std.mem.split(u8, method.descriptor, ")");
        const chunk = chunks.first();
        std.debug.assert(chunk.len < method.descriptor.len);
        const params = chunk[1..];
        const ret = chunks.rest();

        var parameterDescriptors = std.ArrayList(string).init(method_area_allocator);

        var p = params;
        while (p.len > 0) {
            const param = firstType(p);
            parameterDescriptors.append(param) catch unreachable;
            p = p[param.len..p.len];
        }
        method.returnDescriptor = ret;
        method.parameterDescriptors = parameterDescriptors.toOwnedSlice() catch unreachable;

        methods[i] = method;
    }

    const interfaces = make(string, classfile.interfaces.len, method_area_allocator);
    for (0..interfaces.len) |i| {
        interfaces[i] = Helpers.utf8(classfile, classfile.interfaces[i]);
    }

    const className = Helpers.class(classfile, classfile.thisClass);
    const descriptor = intern(concat(&[_]string{ "L", className, ";" }));

    const class: Class = .{
        .name = className,
        .descriptor = descriptor,
        .accessFlags = classfile.accessFlags,
        .superClass = if (classfile.superClass == 0) "" else Helpers.class(classfile, classfile.superClass),
        .interfaces = interfaces,
        .constantPool = constantPool,
        .fields = fields,
        .methods = methods,
        // .instanceVarFields = instanceVarFields,
        // .staticVarFields = staticVarFields,
        .instanceVars = instanceVarsCount,
        .staticVars = staticVars,
        .sourceFile = undefined,
        .isArray = false,
        .componentType = undefined,
        .elementType = undefined,
        .dimensions = undefined,
    };

    return class;
}

/// helper functions to lookup constants
/// the caller own the memory in string pool
const Helpers = struct {
    fn utf8(reader: ClassFile, index: usize) string {
        return intern(reader.constantPool[index].utf8.bytes);
    }

    fn class(reader: ClassFile, classIndex: usize) string {
        const c = reader.constantPool[classIndex].class;
        return utf8(reader, c.nameIndex);
    }

    fn nameAndType(reader: ClassFile, nameAndTypeIndex: usize) [2]string {
        const nt = reader.constantPool[nameAndTypeIndex].nameAndType;
        return [_]string{ utf8(reader, nt.nameIndex), utf8(reader, nt.descriptorIndex) };
    }
};

/// derive an array class directly constructing out of the air.
fn deriveArray(name: string) Class {
    const arrayname = intern(name);
    const componentType = arrayname[1..];
    var elementType: string = undefined;
    var dimensions: u32 = undefined;
    var i: u32 = 0;
    while (i < arrayname.len) {
        if (arrayname[i] != '[') {
            elementType = arrayname[i..];
            dimensions = i;
            break;
        }
        i += 1;
    }
    var interfaces = std.ArrayList(string).init(method_area_allocator);
    interfaces.append("java/io/Serializable") catch unreachable;
    interfaces.append("java/lang/Cloneable") catch unreachable;
    const class: Class = .{
        .name = arrayname,
        .descriptor = arrayname,
        .accessFlags = @intFromEnum(AccessFlags.Class.PUBLIC),
        .superClass = "java/lang/Object",
        .interfaces = interfaces.toOwnedSlice() catch unreachable,
        .constantPool = undefined,
        .fields = undefined,
        .methods = undefined,
        .staticVars = undefined,
        .instanceVars = undefined,
        .sourceFile = undefined,
        .isArray = true,
        .componentType = componentType,
        .elementType = elementType,
        .dimensions = dimensions,
    };

    return class;
}

// extract the first type from descriptor
fn firstType(params: string) string {
    if (params.len == 0) return params;
    return switch (params[0]) {
        'B', 'C', 'D', 'F', 'I', 'J', 'S', 'Z' => params[0..1],
        'L' => {
            var chunks = std.mem.split(u8, params, ";");
            const chunk = chunks.first();
            std.debug.assert(chunk.len < params.len);
            return params[0 .. chunk.len + 1];
        },
        '[' => {
            const component = firstType(params[1..params.len]);
            return params[0 .. component.len + 1];
        },
        else => unreachable,
    };
}
