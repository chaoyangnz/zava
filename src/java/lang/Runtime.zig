const register = @import("../../native.zig").register;
const Reference = @import("../../value.zig").Reference;
const int = @import("../../value.zig").int;

pub fn init() void {
    register("java/lang/Runtime.availableProcessors()I", availableProcessors);
}

fn availableProcessors(this: Reference) int {
    _ = this;
    // return Int(runtime.NumCPU())
}
