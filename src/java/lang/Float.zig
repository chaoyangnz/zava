const float = @import("../../type.zig").float;
const int = @import("../../type.zig").int;

// public static native int floatToRawIntBits(float value)
pub fn floatToRawIntBits(value: float) int {
    return @bitCast(value);
    // bits := math.Float32bits(float32(value))
    // return Int(int32(bits))
}

pub fn intBitsToFloat(bits: int) float {
    return @bitCast(bits);
    // value := math.Float32frombits(uint32(bits))
    // return Float(value)
}
