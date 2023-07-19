const JavaLangString = @import("../../value.zig").JavaLangString;

pub fn getSystemPackage0(vmPackageName: JavaLangString) JavaLangString {
    _ = vmPackageName;
    unreachable;
    // for nl, class := range VM.MethodArea.DefinedClasses {

    // 	if nl.L == nil && strings.HasPrefix(class.Name(), vmPackageName.toNativeString()) {
    // 		return vmPackageName
    // 	}
    // }
    // return NULL
}
