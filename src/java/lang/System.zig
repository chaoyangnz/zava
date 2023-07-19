const register = @import("../../native.zig").register;
const Reference = @import("../../value.zig").Reference;
const JavaLangClass = @import("../../value.zig").JavaLangClass;
const JavaLangString = @import("../../value.zig").JavaLangString;
const int = @import("../../value.zig").int;
const long = @import("../../value.zig").long;
const ObjectRef = @import("../../value.zig").ObjectRef;
const ArrayRef = @import("../../value.zig").ArrayRef;

pub fn init() void {
    register("java/lang/System.registerNatives()V", registerNatives);
    register("java/lang/System.setIn0(Ljava/io/InputStream;)V", setIn0);
    register("java/lang/System.setOut0(Ljava/io/PrintStream;)V", setOut0);
    register("java/lang/System.setErr0(Ljava/io/PrintStream;)V", setErr0);
    register("java/lang/System.currentTimeMillis()J", currentTimeMillis);
    register("java/lang/System.nanoTime()J", nanoTime);
    register("java/lang/System.arraycopy(Ljava/lang/Object;ILjava/lang/Object;II)V", arraycopy);
    register("java/lang/System.identityHashCode(Ljava/lang/Object;)I", identityHashCode);
    register("java/lang/System.initProperties(Ljava/util/Properties;)Ljava/util/Properties;", initProperties);
    register("java/lang/System.mapLibraryName(Ljava/lang/String;)Ljava/lang/String;", mapLibraryName);
}

// private static void registers()
fn registerNatives() void {}

// private static void setIn0(InputStream is)
fn setIn0(is: ObjectRef) void {
    _ = is;
    // VM.ResolveClass("java/lang/System", TRIGGER_BY_ACCESS_MEMBER).SetStaticVariable("in", "Ljava/io/InputStream;", is)
}

// private static void setOut0(PrintStream ps)
fn setOut0(ps: ObjectRef) void {
    _ = ps;
    // VM.ResolveClass("java/lang/System", TRIGGER_BY_ACCESS_MEMBER).SetStaticVariable("out", "Ljava/io/PrintStream;", ps)
}

// private static void setErr0(PrintStream ps)
fn setErr0(ps: ObjectRef) void {
    _ = ps;
    // VM.ResolveClass("java/lang/System", TRIGGER_BY_ACCESS_MEMBER).SetStaticVariable("err", "Ljava/io/PrintStream;", ps)
}

// public static long currentTimeMillis()
fn currentTimeMillis() long {
    // return VM.CurrentTimeMillis()
}

// public static long nanoTime()
fn nanoTime() long {
    // return VM.CurrentTimeNano()
}

// public static void arraycopy(Object fromArray, int fromIndex, Object toArray, int toIndex, int length)
fn arraycopy(src: ArrayRef, srcPos: int, dest: ArrayRef, destPos: int, length: int) void {
    _ = length;
    _ = destPos;
    _ = dest;
    _ = srcPos;
    _ = src;
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
fn identityHashCode(object: Reference) int {
    _ = object;
    // return object.IHashCode()
}

// private static Properties initProperties(Properties properties)
fn initProperties(properties: ObjectRef) ObjectRef {
    _ = properties;

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
    // 	VM.InvokeMethod(setProperty, properties, VM.NewJavaLangString(key), VM.NewJavaLangString(val))
    // }

    // return properties
}

fn mapLibraryName(name: JavaLangString) JavaLangString {
    _ = name;
    // return name
}