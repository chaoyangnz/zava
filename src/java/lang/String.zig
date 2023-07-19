const register = @import("../../native.zig").register;
const JavaLangString = @import("../../value.zig").JavaLangString;

pub fn init() void {
    register("java/lang/String.intern()Ljava/lang/String;", intern);
}

fn intern(this: JavaLangString) JavaLangString {
    _ = this;
    // return VM.InternString(this)
}
