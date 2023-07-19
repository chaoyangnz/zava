const register = @import("../../native.zig").register;
const ObjectRef = @import("../../value.zig").ObjectRef;
const ArrayRef = @import("../../value.zig").ArrayRef;
const JavaLangReflectConstructor = @import("../../value.zig").JavaLangReflectConstructor;

pub fn init() void {
    register("sun/reflect/NativeConstructorAccessorImpl.newInstance0(Ljava/lang/reflect/Constructor;[Ljava/lang/Object;)Ljava/lang/Object;", newInstance0);
}

fn newInstance0(constructor: JavaLangReflectConstructor, args: ArrayRef) ObjectRef {
    _ = args;
    _ = constructor;

    // classObject := constructor.GetInstanceVariableByName("clazz", "Ljava/lang/Class;").(JavaLangClass)
    // class := classObject.retrieveType().(*Class)
    // descriptor := constructor.GetInstanceVariableByName("signature", "Ljava/lang/String;").(JavaLangString).toNativeString()

    // method := class.GetConstructor(descriptor)

    // objeref := VM.NewObject(class)
    // allArgs := []Value{objeref}
    // if !args.IsNull() {
    // 	allArgs = append(allArgs, args.oop.slots...)
    // }

    // VM.InvokeMethod(method, allArgs...)

    // return objeref
}
