const std = @import("std");

const string = @import("./vm.zig").string;
const jsize = @import("./vm.zig").jsize;
const jlen = @import("./vm.zig").jlen;
const naming = @import("./vm.zig").naming;
const strings = @import("./vm.zig").strings;
const vm_allocator = @import("./vm.zig").vm_allocator;
const vm_make = @import("./vm.zig").vm_make;
const vm_free = @import("./vm.zig").vm_free;

const byte = @import("./type.zig").byte;
const int = @import("./type.zig").int;
const long = @import("./type.zig").long;
const float = @import("./type.zig").float;
const double = @import("./type.zig").double;
const boolean = @import("./type.zig").boolean;
const Value = @import("./type.zig").Value;
const Class = @import("./type.zig").Class;
const Method = @import("./type.zig").Method;
const Reference = @import("./type.zig").Reference;
const NULL = @import("./type.zig").NULL;
const ObjectRef = @import("./type.zig").ObjectRef;
const ArrayRef = @import("./type.zig").ArrayRef;
const JavaLangString = @import("./type.zig").JavaLangString;
const JavaLangClass = @import("./type.zig").JavaLangClass;
const JavaLangClassLoader = @import("./type.zig").JavaLangClassLoader;
const JavaLangThrowable = @import("./type.zig").JavaLangThrowable;
const JavaLangThread = @import("./type.zig").JavaLangThread;
const JavaLangReflectConstructor = @import("./type.zig").JavaLangReflectConstructor;
const isPrimitiveType = @import("./type.zig").isPrimitiveType;
const defaultValue = @import("./type.zig").defaultValue;

const resolveClass = @import("./method_area.zig").resolveClass;
const assignableFrom = @import("./method_area.zig").assignableFrom;

const Thread = @import("./engine.zig").Thread;
const Frame = @import("./engine.zig").Frame;
const Context = @import("./engine.zig").Context;

const newObject = @import("./heap.zig").newObject;
const newArray = @import("./heap.zig").newArray;
const getJavaLangClass = @import("./heap.zig").getJavaLangClass;
const getJavaLangString = @import("./heap.zig").getJavaLangString;
const newJavaLangThread = @import("./heap.zig").newJavaLangThread;
const newJavaLangReflectField = @import("./heap.zig").newJavaLangReflectField;
const newJavaLangReflectConstructor = @import("./heap.zig").newJavaLangReflectConstructor;
const setInstanceVar = @import("./heap.zig").setInstanceVar;
const getInstanceVar = @import("./heap.zig").getInstanceVar;
const setStaticVar = @import("./heap.zig").setStaticVar;
const getStaticVar = @import("./heap.zig").getStaticVar;
const toString = @import("./heap.zig").toString;
const internString = @import("./heap.zig").internString;

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

