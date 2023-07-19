const JavaLangClassLoader = @import("../../value.zig").JavaLangClassLoader;
const ArrayRef = @import("../../value.zig").ArrayRef;

pub fn getLookupCacheURLs(classloader: JavaLangClassLoader) ArrayRef {
    _ = classloader;
    unreachable;
    // return VM.NewArrayOfName("[Ljava/net/URL;", 0)
}
