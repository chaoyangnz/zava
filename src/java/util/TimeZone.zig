const register = @import("../../native.zig").register;
const JavaLangString = @import("../../value.zig").JavaLangString;

pub fn int() void {
    register("java/util/TimeZone.getSystemTimeZoneID(Ljava/lang/String;)Ljava/lang/String;", getSystemTimeZoneID);
}

fn getSystemTimeZoneID(javaHome: JavaLangString) JavaLangString {
    _ = javaHome;
    // loc := time.Local
    // return VM.NewJavaLangString(loc.String())
}
