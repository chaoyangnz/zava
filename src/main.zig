const std = @import("std");
const ClassFile = @import("./classfile.zig").ClassFile;
const deriveClass = @import("./method_area.zig").deriveClass;

const hellworld = @embedFile("./HelloWorld.class");
const calendar = @embedFile("./Calendar.class");

pub fn main() !void {
    const classfile = ClassFile.read(calendar);
    _ = classfile;

    const class = deriveClass(calendar);
    _ = class;
}
