const float = @import("../../type.zig").float;
const int = @import("../../type.zig").int;

// public static native int floatToRawIntBits(float value)
pub fn floatToRawIntBits(value: float) int {
    _ = value;
    // bits := math.Float32bits(float32(value))
    // return Int(int32(bits))
    unreachable;
}

pub fn intBitsToFloat(bits: int) float {
    _ = bits;
    // value := math.Float32frombits(uint32(bits))
    // return Float(value)
    unreachable;
}