pub fn call(ctx: Context, args: []Value) ?Value {
    const class = ctx.c.name;
    const name = ctx.m.name;
    const descriptor = ctx.m.descriptor;
    const qualifier = strings.concat(&[_]string{ class, ".", name, descriptor });
    defer vm_free(qualifier);

    if (strings.equals(qualifier, "java/lang/System.registerNatives()V")) {
        java_lang_System.registerNatives(ctx);
        return null;
    }
    if (strings.equals(qualifier, "java/lang/System.setIn0(Ljava/io/InputStream;)V")) {
        java_lang_System.setIn0(ctx, args[0].ref);
        return null;
    }
    if (strings.equals(qualifier, "java/lang/System.setOut0(Ljava/io/PrintStream;)V")) {
        java_lang_System.setOut0(ctx, args[0].ref);
        return null;
    }
    if (strings.equals(qualifier, "java/lang/System.setErr0(Ljava/io/PrintStream;)V")) {
        java_lang_System.setErr0(ctx, args[0].ref);
        return null;
    }
    if (strings.equals(qualifier, "java/lang/System.currentTimeMillis()J")) {
        return .{ .long = java_lang_System.currentTimeMillis(ctx) };
    }
    if (strings.equals(qualifier, "java/lang/System.nanoTime()J")) {
        return .{ .long = java_lang_System.nanoTime(ctx) };
    }
    if (strings.equals(qualifier, "java/lang/System.arraycopy(Ljava/lang/Object;ILjava/lang/Object;II)V")) {
        java_lang_System.arraycopy(ctx, args[0].ref, args[1].int, args[2].ref, args[3].int, args[4].int);
        return null;
    }
    if (strings.equals(qualifier, "java/lang/System.identityHashCode(Ljava/lang/Object;)I")) {
        return .{ .int = java_lang_System.identityHashCode(ctx, args[0].ref) };
    }
    if (strings.equals(qualifier, "java/lang/System.initProperties(Ljava/util/Properties;)Ljava/util/Properties;")) {
        return .{ .ref = java_lang_System.initProperties(ctx, args[0].ref) };
    }
    if (strings.equals(qualifier, "java/lang/System.mapLibraryName(Ljava/lang/String;)Ljava/lang/String;")) {
        return .{ .ref = java_lang_System.mapLibraryName(ctx, args[0].ref) };
    }

    if (strings.equals(qualifier, "java/lang/Object.registerNatives()V")) {
        java_lang_Object.registerNatives(ctx);
        return null;
    }
    if (strings.equals(qualifier, "java/lang/Object.hashCode()I")) {
        return .{ .int = java_lang_Object.hashCode(ctx, args[0].ref) };
    }
    if (strings.equals(qualifier, "java/lang/Object.getClass()Ljava/lang/Class;")) {
        return .{ .ref = java_lang_Object.getClass(ctx, args[0].ref) };
    }
    if (strings.equals(qualifier, "java/lang/Object.clone()Ljava/lang/Object;")) {
        return .{ .ref = java_lang_Object.clone(ctx, args[0].ref) };
    }
    if (strings.equals(qualifier, "java/lang/Object.notifyAll()V")) {
        java_lang_Object.notifyAll(ctx, args[0].ref);
        return null;
    }
    if (strings.equals(qualifier, "java/lang/Object.wait(J)V")) {
        java_lang_Object.wait(ctx, args[0].ref, args[1].long);
        return null;
    }
    if (strings.equals(qualifier, "java/lang/Object.notify()V")) {
        java_lang_Object.notifyAll(ctx, args[0].ref);
        return null;
    }

    if (strings.equals(qualifier, "java/lang/Class.registerNatives()V")) {
        java_lang_Class.registerNatives(ctx);
        return null;
    }
    if (strings.equals(qualifier, "java/lang/Class.getPrimitiveClass(Ljava/lang/String;)Ljava/lang/Class;")) {
        return .{ .ref = java_lang_Class.getPrimitiveClass(ctx, args[0].ref) };
    }
    if (strings.equals(qualifier, "java/lang/Class.desiredAssertionStatus0(Ljava/lang/Class;)Z")) {
        return .{ .boolean = java_lang_Class.desiredAssertionStatus0(ctx, args[0].ref) };
    }
    if (strings.equals(qualifier, "java/lang/Class.getDeclaredFields0(Z)[Ljava/lang/reflect/Field;")) {
        return .{ .ref = java_lang_Class.getDeclaredFields0(ctx, args[0].ref, args[1].as(boolean).boolean) };
    }
    if (strings.equals(qualifier, "java/lang/Class.isPrimitive()Z")) {
        return .{ .boolean = java_lang_Class.isPrimitive(ctx, args[0].ref) };
    }
    if (strings.equals(qualifier, "java/lang/Class.isAssignableFrom(Ljava/lang/Class;)Z")) {
        return .{ .boolean = java_lang_Class.isAssignableFrom(ctx, args[0].ref, args[1].ref) };
    }
    if (strings.equals(qualifier, "java/lang/Class.getName0()Ljava/lang/String;")) {
        return .{ .ref = java_lang_Class.getName0(ctx, args[0].ref) };
    }
    if (strings.equals(qualifier, "java/lang/Class.forName0(Ljava/lang/String;ZLjava/lang/ClassLoader;Ljava/lang/Class;)Ljava/lang/Class;")) {
        return .{ .ref = java_lang_Class.forName0(ctx, args[0].ref, args[1].as(boolean).boolean, args[2].ref, args[3].ref) };
    }
    if (strings.equals(qualifier, "java/lang/Class.isInterface()Z")) {
        return .{ .boolean = java_lang_Class.isInterface(ctx, args[0].ref) };
    }
    if (strings.equals(qualifier, "java/lang/Class.getDeclaredConstructors0(Z)[Ljava/lang/reflect/Constructor;")) {
        return .{ .ref = java_lang_Class.getDeclaredConstructors0(ctx, args[0].ref, args[1].as(boolean).boolean) };
    }
    if (strings.equals(qualifier, "java/lang/Class.getModifiers()I")) {
        return .{ .int = java_lang_Class.getModifiers(ctx, args[0].ref) };
    }
    if (strings.equals(qualifier, "java/lang/Class.getSuperclass()Ljava/lang/Class;")) {
        return .{ .ref = java_lang_Class.getSuperclass(ctx, args[0].ref) };
    }
    if (strings.equals(qualifier, "java/lang/Class.isArray()Z")) {
        return .{ .boolean = java_lang_Class.isArray(ctx, args[0].ref) };
    }
    if (strings.equals(qualifier, "java/lang/Class.getComponentType()Ljava/lang/Class;")) {
        return .{ .ref = java_lang_Class.getComponentType(ctx, args[0].ref) };
    }
    if (strings.equals(qualifier, "java/lang/Class.getEnclosingMethod0()[Ljava/lang/Object;")) {
        return .{ .ref = java_lang_Class.getEnclosingMethod0(ctx, args[0].ref) };
    }
    if (strings.equals(qualifier, "java/lang/Class.getDeclaringClass0()Ljava/lang/Class;")) {
        return .{ .ref = java_lang_Class.getDeclaringClass0(ctx, args[0].ref) };
    }
    if (strings.equals(qualifier, "java/lang/Class.forName0(Ljava/lang/String;ZLjava/lang/ClassLoader;Ljava/lang/Class;)Ljava/lang/Class;")) {
        return .{ .ref = java_lang_Class.forName0(ctx, args[0].ref, args[1].as(boolean).boolean, args[2].ref, args[3].ref) };
    }

    if (strings.equals(qualifier, "java/lang/ClassLoader.registerNatives()V")) {
        java_lang_ClassLoader.registerNatives(ctx);
        return null;
    }
    if (strings.equals(qualifier, "java/lang/ClassLoader.findBuiltinLib(Ljava/lang/String;)Ljava/lang/String;")) {
        return .{ .ref = java_lang_ClassLoader.findBuiltinLib(ctx, args[0].ref) };
    }
    if (strings.equals(qualifier, "java/lang/ClassLoader$NativeLibrary.load(Ljava/lang/String;Z)V")) {
        java_lang_ClassLoader.NativeLibrary_load(ctx, args[0].ref, args[1].ref, args[2].as(boolean).boolean);
        return null;
    }
    if (strings.equals(qualifier, "java/lang/ClassLoader.findLoadedClass0(Ljava/lang/String;)Ljava/lang/Class;")) {
        return .{ .ref = java_lang_ClassLoader.findLoadedClass0(ctx, args[0].ref, args[1].ref) };
    }
    if (strings.equals(qualifier, "java/lang/ClassLoader.defineClass1(Ljava/lang/String;[BIILjava/security/ProtectionDomain;Ljava/lang/String;)Ljava/lang/Class;")) {
        return .{ .ref = java_lang_ClassLoader.defineClass1(ctx, args[0].ref, args[1].ref, args[2].ref, args[3].int, args[4].int, args[5].ref, args[6].ref) };
    }
    if (strings.equals(qualifier, "java/lang/ClassLoader.findBootstrapClass(Ljava/lang/String;)Ljava/lang/Class;")) {
        return .{ .ref = java_lang_ClassLoader.findBootstrapClass(ctx, args[0].ref, args[1].ref) };
    }

    if (strings.equals(qualifier, "java/lang/Package.getSystemPackage0(Ljava/lang/String;)Ljava/lang/String;")) {
        return .{ .ref = java_lang_Package.getSystemPackage0(ctx, args[0].ref) };
    }

    if (strings.equals(qualifier, "java/lang/String.intern()Ljava/lang/String;")) {
        return .{ .ref = java_lang_String.intern(ctx, args[0].ref) };
    }

    if (strings.equals(qualifier, "java/lang/Float.floatToRawIntBits(F)I")) {
        return .{ .int = java_lang_Float.floatToRawIntBits(ctx, args[0].float) };
    }
    if (strings.equals(qualifier, "java/lang/Float.intBitsToFloat(I)F")) {
        return .{ .float = java_lang_Float.intBitsToFloat(ctx, args[0].int) };
    }

    if (strings.equals(qualifier, "java/lang/Double.doubleToRawLongBits(D)J")) {
        return .{ .long = java_lang_Double.doubleToRawLongBits(ctx, args[0].double) };
    }
    if (strings.equals(qualifier, "java/lang/Double.longBitsToDouble(J)D")) {
        return .{ .double = java_lang_Double.longBitsToDouble(ctx, args[0].long) };
    }

    if (strings.equals(qualifier, "java/lang/Thread.registerNatives()V")) {
        java_lang_Thread.registerNatives(ctx);
        return null;
    }
    if (strings.equals(qualifier, "java/lang/Thread.currentThread()Ljava/lang/Thread;")) {
        return .{ .ref = java_lang_Thread.currentThread(ctx) };
    }
    if (strings.equals(qualifier, "java/lang/Thread.setPriority0(I)V")) {
        java_lang_Thread.setPriority0(ctx, args[0].ref, args[1].int);
        return null;
    }
    if (strings.equals(qualifier, "java/lang/Thread.isAlive()Z")) {
        return .{ .boolean = java_lang_Thread.isAlive(ctx, args[0].ref) };
    }
    if (strings.equals(qualifier, "java/lang/Thread.start0()V")) {
        java_lang_Thread.start0(ctx, args[0].ref);
        return null;
    }
    if (strings.equals(qualifier, "java/lang/Thread.sleep(J)V")) {
        java_lang_Thread.sleep(ctx, args[0].long);
        return null;
    }
    if (strings.equals(qualifier, "java/lang/Thread.interrupt0()V")) {
        java_lang_Thread.interrupt0(ctx, args[0].ref);
        return null;
    }
    if (strings.equals(qualifier, "java/lang/Thread.isInterrupted(Z)Z")) {
        return .{ .boolean = java_lang_Thread.isInterrupted(ctx, args[0].ref, args[1].as(boolean).boolean) };
    }

    if (strings.equals(qualifier, "java/lang/Throwable.getStackTraceDepth()I")) {
        return .{ .int = java_lang_Throwable.getStackTraceDepth(ctx, args[0].ref) };
    }
    if (strings.equals(qualifier, "java/lang/Throwable.fillInStackTrace(I)Ljava/lang/Throwable;")) {
        return .{ .ref = java_lang_Throwable.fillInStackTrace(ctx, args[0].ref, args[1].int) };
    }
    if (strings.equals(qualifier, "java/lang/Throwable.getStackTraceElement(I)Ljava/lang/StackTraceElement;")) {
        return .{ .ref = java_lang_Throwable.getStackTraceElement(ctx, args[0].ref, args[1].int) };
    }

    if (strings.equals(qualifier, "java/lang/Runtime.availableProcessors()I")) {
        return .{ .int = java_lang_Runtime.availableProcessors(ctx, args[0].ref) };
    }

    if (strings.equals(qualifier, "java/lang/StrictMath.pow(DD)D")) {
        return .{ .double = java_lang_StrictMath.pow(ctx, args[0].double, args[1].double) };
    }

    if (strings.equals(qualifier, "java/security/AccessController.doPrivileged(Ljava/security/PrivilegedExceptionAction;)Ljava/lang/Object;")) {
        return .{ .ref = java_security_AccessController.doPrivileged(ctx, args[0].ref) };
    }
    if (strings.equals(qualifier, "java/security/AccessController.doPrivileged(Ljava/security/PrivilegedAction;)Ljava/lang/Object;")) {
        return .{ .ref = java_security_AccessController.doPrivileged(ctx, args[0].ref) };
    }
    if (strings.equals(qualifier, "java/security/AccessController.getStackAccessControlContext()Ljava/security/AccessControlContext;")) {
        return .{ .ref = java_security_AccessController.getStackAccessControlContext(ctx) };
    }
    if (strings.equals(qualifier, "java/security/AccessController.doPrivileged(Ljava/security/PrivilegedExceptionAction;Ljava/security/AccessControlContext;)Ljava/lang/Object;")) {
        return .{ .ref = java_security_AccessController.doPrivilegedContext(ctx, args[0].ref, args[1].ref) };
    }

    if (strings.equals(qualifier, "java/lang/reflect/Array.newArray(Ljava/lang/Class;I)Ljava/lang/Object;")) {
        return .{ .ref = java_lang_reflect_Array.newArray(ctx, args[0].ref, args[1].int) };
    }

    if (strings.equals(qualifier, "sun/misc/VM.initialize()V")) {
        sun_misc_VM.initialize(ctx);
        return null;
    }

    if (strings.equals(qualifier, "sun/misc/Unsafe.registerNatives()V")) {
        sun_misc_Unsafe.registerNatives(ctx);
        return null;
    }
    if (strings.equals(qualifier, "sun/misc/Unsafe.arrayBaseOffset(Ljava/lang/Class;)I")) {
        return .{ .int = sun_misc_Unsafe.arrayBaseOffset(ctx, args[0].ref, args[0].ref) };
    }
    if (strings.equals(qualifier, "sun/misc/Unsafe.arrayIndexScale(Ljava/lang/Class;)I")) {
        return .{ .int = sun_misc_Unsafe.arrayIndexScale(ctx, args[0].ref, args[1].ref) };
    }
    if (strings.equals(qualifier, "sun/misc/Unsafe.addressSize()I")) {
        return .{ .int = sun_misc_Unsafe.addressSize(ctx, args[0].ref) };
    }
    if (strings.equals(qualifier, "sun/misc/Unsafe.objectFieldOffset(Ljava/lang/reflect/Field;)J")) {
        return .{ .long = sun_misc_Unsafe.objectFieldOffset(ctx, args[0].ref, args[1].ref) };
    }
    if (strings.equals(qualifier, "sun/misc/Unsafe.compareAndSwapObject(Ljava/lang/Object;JLjava/lang/Object;Ljava/lang/Object;)Z")) {
        return .{ .boolean = sun_misc_Unsafe.compareAndSwapObject(ctx, args[0].ref, args[1].ref, args[2].long, args[3].ref, args[4].ref) };
    }
    if (strings.equals(qualifier, "sun/misc/Unsafe.getIntVolatile(Ljava/lang/Object;J)I")) {
        return .{ .int = sun_misc_Unsafe.getIntVolatile(ctx, args[0].ref, args[1].ref, args[2].long) };
    }
    if (strings.equals(qualifier, "sun/misc/Unsafe.getObjectVolatile(Ljava/lang/Object;J)Ljava/lang/Object;")) {
        return .{ .ref = sun_misc_Unsafe.getObjectVolatile(ctx, args[0].ref, args[1].ref, args[2].long) };
    }
    if (strings.equals(qualifier, "sun/misc/Unsafe.putObjectVolatile(Ljava/lang/Object;JLjava/lang/Object;)V")) {
        sun_misc_Unsafe.putObjectVolatile(ctx, args[0].ref, args[1].ref, args[2].long, args[3].ref);
        return null;
    }

    if (strings.equals(qualifier, "sun/misc/Unsafe.compareAndSwapInt(Ljava/lang/Object;JII)Z")) {
        return .{ .boolean = sun_misc_Unsafe.compareAndSwapInt(ctx, args[0].ref, args[1].ref, args[2].long, args[3].int, args[4].int) };
    }
    if (strings.equals(qualifier, "sun/misc/Unsafe.compareAndSwapLong(Ljava/lang/Object;JJJ)Z")) {
        return .{ .boolean = sun_misc_Unsafe.compareAndSwapLong(ctx, args[0].ref, args[1].ref, args[2].long, args[3].long, args[4].long) };
    }
    if (strings.equals(qualifier, "sun/misc/Unsafe.allocateMemory(J)J")) {
        return .{ .long = sun_misc_Unsafe.allocateMemory(ctx, args[0].ref, args[1].long) };
    }
    if (strings.equals(qualifier, "sun/misc/Unsafe.putLong(JJ)V")) {
        sun_misc_Unsafe.putLong(ctx, args[0].ref, args[1].long, args[2].long);
        return null;
    }
    if (strings.equals(qualifier, "sun/misc/Unsafe.getByte(J)B")) {
        return .{ .byte = sun_misc_Unsafe.getByte(ctx, args[0].ref, args[1].long) };
    }
    if (strings.equals(qualifier, "sun/misc/Unsafe.freeMemory(J)V")) {
        sun_misc_Unsafe.freeMemory(ctx, args[0].ref, args[1].long);
        return null;
    }
    if (strings.equals(qualifier, "sun/misc/Unsafe.ensureClassInitialized(Ljava/lang/Class;)V")) {
        sun_misc_Unsafe.ensureClassInitialized(ctx, args[0].ref, args[1].ref);
        return null;
    }

    if (strings.equals(qualifier, "sun/reflect/Reflection.getCallerClass()Ljava/lang/Class;")) {
        return .{ .ref = sun_reflect_Reflection.getCallerClass(ctx) };
    }
    if (strings.equals(qualifier, "sun/reflect/Reflection.getClassAccessFlags(Ljava/lang/Class;)I")) {
        return .{ .int = sun_reflect_Reflection.getClassAccessFlags(ctx, args[0].ref) };
    }

    if (strings.equals(qualifier, "sun/reflect/NativeConstructorAccessorImpl.newInstance0(Ljava/lang/reflect/Constructor;[Ljava/lang/Object;)Ljava/lang/Object;")) {
        return .{ .ref = sun_reflect_NativeConstructorAccessorImpl.newInstance0(ctx, args[0].ref, args[1].ref) };
    }

    if (strings.equals(qualifier, "sun/misc/URLClassPath.getLookupCacheURLs(Ljava/lang/ClassLoader;)[Ljava/net/URL;")) {
        return .{ .ref = sun_misc_URLClassPath.getLookupCacheURLs(ctx, args[0].ref) };
    }

    if (strings.equals(qualifier, "java/io/FileDescriptor.initIDs()V")) {
        java_io_FileDescriptor.initIDs(ctx);
        return null;
    }

    if (strings.equals(qualifier, "java/io/FileInputStream.initIDs()V")) {
        java_io_FileInputStream.initIDs(ctx);
        return null;
    }
    if (strings.equals(qualifier, "java/io/FileInputStream.open0(Ljava/lang/String;)V")) {
        java_io_FileInputStream.open0(ctx, args[0].ref, args[1].ref);
        return null;
    }
    if (strings.equals(qualifier, "java/io/FileInputStream.readBytes([BII)I")) {
        return .{ .int = java_io_FileInputStream.readBytes(ctx, args[0].ref, args[1].ref, args[2].int, args[3].int) };
    }
    if (strings.equals(qualifier, "java/io/FileInputStream.close0()V")) {
        java_io_FileInputStream.close0(ctx, args[0].ref);
        return null;
    }

    if (strings.equals(qualifier, "java/io/FileOutputStream.initIDs()V")) {
        java_io_FileOutputStream.initIDs(ctx);
        return null;
    }
    if (strings.equals(qualifier, "java/io/FileOutputStream.writeBytes([BIIZ)V")) {
        java_io_FileOutputStream.writeBytes(ctx, args[0].ref, args[1].ref, args[2].int, args[3].int, args[4].as(boolean).boolean);
        return null;
    }

    if (strings.equals(qualifier, "java/io/UnixFileSystem.initIDs()V")) {
        java_io_UnixFileSystem.initIDs(ctx);
        return null;
    }
    if (strings.equals(qualifier, "java/io/UnixFileSystem.canonicalize0(Ljava/lang/String;)Ljava/lang/String;")) {
        return .{ .ref = java_io_UnixFileSystem.canonicalize0(ctx, args[0].ref, args[1].ref) };
    }
    if (strings.equals(qualifier, "java/io/UnixFileSystem.getBooleanAttributes0(Ljava/io/File;)I")) {
        return .{ .int = java_io_UnixFileSystem.getBooleanAttributes0(ctx, args[0].ref, args[1].ref) };
    }
    if (strings.equals(qualifier, "java/io/UnixFileSystem.getLength(Ljava/io/File;)J")) {
        return .{ .long = java_io_UnixFileSystem.getLength(ctx, args[0].ref, args[1].ref) };
    }

    if (strings.equals(qualifier, "java/util/concurrent/atomic/AtomicLong.VMSupportsCS8()Z")) {
        return .{ .boolean = java_util_concurrent_atomic_AtomicLong.VMSupportsCS8(ctx) };
    }

    if (strings.equals(qualifier, "java/util/zip/ZipFile.initIDs()V")) {
        java_util_zip_ZipFile.initIDs(ctx);
        return null;
    }

    if (strings.equals(qualifier, "java/util/TimeZone.getSystemTimeZoneID(Ljava/lang/String;)Ljava/lang/String;")) {
        return .{ .ref = java_util_TimeZone.getSystemTimeZoneID(ctx, args[0].ref) };
    }
    std.debug.panic("Native method {s} not found", .{qualifier});
}

