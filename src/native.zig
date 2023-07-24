const vm_allocator = @import("./heap.zig").vm_allocator;
const std = @import("std");
const concat = @import("./shared.zig").concat;
const string = @import("./shared.zig").string;
const Value = @import("./type.zig").Value;

const java_lang_System = @import("./java/lang/System.zig");
const java_lang_Object = @import("./java/lang/Object.zig");
const java_lang_Class = @import("./java/lang/Class.zig");
const java_lang_ClassLoader = @import("./java/lang/ClassLoader.zig");
const java_lang_Package = @import("./java/lang/Package.zig");
const java_lang_String = @import("./java/lang/String.zig");
const java_lang_Float = @import("./java/lang/Float.zig");
const java_lang_Double = @import("./java/lang/Double.zig");
const java_lang_Thread = @import("./java/lang/Thread.zig");
const java_lang_Throwable = @import("./java/lang/Throwable.zig");
const java_lang_Runtime = @import("./java/lang/Runtime.zig");
const java_lang_StrictMath = @import("./java/lang/StrictMath.zig");
const java_security_AccessController = @import("./java/security/AccessController.zig");
const java_lang_reflect_Array = @import("./java/lang/reflect/Array.zig");
const sun_misc_VM = @import("./sun/misc/VM.zig");
const sun_misc_Unsafe = @import("./sun/misc/Unsafe.zig");
const sun_reflect_Reflection = @import("./sun/reflect/Reflection.zig");
const sun_reflect_NativeConstructorAccessorImpl = @import("./sun/reflect/NativeConstructorAccessorImpl.zig");
const sun_misc_URLClassPath = @import("./sun/misc/URLClassPath.zig");
const java_io_FileDescriptor = @import("./java/io/FileDescriptor.zig");
const java_io_FileInputStream = @import("./java/io/FileInputStream.zig");
const java_io_FileOutputStream = @import("./java/io/FileOutputStream.zig");
const java_io_UnixFileSystem = @import("./java/io/UnixFileSystem.zig");
const java_util_concurrent_atomic_AtomicLong = @import("./java/util/concurrent/atomic/AtomicLong.zig");
const java_util_zip_ZipFile = @import("./java/util/zip/ZipFile.zig");
const java_util_TimeZone = @import("./java/util/TimeZone.zig");

test "call" {
    var args = [_]Value{.{ .long = 5000 }};
    _ = call("java/lang/Thread", "sleep(J)V", &args);
}

fn varargs(comptime T: type, args: []Value) T {
    var tuple: T = undefined;
    inline for (std.meta.fields(T), 0..) |_, i| {
        tuple[i] = args[i];
    }
    return tuple;
}

