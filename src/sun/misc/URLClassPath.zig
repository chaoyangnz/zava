const Context = @import("../../native.zig").Context;
const JavaLangClassLoader = @import("../../type.zig").JavaLangClassLoader;
const ArrayRef = @import("../../type.zig").ArrayRef;

pub fn getLookupCacheURLs(ctx: Context, classloader: JavaLangClassLoader) ArrayRef {
    _ = ctx;
    _ = classloader;
    unreachable;
    // return VM.NewArrayOfName("[Ljava/net/URL;", 0)
}
