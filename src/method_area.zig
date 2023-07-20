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
const buffer = @import("./shared.zig").buffer;

pub const stringPool = std.StringHashMap(JavaLangString).init(method_area_allocator);

const NL = struct {
    N: string,
    L: *Object, // class loader
};

pub const methodArea = std.AutoHashMap(NL, *Class).init(method_area_allocator);

// derive a class representation in vm from bytecode
pub fn deriveClass(N: string, L: JavaLangClassLorder, bytecode: []const u8) *Class {
    _ = N;
    _ = L;
    const classfile = ClassFile.read(bytecode);
    const constantPool = make(Constant, classfile.constantPool.len, method_area_allocator);
    for (1..constantPool.len) |i| {
        const constantInfo = classfile.constantPool[i];
        constantPool[i] = switch (constantInfo) {
            .class => |c| .{ .name = clone(classfile.utf8(c.nameIndex), method_area_allocator) },
            .fieldref, .methodref, .interfaceMethodRef => |c| {
                const nt = classfile.nameAndType(c.nameAndTypeIndex);
                return .{
                    .class = clone(classfile.utf8(c.classIndex)),
                    .name = clone(nt[0], method_area_allocator),
                    .descriptor = clone(nt[1], method_area_allocator),
                };
            },
            .string => |c| .{ .value = clone(classfile.utf8(c.stringIndex)) },
            .utf8 => |c| .{ .value = clone(c.bytes) },
            .integer => |c| .{ .integer = c.value() },
            .long => |c| .{ .long = c.value() },
            .float => |c| .{ .float = c.value() },
            .double => |c| .{ .double = c.value() },
            .nameAndType => |c| .{ .nameAndType = .{
                .name = clone(classfile.utf8(c.nameIndex)),
                .descriptor = clone(classfile.utf8(c.descriptorIndex)),
            } },
            .methodType => |c| .{ .methodType = .{
                .descriptor = clone(classfile.utf8(c.descriptorIndex)),
            } },
            else => unreachable,
        };
    }
    const fields = make(Field, classfile.fields.len, method_area_allocator);
    for (0..fields.len) |i| {
        const fieldInfo = classfile.fields[i];
        fields[i] = .{
            .accessFlag = fieldInfo.accessFlags,
            .name = clone(classfile.utf8(fieldInfo.nameIndex)),
            .descriptor = clone(classfile.utf8(fieldInfo.descriptorIndex)),
            .index = i,
        };
    }

    // derieve instance and static variable fields
    const instaceVarFieldList = std.ArrayList(Field).init(method_area_allocator);
    const staticVarFieldList = std.ArrayList(Field).init(method_area_allocator);
    for (fields) |field| {
        if (field.hasAccessFlag(.STATIC)) {
            staticVarFieldList.append(field);
        } else {
            instaceVarFieldList.append(field);
        }
    }
    const instanceVarFields = instaceVarFieldList.toOwnedSlice();
    const staticVarFields = staticVarFieldList.toOwnedSlice();
    // static variable default values
    const staticVars = make(Value, staticVarFields.len);
    for (0..staticVarFields.len) |i| {
        staticVars[i] = defaultValue(staticVarFields[i].descriptor);
    }

    const methods = make(Method, classfile.methods.len, method_area_allocator);
    for (0..methods.len) |i| {
        const methodInfo = classfile.methods[i];
        var method: Method = .{
            .accessFlag = methodInfo.accessFlags,
            .name = clone(classfile.utf8(methodInfo.nameIndex)),
            .descriptor = clone(classfile.utf8(methodInfo.descriptorIndex)),
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
                            else => unreachable,
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

        const parameterDescriptors = std.ArrayList(string).init(method_area_allocator);

        var p = params;
        while (p.len > 0) {
            const param = firstType(p);
            parameterDescriptors.append(param);
            p = p[param.len..p.len];
        }
        method.returnDescriptor = clone(ret, method_area_allocator);
        method.parameterDescriptors = parameterDescriptors.toOwnedSlice();
    }

    const interfaces = make(string, classfile.interfaces.length, method_area_allocator);
    for (0..interfaces.len) |i| {
        interfaces[i] = constantPool[interfaces[i]].as(.utf8).value;
    }

    const isArray = std.mem.startsWith(u8, classfile.name, "[");
    const componentType: string = undefined;
    const elementType: string = undefined;
    const dimension: u32 = undefined;
    if (isArray) {
        componentType = clone(classfile.name[1..classfile.name.len]);
        var i = 0;
        while (i < classfile.name.len) {
            if (classfile.name[i] != '[') {
                elementType = clone(classfile.name[i..classfile.name.len], method_area_allocator);
                dimension = i;
                break;
            }
        }
    }

    const class: Class = .{
        .name = clone(classfile.name, method_area_allocator),
        .accessFlags = classfile.accessFlag,
        .superClass = if (classfile.superClass == 0) "" else constantPool[classfile.superClass].as(.utf8).value,
        .interfaces = interfaces,
        .constantPool = constantPool,
        .fields = fields,
        .methods = methods,
        .instaceVarFields = instanceVarFields,
        .staticVarFields = staticVarFields,
        .staticVars = staticVars,
        .isArray = isArray,
        .componentType = componentType,
        .elementType = elementType,
        .dimension = dimension,
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
        'Z' => .{ .boolean = false },
        'L', '[' => .{ .ref = NULL },
    };
}
