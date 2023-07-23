const JavaLangClass = @import("../../../type.zig").JavaLangClass;
const ArrayRef = @import("../../../type.zig").ArrayRef;
const int = @import("../../../type.zig").int;

pub fn newArray(componentClassObject: JavaLangClass, length: int) ArrayRef {
    _ = length;
    _ = componentClassObject;
    // componentType := componentClassObject.retrieveType()

    // return VM.NewArrayOfComponent(componentType, length)
    unreachable;
}
