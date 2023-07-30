const Context = @import("../../native.zig").Context;
const Reference = @import("../../type.zig").Reference;
const int = @import("../../type.zig").int;

pub fn availableProcessors(ctx: Context, this: Reference) int {
    _ = ctx;
    _ = this;
    // return Int(runtime.NumCPU())
    unreachable;
}
