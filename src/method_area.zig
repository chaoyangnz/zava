const std = @import("std");
const string = @import("./shared.zig").string;
const Class = @import("./type.zig").Class;
const Constant = @import("./type.zig").Constant;
const Field = @import("./type.zig").Field;
const Method = @import("./type.zig").Method;
const Object = @import("./value.zig").Object;
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
pub fn deriveClass(N: string, L: JavaLangClassLorder, bytecode: []const u8) *Class {
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

    const methods = make(Method, classfile.methods.len, method_area_allocator);
    for (0..fields.len) |i| {
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
                    //TODO
                },
                else => unreachable,
            }
        }
    }
}
