const register = @import("../../native.zig").register;
const JavaLangString = @import("../../value.zig").JavaLangString;

pub fn init() void {
    register("java/lang/Package.getSystemPackage0(Ljava/lang/String;)Ljava/lang/String;", getSystemPackage0);
}

fn getSystemPackage0(vmPackageName: JavaLangString) JavaLangString {
    _ = vmPackageName;
    // for nl, class := range VM.MethodArea.DefinedClasses {

    // 	if nl.L == nil && strings.HasPrefix(class.Name(), vmPackageName.toNativeString()) {
    // 		return vmPackageName
    // 	}
    // }
    // return NULL
}
