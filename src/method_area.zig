const std = @import("std");

const string = @import("./vm.zig").string;
const Endian = @import("./vm.zig").Endian;
const size16 = @import("./vm.zig").size16;
const strings = @import("./vm.zig").strings;
const vm_free = @import("./vm.zig").vm_free;

const Class = @import("./type.zig").Class;
const Constant = @import("./type.zig").Constant;
const Field = @import("./type.zig").Field;
const Method = @import("./type.zig").Method;
const AccessFlags = @import("./type.zig").AccessFlags;
const Value = @import("./type.zig").Value;
const Object = @import("./type.zig").Object;
const NULL = @import("./type.zig").NULL;
const JavaLangString = @import("./type.zig").JavaLangString;
const JavaLangClassLorder = @import("./type.zig").JavaLangClassLoader;
const defaultValue = @import("./type.zig").defaultValue;

const ClassFile = @import("./classfile.zig").ClassFile;
const Reader = @import("./classfile.zig").Reader;

const current = @import("./engine.zig").current;

test "deriveClass" {
    std.testing.log_level = .debug;

    var reader = loadClass("java/lang/AbstractStringBuilder");
    defer reader.close();
    const class = deriveClass(reader.read());
    class.debug();
}

test "deriveArray" {
    std.testing.log_level = .debug;

    const array = deriveArray("[[Ljava/lang/String;");
    array.debug();
}

