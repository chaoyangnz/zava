const Context = @import("../../native.zig").Context;
const JavaLangString = @import("../../type.zig").JavaLangString;

pub fn getSystemPackage0(ctx: Context, vmPackageName: JavaLangString) JavaLangString {
    _ = ctx;
    _ = vmPackageName;
    unreachable;
    // for nl, class := range VM.MethodArea.DefinedClasses {

    // 	if nl.L == nil && strings.HasPrefix(class.Name(), vmPackageName.toNativeString()) {
    // 		return vmPackageName
    // 	}
    // }
    // return NULL
}
