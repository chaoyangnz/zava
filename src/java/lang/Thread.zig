const register = @import("../../native.zig").register;
const Reference = @import("../../value.zig").Reference;
const JavaLangThread = @import("../../value.zig").JavaLangThread;
const int = @import("../../value.zig").int;
const boolean = @import("../../value.zig").boolean;
const long = @import("../../value.zig").long;

pub fn init() void {
    register("java/lang/Thread.registerNatives()V", registerNatives);
    register("java/lang/Thread.currentThread()Ljava/lang/Thread;", currentThread);
    register("java/lang/Thread.setPriority0(I)V", setPriority0);
    register("java/lang/Thread.isAlive()Z", isAlive);
    register("java/lang/Thread.start0()V", start0);
    register("java/lang/Thread.sleep(J)V", sleep);
    register("java/lang/Thread.interrupt0()V", interrupt0);
    register("java/lang/Thread.isInterrupted(Z)Z", isInterrupted);
}

// private static void registerNatives()
fn registerNatives() void {}

fn currentThread() JavaLangThread {
    // return VM.CurrentThread().threadObject
}

fn setPriority0(this: Reference, priority: int) void {
    _ = priority;
    _ = this;
    // if priority < 1 {
    // 	this.SetInstanceVariableByName("priority", "I", Int(5))
    // }

}

fn isAlive(this: Reference) boolean {
    _ = this;
    // return FALSE
}

fn start0(this: Reference) void {
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

fn sleep(millis: long) void {
    _ = millis;
    // thread := VM.CurrentThread()
    // interrupted := thread.sleep(int64(millis))
    // if interrupted {
    // 	VM.Throw("java/lang/InterruptedException", "sleep interrupted")
    // }
}

fn interrupt0(this: JavaLangThread) void {
    _ = this;
    // thread := this.retrieveThread()
    // thread.interrupt()
}

fn isInterrupted(this: JavaLangThread, clearInterrupted: boolean) boolean {
    _ = clearInterrupted;
    _ = this;
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
