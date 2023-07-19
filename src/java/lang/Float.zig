const register = @import("../../native.zig").register;
const float = @import("../../value.zig").float;
const int = @import("../../value.zig").int;

pub fn init() void {
    register("java/lang/Float.floatToRawIntBits(F)I", floatToRawIntBits);
    register("java/lang/Float.intBitsToFloat(I)F", intBitsToFloat);
}

// public static native int floatToRawIntBits(float value)
fn floatToRawIntBits(value: float) int {
    _ = value;
    // bits := math.Float32bits(float32(value))
    // return Int(int32(bits))
}

fn intBitsToFloat(bits: int) float {
    _ = bits;
    // value := math.Float32frombits(uint32(bits))
    // return Float(value)
}
