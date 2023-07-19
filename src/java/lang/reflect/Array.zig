const register = @import("../../../native.zig").register;
const JavaLangClass = @import("../../../value.zig").JavaLangClass;
const ArrayRef = @import("../../../value.zig").ArrayRef;
const int = @import("../../../value.zig").int;

pub fn init() void {
    register("java/lang/reflect/Array.newArray(Ljava/lang/Class;I)Ljava/lang/Object;", newArray);
}

fn newArray(componentClassObject: JavaLangClass, length: int) ArrayRef {
    _ = length;
    _ = componentClassObject;
    // componentType := componentClassObject.retrieveType()

    // return VM.NewArrayOfComponent(componentType, length)
}
