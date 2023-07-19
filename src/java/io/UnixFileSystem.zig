const register = @import("../../native.zig").register;
const Reference = @import("../../value.zig").Reference;
const int = @import("../../value.zig").int;
const long = @import("../../value.zig").long;
const JavaLangString = @import("../../value.zig").JavaLangString;

pub fn init() void {
    register("java/io/UnixFileSystem.initIDs()V", initIDs);
    register("java/io/UnixFileSystem.canonicalize0(Ljava/lang/String;)Ljava/lang/String;", canonicalize0);
    register("java/io/UnixFileSystem.getBooleanAttributes0(Ljava/io/File;)I", getBooleanAttributes0);
    register("java/io/UnixFileSystem.getLength(Ljava/io/File;)J", getLength);
}

pub fn initIDs() void {
    // // do nothing
}

// @Native public static final int BA_EXISTS    = 0x01;
// @Native public static final int BA_REGULAR   = 0x02;
// @Native public static final int BA_DIRECTORY = 0x04;
// @Native public static final int BA_HIDDEN    = 0x08;
pub fn getBooleanAttributes0(this: Reference, file: Reference) int {
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

pub fn canonicalize0(this: Reference, path: JavaLangString) JavaLangString {
    _ = path;
    _ = this;
    unreachable;
    // return VM.NewJavaLangString(filepath.Clean(path.toNativeString()))
}

pub fn getLength(this: Reference, file: Reference) long {
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
