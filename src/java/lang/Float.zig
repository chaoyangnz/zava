const Context = @import("../../native.zig").Context;
const float = @import("../../type.zig").float;
const int = @import("../../type.zig").int;

// public static native int floatToRawIntBits(float value)
pub fn floatToRawIntBits(ctx: Context, value: float) int {
    _ = ctx;
    return @bitCast(value);
    // bits := math.Float32bits(float32(value))
    // return Int(int32(bits))
}

pub fn intBitsToFloat(ctx: Context, bits: int) float {
    _ = ctx;
    return @bitCast(bits);
    // value := math.Float32frombits(uint32(bits))
    // return Float(value)
}
