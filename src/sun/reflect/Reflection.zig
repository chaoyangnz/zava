const register = @import("../../native.zig").register;
const JavaLangClass = @import("../../value.zig").JavaLangClass;
const int = @import("../../value.zig").int;

pub fn init() void {
    register("sun/reflect/Reflection.getCallerClass()Ljava/lang/Class;", getCallerClass);
    register("sun/reflect/Reflection.getClassAccessFlags(Ljava/lang/Class;)I", getClassAccessFlags);
}

pub fn getCallerClass() JavaLangClass {
    unreachable;
    // //todo

    // vmStack := VM.CurrentThread().vmStack
    // if len(vmStack) == 1 {
    // 	return NULL
    // } else {
    // 	return vmStack[len(vmStack)-2].method.class.ClassObject()
    // }
}

pub fn getClassAccessFlags(classObj: JavaLangClass) int {
    _ = classObj;
    unreachable;
    // return Int(u16toi32(classObj.retrieveType().(*Class).accessFlags))
}
