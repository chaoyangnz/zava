const Context = @import("../../native.zig").Context;
const double = @import("../../type.zig").double;

// private static void registers()
pub fn pow(ctx: Context, base: double, exponent: double) double {
    _ = ctx;
    _ = exponent;
    _ = base;
    // return Double(math.Pow(float64(base), float64(exponent)))
    unreachable;
}
