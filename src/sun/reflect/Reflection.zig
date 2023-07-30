const Context = @import("../../native.zig").Context;
const JavaLangClass = @import("../../type.zig").JavaLangClass;
const int = @import("../../type.zig").int;
const current = @import("../../engine.zig").current;
const NULL = @import("../../type.zig").NULL;
const newJavaLangClass = @import("../../intrinsic.zig").newJavaLangClass;

pub fn getCallerClass(ctx: Context) JavaLangClass {
    _ = ctx;
    const t = current();
    const len = t.stack.items.len;
    if (len < 2) {
        return NULL;
    } else {
        return newJavaLangClass(null, t.stack.items[len - 2].class.name);
    }
    // //todo

    // vmStack := VM.CurrentThread().vmStack
    // if len(vmStack) == 1 {
    // 	return NULL
    // } else {
    // 	return vmStack[len(vmStack)-2].method.class.ClassObject()
    // }
}

pub fn getClassAccessFlags(ctx: Context, classObj: JavaLangClass) int {
    _ = ctx;
    _ = classObj;
    unreachable;
    // return Int(u16toi32(classObj.retrieveType().(*Class).accessFlags))
}
