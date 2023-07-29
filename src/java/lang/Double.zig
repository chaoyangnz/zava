const double = @import("../../type.zig").double;
const long = @import("../../type.zig").long;

// public static native int floatToRawIntBits(float value)
pub fn doubleToRawLongBits(value: double) long {
    return @bitCast(value);
    // bits := math.Float64bits(float64(value))
    // return Long(int64(bits))
}

// public static native int floatToRawIntBits(float value)
pub fn longBitsToDouble(bits: long) double {
    return @bitCast(bits);
    // value := math.Float64frombits(uint64(bits)) // todo
    // return Double(value)
}
