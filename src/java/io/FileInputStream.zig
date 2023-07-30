const Context = @import("../../native.zig").Context;
const Reference = @import("../../type.zig").Reference;
const JavaLangString = @import("../../type.zig").JavaLangString;
const ArrayRef = @import("../../type.zig").ArrayRef;
const int = @import("../../type.zig").int;

pub fn initIDs(ctx: Context) void {
    _ = ctx;

    // // TODO
}

pub fn open0(ctx: Context, this: Reference, name: JavaLangString) void {
    _ = ctx;
    _ = name;
    _ = this;
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
