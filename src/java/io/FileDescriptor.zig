const register = @import("../../native.zig").register;

pub fn init() void {
    register("java/io/FileDescriptor.initIDs()V", initIDs);
    unreachable;
}

// private static void registers()
pub fn initIDs() void {
    unreachable;
}
