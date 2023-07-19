const vm_allocator = @import("./heap.zig").vm_allocator;
const std = @import("std");
const string = @import("./shared.zig").string;

const registry = std.AutoHashMap(string, anyopaque).init(vm_allocator);

pub fn register(qualifier: string, native: anytype) void {
    registry.put(qualifier, native);
}

pub fn init() void {
    @import("./java/lang/System.zig").init();
    @import("./java/lang/Object.zig").init();
    @import("./java/lang/Class.zig").init();
    @import("./java/lang/ClassLoader.zig").init();
    @import("./java/lang/Package.zig").init();

    @import("./java/lang/String.zig").init();
    @import("./java/lang/Float.zig").init();
    @import("./java/lang/Double.zig").init();

    @import("./java/lang/Thread.zig").init();
    @import("./java/lang/Throwable.zig").init();
    @import("./java/lang/Runtime.zig").init();

    @import("./java/lang/StrictMath.zig").init();

    @import("./java/security/AccessController.zig").init();

    @import("./java/lang/reflect/Array.zig").init();

    @import("./sun/misc/VM.zig").init();
    @import("./sun/misc/Unsafe.zig").init();
    @import("./sun/reflect/Reflection.zig").init();
    @import("./sun/reflect/NativeConstructorAccessorImpl.zig").init();
    @import("./sun/misc/URLClassPath.zig").init();

    @import("./java/io/FileDescriptor.zig").init();
    @import("./java/io/FieInputStream.zig").init();
    @import("./java/io/FieOutputStream.zig").init();
    @import("./java/io/UnixFileSystem.zig").init();

    @import("./java/util/concurrent/atomic/AtomicLong.zig").init();

    @import("./java/util/zip/ZipFile.zig").init();
    @import("./java/util/TimeZone.zig").init();
}
