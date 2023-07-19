const Reference = @import("../../value.zig").Reference;
const JavaLangThread = @import("../../value.zig").JavaLangThread;
const int = @import("../../value.zig").int;
const boolean = @import("../../value.zig").boolean;
const long = @import("../../value.zig").long;

// private static void registerNatives()
pub fn registerNatives() void {}

pub fn currentThread() JavaLangThread {
    unreachable;
    // return VM.CurrentThread().threadObject
}

pub fn setPriority0(this: Reference, priority: int) void {
    _ = priority;
    _ = this;
    // if priority < 1 {
    // 	this.SetInstanceVariableByName("priority", "I", Int(5))
    // }

}

pub fn isAlive(this: Reference) boolean {
    _ = this;
    unreachable;
    // return FALSE
}

pub fn start0(this: Reference) void {
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

pub fn sleep(millis: long) void {
    _ = millis;
    // thread := VM.CurrentThread()
    // interrupted := thread.sleep(int64(millis))
    // if interrupted {
    // 	VM.Throw("java/lang/InterruptedException", "sleep interrupted")
    // }
}

pub fn interrupt0(this: JavaLangThread) void {
    _ = this;
    // thread := this.retrieveThread()
    // thread.interrupt()
}

pub fn isInterrupted(this: JavaLangThread, clearInterrupted: boolean) boolean {
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
