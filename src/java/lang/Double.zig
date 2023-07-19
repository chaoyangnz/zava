const register = @import("../../native.zig").register;
const double = @import("../../value.zig").double;
const long = @import("../../value.zig").long;

pub fn init() void {
    register("java/lang/Double.doubleToRawLongBits(D)J", doubleToRawLongBits);
    register("java/lang/Double.longBitsToDouble(J)D", longBitsToDouble);
}

// public static native int floatToRawIntBits(float value)
fn doubleToRawLongBits(value: double) long {
    _ = value;
    // bits := math.Float64bits(float64(value))
    // return Long(int64(bits))
}

// public static native int floatToRawIntBits(float value)
fn longBitsToDouble(bits: long) double {
    _ = bits;
    // value := math.Float64frombits(uint64(bits)) // todo
    // return Double(value)
}
