const register = @import("../../../native.zig").register;

pub fn init() void {
    register("java/util/zip/ZipFile.initIDs()V", initIDs);
}

fn initIDs() void {
    // //DO NOTHING
}
