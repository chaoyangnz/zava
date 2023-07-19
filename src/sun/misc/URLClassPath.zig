const register = @import("../../native.zig").register;
const JavaLangClassLoader = @import("../../value.zig").JavaLangClassLoader;
const ArrayRef = @import("../../value.zig").ArrayRef;

pub fn init() void {
    register("sun/misc/URLClassPath.getLookupCacheURLs(Ljava/lang/ClassLoader;)[Ljava/net/URL;", getLookupCacheURLs);
}

fn getLookupCacheURLs(classloader: JavaLangClassLoader) ArrayRef {
    _ = classloader;
    // return VM.NewArrayOfName("[Ljava/net/URL;", 0)
}
