const Context = @import("../../native.zig").Context;
const Reference = @import("../../type.zig").Reference;
const JavaLangThread = @import("../../type.zig").JavaLangThread;
const int = @import("../../type.zig").int;
const boolean = @import("../../type.zig").boolean;
const long = @import("../../type.zig").long;
const newJavaLangThread = @import("../../intrinsic.zig").newJavaLangThread;

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
