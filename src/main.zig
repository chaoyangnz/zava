const std = @import("std");
const ClassFile = @import("./classfile.zig").ClassFile;
const Reader = @import("./classfile.zig").Reader;
const lookupClass = @import("./method_area.zig").lookupClass;
const NULL = @import("./value.zig").NULL;

const hellworld = @embedFile("./HelloWorld.class");
const calendar = @embedFile("./Calendar.class");

pub fn main() !void {
    var reader = Reader.withBytes(calendar);
    defer reader.close();
    const classfile = reader.read();
    classfile.debug();

    const class = lookupClass(NULL, "Calendar");
    class.debug();

    const array = lookupClass(NULL, "[[Ljava/lang/String;");
    array.debug();
}
