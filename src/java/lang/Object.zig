const Reference = @import("../../value.zig").Reference;
const JavaLangClass = @import("../../value.zig").JavaLangClass;
const JavaLangString = @import("../../value.zig").JavaLangString;
const int = @import("../../value.zig").int;
const long = @import("../../value.zig").long;

// private static void registerNatives()
pub fn registerNatives() void {}

pub fn hashCode(this: Reference) int {
    _ = this;
    unreachable;
    // return this.IHashCode()
}

pub fn getClass(this: Reference) JavaLangClass {
    _ = this;
    unreachable;
    // return this.Class().ClassObject()
}

pub fn clone(this: Reference) Reference {
    _ = this;
    unreachable;
    // cloneable := VM.ResolveClass("java/lang/Cloneable", TRIGGER_BY_CHECK_OBJECT_TYPE)
    // if !cloneable.IsAssignableFrom(this.Class()) {
    // 	VM.Throw("java/lang/CloneNotSupportedException", "Not implement java.lang.Cloneable")
    // }

    // return this.Clone()
}

pub fn wait(this: Reference, millis: long) void {
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

pub fn notifyAll(this: Reference) void {
    _ = this;
    // monitor := this.Monitor()
    // if !monitor.HasOwner(VM.CurrentThread()) {
    // 	VM.Throw("java/lang/IllegalMonitorStateException", "Cannot notifyAll() when not holding a monitor")
    // }

    // monitor.NotifyAll()
}