const java_lang_System = struct {
    // private static void registers()
    pub fn registerNatives(ctx: Context) void {
        _ = ctx;
    }

    // private static void setIn0(InputStream is)
    pub fn setIn0(ctx: Context, is: ObjectRef) void {
        const class = resolveClass(ctx.c, "java/lang/System");
        setStaticVar(class, "in", "Ljava/io/InputStream;", .{ .ref = is });
        // VM.ResolveClass("java/lang/System", TRIGGER_BY_ACCESS_MEMBER).SetStaticVariable("in", "Ljava/io/InputStream;", is)
    }

    // private static void setOut0(PrintStream ps)
    pub fn setOut0(ctx: Context, ps: ObjectRef) void {
        const class = resolveClass(ctx.c, "java/lang/System");
        setStaticVar(class, "out", "Ljava/io/PrintStream;", .{ .ref = ps });
        // VM.ResolveClass("java/lang/System", TRIGGER_BY_ACCESS_MEMBER).SetStaticVariable("out", "Ljava/io/PrintStream;", ps)
    }

    // private static void setErr0(PrintStream ps)
    pub fn setErr0(ctx: Context, ps: ObjectRef) void {
        const class = resolveClass(ctx.c, "java/lang/System");
        setStaticVar(class, "err", "Ljava/io/PrintStream;", .{ .ref = ps });
        // VM.ResolveClass("java/lang/System", TRIGGER_BY_ACCESS_MEMBER).SetStaticVariable("err", "Ljava/io/PrintStream;", ps)
    }

    // public static long currentTimeMillis()
    pub fn currentTimeMillis(ctx: Context) long {
        _ = ctx;
        return std.time.milliTimestamp();
        // return VM.CurrentTimeMillis()
    }

    // public static long nanoTime()
    pub fn nanoTime(ctx: Context) long {
        _ = ctx;
        return @intCast(std.time.nanoTimestamp());
        // return VM.CurrentTimeNano()
    }

    // public static void arraycopy(Object fromArray, int fromIndex, Object toArray, int toIndex, int length)
    pub fn arraycopy(ctx: Context, src: ArrayRef, srcPos: int, dest: ArrayRef, destPos: int, length: int) void {
        _ = ctx;
        if (!src.class().isArray or !dest.class().isArray) {
            unreachable;
        }

        if (srcPos < 0 or destPos < 0 or srcPos + length > src.len() or destPos + length > dest.len()) {
            unreachable;
        }

        for (0..@intCast(length)) |i| {
            var srcIndex: usize = @intCast(srcPos);
            var destIndex: usize = @intCast(destPos);
            dest.set(@intCast(destIndex + i), src.get(@intCast(srcIndex + i)));
        }
        // if !src.Class().IsArray() || !dest.Class().IsArray() {
        // 	VM.Throw("java/lang/ArrayStoreException", "")
        // }

        // if srcPos+length > src.ArrayLength() || destPos+length > dest.ArrayLength() {
        // 	VM.Throw("java/lang/ArrayIndexOutOfBoundsException", "")
        // }
        // for i := Int(0); i < length; i++ {
        // 	dest.SetArrayElement(destPos+i, src.GetArrayElement(srcPos+i))
        // }
    }

    // public static int identityHashCode(Object object)
    pub fn identityHashCode(ctx: Context, object: Reference) int {
        _ = ctx;
        return object.object().header.hashCode;
        // return object.IHashCode()
    }

    // private static Properties initProperties(Properties properties)
    pub fn initProperties(ctx: Context, properties: ObjectRef) ObjectRef {
        const setProperty = properties.class().method("setProperty", "(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/Object;", false);

        const args = vm_make(Value, 3);
        defer vm_free(args);
        args[0] = .{ .ref = properties };

        const map = [_]string{
            "java.version", "1.8.0_152-ea",
            "java.home",                     "", //currentPath,
            "java.specification.name",       "Java Platform API Specification",
            "java.specification.version",    "1.8",
            "java.specification.vendor",     "Oracle Corporation",

            "java.vendor",                   "Oracle Corporation",
            "java.vendor.url",               "http://java.oracle.com/",
            "java.vendor.url.bug",           "http://bugreport.sun.com/bugreport/",

            "java.vm.name",                  "Zava 64-Bit VM",
            "java.vm.version",               "1.0.0",
            "java.vm.vendor",                "Chao Yang",
            "java.vm.info",                  "mixed mode",
            "java.vm.specification.name",    "Java Virtual Machine Specification",
            "java.vm.specification.version", "1.8",
            "java.vm.specification.vendor",  "Oracle Corporation",

            "java.runtime.name",             "Java(TM) SE Runtime Environment",
            "java.runtime.version",          "1.8.0_152-ea-b05",

            "java.class.version",            "52.0",
            "java.class.path", "src/classes;jdk/classes", // app classloader path
            "java.io.tmpdir", "/var/tmp", //classpath, //TODO
            "java.library.path", "", //classpath, //TODO
            "java.ext.dirs", "", //TODO
            "java.endorsed.dirs",   "", //classpath, //TODO
            "java.awt.graphicsenv", "sun.awt.CGraphicsEnvironment",
            "java.awt.printerjob",  "sun.lwawt.macosx.CPrinterJob",
            "awt.toolkit",          "sun.lwawt.macosx.LWCToolkit",

            "path.separator",       ":",
            "line.separator",       "\n",
            "file.separator",       "/",
            "file.encoding",        "UTF-8",
            "file.encoding.pkg",    "sun.io",

            "sun.stdout.encoding",  "UTF-8",
            "sun.stderr.encoding",  "UTF-8",
            "os.name", "Mac OS X", // FIXME
            "os.arch", "x86_64", // FIXME
            "os.version", "10.12.5", // FIXME
            "user.name", "", //user.Name,
            "user.home", "", //user.HomeDir,
            "user.country", "US", // FIXME
            "user.language", "en", // FIXME
            "user.timezone", "", // FIXME
            "user.dir",          "", //user.HomeDir,

            "sun.java.launcher", "SUN_STANDARD",
            "sun.java.command",        "", //strings.Join(os.Args, " "),
            "sun.boot.library.path",   "",
            "sun.boot.class.path",     "",
            "sun.os.patch.level",      "unknown",
            "sun.jnu.encoding",        "UTF-8",
            "sun.management.compiler", "HotSpot 64-Bit Tiered Compilers",
            "sun.arch.data.model",     "64",
            "sun.cpu.endian",          "little",
            "sun.io.unicode.encoding", "UnicodeBig",
            "sun.cpu.isalist",         "",

            "http.nonProxyHosts",      "local|*.local|169.254/16|*.169.254/16",
            "ftp.nonProxyHosts",       "local|*.local|169.254/16|*.169.254/16",
            "socksNonProxyHosts",      "local|*.local|169.254/16|*.169.254/16",
            "gopherProxySet",          "false",
        };
        var i: usize = 0;
        while (i < map.len) {
            args[1] = .{ .ref = getJavaLangString(ctx.c, map[i]) };
            args[2] = .{ .ref = getJavaLangString(ctx.c, map[i + 1]) };
            ctx.t.invoke(properties.class(), setProperty.?, args);
            i += 2;
        }

        // args[1] = .{ .ref = getJavaLangString(null, "java.vm.name") };
        // args[2] = .{ .ref = getJavaLangString(null, "Zara") };
        // ctx.t.invoke(properties.class(), setProperty.?, args);

        // args[1] = .{ .ref = getJavaLangString(null, "file.encoding") };
        // args[2] = .{ .ref = getJavaLangString(null, "UTF-8") };
        // ctx.t.invoke(properties.class(), setProperty.?, args);

        return properties;

        // currentPath, _ := filepath.Abs(filepath.Dir(os.Args[0]) + "/..")
        // user, _ := user.Current()

        // classpath := VM.GetSystemProperty("classpath.system") + ":" +
        // 	VM.GetSystemProperty("classpath.extension") + ":" +
        // 	VM.GetSystemProperty("classpath.application") + ":."

        // paths := strings.Split(classpath, ":")
        // var abs_paths []string
        // for _, seg := range paths {
        // 	abs_path, _ := filepath.Abs(seg)
        // 	abs_paths = append(abs_paths, abs_path)
        // }
        // classpath = strings.Join(abs_paths, ":")

        // m := map[string]string{
        // 	"java.version":               "1.8.0_152-ea",
        // 	"java.home":                  currentPath,
        // 	"java.specification.name":    "Java Platform API Specification",
        // 	"java.specification.version": "1.8",
        // 	"java.specification.vendor":  "Oracle Corporation",

        // 	"java.vendor":         "Oracle Corporation",
        // 	"java.vendor.url":     "http://java.oracle.com/",
        // 	"java.vendor.url.bug": "http://bugreport.sun.com/bugreport/",

        // 	"java.vm.name":                  "Gava 64-Bit VM",
        // 	"java.vm.version":               "1.0.0",
        // 	"java.vm.vendor":                "Chao Yang",
        // 	"java.vm.info":                  "mixed mode",
        // 	"java.vm.specification.name":    "Java Virtual Machine Specification",
        // 	"java.vm.specification.version": "1.8",
        // 	"java.vm.specification.vendor":  "Oracle Corporation",

        // 	"java.runtime.name":    "Java(TM) SE Runtime Environment",
        // 	"java.runtime.version": "1.8.0_152-ea-b05",

        // 	"java.class.version": "52.0",
        // 	"java.class.path":    classpath, // app classloader path

        // 	"java.io.tmpdir":       classpath, //TODO
        // 	"java.library.path":    classpath, //TODO
        // 	"java.ext.dirs":        "",        //TODO
        // 	"java.endorsed.dirs":   classpath, //TODO
        // 	"java.awt.graphicsenv": "sun.awt.CGraphicsEnvironment",
        // 	"java.awt.printerjob":  "sun.lwawt.macosx.CPrinterJob",
        // 	"awt.toolkit":          "sun.lwawt.macosx.LWCToolkit",

        // 	"path.separator":    ":",
        // 	"line.separator":    "\n",
        // 	"file.separator":    "/",
        // 	"file.encoding":     "UTF-8",
        // 	"file.encoding.pkg": "sun.io",

        // 	"sun.stdout.encoding": "UTF-8",
        // 	"sun.stderr.encoding": "UTF-8",

        // 	"os.name":    "Mac OS X", // FIXME
        // 	"os.arch":    "x86_64",   // FIXME
        // 	"os.version": "10.12.5",  // FIXME

        // 	"user.name":     user.Name,
        // 	"user.home":     user.HomeDir,
        // 	"user.country":  "US", // FIXME
        // 	"user.language": "en", // FIXME
        // 	"user.timezone": "",   // FIXME
        // 	"user.dir":      user.HomeDir,

        // 	"sun.java.launcher":       "SUN_STANDARD",
        // 	"sun.java.command":        strings.Join(os.Args, " "),
        // 	"sun.boot.library.path":   "",
        // 	"sun.boot.class.path":     "",
        // 	"sun.os.patch.level":      "unknown",
        // 	"sun.jnu.encoding":        "UTF-8",
        // 	"sun.management.compiler": "HotSpot 64-Bit Tiered Compilers",
        // 	"sun.arch.data.model":     "64",
        // 	"sun.cpu.endian":          "little",
        // 	"sun.io.unicode.encoding": "UnicodeBig",
        // 	"sun.cpu.isalist":         "",

        // 	"http.nonProxyHosts": "local|*.local|169.254/16|*.169.254/16",
        // 	"ftp.nonProxyHosts":  "local|*.local|169.254/16|*.169.254/16",
        // 	"socksNonProxyHosts": "local|*.local|169.254/16|*.169.254/16",
        // 	"gopherProxySet":     "false",
        // }

        // setProperty := properties.Class().GetMethod("setProperty", "(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/Object;")
        // for key, val := range m {
        // 	VM.InvokeMethod(setProperty, properties, VM.getJavaLangString(key), VM.getJavaLangString(val))
        // }

        // return properties
    }

    pub fn mapLibraryName(ctx: Context, name: JavaLangString) JavaLangString {
        _ = ctx;
        return name;
        // return name
    }
};

