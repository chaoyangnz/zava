const vm_allocator = @import("./heap.zig").vm_allocator;
const std = @import("std");
const concat = @import("./shared.zig").concat;
const string = @import("./shared.zig").string;
const Value = @import("./value.zig").Value;

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
    _ = call("java/lang/System", "currentTimeMillis()J", &[_]Value{});
}

pub fn call(class: string, method: string, args: []Value) Value {
    const qualifier = concat(&[_]string{ class, ".", method });
    for (0..natives.len / 2) |i| {
        if (std.mem.eql(u8, qualifier, natives[i * 2])) {
            return @call(.auto, natives[i + 1], args);
        }
    }
    std.debug.panic("Native method {s} not found", .{qualifier});
}

const natives = .{
    "java/lang/System.registerNatives()V",
    java_lang_System.registerNatives,
    "java/lang/System.setIn0(Ljava/io/InputStream;)V",
    java_lang_System.setIn0,
    "java/lang/System.setOut0(Ljava/io/PrintStream;)V",
    java_lang_System.setOut0,
    "java/lang/System.setErr0(Ljava/io/PrintStream;)V",
    java_lang_System.setErr0,
    "java/lang/System.currentTimeMillis()J",
    java_lang_System.currentTimeMillis,
    "java/lang/System.nanoTime()J",
    java_lang_System.nanoTime,
    "java/lang/System.arraycopy(Ljava/lang/Object;ILjava/lang/Object;II)V",
    java_lang_System.arraycopy,
    "java/lang/System.identityHashCode(Ljava/lang/Object;)I",
    java_lang_System.identityHashCode,
    "java/lang/System.initProperties(Ljava/util/Properties;)Ljava/util/Properties;",
    java_lang_System.initProperties,
    "java/lang/System.mapLibraryName(Ljava/lang/String;)Ljava/lang/String;",
    java_lang_System.mapLibraryName,

    "java/lang/Object.registerNatives()V",
    java_lang_Object.registerNatives,
    "java/lang/Object.hashCode()I",
    java_lang_Object.hashCode,
    "java/lang/Object.getClass()Ljava/lang/Class;",
    java_lang_Object.getClass,
    "java/lang/Object.clone()Ljava/lang/Object;",
    java_lang_Object.clone,
    "java/lang/Object.notifyAll()V",
    java_lang_Object.notifyAll,
    "java/lang/Object.wait(J)V",
    java_lang_Object.wait,
    "java/lang/Object.notify()V",
    java_lang_Object.notifyAll,

    "java/lang/Class.registerNatives()V",
    java_lang_Class.registerNatives,
    "java/lang/Class.getPrimitiveClass(Ljava/lang/String;)Ljava/lang/Class;",
    java_lang_Class.getPrimitiveClass,
    "java/lang/Class.desiredAssertionStatus0(Ljava/lang/Class;)Z",
    java_lang_Class.desiredAssertionStatus0,
    "java/lang/Class.getDeclaredFields0(Z)[Ljava/lang/reflect/Field;",
    java_lang_Class.getDeclaredFields0,
    "java/lang/Class.isPrimitive()Z",
    java_lang_Class.isPrimitive,
    "java/lang/Class.isAssignableFrom(Ljava/lang/Class;)Z",
    java_lang_Class.isAssignableFrom,
    "java/lang/Class.getName0()Ljava/lang/String;",
    java_lang_Class.getName0,
    "java/lang/Class.forName0(Ljava/lang/String;ZLjava/lang/ClassLoader;Ljava/lang/Class;)Ljava/lang/Class;",
    java_lang_Class.forName0,
    "java/lang/Class.isInterface()Z",
    java_lang_Class.isInterface,
    "java/lang/Class.getDeclaredConstructors0(Z)[Ljava/lang/reflect/Constructor;",
    java_lang_Class.getDeclaredConstructors0,
    "java/lang/Class.getModifiers()I",
    java_lang_Class.getModifiers,
    "java/lang/Class.getSuperclass()Ljava/lang/Class;",
    java_lang_Class.getSuperclass,
    "java/lang/Class.isArray()Z",
    java_lang_Class.isArray,
    "java/lang/Class.getComponentType()Ljava/lang/Class;",
    java_lang_Class.getComponentType,
    "java/lang/Class.getEnclosingMethod0()[Ljava/lang/Object;",
    java_lang_Class.getEnclosingMethod0,
    "java/lang/Class.getDeclaringClass0()Ljava/lang/Class;",
    java_lang_Class.getDeclaringClass0,
    "java/lang/Class.forName0(Ljava/lang/String;ZLjava/lang/ClassLoader;Ljava/lang/Class;)Ljava/lang/Class;",
    java_lang_Class.forName0,

    "java/lang/ClassLoader.registerNatives()V",
    java_lang_ClassLoader.registerNatives,
    "java/lang/ClassLoader.findBuiltinLib(Ljava/lang/String;)Ljava/lang/String;",
    java_lang_ClassLoader.findBuiltinLib,
    "java/lang/ClassLoader$NativeLibrary.load(Ljava/lang/String;Z)V",
    java_lang_ClassLoader.NativeLibrary_load,
    "java/lang/ClassLoader.findLoadedClass0(Ljava/lang/String;)Ljava/lang/Class;",
    java_lang_ClassLoader.findLoadedClass0,
    "java/lang/ClassLoader.defineClass1(Ljava/lang/String;[BIILjava/security/ProtectionDomain;Ljava/lang/String;)Ljava/lang/Class;",
    java_lang_ClassLoader.defineClass1,
    "java/lang/ClassLoader.findBootstrapClass(Ljava/lang/String;)Ljava/lang/Class;",
    java_lang_ClassLoader.findBootstrapClass,

    "java/lang/Package.getSystemPackage0(Ljava/lang/String;)Ljava/lang/String;",
    java_lang_Package.getSystemPackage0,

    "java/lang/String.intern()Ljava/lang/String;",
    java_lang_String.intern,

    "java/lang/Float.floatToRawIntBits(F)I",
    java_lang_Float.floatToRawIntBits,
    "java/lang/Float.intBitsToFloat(I)F",
    java_lang_Float.intBitsToFloat,

    "java/lang/Double.doubleToRawLongBits(D)J",
    java_lang_Double.doubleToRawLongBits,
    "java/lang/Double.longBitsToDouble(J)D",
    java_lang_Double.longBitsToDouble,

    "java/lang/Thread.registerNatives()V",
    java_lang_Thread.registerNatives,
    "java/lang/Thread.currentThread()Ljava/lang/Thread;",
    java_lang_Thread.currentThread,
    "java/lang/Thread.setPriority0(I)V",
    java_lang_Thread.setPriority0,
    "java/lang/Thread.isAlive()Z",
    java_lang_Thread.isAlive,
    "java/lang/Thread.start0()V",
    java_lang_Thread.start0,
    "java/lang/Thread.sleep(J)V",
    java_lang_Thread.sleep,
    "java/lang/Thread.interrupt0()V",
    java_lang_Thread.interrupt0,
    "java/lang/Thread.isInterrupted(Z)Z",
    java_lang_Thread.isInterrupted,

    "java/lang/Throwable.getStackTraceDepth()I",
    java_lang_Throwable.getStackTraceDepth,
    "java/lang/Throwable.fillInStackTrace(I)Ljava/lang/Throwable;",
    java_lang_Throwable.fillInStackTrace,
    "java/lang/Throwable.getStackTraceElement(I)Ljava/lang/StackTraceElement;",
    java_lang_Throwable.getStackTraceElement,

    "java/lang/Runtime.availableProcessors()I",
    java_lang_Runtime.availableProcessors,

    "java/lang/StrictMath.pow(DD)D",
    java_lang_StrictMath.pow,

    "java/security/AccessController.doPrivileged(Ljava/security/PrivilegedExceptionAction;)Ljava/lang/Object;",
    java_security_AccessController.doPrivileged,
    "java/security/AccessController.doPrivileged(Ljava/security/PrivilegedAction;)Ljava/lang/Object;",
    java_security_AccessController.doPrivileged,
    "java/security/AccessController.getStackAccessControlContext()Ljava/security/AccessControlContext;",
    java_security_AccessController.getStackAccessControlContext,
    "java/security/AccessController.doPrivileged(Ljava/security/PrivilegedExceptionAction;Ljava/security/AccessControlContext;)Ljava/lang/Object;",
    java_security_AccessController.doPrivilegedContext,

    "java/lang/reflect/Array.newArray(Ljava/lang/Class;I)Ljava/lang/Object;",
    java_lang_reflect_Array.newArray,

    "sun/misc/VM.initialize()V",
    sun_misc_VM.initialize,

    "sun/misc/Unsafe.registerNatives()V",
    sun_misc_Unsafe.registerNatives,
    "sun/misc/Unsafe.arrayBaseOffset(Ljava/lang/Class;)I",
    sun_misc_Unsafe.arrayBaseOffset,
    "sun/misc/Unsafe.arrayIndexScale(Ljava/lang/Class;)I",
    sun_misc_Unsafe.arrayIndexScale,
    "sun/misc/Unsafe.addressSize()I",
    sun_misc_Unsafe.addressSize,
    "sun/misc/Unsafe.objectFieldOffset(Ljava/lang/reflect/Field;)J",
    sun_misc_Unsafe.objectFieldOffset,
    "sun/misc/Unsafe.compareAndSwapObject(Ljava/lang/Object;JLjava/lang/Object;Ljava/lang/Object;)Z",
    sun_misc_Unsafe.compareAndSwapObject,
    "sun/misc/Unsafe.getIntVolatile(Ljava/lang/Object;J)I",
    sun_misc_Unsafe.getIntVolatile,
    "sun/misc/Unsafe.getObjectVolatile(Ljava/lang/Object;J)Ljava/lang/Object;",
    sun_misc_Unsafe.getObjectVolatile,
    "sun/misc/Unsafe.putObjectVolatile(Ljava/lang/Object;JLjava/lang/Object;)V",
    sun_misc_Unsafe.putObjectVolatile,

    "sun/misc/Unsafe.compareAndSwapInt(Ljava/lang/Object;JII)Z",
    sun_misc_Unsafe.compareAndSwapInt,
    "sun/misc/Unsafe.compareAndSwapLong(Ljava/lang/Object;JJJ)Z",
    sun_misc_Unsafe.compareAndSwapLong,
    "sun/misc/Unsafe.allocateMemory(J)J",
    sun_misc_Unsafe.allocateMemory,
    "sun/misc/Unsafe.putLong(JJ)V",
    sun_misc_Unsafe.putLong,
    "sun/misc/Unsafe.getByte(J)B",
    sun_misc_Unsafe.getByte,
    "sun/misc/Unsafe.freeMemory(J)V",
    sun_misc_Unsafe.freeMemory,
    "sun/misc/Unsafe.ensureClassInitialized(Ljava/lang/Class;)V",
    sun_misc_Unsafe.ensureClassInitialized,

    "sun/reflect/Reflection.getCallerClass()Ljava/lang/Class;",
    sun_reflect_Reflection.getCallerClass,
    "sun/reflect/Reflection.getClassAccessFlags(Ljava/lang/Class;)I",
    sun_reflect_Reflection.getClassAccessFlags,

    "sun/reflect/NativeConstructorAccessorImpl.newInstance0(Ljava/lang/reflect/Constructor;[Ljava/lang/Object;)Ljava/lang/Object;",
    sun_reflect_NativeConstructorAccessorImpl.newInstance0,

    "sun/misc/URLClassPath.getLookupCacheURLs(Ljava/lang/ClassLoader;)[Ljava/net/URL;",
    sun_misc_URLClassPath.getLookupCacheURLs,

    "java/io/FileDescriptor.initIDs()V",
    java_io_FileDescriptor.initIDs,

    "java/io/FileInputStream.initIDs()V",
    java_io_FileInputStream.initIDs,
    "java/io/FileInputStream.open0(Ljava/lang/String;)V",
    java_io_FileInputStream.open0,
    "java/io/FileInputStream.readBytes([BII)I",
    java_io_FileInputStream.readBytes,
    "java/io/FileInputStream.close0()V",
    java_io_FileInputStream.close0,

    "java/io/FileOutputStream.initIDs()V",
    java_io_FileOutputStream.initIDs,
    "java/io/FileOutputStream.writeBytes([BIIZ)V",
    java_io_FileOutputStream.writeBytes,

    "java/io/UnixFileSystem.initIDs()V",
    java_io_UnixFileSystem.initIDs,
    "java/io/UnixFileSystem.canonicalize0(Ljava/lang/String;)Ljava/lang/String;",
    java_io_UnixFileSystem.canonicalize0,
    "java/io/UnixFileSystem.getBooleanAttributes0(Ljava/io/File;)I",
    java_io_UnixFileSystem.getBooleanAttributes0,
    "java/io/UnixFileSystem.getLength(Ljava/io/File;)J",
    java_io_UnixFileSystem.getLength,

    "java/util/concurrent/atomic/AtomicLong.VMSupportsCS8()Z",
    java_util_concurrent_atomic_AtomicLong.VMSupportsCS8,

    "java/util/zip/ZipFile.initIDs()V",
    java_util_zip_ZipFile.initIDs,

    "java/util/TimeZone.getSystemTimeZoneID(Ljava/lang/String;)Ljava/lang/String;",
    java_util_TimeZone.getSystemTimeZoneID,
};
