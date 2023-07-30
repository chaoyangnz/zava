const std = @import("std");
const Context = @import("../../native.zig").Context;
const Reference = @import("../../type.zig").Reference;
const NULL = @import("../../type.zig").NULL;
const arguments = @import("../../vm.zig").arguments;

// because here need to call java method, so the return value will automatically be placed in the stack
pub fn doPrivileged(ctx: Context, action: Reference) Reference {
    const method = action.class().method("run", "()Ljava/lang/Object;", false).?;
    const args = arguments(method);
    args[0] = .{ .ref = action };
    ctx.t.invoke(action.class(), method, args);
    std.debug.assert(ctx.t.active().?.stack.items.len > 0); // assume no exception for the above method call
    return ctx.t.active().?.pop().as(Reference).ref;
    // method := action.Class().FindMethod("run", "()Ljava/lang/Object;")
    // return VM.InvokeMethod(method, action).(Reference)
}

pub fn getStackAccessControlContext(ctx: Context) Reference {
    _ = ctx;
    return NULL;

    // //TODO
    // return NULL
}

pub fn doPrivilegedContext(ctx: Context, action: Reference, context: Reference) Reference {
    _ = context;
    return doPrivileged(ctx, action);
}
