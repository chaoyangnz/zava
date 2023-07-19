const register = @import("../../native.zig").register;

pub fn init() void {
    register("sun/misc/VM.initialize()V", initialize);
}

// private static void registerNatives()
fn initialize() void {}
