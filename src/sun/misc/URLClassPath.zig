const JavaLangClassLoader = @import("../../type.zig").JavaLangClassLoader;
const ArrayRef = @import("../../type.zig").ArrayRef;

pub fn getLookupCacheURLs(classloader: JavaLangClassLoader) ArrayRef {
    _ = classloader;
    unreachable;
    // return VM.NewArrayOfName("[Ljava/net/URL;", 0)
}
