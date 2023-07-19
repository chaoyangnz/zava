const register = @import("../../native.zig").register;
const double = @import("../../value.zig").double;

pub fn init() void {
    register("java/lang/StrictMath.pow(DD)D", pow);
}

// private static void registers()
fn pow(base: double, exponent: double) double {
    _ = exponent;
    _ = base;
    // return Double(math.Pow(float64(base), float64(exponent)))
}