test "resolveClass" {
    std.testing.log_level = .debug;

    const class = resolveClass(null, "Calendar");
    const class1 = resolveClass(null, "Calendar");
    // class.debug();
    try std.testing.expect(class == class1);
    try std.testing.expect(classPool.count() == 1);
    try std.testing.expect(definingClasses.count() == 1);
    try std.testing.expect(definingClasses.get(class).? == null);
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

/// allocate a slice of elements in method area
fn make(comptime T: type, capacity: usize) []T {
    return method_area_allocator.alloc(T, capacity) catch unreachable;
}

/// allocate a single object in method area
fn new(comptime T: type, value: T) *T {
    var ptr = method_area_allocator.create(T) catch unreachable;
    ptr.* = value;
    return ptr;
}

pub const classpath = [_]string{ "examples/classes", "jdk/classes" };

/// string pool
var stringPool = std.StringHashMap(void).init(method_area_allocator);

fn clone(str: []const u8) string {
    const newstr = make(u8, str.len);
    @memcpy(newstr, str);
    return newstr;
}

pub fn intern(str: []const u8) string {
    if (!stringPool.contains(str)) {
        const newstr = clone(str);
        stringPool.put(newstr, void{}) catch unreachable;
    }
    return stringPool.getKey(str).?;
}

/// class pool
const ClassLoader = ?*Object;
const ClassNamespace = std.StringHashMap(*const Class);
/// ClassLoader -> [name]: Class
/// the class pointer is also put into defining classes
var classPool = std.AutoHashMap(ClassLoader, ClassNamespace).init(method_area_allocator);
/// Class -> Classloader
var definingClasses = std.AutoHashMap(*const Class, ClassLoader).init(method_area_allocator);

/// class is the defining class which name symbolic is from.
/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-5.html#jvms-5.4.3.1
/// resolveClass(D, N) C
pub fn resolveClass(definingClass: ?*const Class, name: string) *const Class {
    var classloader: ?*Object = if (definingClass != null) definingClasses.get(definingClass.?) orelse null else null; // fallback to bootstrap classloader

    // TODO parent delegation
    if (!classPool.contains(classloader)) {
        classPool.put(classloader, ClassNamespace.init(method_area_allocator)) catch unreachable;
    }
    var namespace = classPool.getPtr(classloader).?;
    if (!namespace.contains(name)) {
        const class = createClass(classloader, name);
        namespace.put(intern(name), class) catch unreachable;
        definingClasses.put(class, classloader) catch unreachable;
        initialiseClass(class);
    }

    return namespace.get(name).?;
}

pub const ResolvedMethod = struct {
    class: *const Class,
    method: *const Method,
};
pub const ResolvedField = struct {
    class: *const Class,
    field: *const Field,
};

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-5.html#jvms-5.3.3
pub fn resolveMethod(definingClass: *const Class, class: string, name: string, descriptor: string) ResolvedMethod {
    const m = doResolveMethod(definingClass, class, name, descriptor);
    if (m != null) {
        return m.?;
    } else {
        std.log.warn("Failed to resolve method {s}.{s}: {s}", .{ class, name, descriptor });
        unreachable;
    }
}

fn doResolveMethod(definingClass: *const Class, class: string, name: string, descriptor: string) ?ResolvedMethod {
    var c = resolveClass(definingClass, class);
    const m = c.method(name, descriptor, false);
    if (m != null) {
        return .{ .class = c, .method = m.? };
    }
    if (std.mem.eql(u8, c.super_class, "")) {
        return null;
    }
    return doResolveMethod(c, c.super_class, name, descriptor);
}

fn doResolveInterfaceMethod(definingClass: *const Class, class: string, name: string, descriptor: string) ?ResolvedMethod {
    var c = resolveClass(definingClass, class);
    const m = c.method(name, descriptor, false);
    if (m != null) {
        return .{ .class = c, .method = m.? };
    }
    if (std.mem.eql(u8, c.super_class, "")) {
        return null;
    }
    const methodAlongClass = doResolveMethod(c, c.super_class, name, descriptor);
    if (methodAlongClass != null) {
        return methodAlongClass.?;
    }
    for (0..c.interfaces.len) |i| {
        const methodAlongInterface = doResolveInterfaceMethod(c, c.interfaces[i], name, descriptor);
        if (methodAlongInterface != null) {
            return methodAlongInterface.?;
        }
    }

    return null;
}

pub fn resolveInterfaceMethod(definingClass: *const Class, class: string, name: string, descriptor: string) ResolvedMethod {
    const m = doResolveInterfaceMethod(definingClass, class, name, descriptor);
    if (m != null) {
        return m.?;
    } else {
        std.log.warn("Failed to resolve interface method {s}.{s}: {s}", .{ class, name, descriptor });
        unreachable;
    }
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-5.html#jvms-5.3.2
pub fn resolveField(definingClass: *const Class, class: string, name: string, descriptor: string) ResolvedField {
    var c = resolveClass(definingClass, class);
    while (true) {
        const f = c.field(name, descriptor, false);
        if (f != null) {
            return .{ .class = c, .field = f.? };
        }
        if (std.mem.eql(u8, c.super_class, "")) {
            break;
        }
        c = resolveClass(definingClass, c.super_class);
    }
    unreachable;
}

pub fn resolveStaticField(class: *const Class, name: string, descriptor: string) ResolvedField {
    var c = class;
    while (true) {
        const f = c.field(name, descriptor, true);
        if (f != null) {
            return .{ .class = c, .field = f.? };
        }
        if (std.mem.eql(u8, c.super_class, "")) {
            break;
        }
        c = resolveClass(class, c.super_class);
    }
    unreachable;
}

/// create a class or array class
/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-5.html#jvms-5.3
/// creation + loading
fn createClass(classloader: ClassLoader, name: string) *const Class {
    if (name[0] != '[') {
        var reader = if (classloader == null) loadClass(name) else loadClassUd(classloader, name);
        defer reader.close();
        std.log.info("{s}  🔺{s}", .{ current().indent(), name });
        return new(Class, deriveClass(reader.read()));
    } else {
        return new(Class, deriveArray(name));
    }
}

/// class loaders
/// bootstrap class loader loads a class from class path.
fn loadClass(name: string) Reader {
    for (classpath) |path| {
        const fileName = strings.concat(&[_]string{ name, ".class" });
        const dir = std.fs.cwd().openDir(path, .{}) catch continue;
        const file = dir.openFile(fileName, .{}) catch continue;
        defer file.close();
        return Reader.open(file.reader());
    }
    std.log.warn("Class not found: {s}", .{name});
    unreachable;
}

/// user defined class loader loads a class from class path, network or somewhere else
fn loadClassUd(classloader: ClassLoader, name: string) Reader {
    _ = name;
    _ = classloader;
    std.debug.panic("User defined classloader is not implemented", .{});
}

fn initialiseClass(class: *const Class) void {
    if (!class.is_array) {
        const clinit = class.method("<clinit>", "()V", true);
        if (clinit == null) return;
        current().invoke(class, clinit.?, &[_]Value{});
    }
}

// derive a class representation in vm from class file
// all the slices in Class will be in method area
// once the whole class is put into class pool (backed by method area), then the deep Class memory is in method area.
fn deriveClass(classfile: ClassFile) Class {
    var constantPool = make(Constant, classfile.constantPool.len);
    for (1..constantPool.len) |i| {
        const constantInfo = classfile.constantPool[i];
        constantPool[i] = switch (constantInfo) {
            .class => |c| .{ .classref = .{ .class = ClassfileHelpers.utf8(classfile, c.nameIndex) } },
            .fieldref => |c| blk: {
                const nt = ClassfileHelpers.nameAndType(classfile, c.nameAndTypeIndex);
                break :blk .{ .fieldref = .{
                    .class = ClassfileHelpers.class(classfile, c.classIndex),
                    .name = nt[0],
                    .descriptor = nt[1],
                } };
            },
            .methodref => |c| blk: {
                const nt = ClassfileHelpers.nameAndType(classfile, c.nameAndTypeIndex);
                break :blk .{ .methodref = .{
                    .class = ClassfileHelpers.class(classfile, c.classIndex),
                    .name = nt[0],
                    .descriptor = nt[1],
                } };
            },
            .interfaceMethodref => |c| blk: {
                const nt = ClassfileHelpers.nameAndType(classfile, c.nameAndTypeIndex);
                break :blk .{ .interfaceMethodref = .{
                    .class = ClassfileHelpers.class(classfile, c.classIndex),
                    .name = nt[0],
                    .descriptor = nt[1],
                } };
            },
            .string => |c| .{ .string = .{ .value = ClassfileHelpers.utf8(classfile, c.stringIndex) } },
            .utf8 => |_| .{ .utf8 = .{ .value = ClassfileHelpers.utf8(classfile, i) } },
            .integer => |c| .{ .integer = .{ .value = c.value() } },
            .long => |c| .{ .long = .{ .value = c.value() } },
            .float => |c| .{ .float = .{ .value = c.value() } },
            .double => |c| .{ .double = .{ .value = c.value() } },
            .nameAndType => |c| .{ .nameAndType = .{
                .name = ClassfileHelpers.utf8(classfile, c.nameIndex),
                .descriptor = ClassfileHelpers.utf8(classfile, c.descriptorIndex),
            } },
            .methodType => |c| .{ .methodType = .{
                .descriptor = ClassfileHelpers.utf8(classfile, c.descriptorIndex),
            } },
            .invokeDynamic => |c| blk: {
                const nt = ClassfileHelpers.nameAndType(classfile, c.nameAndTypeIndex);
                break :blk .{
                    .invokeDynamic = .{
                        // .bootstrapMethod = ClassfileHelpers.utf8(classfile, c.bootstrapMethodAttrIndex),
                        // TODO
                        .bootstrap_method = "",
                        .name = nt[0],
                        .descriptor = nt[1],
                    },
                };
            },
            .methodHandle => |c| .{ .methodHandle = .{
                .reference_kind = c.referenceKind,
                .reference_index = c.referenceIndex,
            } },
            // else => |t| {
            //     std.debug.panic("Unsupported constant {}", .{t});
            // },
        };
    }
    const fields = make(Field, classfile.fields.len);
    var staticVarsCount: u16 = 0;
    var instanceVarsCount: u16 = 0;
    for (0..fields.len) |i| {
        const fieldInfo = classfile.fields[i];
        var field: Field = .{ // fieldInfo.accessFlags
            .access_flags = .{
                .raw = fieldInfo.accessFlags,
                .public = fieldInfo.accessFlags & 0x0001 > 0,
                .private = fieldInfo.accessFlags & 0x0002 > 0,
                .protected = fieldInfo.accessFlags & 0x0004 > 0,
                .static = fieldInfo.accessFlags & 0x0008 > 0,
                .final = fieldInfo.accessFlags & 0x0010 > 0,
                .@"volatile" = fieldInfo.accessFlags & 0x0040 > 0,
                .transient = fieldInfo.accessFlags & 0x0080 > 0,
                .synthetic = fieldInfo.accessFlags & 0x1000 > 0,
                .@"enum" = fieldInfo.accessFlags & 0x4000 > 0,
            },
            .name = ClassfileHelpers.utf8(classfile, fieldInfo.nameIndex),
            .descriptor = ClassfileHelpers.utf8(classfile, fieldInfo.descriptorIndex),
            .index = size16(i),
            .slot = undefined,
        };
        if (field.access_flags.static) {
            field.slot = staticVarsCount;
            staticVarsCount += 1;
        } else {
            field.slot = instanceVarsCount;
            instanceVarsCount += 1;
        }

        fields[i] = field;
    }

    // https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-5.html#jvms-5.4.2
    // static variable default values
    const staticVars = make(Value, staticVarsCount);
    for (fields) |field| {
        if (field.access_flags.static) {
            staticVars[field.slot] = defaultValue(field.descriptor);
        }
    }

    const methods = make(Method, classfile.methods.len);
    for (0..methods.len) |i| {
        const methodInfo = classfile.methods[i];
        var method: Method = .{
            .access_flags = .{
                .raw = methodInfo.accessFlags,
                .public = methodInfo.accessFlags & 0x0001 > 0,
                .private = methodInfo.accessFlags & 0x0002 > 0,
                .protected = methodInfo.accessFlags & 0x0004 > 0,
                .static = methodInfo.accessFlags & 0x0008 > 0,
                .final = methodInfo.accessFlags & 0x0010 > 0,
                .synchronized = methodInfo.accessFlags & 0x0020 > 0,
                .bridge = methodInfo.accessFlags & 0x0040 > 0,
                .varargs = methodInfo.accessFlags & 0x0080 > 0,
                .native = methodInfo.accessFlags & 0x0100 > 0,
                .abstract = methodInfo.accessFlags & 0x0400 > 0,
                .strict = methodInfo.accessFlags & 0x0800 > 0,
                .synthetic = methodInfo.accessFlags & 0x1000 > 0,
            },
            .name = ClassfileHelpers.utf8(classfile, methodInfo.nameIndex),
            .descriptor = ClassfileHelpers.utf8(classfile, methodInfo.descriptorIndex),
            .max_stack = undefined,
            .max_locals = undefined,
            .code = undefined,
            .exceptions = undefined,
            .local_vars = undefined,
            .line_numbers = undefined,
            .parameter_descriptors = undefined,
            .return_descriptor = undefined,
        };

        for (methodInfo.attributes) |attribute| {
            switch (attribute) {
                .code => |a| {
                    method.max_stack = a.maxStack;
                    method.max_locals = a.maxLocals;
                    method.code = clone(a.code);
                    const exceptions = make(Method.ExceptionHandler, a.exceptionTable.len);
                    method.exceptions = exceptions;
                    for (0..exceptions.len) |j| {
                        const exceptionTableEntry = a.exceptionTable[j];
                        exceptions[j] = .{
                            .start_pc = exceptionTableEntry.startPc,
                            .end_pc = exceptionTableEntry.endPc,
                            .handle_pc = exceptionTableEntry.handlerPc,
                            .catch_type = exceptionTableEntry.catchType,
                        };
                    }

                    for (a.attributes) |codeAttribute| {
                        switch (codeAttribute) {
                            .localVariableTable => |lvt| {
                                const localVars = make(Method.LocalVariable, lvt.localVariableTable.len);
                                method.local_vars = localVars;
                                for (0..localVars.len) |k| {
                                    const localVariableTableEntry = lvt.localVariableTable[k];
                                    localVars[k] = .{
                                        .start_pc = localVariableTableEntry.startPc,
                                        .length = localVariableTableEntry.length,
                                        .index = localVariableTableEntry.index,
                                        .name = ClassfileHelpers.utf8(classfile, localVariableTableEntry.nameIndex),
                                        .descriptor = ClassfileHelpers.utf8(classfile, localVariableTableEntry.descriptorIndex),
                                    };
                                }
                            },
                            .lineNumberTable => |lnt| {
                                const lineNumbers = make(Method.LineNumber, lnt.lineNumberTable.len);
                                method.line_numbers = lineNumbers;
                                for (0..lineNumbers.len) |k| {
                                    const lineNumberTableEntry = lnt.lineNumberTable[k];
                                    lineNumbers[k] = .{
                                        .start_pc = lineNumberTableEntry.startPc,
                                        .line_number = lineNumberTableEntry.lineNumber,
                                    };
                                }
                            },
                            else => {},
                        }
                    }
                },
                else => {
                    // std.log.debug("Ignore method attribute", .{});
                },
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
        method.return_descriptor = ret;
        method.parameter_descriptors = parameterDescriptors.toOwnedSlice() catch unreachable;

        methods[i] = method;
    }

    const interfaces = make(string, classfile.interfaces.len);
    for (0..interfaces.len) |i| {
        interfaces[i] = ClassfileHelpers.class(classfile, classfile.interfaces[i]);
    }

    const className = ClassfileHelpers.class(classfile, classfile.thisClass);
    const desc = strings.concat(&[_]string{ "L", className, ";" });
    defer vm_free(desc);
    const descriptor = intern(desc);

    const class: Class = .{
        .name = className,
        .descriptor = descriptor,
        .access_flags = .{
            .raw = classfile.accessFlags,
            .public = classfile.accessFlags & 0x0001 > 0,
            .final = classfile.accessFlags & 0x0010 > 0,
            .super = classfile.accessFlags & 0x0020 > 0,
            .interface = classfile.accessFlags & 0x0200 > 0,
            .abstract = classfile.accessFlags & 0x0400 > 0,
            .synthetic = classfile.accessFlags & 0x1000 > 0,
            .annotation = classfile.accessFlags & 0x2000 > 0,
            .@"enum" = classfile.accessFlags & 0x4000 > 0,
        },
        .super_class = if (classfile.superClass == 0) "" else ClassfileHelpers.class(classfile, classfile.superClass),
        .interfaces = interfaces,
        .constants = constantPool,
        .fields = fields,
        .methods = methods,
        // .instanceVarFields = instanceVarFields,
        // .staticVarFields = staticVarFields,
        .instance_vars = instanceVarsCount,
        .static_vars = staticVars,
        .source_file = undefined,
        .is_array = false,
        .component_type = undefined,
        .element_type = undefined,
        .dimensions = undefined,
    };

    return class;
}

/// helper functions to lookup constants
/// the caller own the memory in string pool
const ClassfileHelpers = struct {
    fn utf8(classfile: ClassFile, index: usize) string {
        return intern(classfile.constantPool[index].utf8.bytes);
    }

    fn class(classfile: ClassFile, classIndex: usize) string {
        const c = classfile.constantPool[classIndex].class;
        return utf8(classfile, c.nameIndex);
    }

    fn nameAndType(classfile: ClassFile, nameAndTypeIndex: usize) [2]string {
        const nt = classfile.constantPool[nameAndTypeIndex].nameAndType;
        return [_]string{ utf8(classfile, nt.nameIndex), utf8(classfile, nt.descriptorIndex) };
    }
};

/// derive an array class directly constructing out of the air.
fn deriveArray(name: string) Class {
    const array_name = intern(name);
    const component_type = array_name[1..];
    var element_type: string = undefined;
    var dimensions: u32 = undefined;
    var i: u32 = 0;
    while (i < array_name.len) {
        if (array_name[i] != '[') {
            element_type = array_name[i..];
            dimensions = i;
            break;
        }
        i += 1;
    }
    var interfaces = std.ArrayList(string).init(method_area_allocator);
    interfaces.append("java/io/Serializable") catch unreachable;
    interfaces.append("java/lang/Cloneable") catch unreachable;
    const fields = method_area_allocator.alloc(Field, 0) catch unreachable;
    const methods = method_area_allocator.alloc(Method, 0) catch unreachable;
    const staticVars = method_area_allocator.alloc(Value, 0) catch unreachable;
    const class: Class = .{
        .name = array_name,
        .descriptor = array_name,
        .access_flags = .{
            .raw = 0x0001,
            .public = true,
            .final = false,
            .super = false,
            .interface = false,
            .abstract = false,
            .synthetic = false,
            .annotation = false,
            .@"enum" = false,
        },
        .super_class = "java/lang/Object",
        .interfaces = interfaces.toOwnedSlice() catch unreachable,
        .constants = undefined,
        .fields = fields,
        .methods = methods,
        .static_vars = staticVars,
        .instance_vars = 0,
        .source_file = undefined,
        .is_array = true,
        .component_type = component_type,
        .element_type = element_type,
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

/// check if `class` is a subclass of `this`
pub fn assignableFrom(class: *const Class, subclass: *const Class) bool {
    if (class == subclass) return true;

    if (class.access_flags.interface) {
        var c = subclass;
        if (c == class) return true;
        for (c.interfaces) |interface| {
            if (assignableFrom(class, resolveClass(c, interface))) {
                return true;
            }
        }
        if (std.mem.eql(u8, c.super_class, "")) {
            return false;
        }
        return assignableFrom(class, resolveClass(c, c.super_class));
    } else if (class.is_array) {
        if (subclass.is_array) {
            // covariant
            return assignableFrom(resolveClass(class, class.component_type), resolveClass(subclass, subclass.component_type));
        }
    } else {
        var c = subclass;
        if (c == class) {
            return true;
        }
        if (std.mem.eql(u8, c.super_class, "")) {
            return false;
        }

        return assignableFrom(class, resolveClass(c, c.super_class));
    }

    return false;
}
