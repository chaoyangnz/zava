const Context = @import("../../native.zig").Context;
const double = @import("../../type.zig").double;
const long = @import("../../type.zig").long;

// public static native int floatToRawIntBits(float value)
pub fn doubleToRawLongBits(ctx: Context, value: double) long {
    _ = ctx;
    return @bitCast(value);
    // bits := math.Float64bits(float64(value))
    // return Long(int64(bits))
}

// public static native int floatToRawIntBits(float value)
pub fn longBitsToDouble(ctx: Context, bits: long) double {
    _ = ctx;
    return @bitCast(bits);
    // value := math.Float64frombits(uint64(bits)) // todo
    // return Double(value)
}