const java_lang_Object = struct {
    // private static void registerNatives()
    pub fn registerNatives(ctx: Context) void {
        _ = ctx;
    }

    pub fn hashCode(ctx: Context, this: Reference) int {
        _ = ctx;
        return this.object().header.hashCode;
        // return this.IHashCode()
    }

    pub fn getClass(ctx: Context, this: Reference) JavaLangClass {
        return getJavaLangClass(ctx.c, this.class().descriptor);
        // return this.Class().ClassObject()
    }

    pub fn clone(ctx: Context, this: Reference) Reference {
        const cloneable = resolveClass(ctx.c, "java/lang/Cloneable");
        if (!assignableFrom(cloneable, this.class())) {
            unreachable;
            // return ctx.f.vm_throw("java/lang/CloneNotSupportedException");
        }
        const class = this.class();
        var cloned: Reference = undefined;
        if (class.isArray) {
            cloned = newArray(ctx.c, class.name, this.len());
        } else {
            cloned = newObject(ctx.c, class.name);
        }
        for (0..this.len()) |i| {
            cloned.set(@intCast(i), this.get(@intCast(i)));
        }
        return cloned;
        // cloneable := VM.ResolveClass("java/lang/Cloneable", TRIGGER_BY_CHECK_OBJECT_TYPE)
        // if !cloneable.IsAssignableFrom(this.Class()) {
        // 	VM.Throw("java/lang/CloneNotSupportedException", "Not implement java.lang.Cloneable")
        // }

        // return this.Clone()
    }

    pub fn wait(ctx: Context, this: Reference, millis: long) void {
        _ = ctx;
        _ = millis;
        _ = this;
        // // TODO timeout
        // monitor := this.Monitor()
        // if !monitor.HasOwner(VM.CurrentThread()) {
        // 	VM.Throw("java/lang/IllegalMonitorStateException", "Cannot wait() when not holding a monitor")
        // }

        // interrupted := monitor.Wait(int64(millis))
        // if interrupted {
        // 	VM.Throw("java/lang/InterruptedException", "wait interrupted")
        // }
    }

    pub fn notifyAll(ctx: Context, this: Reference) void {
        _ = ctx;
        _ = this;
        // monitor := this.Monitor()
        // if !monitor.HasOwner(VM.CurrentThread()) {
        // 	VM.Throw("java/lang/IllegalMonitorStateException", "Cannot notifyAll() when not holding a monitor")
        // }

        // monitor.NotifyAll()
    }
};
const java_lang_Class = struct {
    // private static void registerNatives()
    pub fn registerNatives(ctx: Context) void {
        _ = ctx;
    }

    // static Class getPrimitiveClass(String name)
    pub fn getPrimitiveClass(ctx: Context, name: JavaLangString) JavaLangClass {
        const java_name = toString(name);
        const descriptor = naming.descriptor(java_name);
        if (!isPrimitiveType(descriptor)) {
            unreachable;
        }
        return getJavaLangClass(ctx.c, descriptor);
        // switch name.toNativeString() {
        // case "byte":
        // 	return BYTE_TYPE.ClassObject()
        // case "short":
        // 	return SHORT_TYPE.ClassObject()
        // case "char":
        // 	return CHAR_TYPE.ClassObject()
        // case "int":
        // 	return INT_TYPE.ClassObject()
        // case "long":
        // 	return LONG_TYPE.ClassObject()
        // case "float":
        // 	return FLOAT_TYPE.ClassObject()
        // case "double":
        // 	return DOUBLE_TYPE.ClassObject()
        // case "boolean":
        // 	return boolean_TYPE.ClassObject()
        // default:
        // 	VM.Throw("java/lang/RuntimeException", "Not a primitive type")
        // }
        // return NULL
    }

    // private static boolean desiredAssertionStatus0(Class javaClass)
    pub fn desiredAssertionStatus0(ctx: Context, clazz: JavaLangClass) boolean {
        _ = ctx;
        _ = clazz;
        // // Always disable assertions
        return 0;
    }

    pub fn getDeclaredFields0(ctx: Context, this: JavaLangClass, publicOnly: boolean) ArrayRef {
        const class = this.object().internal.class;
        std.debug.assert(class != null);
        const fields = class.?.fields;

        var fieldsArrayref: ArrayRef = undefined;
        if (publicOnly == 1) {
            var len: u32 = 0;
            for (fields) |field| {
                if (field.accessFlags.public) {
                    len += 1;
                }
            }
            fieldsArrayref = newArray(ctx.c, "[Ljava/lang/reflect/Field;", len);
            for (fields, 0..) |*field, i| {
                if (field.accessFlags.public) {
                    fieldsArrayref.set(jsize(i), .{ .ref = newJavaLangReflectField(ctx.c, this, field) });
                }
            }
        } else {
            fieldsArrayref = newArray(ctx.c, "[Ljava/lang/reflect/Field;", jlen(fields.len));
            for (fields, 0..) |*field, i| {
                fieldsArrayref.set(jsize(i), .{ .ref = newJavaLangReflectField(ctx.c, this, field) });
            }
        }

        return fieldsArrayref;

        // class := this.retrieveType().(*Class)
        // fields := class.GetDeclaredFields(publicOnly.IsTrue())
        // fieldObjectArr := VM.NewArrayOfName("[Ljava/lang/reflect/Field;", Int(len(fields)))
        // for i, field := range fields {
        // 	fieldObjectArr.SetArrayElement(Int(i), VM.NewJavaLangReflectField(field))
        // }

        // return fieldObjectArr
    }

    pub fn isPrimitive(ctx: Context, this: JavaLangClass) boolean {
        _ = ctx;
        const name = getInstanceVar(this, "name", "Ljava/lang/String;").ref;
        const descriptor = toString(name);
        defer vm_free(descriptor);
        return if (isPrimitiveType(descriptor)) 1 else 0;
        // type_ := this.retrieveType()
        // if _, ok := type_.(*Class); ok {
        // 	return FALSE
        // }
        // return TRUE
    }

    pub fn isAssignableFrom(ctx: Context, this: JavaLangClass, cls: JavaLangClass) boolean {
        _ = ctx;
        const class = this.object().internal.class;
        const clazz = cls.object().internal.class;
        if (class != null and clazz != null and assignableFrom(class.?, clazz.?)) {
            return 1;
        }
        return 0;
        // thisClass := this.retrieveType().(*Class)
        // clsClass := cls.retrieveType().(*Class)

        // assignable := FALSE
        // if thisClass.IsAssignableFrom(clsClass) {
        // 	assignable = TRUE
        // }
        // return assignable
    }

    pub fn getName0(ctx: Context, this: JavaLangClass) JavaLangString {
        _ = ctx;
        _ = this;
        unreachable;
        // return binaryNameToJavaName(this.retrieveType().Name())
    }

    pub fn forName0(ctx: Context, name: JavaLangString, initialize: boolean, loader: JavaLangClassLoader, caller: JavaLangClass) JavaLangClass {
        _ = caller;
        _ = loader;
        _ = initialize;
        const java_name = toString(name);
        const descriptor = naming.descriptor(java_name);

        return getJavaLangClass(ctx.c, descriptor);
        // className := javaNameToBinaryName(name)
        // return VM.ResolveClass(className, TRIGGER_BY_JAVA_REFLECTION).ClassObject()
    }

    pub fn isInterface(ctx: Context, this: JavaLangClass) boolean {
        _ = ctx;
        const class = this.object().internal.class;
        return if (class != null and class.?.accessFlags.interface) 1 else 0;
        // if this.retrieveType().(*Class).IsInterface() {
        // 	return TRUE
        // }
        // return FALSE
    }

    pub fn getDeclaredConstructors0(ctx: Context, this: JavaLangClass, publicOnly: boolean) ArrayRef {
        _ = publicOnly;
        const class = this.object().internal.class;
        std.debug.assert(class != null);
        var constructors = std.ArrayList(*const Method).init(vm_allocator);
        defer constructors.deinit();
        for (class.?.methods) |*method| {
            if (strings.equals(method.name, "<init>")) {
                constructors.append(method) catch unreachable;
            }
        }
        const len = constructors.items.len;
        const arrayref = newArray(ctx.c, "[Ljava/lang/reflect/Constructor;", jlen(len));
        for (0..len) |i| {
            arrayref.set(@intCast(0), .{ .ref = newJavaLangReflectConstructor(ctx.c, this, constructors.items[i]) });
        }

        return arrayref;
        // class := this.retrieveType().(*Class)

        // constructors := class.GetConstructors(publicOnly.IsTrue())

        // constructorArr := VM.NewArrayOfName("[Ljava/lang/reflect/Constructor;", Int(len(constructors)))
        // for i, constructor := range constructors {
        // 	constructorArr.SetArrayElement(Int(i), VM.NewJavaLangReflectConstructor(constructor))
        // }

        // return constructorArr
    }

    pub fn getModifiers(ctx: Context, this: JavaLangClass) int {
        _ = ctx;
        const class = this.object().internal.class;
        std.debug.assert(class != null);
        return @intCast(class.?.accessFlags.raw);
        // return Int(u16toi32(this.retrieveType().(*Class).accessFlags))
    }

    pub fn getSuperclass(ctx: Context, this: JavaLangClass) JavaLangClass {
        const class = this.object().internal.class;
        std.debug.assert(class != null);
        if (strings.equals(class.?.name, "java/lang/Object")) {
            return NULL;
        }
        return getJavaLangClass(ctx.c, naming.descriptor(class.?.superClass));
        // class := this.retrieveType().(*Class)
        // if class.name == "java/lang/Object" {
        // 	return NULL
        // }
        // return class.superClass.ClassObject()
    }

    pub fn isArray(ctx: Context, this: JavaLangClass) boolean {
        _ = ctx;
        const class = this.object().internal.class;
        return if (class != null and class.?.isArray) 1 else 0;
        // type0 := this.retrieveType().(Type)
        // switch type0.(type) {
        // case *Class:
        // 	if type0.(*Class).IsArray() {
        // 		return TRUE
        // 	}
        // }
        // return FALSE
    }

    pub fn getComponentType(ctx: Context, this: JavaLangClass) JavaLangClass {
        const class = this.object().internal.class;
        std.debug.assert(class != null and class.?.isArray);
        return getJavaLangClass(ctx.c, class.?.componentType);
        // class := this.retrieveType().(*Class)
        // if !class.IsArray() {
        // 	Fatal("%s is not array type", this.Class().name)
        // }

        // return class.componentType.ClassObject()
    }

    pub fn getEnclosingMethod0(ctx: Context, this: JavaLangClass) ArrayRef {
        _ = ctx;
        _ = this;
        unreachable;

        // //TODO
        // return NULL
    }

    pub fn getDeclaringClass0(ctx: Context, this: JavaLangClass) JavaLangClass {
        _ = ctx;
        _ = this;
        unreachable;

        // //TODO
        // return NULL
    }
};
const java_lang_ClassLoader = struct {
    pub fn registerNatives(ctx: Context) void {
        _ = ctx;
        // TODO
    }

    pub fn findBuiltinLib(ctx: Context, name: JavaLangString) JavaLangString {
        _ = ctx;
        _ = name;
        unreachable;
        // return name
    }

    pub fn NativeLibrary_load(ctx: Context, this: JavaLangClassLoader, name: JavaLangString, flag: boolean) void {
        _ = ctx;
        _ = flag;
        _ = name;
        _ = this;
        // DO NOTHING
    }
    pub fn findLoadedClass0(ctx: Context, this: JavaLangClassLoader, className: JavaLangString) JavaLangClass {
        _ = ctx;
        _ = className;
        _ = this;
        unreachable;
        // name := javaNameToBinaryName(className)
        // var C = NULL
        // if class, ok := VM.getInitiatedClass(name, this); ok {
        // 	C = class.ClassObject()
        // }
        // if C.IsNull() {
        // 	VM.Info("  ***findLoadedClass0() %s fail [%s] \n", name, this.Class().name)
        // } else {
        // 	VM.Info("  ***findLoadedClass0() %s success [%s] \n", name, this.Class().name)
        // }
        // return C
    }
    pub fn findBootstrapClass(ctx: Context, this: JavaLangClassLoader, className: JavaLangString) JavaLangClass {
        _ = ctx;
        _ = className;
        _ = this;
        unreachable;
        // name := javaNameToBinaryName(className)
        // var C = NULL
        // if class, ok := VM.GetDefinedClass(name, NULL); ok {
        // 	C = class.ClassObject()
        // 	VM.Info("  ***findBootstrapClass() %s success [%s] *c=%p jc=%p \n", name, this.Class().name, class, class.classObject.oop)
        // } else {
        // 	c := VM.createClass(name, NULL, TRIGGER_BY_CHECK_OBJECT_TYPE)
        // 	if c != nil {
        // 		C = c.ClassObject()
        // 	}
        // }

        // return C
    }
    pub fn defineClass1(ctx: Context, this: JavaLangClassLoader, className: JavaLangString, byteArrRef: ArrayRef, offset: int, length: int, pd: Reference, source: JavaLangString) JavaLangClass {
        _ = ctx;
        _ = source;
        _ = pd;
        _ = length;
        _ = offset;
        _ = byteArrRef;
        _ = className;
        _ = this;
        unreachable;
        // byteArr := byteArrRef.ArrayElements()[offset : offset+length]
        // bytes := make([]byte, length)
        // for i, b := range byteArr {
        // 	bytes[i] = byte(b.(Byte))
        // }

        // C := VM.deriveClass(javaNameToBinaryName(className), this, bytes, TRIGGER_BY_JAVA_CLASSLOADER)
        // //VM.link(C)

        // // associate JavaLangClass object
        // //class.classObject = VM.getJavaLangClass(class)
        // //// specify its defining classloader
        // C.ClassObject().SetInstanceVariableByName("classLoader", "Ljava/lang/ClassLoader;", this)
        // VM.Info("  ==after java.lang.ClassLoader#defineClass1  %s *c=%p (derived) jc=%p \n", C.name, C, C.ClassObject().oop)

        // //C.sourceFile = source.toNativeString() + C.Name() + ".java"

        // return C.ClassObject()
    }
};
const java_lang_Package = struct {
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
};
const java_lang_String = struct {
    pub fn intern(ctx: Context, this: JavaLangString) JavaLangString {
        _ = ctx;
        return internString(this);
        // return VM.InternString(this)
    }
};
const java_lang_Float = struct { // public static native int floatToRawIntBits(float value)
    pub fn floatToRawIntBits(ctx: Context, value: float) int {
        _ = ctx;
        return @bitCast(value);
        // bits := math.Float32bits(float32(value))
        // return Int(int32(bits))
    }

    pub fn intBitsToFloat(ctx: Context, bits: int) float {
        _ = ctx;
        return @bitCast(bits);
        // value := math.Float32frombits(uint32(bits))
        // return Float(value)
    }
};
const java_lang_Double = struct {
    // public static native int floatToRawIntBits(float value)
    pub fn doubleToRawLongBits(ctx: Context, value: double) long {
        _ = ctx;
        return @bitCast(value);
        // bits := math.Float64bits(float64(value))
        // return Long(int64(bits))
    }

    // public static native int floatToRawIntBits(float value)
    pub fn longBitsToDouble(ctx: Context, bits: long) double {
        _ = ctx;
        return @bitCast(bits);
        // value := math.Float64frombits(uint64(bits)) // todo
        // return Double(value)
    }
};
const java_lang_Thread = struct {
    // private static void registerNatives()
    pub fn registerNatives(ctx: Context) void {
        _ = ctx;
    }

    pub fn currentThread(ctx: Context) JavaLangThread {
        return newJavaLangThread(ctx.c, ctx.t);
        // return VM.CurrentThread().threadObject
    }

    pub fn setPriority0(ctx: Context, this: Reference, priority: int) void {
        _ = ctx;
        _ = priority;
        _ = this;
        // if priority < 1 {
        // 	this.SetInstanceVariableByName("priority", "I", Int(5))
        // }

    }

    pub fn isAlive(ctx: Context, this: Reference) boolean {
        _ = this;
        _ = ctx;
        return 0;
        // return FALSE
    }

    pub fn start0(ctx: Context, this: Reference) void {
        _ = ctx;
        _ = this;
        // if this.Class().name == "java/lang/ref/Reference$ReferenceHandler" {
        // 	return // TODO hack: ignore these threads
        // }
        // name := this.GetInstanceVariableByName("name", "Ljava/lang/String;").(JavaLangString).toNativeString()
        // runMethod := this.Class().GetMethod("run", "()V")

        // thread := VM.NewThread(name, func() {
        // 	VM.InvokeMethod(runMethod, this)
        // }, func() {})

        // thread.threadObject = this
        // thread.start()
    }

    pub fn sleep(ctx: Context, millis: long) void {
        _ = ctx;
        _ = millis;
        // thread := VM.CurrentThread()
        // interrupted := thread.sleep(int64(millis))
        // if interrupted {
        // 	VM.Throw("java/lang/InterruptedException", "sleep interrupted")
        // }
    }

    pub fn interrupt0(ctx: Context, this: JavaLangThread) void {
        _ = ctx;
        _ = this;
        // thread := this.retrieveThread()
        // thread.interrupt()
    }

    pub fn isInterrupted(ctx: Context, this: JavaLangThread, clearInterrupted: boolean) boolean {
        _ = ctx;
        _ = clearInterrupted;
        _ = this;
        unreachable;
        // interrupted := false
        // if this.retrieveThread().interrupted {
        // 	interrupted = true
        // }
        // if clearInterrupted.IsTrue() {
        // 	this.retrieveThread().interrupted = false
        // }
        // if interrupted {
        // 	return TRUE
        // }
        // return FALSE
    }
};
const java_lang_Throwable = struct {
    pub fn getStackTraceDepth(ctx: Context, this: Reference) int {
        _ = ctx;
        _ = this;
        unreachable;
        // thread := VM.CurrentThread()
        // return Int(len(thread.vmStack) - this.Class().InheritanceDepth()) // skip how many frames
    }

    pub fn fillInStackTrace(ctx: Context, this: JavaLangThrowable, dummy: int) Reference {
        _ = dummy;

        var depth: usize = 1; // exception inheritance until object
        var class = this.class();
        while (true) {
            if (strings.equals(class.superClass, "")) {
                break;
            }
            class = resolveClass(ctx.c, class.superClass);
            depth += 1;
        }
        const len = ctx.t.depth() - depth;

        const stackTrace = newArray(ctx.c, "[Ljava/lang/StackTraceElement;", jlen(len));
        for (0..len) |i| {
            const frame = ctx.t.stack.items[i];
            const stackTraceElement = newObject(ctx.c, "java/lang/StackTraceElement");
            setInstanceVar(stackTraceElement, "declaringClass", "Ljava/lang/String;", .{ .ref = getJavaLangString(ctx.c, frame.class.name) });
            setInstanceVar(stackTraceElement, "methodName", "Ljava/lang/String;", .{ .ref = getJavaLangString(ctx.c, frame.method.name) });
            setInstanceVar(stackTraceElement, "fileName", "Ljava/lang/String;", .{ .ref = getJavaLangString(ctx.c, "") });
            setInstanceVar(stackTraceElement, "lineNumber", "I", .{ .int = @intCast(frame.pc) }); // FIXME
            stackTrace.set(jsize(len - 1 - i), .{ .ref = stackTraceElement });
        }

        this.object().internal.stackTrace = stackTrace;

        // ⚠️⚠️⚠️ we are unable to set stackTrace in throwable.stackTrace, as a following instruction sets its value to empty Throwable.UNASSIGNED_STACK
        // ⚠️⚠️⚠️ setInstanceVar(this, "stackTrace", "[Ljava/lang/StackTraceElement;", .{ .ref = stackTrace });

        return this;

        // thread := VM.CurrentThread()

        // depth := len(thread.vmStack) - this.Class().InheritanceDepth() // skip how many frames
        // //backtrace := NewArray("[Ljava/lang/String;", Int(depth))
        // //
        // //for i, frame := range thread.vmStack[:depth] {
        // //	javaClassName := strings.Replace(frame.method.class.name, "/", ".", -1)
        // //	str := getJavaLangString(javaClassName + "." + frame.method.name + frame.getSourceFileAndLineNumber(this))
        // //	backtrace.SetArrayElement(Int(depth-1-i), str)
        // //}
        // //
        // //this.SetInstanceVariableByName("backtrace", "Ljava/lang/Object;", backtrace)

        // backtrace := make([]StackTraceElement, depth)

        // for i, frame := range thread.vmStack[:depth] {
        // 	javaClassName := strings.Replace(frame.method.class.name, "/", ".", -1)
        // 	methodName := frame.method.name
        // 	fileName := frame.getSourceFile()
        // 	lineNumber := frame.getLineNumber()
        // 	backtrace[depth-1-i] = StackTraceElement{javaClassName, methodName, fileName, lineNumber}
        // }

        // this.attachStacktrace(backtrace)

        // return this
    }

    pub fn getStackTraceElement(ctx: Context, this: JavaLangThrowable, i: int) ObjectRef {
        _ = ctx;
        _ = i;
        _ = this;
        unreachable;
        // stacktraceelement := this.retrieveStacktrace()[i]

        // ste := VM.NewObjectOfName("java/lang/StackTraceElement")
        // ste.SetInstanceVariableByName("declaringClass", "Ljava/lang/String;", VM.getJavaLangString(stacktraceelement.declaringClass))
        // ste.SetInstanceVariableByName("methodName", "Ljava/lang/String;", VM.getJavaLangString(stacktraceelement.methodName))
        // ste.SetInstanceVariableByName("fileName", "Ljava/lang/String;", VM.getJavaLangString(stacktraceelement.fileName))
        // ste.SetInstanceVariableByName("lineNumber", "I", Int(stacktraceelement.lineNumber))

        // return ste
    }
};
const java_lang_Runtime = struct {
    pub fn availableProcessors(ctx: Context, this: Reference) int {
        _ = ctx;
        _ = this;
        // TODO
        return 4;
        // return Int(runtime.NumCPU())
    }
};
const java_lang_StrictMath = struct {
    // private static void registers()
    pub fn pow(ctx: Context, base: double, exponent: double) double {
        _ = ctx;
        _ = exponent;
        _ = base;
        // return Double(math.Pow(float64(base), float64(exponent)))
        unreachable;
    }
};
const java_security_AccessController = struct {
    // because here need to call java method, so the return value will automatically be placed in the stack
    pub fn doPrivileged(ctx: Context, action: Reference) Reference {
        const method = action.class().method("run", "()Ljava/lang/Object;", false).?;
        const args = vm_make(Value, method.parameterDescriptors.len + 1);
        defer vm_free(args);
        args[0] = .{ .ref = action };
        ctx.t.invoke(action.class(), method, args);
        std.debug.assert(ctx.t.active().?.stack.items.len > 0); // assume no exception for the above method call
        return ctx.t.active().?.pop().as(Reference).ref;
        // method := action.Class().FindMethod("run", "()Ljava/lang/Object;")
        // return VM.InvokeMethod(method, action).(Reference)
    }

    pub fn getStackAccessControlContext(ctx: Context) Reference {
        _ = ctx;
        return NULL;

        // //TODO
        // return NULL
    }

    pub fn doPrivilegedContext(ctx: Context, action: Reference, context: Reference) Reference {
        _ = context;
        return doPrivileged(ctx, action);
    }
};
const java_lang_reflect_Array = struct {
    pub fn newArray(ctx: Context, componentClassObject: JavaLangClass, length: int) ArrayRef {
        _ = ctx;
        _ = length;
        _ = componentClassObject;
        // componentType := componentClassObject.retrieveType()

        // return VM.NewArrayOfComponent(componentType, length)
        unreachable;
    }
};
const sun_misc_VM = struct {
    // private static void registerNatives()
    pub fn initialize(ctx: Context) void {
        _ = ctx;
    }
};
const sun_misc_Unsafe = struct {
    // private static void registerNatives()
    pub fn registerNatives(ctx: Context) void {
        _ = ctx;
    }

    pub fn arrayBaseOffset(ctx: Context, this: Reference, arrayClass: JavaLangClass) int {
        _ = ctx;
        _ = arrayClass;
        _ = this;
        return 0;
        // //todo
        // return Int(0)
    }

    pub fn arrayIndexScale(ctx: Context, this: Reference, arrayClass: JavaLangClass) int {
        _ = ctx;
        _ = arrayClass;
        _ = this;
        return 1;
        // //todo
        // return Int(1)
    }

    pub fn addressSize(ctx: Context, this: Reference) int {
        _ = ctx;
        _ = this;
        return 8;
        // //todo
        // return Int(8)
    }

    pub fn objectFieldOffset(ctx: Context, this: Reference, fieldObject: Reference) long {
        _ = this;
        _ = ctx;
        return getInstanceVar(fieldObject, "slot", "I").int;

        // slot := fieldObject.GetInstanceVariableByName("slot", "I").(Int)
        // return Long(slot)
    }

    pub fn compareAndSwapObject(ctx: Context, this: Reference, obj: Reference, offset: long, expected: Reference, newVal: Reference) boolean {
        _ = this;
        _ = ctx;
        std.debug.assert(obj.nonNull());

        const current = obj.get(@intCast(offset)).ref;
        if (current.equals(expected)) {
            obj.set(@intCast(offset), .{ .ref = newVal });

            return 1;
        }
        return 0;
        // if obj.IsNull() {
        // 	VM.Throw("java/lang/NullPointerException", "")
        // }

        // slots := obj.oop.slots
        // current := slots[offset]
        // if current == expected {
        // 	slots[offset] = newVal
        // 	return TRUE
        // }

        // return FALSE
    }

    pub fn compareAndSwapInt(ctx: Context, this: Reference, obj: Reference, offset: long, expected: int, newVal: int) boolean {
        _ = this;
        _ = ctx;
        std.debug.assert(obj.nonNull());

        const current = obj.get(@intCast(offset)).int;
        if (current == expected) {
            obj.set(@intCast(offset), .{ .int = newVal });
            return 1;
        }

        return 0;

        // if obj.IsNull() {
        // 	VM.Throw("java/lang/NullPointerException", "")
        // }

        // slots := obj.oop.slots
        // current := slots[offset]
        // if current == expected {
        // 	slots[offset] = newVal
        // 	return TRUE
        // }

        // return FALSE
    }

    pub fn compareAndSwapLong(ctx: Context, this: Reference, obj: Reference, offset: long, expected: long, newVal: long) boolean {
        _ = this;
        _ = ctx;
        std.debug.assert(obj.nonNull());

        const current = obj.get(@intCast(offset)).long;
        if (current == expected) {
            obj.set(@intCast(offset), .{ .long = newVal });
            return 1;
        }

        return 0;
        // if obj.IsNull() {
        // 	VM.Throw("java/lang/NullPointerException", "")
        // }

        // slots := obj.oop.slots
        // current := slots[offset]
        // if current == expected {
        // 	slots[offset] = newVal
        // 	return TRUE
        // }

        // return FALSE
    }

    pub fn getIntVolatile(ctx: Context, this: Reference, obj: Reference, offset: long) int {
        _ = this;
        _ = ctx;
        std.debug.assert(obj.nonNull());

        return obj.get(@intCast(offset)).int;
        // if obj.IsNull() {
        // 	VM.Throw("java/lang/NullPointerException", "")
        // }

        // slots := obj.oop.slots
        // return slots[offset].(Int)
    }

    pub fn getObjectVolatile(ctx: Context, this: Reference, obj: Reference, offset: long) Reference {
        _ = ctx;
        _ = this;
        return obj.get(@intCast(offset)).ref;
        // slots := obj.oop.slots
        // return slots[offset].(Reference)
    }

    pub fn putObjectVolatile(ctx: Context, this: Reference, obj: Reference, offset: long, val: Reference) void {
        _ = ctx;
        _ = val;
        _ = offset;
        _ = obj;
        _ = this;
        unreachable;
        // slots := obj.oop.slots
        // slots[offset] = val
    }

    pub fn allocateMemory(ctx: Context, this: Reference, size: long) long {
        _ = this;
        _ = ctx;
        const mem = vm_make(u8, @intCast(size));
        const addr = &mem[0];

        std.log.info("allocate {d} bytes from off-heap memory at 0x{x:0>8}", .{ size, addr });
        return @intCast(@intFromPtr(addr));
        // //TODO
        // return size
    }

    pub fn putLong(ctx: Context, this: Reference, address: long, val: long) void {
        _ = this;
        _ = ctx;
        const addr: usize = @intCast(address);
        const ptr: [*]u8 = @ptrFromInt(addr);
        const value: u64 = @bitCast(val);
        for (0..8) |i| {
            const sh: u6 = @intCast((7 - i) * 8);
            const b: u8 = @truncate((value >> sh) & 0xFF);
            ptr[i] = b;
        }

        std.log.info("put long 0x{x:0>8} from off-heap memory at 0x{x:0>8}", .{ val, addr });
        // //TODO
    }

    pub fn getByte(ctx: Context, this: Reference, address: long) byte {
        _ = this;
        _ = ctx;

        const addr: usize = @intCast(address);
        const ptr: *u8 = @ptrFromInt(addr);
        const b: i8 = @bitCast(ptr.*);

        std.log.info("get a byte 0x{x:0>2} from off-heap memory at 0x{x:0>8}", .{ b, addr });
        return b;
        // //TODO
        // return Byte(0x08) //0x01 big_endian
    }

    pub fn freeMemory(ctx: Context, this: Reference, size: long) void {
        _ = ctx;
        _ = size;
        _ = this;
        // // do nothing
    }

    pub fn ensureClassInitialized(ctx: Context, this: Reference, class: JavaLangClass) void {
        _ = ctx;
        _ = class;
        _ = this;
        // // LOCK ???
        // if class.retrieveType().(*Class).initialized != INITIALIZED {
        // 	VM.Throw("java/lang/AssertionError", "Class has not been initialized")
        // }
    }
};
const sun_reflect_Reflection = struct {
    pub fn getCallerClass(ctx: Context) JavaLangClass {
        const len = ctx.t.stack.items.len;
        if (len < 2) {
            return NULL;
        } else {
            const name = ctx.t.stack.items[len - 2].class.name;
            const descriptor = strings.concat(&[_]string{ "L", name, ";" });
            defer vm_free(descriptor);
            return getJavaLangClass(ctx.c, descriptor);
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
        const class = classObj.object().internal.class;
        std.debug.assert(class != null);
        return @intCast(class.?.accessFlags.raw);
        // return Int(u16toi32(classObj.retrieveType().(*Class).accessFlags))
    }
};
const sun_reflect_NativeConstructorAccessorImpl = struct {
    pub fn newInstance0(ctx: Context, constructor: JavaLangReflectConstructor, args: ArrayRef) ObjectRef {
        const clazz = getInstanceVar(constructor, "clazz", "Ljava/lang/Class;").ref;
        const class = clazz.object().internal.class;
        std.debug.assert(class != null);
        const desc = getInstanceVar(constructor, "signature", "Ljava/lang/String;").ref;
        const descriptor = toString(desc);
        const method = class.?.method("<init>", descriptor, false).?;
        const objeref = newObject(ctx.c, class.?.name);

        var arguments: []Value = undefined;
        if (args.nonNull()) {
            arguments = vm_make(Value, args.len() + 1);
            arguments[0] = .{ .ref = objeref };
            for (0..args.len()) |i| {
                arguments[i + 1] = args.get(jlen(i));
            }
        } else {
            var a = [_]Value{.{ .ref = objeref }};
            arguments = &a;
        }
        ctx.t.invoke(class.?, method, arguments);

        return objeref;

        // classObject := constructor.GetInstanceVariableByName("clazz", "Ljava/lang/Class;").(JavaLangClass)
        // class := classObject.retrieveType().(*Class)
        // descriptor := constructor.GetInstanceVariableByName("signature", "Ljava/lang/String;").(JavaLangString).toNativeString()

        // method := class.GetConstructor(descriptor)

        // objeref := VM.NewObject(class)
        // allArgs := []Value{objeref}
        // if !args.IsNull() {
        // 	allArgs = append(allArgs, args.oop.slots...)
        // }

        // VM.InvokeMethod(method, allArgs...)

        // return objeref
    }
};
const sun_misc_URLClassPath = struct {
    pub fn getLookupCacheURLs(ctx: Context, classloader: JavaLangClassLoader) ArrayRef {
        _ = ctx;
        _ = classloader;
        unreachable;
        // return VM.NewArrayOfName("[Ljava/net/URL;", 0)
    }
};
const java_io_FileDescriptor = struct {
    // private static void registers()
    pub fn initIDs(ctx: Context) void {
        _ = ctx;
    }
};
const java_io_FileInputStream = struct {
    pub fn initIDs(ctx: Context) void {
        _ = ctx;

        // // TODO
    }

    pub fn open0(ctx: Context, this: Reference, name: JavaLangString) void {
        _ = ctx;
        _ = name;
        _ = this;
        unreachable;
        // _, error := os.Open(name.toNativeString())
        // if error != nil {
        // 	VM.Throw("java/io/IOException", "Cannot open file: %s", name.toNativeString())
        // }
    }

    pub fn readBytes(ctx: Context, this: Reference, byteArr: ArrayRef, offset: int, length: int) int {
        _ = ctx;
        _ = length;
        _ = offset;
        _ = byteArr;
        _ = this;
        unreachable;

        // var file *os.File

        // fileDescriptor := this.GetInstanceVariableByName("fd", "Ljava/io/FileDescriptor;").(Reference)
        // path := this.GetInstanceVariableByName("path", "Ljava/lang/String;").(JavaLangString)

        // if !path.IsNull() {
        // 	f, err := os.Open(path.toNativeString())
        // 	if err != nil {
        // 		VM.Throw("java/io/IOException", "Cannot open file: %s", path.toNativeString())
        // 	}
        // 	file = f
        // } else if !fileDescriptor.IsNull() {
        // 	fd := fileDescriptor.GetInstanceVariableByName("fd", "I").(Int)
        // 	switch fd {
        // 	case 0:
        // 		file = os.Stdin
        // 	case 1:
        // 		file = os.Stdout
        // 	case 2:
        // 		file = os.Stderr
        // 	default:
        // 		file = os.NewFile(uintptr(fd), "")
        // 	}
        // }

        // if file == nil {
        // 	VM.Throw("java/io/IOException", "File cannot open")
        // }

        // bytes := make([]byte, length)

        // file.Seek(int64(offset), 0)
        // nsize, err := file.Read(bytes)
        // VM.ExecutionEngine.ioLogger.Info("🅹 ⤆ %s - buffer size: %d, offset: %d, len: %d, actual read: %d \n", file.Name(), byteArr.ArrayLength(), offset, length, nsize)
        // if err == nil || nsize == int(length) {
        // 	for i := 0; i < int(length); i++ {
        // 		byteArr.SetArrayElement(offset+Int(i), Byte(bytes[i]))
        // 	}
        // 	return Int(nsize)
        // }

        // VM.Throw("java/io/IOException", err.Error())
        // return -1
    }

    pub fn close0(ctx: Context, this: Reference) void {
        _ = ctx;
        _ = this;

        unreachable;
        // var file *os.File

        // fileDescriptor := this.GetInstanceVariableByName("fd", "Ljava/io/FileDescriptor;").(Reference)
        // path := this.GetInstanceVariableByName("path", "Ljava/lang/String;").(JavaLangString)
        // if !fileDescriptor.IsNull() {
        // 	fd := fileDescriptor.GetInstanceVariableByName("fd", "I").(Int)
        // 	switch fd {
        // 	case 0:
        // 		file = os.Stdin
        // 	case 1:
        // 		file = os.Stdout
        // 	case 2:
        // 		file = os.Stderr
        // 	}
        // } else {
        // 	f, err := os.Open(path.toNativeString())
        // 	if err != nil {
        // 		VM.Throw("java/io/IOException", "Cannot open file: %s", path.toNativeString())
        // 	}
        // 	file = f
        // }

        // err := file.Close()
        // if err != nil {
        // 	VM.Throw("java/io/IOException", "Cannot close file: %s", path)
        // }
    }
};
const java_io_FileOutputStream = struct {
    pub fn initIDs(ctx: Context) void {
        _ = ctx;
        // // TODO
    }

    pub fn writeBytes(ctx: Context, this: Reference, byteArr: ArrayRef, offset: int, length: int, append: boolean) void {
        _ = ctx;

        const fileDescriptor = getInstanceVar(this, "fd", "Ljava/io/FileDescriptor;").ref;
        const path = getInstanceVar(this, "path", "Ljava/lang/String;").ref;
        var file: std.fs.File = undefined;
        if (path.nonNull()) {
            file = std.fs.openFileAbsolute(toString(path), .{ .mode = .read_write }) catch unreachable;
            defer file.close();
        } else if (fileDescriptor.nonNull()) {
            const fd = getInstanceVar(fileDescriptor, "fd", "I").int;
            file = switch (fd) {
                0 => std.io.getStdIn(),
                1 => std.io.getStdErr(),
                2 => std.io.getStdErr(),
                else => unreachable,
            };
        }

        const bytes = vm_make(u8, jlen(length));
        for (0..bytes.len) |i| {
            const j = jlen(i);
            const o = jlen(offset);
            bytes[i] = @bitCast(byteArr.get(j + o).byte);
        }

        if (append == 1) {
            var stat = file.stat() catch unreachable;
            file.seekTo(stat.size) catch unreachable;
        }

        _ = file.writer().print("{s}", .{bytes}) catch unreachable;

        // var file *os.File

        // fileDescriptor := this.GetInstanceVariableByName("fd", "Ljava/io/FileDescriptor;").(Reference)
        // path := this.GetInstanceVariableByName("path", "Ljava/lang/String;").(JavaLangString)

        // if !path.IsNull() {
        // 	f, err := os.Open(path.toNativeString())
        // 	if err != nil {
        // 		VM.Throw("java/lang/IOException", "Cannot open file: %s", path.toNativeString())
        // 	}
        // 	file = f
        // } else if !fileDescriptor.IsNull() {
        // 	fd := fileDescriptor.GetInstanceVariableByName("fd", "I").(Int)
        // 	switch fd {
        // 	case 0:
        // 		file = os.Stdin
        // 	case 1:
        // 		file = os.Stdout
        // 	case 2:
        // 		file = os.Stderr
        // 	default:
        // 		file = os.NewFile(uintptr(fd), "")
        // 	}
        // }

        // if file == nil {
        // 	VM.Throw("java/lang/IOException", "File cannot open")
        // }

        // if append.IsTrue() {
        // 	file.Chmod(os.ModeAppend)
        // }

        // bytes := make([]byte, byteArr.ArrayLength())
        // for i := 0; i < int(byteArr.ArrayLength()); i++ {
        // 	bytes[i] = byte(int8(byteArr.GetArrayElement(Int(i)).(Byte)))
        // }

        // bytes = bytes[offset : offset+length]
        // //ptr := unsafe.Pointer(&bytes)

        // f := bufio.NewWriter(file)
        // defer f.Flush()
        // nsize, err := f.Write(bytes)
        // VM.ExecutionEngine.ioLogger.Info("🅹 ⤇ %s - buffer size: %d, offset: %d, len: %d, actual write: %d \n", file.Name(), byteArr.ArrayLength(), offset, length, nsize)
        // if err == nil {
        // 	return
        // }
        // VM.Throw("java/lang/IOException", "Cannot write to file: %s", file.Name())
    }
};
const java_io_UnixFileSystem = struct {
    pub fn initIDs(ctx: Context) void {
        _ = ctx;
        // // do nothing
    }

    // @Native public static final int BA_EXISTS    = 0x01;
    // @Native public static final int BA_REGULAR   = 0x02;
    // @Native public static final int BA_DIRECTORY = 0x04;
    // @Native public static final int BA_HIDDEN    = 0x08;
    pub fn getBooleanAttributes0(ctx: Context, this: Reference, file: Reference) int {
        _ = ctx;
        _ = file;
        _ = this;
        unreachable;
        // path := file.GetInstanceVariableByName("path", "Ljava/lang/String;").(JavaLangString).toNativeString()
        // fileInfo, err := os.Stat(path)
        // attr := 0
        // if err == nil {
        // 	attr |= 0x01
        // 	if fileInfo.Mode().IsRegular() {
        // 		attr |= 0x02
        // 	}
        // 	if fileInfo.Mode().IsDir() {
        // 		attr |= 0x04
        // 	}
        // 	if hidden, err := IsHidden(path); hidden && err != nil {
        // 		attr |= 0x08
        // 	}
        // 	return Int(attr)
        // }

        // VM.Throw("java/io/IOException", "Cannot get file attributes: %s", path)
        // return -1

    }

    // fn IsHidden(filename :string) (bool, error) {

    // if runtime.GOOS != "windows" {

    // 	// unix/linux file or directory that starts with . is hidden
    // 	if filename[0:1] == "." {
    // 		return true, nil

    // 	} else {
    // 		return false, nil
    // 	}

    // } else {
    // 	log.Fatal("Unable to check if file is hidden under this OS")
    // }
    // return false, nil
    // }

    pub fn canonicalize0(ctx: Context, this: Reference, path: JavaLangString) JavaLangString {
        _ = ctx;
        _ = path;
        _ = this;
        unreachable;
        // return VM.getJavaLangString(filepath.Clean(path.toNativeString()))
    }

    pub fn getLength(ctx: Context, this: Reference, file: Reference) long {
        _ = ctx;
        _ = file;
        _ = this;
        unreachable;
        // path := file.GetInstanceVariableByName("path", "Ljava/lang/String;").(JavaLangString).toNativeString()
        // fileInfo, err := os.Stat(path)
        // if err == nil {
        // 	VM.ExecutionEngine.ioLogger.Info("📒    %s - length %d \n", path, fileInfo.Size())
        // 	return Long(fileInfo.Size())
        // }
        // VM.Throw("java/io/IOException", "Cannot get file length: %s", path)
        // return -1
    }
};
const java_util_concurrent_atomic_AtomicLong = struct {
    pub fn VMSupportsCS8(ctx: Context) boolean {
        _ = ctx;
        return 1;

        // return TRUE
    }
};
const java_util_zip_ZipFile = struct {
    pub fn initIDs(ctx: Context) void {
        _ = ctx;

        // //DO NOTHING
        unreachable;
    }
};
const java_util_TimeZone = struct {
    pub fn getSystemTimeZoneID(ctx: Context, javaHome: JavaLangString) JavaLangString {
        _ = ctx;
        _ = javaHome;
        // loc := time.Local
        // return VM.getJavaLangString(loc.String())
        unreachable;
    }
};
