const Reference = @import("../../value.zig").Reference;

// because here need to call java method, so the return value will automatically be placed in the stack
pub fn doPrivileged(action: Reference) Reference {
    _ = action;
    // method := action.Class().FindMethod("run", "()Ljava/lang/Object;")
    // return VM.InvokeMethod(method, action).(Reference)
    unreachable;
}

pub fn getStackAccessControlContext() Reference {

    // //TODO
    // return NULL
    unreachable;
}

pub fn doPrivilegedContext(action: Reference, context: Reference) Reference {
    _ = context;
    _ = action;
    // return doPrivileged(action)
    unreachable;
}
