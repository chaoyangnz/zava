const Reference = @import("../../type.zig").Reference;
const int = @import("../../type.zig").int;

pub fn availableProcessors(this: Reference) int {
    _ = this;
    // return Int(runtime.NumCPU())
    unreachable;
}
