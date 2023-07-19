const Reference = @import("../../value.zig").Reference;
const ObjectRef = @import("../../value.zig").ObjectRef;
const JavaLangThrowable = @import("../../value.zig").JavaLangThrowable;
const int = @import("../../value.zig").int;
const long = @import("../../value.zig").long;

pub fn getStackTraceDepth(this: Reference) int {
    _ = this;
    unreachable;
    // thread := VM.CurrentThread()
    // return Int(len(thread.vmStack) - this.Class().InheritanceDepth()) // skip how many frames
}

pub fn fillInStackTrace(this: Reference, dummy: int) Reference {
    _ = dummy;
    _ = this;
    unreachable;
    // thread := VM.CurrentThread()

    // depth := len(thread.vmStack) - this.Class().InheritanceDepth() // skip how many frames
    // //backtrace := NewArray("[Ljava/lang/String;", Int(depth))
    // //
    // //for i, frame := range thread.vmStack[:depth] {
    // //	javaClassName := strings.Replace(frame.method.class.name, "/", ".", -1)
    // //	str := NewJavaLangString(javaClassName + "." + frame.method.name + frame.getSourceFileAndLineNumber(this))
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

pub fn getStackTraceElement(this: JavaLangThrowable, i: int) ObjectRef {
    _ = i;
    _ = this;
    unreachable;
    // stacktraceelement := this.retrieveStacktrace()[i]

    // ste := VM.NewObjectOfName("java/lang/StackTraceElement")
    // ste.SetInstanceVariableByName("declaringClass", "Ljava/lang/String;", VM.NewJavaLangString(stacktraceelement.declaringClass))
    // ste.SetInstanceVariableByName("methodName", "Ljava/lang/String;", VM.NewJavaLangString(stacktraceelement.methodName))
    // ste.SetInstanceVariableByName("fileName", "Ljava/lang/String;", VM.NewJavaLangString(stacktraceelement.fileName))
    // ste.SetInstanceVariableByName("lineNumber", "I", Int(stacktraceelement.lineNumber))

    // return ste
}
