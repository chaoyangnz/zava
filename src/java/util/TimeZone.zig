const JavaLangString = @import("../../value.zig").JavaLangString;

pub fn getSystemTimeZoneID(javaHome: JavaLangString) JavaLangString {
    _ = javaHome;
    // loc := time.Local
    // return VM.NewJavaLangString(loc.String())
    unreachable;
}
