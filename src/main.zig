const std = @import("std");
const ClassFile = @import("./classfile.zig").ClassFile;
const createClass = @import("./method_area.zig").createClass;
const NULL = @import("./value.zig").NULL;

const hellworld = @embedFile("./HelloWorld.class");
const calendar = @embedFile("./Calendar.class");

pub fn main() !void {
    const classfile = ClassFile.read(calendar);
    _ = classfile;

    const class = createClass(NULL, "Calendar");
    _ = class;

    const array = createClass(NULL, "[[Ljava/lang/String;");
    _ = array;
}
