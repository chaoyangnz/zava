const JavaLangClass = @import("../../../value.zig").JavaLangClass;
const ArrayRef = @import("../../../value.zig").ArrayRef;
const int = @import("../../../value.zig").int;

pub fn newArray(componentClassObject: JavaLangClass, length: int) ArrayRef {
    _ = length;
    _ = componentClassObject;
    // componentType := componentClassObject.retrieveType()

    // return VM.NewArrayOfComponent(componentType, length)
    unreachable;
}
