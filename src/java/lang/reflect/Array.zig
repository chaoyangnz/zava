const Context = @import("../../../native.zig").Context;
const JavaLangClass = @import("../../../type.zig").JavaLangClass;
const ArrayRef = @import("../../../type.zig").ArrayRef;
const int = @import("../../../type.zig").int;

pub fn newArray(ctx: Context, componentClassObject: JavaLangClass, length: int) ArrayRef {
    _ = ctx;
    _ = length;
    _ = componentClassObject;
    // componentType := componentClassObject.retrieveType()

    // return VM.NewArrayOfComponent(componentType, length)
    unreachable;
}
