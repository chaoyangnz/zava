const std = @import("std");
const Context = @import("../../native.zig").Context;
const Reference = @import("../../type.zig").Reference;
const ObjectRef = @import("../../type.zig").ObjectRef;
const JavaLangThrowable = @import("../../type.zig").JavaLangThrowable;
const int = @import("../../type.zig").int;
const long = @import("../../type.zig").long;
const Value = @import("../../type.zig").Value;
const newArray = @import("../../heap.zig").newArray;
const newObject = @import("../../heap.zig").newObject;
const setInstanceVar = @import("../../vm.zig").setInstanceVar;
const getInstanceVar = @import("../../vm.zig").getInstanceVar;
const newJavaLangString = @import("../../intrinsic.zig").newJavaLangString;
const jsize = @import("../../shared.zig").jsize;
const jcount = @import("../../shared.zig").jcount;

pub fn getStackTraceDepth(ctx: Context, this: Reference) int {
    _ = ctx;
    _ = this;
    unreachable;
    // thread := VM.CurrentThread()
    // return Int(len(thread.vmStack) - this.Class().InheritanceDepth()) // skip how many frames
}

pub fn fillInStackTrace(ctx: Context, this: JavaLangThrowable, dummy: int) Reference {
    _ = dummy;

    const stackTrace = newArray(ctx.c, "[Ljava/lang/StackTraceElement;", jcount(ctx.t.depth()));
    for (0..ctx.t.depth()) |i| {
        const frame = ctx.t.stack.items[i];
        const stackTraceElement = newObject(ctx.c, "java/lang/StackTraceElement");
        setInstanceVar(stackTraceElement, "declaringClass", "Ljava/lang/String;", .{ .ref = newJavaLangString(ctx.c, frame.class.name) });
        setInstanceVar(stackTraceElement, "methodName", "Ljava/lang/String;", .{ .ref = newJavaLangString(ctx.c, frame.method.name) });
        setInstanceVar(stackTraceElement, "fileName", "Ljava/lang/String;", .{ .ref = newJavaLangString(ctx.c, "") });
        setInstanceVar(stackTraceElement, "lineNumber", "I", .{ .int = @intCast(frame.pc) }); // FIXME
        stackTrace.set(jsize(ctx.t.depth() - 1 - i), .{ .ref = stackTraceElement });
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

pub fn getStackTraceElement(ctx: Context, this: JavaLangThrowable, i: int) ObjectRef {
    _ = ctx;
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
