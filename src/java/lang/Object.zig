const register = @import("../../native.zig").register;
const Reference = @import("../../value.zig").Reference;
const JavaLangClass = @import("../../value.zig").JavaLangClass;
const JavaLangString = @import("../../value.zig").JavaLangString;
const int = @import("../../value.zig").int;
const long = @import("../../value.zig").long;

pub fn init() void {
    register("java/lang/Object.registerNatives()V", registerNatives);
    register("java/lang/Object.hashCode()I", hashCode);
    register("java/lang/Object.getClass()Ljava/lang/Class;", getClass);
    register("java/lang/Object.clone()Ljava/lang/Object;", clone);
    register("java/lang/Object.notifyAll()V", notifyAll);
    register("java/lang/Object.wait(J)V", wait);
    register("java/lang/Object.notify()V", notifyAll);
}

// private static void registerNatives()
fn registerNatives() void {}

fn hashCode(this: Reference) int {
    _ = this;
    // return this.IHashCode()
}

fn getClass(this: Reference) JavaLangClass {
    _ = this;
    // return this.Class().ClassObject()
}

fn clone(this: Reference) Reference {
    _ = this;
    // cloneable := VM.ResolveClass("java/lang/Cloneable", TRIGGER_BY_CHECK_OBJECT_TYPE)
    // if !cloneable.IsAssignableFrom(this.Class()) {
    // 	VM.Throw("java/lang/CloneNotSupportedException", "Not implement java.lang.Cloneable")
    // }

    // return this.Clone()
}

fn wait(this: Reference, millis: long) void {
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

fn notifyAll(this: Reference) void {
    _ = this;
    // monitor := this.Monitor()
    // if !monitor.HasOwner(VM.CurrentThread()) {
    // 	VM.Throw("java/lang/IllegalMonitorStateException", "Cannot notifyAll() when not holding a monitor")
    // }

    // monitor.NotifyAll()
}
