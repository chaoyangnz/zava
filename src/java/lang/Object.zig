const Context = @import("../../native.zig").Context;
const Reference = @import("../../type.zig").Reference;
const JavaLangClass = @import("../../type.zig").JavaLangClass;
const JavaLangString = @import("../../type.zig").JavaLangString;
const int = @import("../../type.zig").int;
const long = @import("../../type.zig").long;

// private static void registerNatives()
pub fn registerNatives(ctx: Context) void {
    _ = ctx;
}

pub fn hashCode(ctx: Context, this: Reference) int {
    _ = ctx;
    return this.object().header.hashCode;
    // return this.IHashCode()
}

pub fn getClass(ctx: Context, this: Reference) JavaLangClass {
    _ = ctx;
    _ = this;
    unreachable;
    // return this.Class().ClassObject()
}

pub fn clone(ctx: Context, this: Reference) Reference {
    _ = ctx;
    _ = this;
    unreachable;
    // cloneable := VM.ResolveClass("java/lang/Cloneable", TRIGGER_BY_CHECK_OBJECT_TYPE)
    // if !cloneable.IsAssignableFrom(this.Class()) {
    // 	VM.Throw("java/lang/CloneNotSupportedException", "Not implement java.lang.Cloneable")
    // }

    // return this.Clone()
}

pub fn wait(ctx: Context, this: Reference, millis: long) void {
    _ = ctx;
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

pub fn notifyAll(ctx: Context, this: Reference) void {
    _ = ctx;
    _ = this;
    // monitor := this.Monitor()
    // if !monitor.HasOwner(VM.CurrentThread()) {
    // 	VM.Throw("java/lang/IllegalMonitorStateException", "Cannot notifyAll() when not holding a monitor")
    // }

    // monitor.NotifyAll()
}
