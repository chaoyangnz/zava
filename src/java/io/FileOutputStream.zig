const Context = @import("../../native.zig").Context;
const Reference = @import("../../type.zig").Reference;
const JavaLangString = @import("../../type.zig").JavaLangString;
const ArrayRef = @import("../../type.zig").ArrayRef;
const int = @import("../../type.zig").int;
const boolean = @import("../../type.zig").boolean;

pub fn initIDs(ctx: Context) void {
    _ = ctx;
    // // TODO
}

pub fn writeBytes(ctx: Context, this: Reference, byteArr: ArrayRef, offset: int, length: int, append: boolean) void {
    _ = ctx;
    _ = append;
    _ = length;
    _ = offset;
    _ = byteArr;
    _ = this;
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
