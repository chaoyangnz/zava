const std = @import("std");
const classfile = @import("./classfile.zig");

const hellworld = @embedFile("./HelloWorld.class");
const calendar = @embedFile("./Calendar.class");

pub fn main() !void {
    const class = classfile.ClassFile.read(calendar);
    _ = class;
}
