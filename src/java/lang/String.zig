const Context = @import("../../native.zig").Context;
const JavaLangString = @import("../../type.zig").JavaLangString;

pub fn intern(ctx: Context, this: JavaLangString) JavaLangString {
    _ = ctx;
    _ = this;

    // return VM.InternString(this)
    unreachable;
}
