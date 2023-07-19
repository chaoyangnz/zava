const Reference = @import("../../value.zig").Reference;
const int = @import("../../value.zig").int;

pub fn availableProcessors(this: Reference) int {
    _ = this;
    // return Int(runtime.NumCPU())
    unreachable;
}
