const register = @import("../../native.zig").register;
const Reference = @import("../../value.zig").Reference;

pub fn init() void {
    register("java/security/AccessController.doPrivileged(Ljava/security/PrivilegedExceptionAction;)Ljava/lang/Object;", doPrivileged);
    register("java/security/AccessController.doPrivileged(Ljava/security/PrivilegedAction;)Ljava/lang/Object;", doPrivileged);
    register("java/security/AccessController.getStackAccessControlContext()Ljava/security/AccessControlContext;", getStackAccessControlContext);
    register("java/security/AccessController.doPrivileged(Ljava/security/PrivilegedExceptionAction;Ljava/security/AccessControlContext;)Ljava/lang/Object;", doPrivilegedContext);
}

// because here need to call java method, so the return value will automatically be placed in the stack
fn doPrivileged(action: Reference) Reference {
    _ = action;
    // method := action.Class().FindMethod("run", "()Ljava/lang/Object;")
    // return VM.InvokeMethod(method, action).(Reference)
}

fn getStackAccessControlContext() Reference {
    // //TODO
    // return NULL
}

fn doPrivilegedContext(action: Reference, context: Reference) Reference {
    _ = context;
    _ = action;
    // return doPrivileged(action)
}
