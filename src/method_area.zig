const std = @import("std");
const string = @import("./shared.zig").string;
const Class = @import("./type.zig").Class;
const Constant = @import("./type.zig").Constant;
const Field = @import("./type.zig").Field;
const Method = @import("./type.zig").Method;
const Value = @import("./value.zig").Value;
const Object = @import("./value.zig").Object;
const NULL = @import("./value.zig").NULL;
const JavaLangString = @import("./value.zig").JavaLangString;
const JavaLangClassLorder = @import("./value.zig").JavaLangClassLoader;
const ClassFile = @import("./classfile.zig").ClassFile;
const Endian = @import("./shared.zig").Endian;
const method_area_allocator = @import("./heap.zig").method_area_allocator;
const make = @import("./heap.zig").make;
const clone = @import("./heap.zig").clone;

pub const stringPool = std.StringHashMap(JavaLangString).init(method_area_allocator);

const NL = struct {
    N: string,
    L: *Object, // class loader
};

pub const methodArea = std.AutoHashMap(NL, *Class).init(method_area_allocator);

// derive a class representation in vm from bytecode
pub fn deriveClass( //N: string, L: JavaLangClassLorder,
    bytecode: []const u8,
) Class {
    // _ = N;
    // _ = L;
    const classfile = ClassFile.read(bytecode);
    var constantPool = make(Constant, classfile.constantPool.len, method_area_allocator);
    for (1..constantPool.len) |i| {
        const constantInfo = classfile.constantPool[i];
        constantPool[i] = switch (constantInfo) {
            .class => |c| .{ .classref = .{ .class = clone(classfile.utf8(c.nameIndex), method_area_allocator) } },
            .fieldref => |c| blk: {
                const nt = classfile.nameAndType(c.nameAndTypeIndex);
                break :blk .{ .fieldref = .{
                    .class = clone(classfile.class(c.classIndex), method_area_allocator),
                    .name = clone(nt[0], method_area_allocator),
                    .descriptor = clone(nt[1], method_area_allocator),
                } };
            },
            .methodref => |c| blk: {
                const nt = classfile.nameAndType(c.nameAndTypeIndex);
                break :blk .{ .methodref = .{
                    .class = clone(classfile.class(c.classIndex), method_area_allocator),
                    .name = clone(nt[0], method_area_allocator),
                    .descriptor = clone(nt[1], method_area_allocator),
                } };
            },
            .interfaceMethodref => |c| blk: {
                const nt = classfile.nameAndType(c.nameAndTypeIndex);
                break :blk .{ .interfaceMethodref = .{
                    .class = clone(classfile.class(c.classIndex), method_area_allocator),
                    .name = clone(nt[0], method_area_allocator),
                    .descriptor = clone(nt[1], method_area_allocator),
                } };
            },
            .string => |c| .{ .string = .{ .value = clone(classfile.utf8(c.stringIndex), method_area_allocator) } },
            .utf8 => |c| .{ .utf8 = .{ .value = clone(c.bytes, method_area_allocator) } },
            .integer => |c| .{ .integer = .{ .value = c.value() } },
            .long => |c| .{ .long = .{ .value = c.value() } },
            .float => |c| .{ .float = .{ .value = c.value() } },
            .double => |c| .{ .double = .{ .value = c.value() } },
            .nameAndType => |c| .{ .nameAndType = .{
                .name = clone(classfile.utf8(c.nameIndex), method_area_allocator),
                .descriptor = clone(classfile.utf8(c.descriptorIndex), method_area_allocator),
            } },
            .methodType => |c| .{ .methodType = .{
                .descriptor = clone(classfile.utf8(c.descriptorIndex), method_area_allocator),
            } },
            else => unreachable,
        };
    }
    const fields = make(Field, classfile.fields.len, method_area_allocator);
    for (0..fields.len) |i| {
        const fieldInfo = classfile.fields[i];
        fields[i] = .{
            .accessFlags = fieldInfo.accessFlags,
            .name = clone(classfile.utf8(fieldInfo.nameIndex), method_area_allocator),
            .descriptor = clone(classfile.utf8(fieldInfo.descriptorIndex), method_area_allocator),
            .index = i,
        };
    }

    // derieve instance and static variable fields
    var instaceVarFieldList = std.ArrayList(Field).init(method_area_allocator);
    var staticVarFieldList = std.ArrayList(Field).init(method_area_allocator);
    for (fields) |field| {
        if (field.hasAccessFlag(.STATIC)) {
            staticVarFieldList.append(field) catch unreachable;
        } else {
            instaceVarFieldList.append(field) catch unreachable;
        }
    }
    const instanceVarFields = instaceVarFieldList.toOwnedSlice() catch unreachable;
    const staticVarFields = staticVarFieldList.toOwnedSlice() catch unreachable;
    // static variable default values
    const staticVars = make(Value, staticVarFields.len, method_area_allocator);
    for (0..staticVarFields.len) |i| {
        staticVars[i] = defaultValue(staticVarFields[i].descriptor);
    }

    const methods = make(Method, classfile.methods.len, method_area_allocator);
    for (0..methods.len) |i| {
        const methodInfo = classfile.methods[i];
        var method: Method = .{
            .accessFlags = methodInfo.accessFlags,
            .name = clone(classfile.utf8(methodInfo.nameIndex), method_area_allocator),
            .descriptor = clone(classfile.utf8(methodInfo.descriptorIndex), method_area_allocator),
            .maxStack = undefined,
            .maxLocals = undefined,
            .code = undefined,
            .exceptions = undefined,
            .localVars = undefined,
            .lineNumbers = undefined,
            .parameterDescriptors = undefined,
            .returnDescriptor = undefined,
        };
        methods[i] = method;

        for (methodInfo.attributes) |attribute| {
            switch (attribute) {
                .code => |a| {
                    method.maxStack = a.maxStack;
                    method.maxLocals = a.maxLocals;
                    method.code = a.code;
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
                                        .name = classfile.utf8(localVariableTableEntry.nameIndex),
                                        .descriptor = classfile.utf8(localVariableTableEntry.descriptorIndex),
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
        const params = method.descriptor[1..chunk.len];
        const ret = chunks.rest();

        var parameterDescriptors = std.ArrayList(string).init(method_area_allocator);

        var p = params;
        while (p.len > 0) {
            const param = firstType(p);
            parameterDescriptors.append(param) catch unreachable;
            p = p[param.len..p.len];
        }
        method.returnDescriptor = clone(ret, method_area_allocator);
        method.parameterDescriptors = parameterDescriptors.toOwnedSlice() catch unreachable;
    }

    const interfaces = make(string, classfile.interfaces.len, method_area_allocator);
    for (0..interfaces.len) |i| {
        interfaces[i] = clone(classfile.utf8(classfile.interfaces[i]), method_area_allocator);
    }

    const className = clone(classfile.class(classfile.thisClass), method_area_allocator);
    const isArray = std.mem.startsWith(u8, className, "[");
    var componentType: string = undefined;
    var elementType: string = undefined;
    var dimension: u32 = undefined;
    if (isArray) {
        componentType = clone(className[1..className.len], method_area_allocator);
        var i: u32 = 0;
        while (i < className.len) {
            if (className[i] != '[') {
                elementType = clone(className[i..className.len], method_area_allocator);
                dimension = i;
                break;
            }
        }
    }

    const class: Class = .{
        .name = className,
        .accessFlags = classfile.accessFlags,
        .superClass = if (classfile.superClass == 0) "" else classfile.class(classfile.superClass),
        .interfaces = interfaces,
        .constantPool = constantPool,
        .fields = fields,
        .methods = methods,
        .instanceVarFields = instanceVarFields,
        .staticVarFields = staticVarFields,
        .staticVars = staticVars,
        .isArray = isArray,
        .componentType = componentType,
        .elementType = elementType,
        .dimensions = dimension,
        .sourceFile = undefined,
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
fn defaultValue(descriptor: string) Value {
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
