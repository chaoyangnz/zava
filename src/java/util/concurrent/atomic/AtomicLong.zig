const register = @import("../../../../native.zig").register;
const boolean = @import("../../value.zig").boolean;

pub fn init() void {
    register("java/util/concurrent/atomic/AtomicLong.VMSupportsCS8()Z", VMSupportsCS8);
}

fn VMSupportsCS8() boolean {
    // return TRUE
}