pub fn call(class: string, name: string, descriptor: string, args: []Value) ?Value {
    const qualifier = concat(&[_]string{ class, ".", name, descriptor });
    if (std.mem.eql(u8, qualifier, "java/lang/System.registerNatives()V")) {
        java_lang_System.registerNatives();
        return null;
    }
    if (std.mem.eql(u8, qualifier, "java/lang/System.setIn0(Ljava/io/InputStream;)V")) {
        java_lang_System.setIn0(args[0].ref);
        return null;
    }
    if (std.mem.eql(u8, qualifier, "java/lang/System.setOut0(Ljava/io/PrintStream;)V")) {
        java_lang_System.setOut0(args[0].ref);
        return null;
    }
    if (std.mem.eql(u8, qualifier, "java/lang/System.setErr0(Ljava/io/PrintStream;)V")) {
        java_lang_System.setErr0(args[0].ref);
        return null;
    }
    if (std.mem.eql(u8, qualifier, "java/lang/System.currentTimeMillis()J")) {
        return .{ .long = java_lang_System.currentTimeMillis() };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/System.nanoTime()J")) {
        return .{ .long = java_lang_System.nanoTime() };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/System.arraycopy(Ljava/lang/Object;ILjava/lang/Object;II)V")) {
        java_lang_System.arraycopy(args[0].ref, args[1].int, args[2].ref, args[3].int, args[4].int);
        return null;
    }
    if (std.mem.eql(u8, qualifier, "java/lang/System.identityHashCode(Ljava/lang/Object;)I")) {
        return .{ .int = java_lang_System.identityHashCode(args[0].ref) };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/System.initProperties(Ljava/util/Properties;)Ljava/util/Properties;")) {
        return .{ .ref = java_lang_System.initProperties(args[0].ref) };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/System.mapLibraryName(Ljava/lang/String;)Ljava/lang/String;")) {
        return .{ .ref = java_lang_System.mapLibraryName(args[0].ref) };
    }

    if (std.mem.eql(u8, qualifier, "java/lang/Object.registerNatives()V")) {
        java_lang_Object.registerNatives();
        return null;
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Object.hashCode()I")) {
        return .{ .int = java_lang_Object.hashCode(args[0].ref) };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Object.getClass()Ljava/lang/Class;")) {
        return .{ .ref = java_lang_Object.getClass(args[0].ref) };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Object.clone()Ljava/lang/Object;")) {
        return .{ .ref = java_lang_Object.clone(args[0].ref) };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Object.notifyAll()V")) {
        java_lang_Object.notifyAll(args[0].ref);
        return null;
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Object.wait(J)V")) {
        java_lang_Object.wait(args[0].ref, args[1].long);
        return null;
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Object.notify()V")) {
        java_lang_Object.notifyAll(args[0].ref);
        return null;
    }

    if (std.mem.eql(u8, qualifier, "java/lang/Class.registerNatives()V")) {
        java_lang_Class.registerNatives();
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Class.getPrimitiveClass(Ljava/lang/String;)Ljava/lang/Class;")) {
        return .{ .ref = java_lang_Class.getPrimitiveClass(args[0].ref) };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Class.desiredAssertionStatus0(Ljava/lang/Class;)Z")) {
        return .{ .boolean = java_lang_Class.desiredAssertionStatus0(args[0].ref) };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Class.getDeclaredFields0(Z)[Ljava/lang/reflect/Field;")) {
        return .{ .ref = java_lang_Class.getDeclaredFields0(args[0].ref, args[1].boolean) };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Class.isPrimitive()Z")) {
        return .{ .boolean = java_lang_Class.isPrimitive(args[0].ref) };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Class.isAssignableFrom(Ljava/lang/Class;)Z")) {
        return .{ .boolean = java_lang_Class.isAssignableFrom(args[0].ref, args[1].ref) };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Class.getName0()Ljava/lang/String;")) {
        return .{ .ref = java_lang_Class.getName0(args[0].ref) };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Class.forName0(Ljava/lang/String;ZLjava/lang/ClassLoader;Ljava/lang/Class;)Ljava/lang/Class;")) {
        return .{ .ref = java_lang_Class.forName0(args[0].ref, args[1].boolean, args[2].ref, args[3].ref) };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Class.isInterface()Z")) {
        return .{ .boolean = java_lang_Class.isInterface(args[0].ref) };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Class.getDeclaredConstructors0(Z)[Ljava/lang/reflect/Constructor;")) {
        return .{ .ref = java_lang_Class.getDeclaredConstructors0(args[0].ref, args[1].boolean) };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Class.getModifiers()I")) {
        return .{ .int = java_lang_Class.getModifiers(args[0].ref) };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Class.getSuperclass()Ljava/lang/Class;")) {
        return .{ .ref = java_lang_Class.getSuperclass(args[0].ref) };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Class.isArray()Z")) {
        return .{ .boolean = java_lang_Class.isArray(args[0].ref) };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Class.getComponentType()Ljava/lang/Class;")) {
        return .{ .ref = java_lang_Class.getComponentType(args[0].ref) };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Class.getEnclosingMethod0()[Ljava/lang/Object;")) {
        return .{ .ref = java_lang_Class.getEnclosingMethod0(args[0].ref) };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Class.getDeclaringClass0()Ljava/lang/Class;")) {
        return .{ .ref = java_lang_Class.getDeclaringClass0(args[0].ref) };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Class.forName0(Ljava/lang/String;ZLjava/lang/ClassLoader;Ljava/lang/Class;)Ljava/lang/Class;")) {
        return .{ .ref = java_lang_Class.forName0(args[0].ref, args[1].boolean, args[2].ref, args[3].ref) };
    }

    if (std.mem.eql(u8, qualifier, "java/lang/ClassLoader.registerNatives()V")) {
        java_lang_ClassLoader.registerNatives();
        return null;
    }
    if (std.mem.eql(u8, qualifier, "java/lang/ClassLoader.findBuiltinLib(Ljava/lang/String;)Ljava/lang/String;")) {
        return .{ .ref = java_lang_ClassLoader.findBuiltinLib(args[0].ref) };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/ClassLoader$NativeLibrary.load(Ljava/lang/String;Z)V")) {
        java_lang_ClassLoader.NativeLibrary_load(args[0].ref, args[1].ref, args[2].boolean);
        return null;
    }
    if (std.mem.eql(u8, qualifier, "java/lang/ClassLoader.findLoadedClass0(Ljava/lang/String;)Ljava/lang/Class;")) {
        return .{ .ref = java_lang_ClassLoader.findLoadedClass0(args[0].ref, args[1].ref) };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/ClassLoader.defineClass1(Ljava/lang/String;[BIILjava/security/ProtectionDomain;Ljava/lang/String;)Ljava/lang/Class;")) {
        return .{ .ref = java_lang_ClassLoader.defineClass1(args[0].ref, args[1].ref, args[2].ref, args[3].int, args[4].int, args[5].ref, args[6].ref) };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/ClassLoader.findBootstrapClass(Ljava/lang/String;)Ljava/lang/Class;")) {
        return .{ .ref = java_lang_ClassLoader.findBootstrapClass(args[0].ref, args[1].ref) };
    }

    if (std.mem.eql(u8, qualifier, "java/lang/Package.getSystemPackage0(Ljava/lang/String;)Ljava/lang/String;")) {
        return .{ .ref = java_lang_Package.getSystemPackage0(args[0].ref) };
    }

    if (std.mem.eql(u8, qualifier, "java/lang/String.intern()Ljava/lang/String;")) {
        return .{ .ref = java_lang_String.intern(args[0].ref) };
    }

    if (std.mem.eql(u8, qualifier, "java/lang/Float.floatToRawIntBits(F)I")) {
        return .{ .int = java_lang_Float.floatToRawIntBits(args[0].float) };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Float.intBitsToFloat(I)F")) {
        return .{ .float = java_lang_Float.intBitsToFloat(args[0].int) };
    }

    if (std.mem.eql(u8, qualifier, "java/lang/Double.doubleToRawLongBits(D)J")) {
        return .{ .long = java_lang_Double.doubleToRawLongBits(args[0].double) };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Double.longBitsToDouble(J)D")) {
        return .{ .double = java_lang_Double.longBitsToDouble(args[0].long) };
    }

    if (std.mem.eql(u8, qualifier, "java/lang/Thread.registerNatives()V")) {
        java_lang_Thread.registerNatives();
        return null;
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Thread.currentThread()Ljava/lang/Thread;")) {
        return .{ .ref = java_lang_Thread.currentThread() };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Thread.setPriority0(I)V")) {
        java_lang_Thread.setPriority0(args[0].ref, args[1].int);
        return null;
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Thread.isAlive()Z")) {
        return .{ .boolean = java_lang_Thread.isAlive(args[0].ref) };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Thread.start0()V")) {
        java_lang_Thread.start0(args[0].ref);
        return null;
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Thread.sleep(J)V")) {
        java_lang_Thread.sleep(args[0].long);
        return null;
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Thread.interrupt0()V")) {
        java_lang_Thread.interrupt0(args[0].ref);
        return null;
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Thread.isInterrupted(Z)Z")) {
        return .{ .boolean = java_lang_Thread.isInterrupted(args[0].ref, args[1].boolean) };
    }

    if (std.mem.eql(u8, qualifier, "java/lang/Throwable.getStackTraceDepth()I")) {
        return .{ .int = java_lang_Throwable.getStackTraceDepth(args[0].ref) };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Throwable.fillInStackTrace(I)Ljava/lang/Throwable;")) {
        return .{ .ref = java_lang_Throwable.fillInStackTrace(args[0].ref, args[1].int) };
    }
    if (std.mem.eql(u8, qualifier, "java/lang/Throwable.getStackTraceElement(I)Ljava/lang/StackTraceElement;")) {
        return .{ .ref = java_lang_Throwable.getStackTraceElement(args[0].ref, args[1].int) };
    }

    if (std.mem.eql(u8, qualifier, "java/lang/Runtime.availableProcessors()I")) {
        return .{ .int = java_lang_Runtime.availableProcessors(args[0].ref) };
    }

    if (std.mem.eql(u8, qualifier, "java/lang/StrictMath.pow(DD)D")) {
        return .{ .double = java_lang_StrictMath.pow(args[0].double, args[1].double) };
    }

    if (std.mem.eql(u8, qualifier, "java/security/AccessController.doPrivileged(Ljava/security/PrivilegedExceptionAction;)Ljava/lang/Object;")) {
        return .{ .ref = java_security_AccessController.doPrivileged(args[0].ref) };
    }
    if (std.mem.eql(u8, qualifier, "java/security/AccessController.doPrivileged(Ljava/security/PrivilegedAction;)Ljava/lang/Object;")) {
        return .{ .ref = java_security_AccessController.doPrivileged(args[0].ref) };
    }
    if (std.mem.eql(u8, qualifier, "java/security/AccessController.getStackAccessControlContext()Ljava/security/AccessControlContext;")) {
        return .{ .ref = java_security_AccessController.getStackAccessControlContext() };
    }
    if (std.mem.eql(u8, qualifier, "java/security/AccessController.doPrivileged(Ljava/security/PrivilegedExceptionAction;Ljava/security/AccessControlContext;)Ljava/lang/Object;")) {
        return .{ .ref = java_security_AccessController.doPrivilegedContext(args[0].ref, args[1].ref) };
    }

    if (std.mem.eql(u8, qualifier, "java/lang/reflect/Array.newArray(Ljava/lang/Class;I)Ljava/lang/Object;")) {
        return .{ .ref = java_lang_reflect_Array.newArray(args[0].ref, args[1].int) };
    }

    if (std.mem.eql(u8, qualifier, "sun/misc/VM.initialize()V")) {
        sun_misc_VM.initialize();
        return null;
    }

    if (std.mem.eql(u8, qualifier, "sun/misc/Unsafe.registerNatives()V")) {
        sun_misc_Unsafe.registerNatives();
        return null;
    }
    if (std.mem.eql(u8, qualifier, "sun/misc/Unsafe.arrayBaseOffset(Ljava/lang/Class;)I")) {
        return .{ .int = sun_misc_Unsafe.arrayBaseOffset(args[0].ref, args[0].ref) };
    }
    if (std.mem.eql(u8, qualifier, "sun/misc/Unsafe.arrayIndexScale(Ljava/lang/Class;)I")) {
        return .{ .int = sun_misc_Unsafe.arrayIndexScale(args[0].ref, args[1].ref) };
    }
    if (std.mem.eql(u8, qualifier, "sun/misc/Unsafe.addressSize()I")) {
        return .{ .int = sun_misc_Unsafe.addressSize(args[0].ref) };
    }
    if (std.mem.eql(u8, qualifier, "sun/misc/Unsafe.objectFieldOffset(Ljava/lang/reflect/Field;)J")) {
        return .{ .long = sun_misc_Unsafe.objectFieldOffset(args[0].ref, args[1].ref) };
    }
    if (std.mem.eql(u8, qualifier, "sun/misc/Unsafe.compareAndSwapObject(Ljava/lang/Object;JLjava/lang/Object;Ljava/lang/Object;)Z")) {
        return .{ .boolean = sun_misc_Unsafe.compareAndSwapObject(args[0].ref, args[1].ref, args[2].long, args[3].ref, args[4].ref) };
    }
    if (std.mem.eql(u8, qualifier, "sun/misc/Unsafe.getIntVolatile(Ljava/lang/Object;J)I")) {
        return .{ .int = sun_misc_Unsafe.getIntVolatile(args[0].ref, args[1].ref, args[2].long) };
    }
    if (std.mem.eql(u8, qualifier, "sun/misc/Unsafe.getObjectVolatile(Ljava/lang/Object;J)Ljava/lang/Object;")) {
        return .{ .ref = sun_misc_Unsafe.getObjectVolatile(args[0].ref, args[1].ref, args[2].long) };
    }
    if (std.mem.eql(u8, qualifier, "sun/misc/Unsafe.putObjectVolatile(Ljava/lang/Object;JLjava/lang/Object;)V")) {
        sun_misc_Unsafe.putObjectVolatile(args[0].ref, args[1].ref, args[2].long, args[3].ref);
        return null;
    }

    if (std.mem.eql(u8, qualifier, "sun/misc/Unsafe.compareAndSwapInt(Ljava/lang/Object;JII)Z")) {
        return .{ .boolean = sun_misc_Unsafe.compareAndSwapInt(args[0].ref, args[1].ref, args[2].long, args[3].int, args[4].int) };
    }
    if (std.mem.eql(u8, qualifier, "sun/misc/Unsafe.compareAndSwapLong(Ljava/lang/Object;JJJ)Z")) {
        return .{ .boolean = sun_misc_Unsafe.compareAndSwapLong(args[0].ref, args[1].ref, args[2].long, args[3].long, args[4].long) };
    }
    if (std.mem.eql(u8, qualifier, "sun/misc/Unsafe.allocateMemory(J)J")) {
        return .{ .long = sun_misc_Unsafe.allocateMemory(args[0].ref, args[1].long) };
    }
    if (std.mem.eql(u8, qualifier, "sun/misc/Unsafe.putLong(JJ)V")) {
        sun_misc_Unsafe.putLong(args[0].ref, args[1].long, args[2].long);
        return null;
    }
    if (std.mem.eql(u8, qualifier, "sun/misc/Unsafe.getByte(J)B")) {
        return .{ .byte = sun_misc_Unsafe.getByte(args[0].ref, args[1].long) };
    }
    if (std.mem.eql(u8, qualifier, "sun/misc/Unsafe.freeMemory(J)V")) {
        sun_misc_Unsafe.freeMemory(args[0].ref, args[1].long);
        return null;
    }
    if (std.mem.eql(u8, qualifier, "sun/misc/Unsafe.ensureClassInitialized(Ljava/lang/Class;)V")) {
        sun_misc_Unsafe.ensureClassInitialized(args[0].ref, args[1].ref);
        return null;
    }

    if (std.mem.eql(u8, qualifier, "sun/reflect/Reflection.getCallerClass()Ljava/lang/Class;")) {
        return .{ .ref = sun_reflect_Reflection.getCallerClass() };
    }
    if (std.mem.eql(u8, qualifier, "sun/reflect/Reflection.getClassAccessFlags(Ljava/lang/Class;)I")) {
        return .{ .int = sun_reflect_Reflection.getClassAccessFlags(args[0].ref) };
    }

    if (std.mem.eql(u8, qualifier, "sun/reflect/NativeConstructorAccessorImpl.newInstance0(Ljava/lang/reflect/Constructor;[Ljava/lang/Object;)Ljava/lang/Object;")) {
        return .{ .ref = sun_reflect_NativeConstructorAccessorImpl.newInstance0(args[0].ref, args[1].ref) };
    }

    if (std.mem.eql(u8, qualifier, "sun/misc/URLClassPath.getLookupCacheURLs(Ljava/lang/ClassLoader;)[Ljava/net/URL;")) {
        return .{ .ref = sun_misc_URLClassPath.getLookupCacheURLs(args[0].ref) };
    }

    if (std.mem.eql(u8, qualifier, "java/io/FileDescriptor.initIDs()V")) {
        java_io_FileDescriptor.initIDs();
        return null;
    }

    if (std.mem.eql(u8, qualifier, "java/io/FileInputStream.initIDs()V")) {
        java_io_FileInputStream.initIDs();
        return null;
    }
    if (std.mem.eql(u8, qualifier, "java/io/FileInputStream.open0(Ljava/lang/String;)V")) {
        java_io_FileInputStream.open0(args[0].ref, args[1].ref);
        return null;
    }
    if (std.mem.eql(u8, qualifier, "java/io/FileInputStream.readBytes([BII)I")) {
        return .{ .int = java_io_FileInputStream.readBytes(args[0].ref, args[1].ref, args[2].int, args[3].int) };
    }
    if (std.mem.eql(u8, qualifier, "java/io/FileInputStream.close0()V")) {
        java_io_FileInputStream.close0(args[0].ref);
        return null;
    }

    if (std.mem.eql(u8, qualifier, "java/io/FileOutputStream.initIDs()V")) {
        java_io_FileOutputStream.initIDs();
        return null;
    }
    if (std.mem.eql(u8, qualifier, "java/io/FileOutputStream.writeBytes([BIIZ)V")) {
        java_io_FileOutputStream.writeBytes(args[0].ref, args[1].ref, args[2].int, args[3].int, args[4].boolean);
        return null;
    }

    if (std.mem.eql(u8, qualifier, "java/io/UnixFileSystem.initIDs()V")) {
        java_io_UnixFileSystem.initIDs();
        return null;
    }
    if (std.mem.eql(u8, qualifier, "java/io/UnixFileSystem.canonicalize0(Ljava/lang/String;)Ljava/lang/String;")) {
        return .{ .ref = java_io_UnixFileSystem.canonicalize0(args[0].ref, args[1].ref) };
    }
    if (std.mem.eql(u8, qualifier, "java/io/UnixFileSystem.getBooleanAttributes0(Ljava/io/File;)I")) {
        return .{ .int = java_io_UnixFileSystem.getBooleanAttributes0(args[0].ref, args[1].ref) };
    }
    if (std.mem.eql(u8, qualifier, "java/io/UnixFileSystem.getLength(Ljava/io/File;)J")) {
        return .{ .long = java_io_UnixFileSystem.getLength(args[0].ref, args[1].ref) };
    }

    if (std.mem.eql(u8, qualifier, "java/util/concurrent/atomic/AtomicLong.VMSupportsCS8()Z")) {
        return .{ .boolean = java_util_concurrent_atomic_AtomicLong.VMSupportsCS8() };
    }

    if (std.mem.eql(u8, qualifier, "java/util/zip/ZipFile.initIDs()V")) {
        java_util_zip_ZipFile.initIDs();
        return null;
    }

    if (std.mem.eql(u8, qualifier, "java/util/TimeZone.getSystemTimeZoneID(Ljava/lang/String;)Ljava/lang/String;")) {
        return .{ .ref = java_util_TimeZone.getSystemTimeZoneID(args[0].ref) };
    }
    std.debug.panic("Native method {s} not found", .{qualifier});
}
