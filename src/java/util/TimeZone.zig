const Context = @import("../../native.zig").Context;
const JavaLangString = @import("../../type.zig").JavaLangString;

pub fn getSystemTimeZoneID(ctx: Context, javaHome: JavaLangString) JavaLangString {
    _ = ctx;
    _ = javaHome;
    // loc := time.Local
    // return VM.NewJavaLangString(loc.String())
    unreachable;
}
