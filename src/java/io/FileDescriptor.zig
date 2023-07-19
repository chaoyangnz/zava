const register = @import("../../native.zig").register;

pub fn init() void {
    register("java/io/FileDescriptor.initIDs()V", initIDs);
}

// private static void registers()
fn initIDs() void {}
