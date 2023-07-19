const JavaLangString = @import("../../value.zig").JavaLangString;

pub fn intern(this: JavaLangString) JavaLangString {
    _ = this;

    // return VM.InternString(this)
    unreachable;
}
