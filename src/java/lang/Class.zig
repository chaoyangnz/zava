const JavaLangClass = @import("../../type.zig").JavaLangClass;
const JavaLangString = @import("../../type.zig").JavaLangString;
const JavaLangClassLoader = @import("../../type.zig").JavaLangClassLoader;
const boolean = @import("../../type.zig").boolean;
const int = @import("../../type.zig").int;
const ArrayRef = @import("../../type.zig").ArrayRef;

// private static void registerNatives()
pub fn registerNatives() void {}

// static Class getPrimitiveClass(String name)
pub fn getPrimitiveClass(name: JavaLangString) JavaLangClass {
    _ = name;
    unreachable;
    // switch name.toNativeString() {
    // case "byte":
    // 	return BYTE_TYPE.ClassObject()
    // case "short":
    // 	return SHORT_TYPE.ClassObject()
    // case "char":
    // 	return CHAR_TYPE.ClassObject()
    // case "int":
    // 	return INT_TYPE.ClassObject()
    // case "long":
    // 	return LONG_TYPE.ClassObject()
    // case "float":
    // 	return FLOAT_TYPE.ClassObject()
    // case "double":
    // 	return DOUBLE_TYPE.ClassObject()
    // case "boolean":
    // 	return boolean_TYPE.ClassObject()
    // default:
    // 	VM.Throw("java/lang/RuntimeException", "Not a primitive type")
    // }
    // return NULL
}

// private static boolean desiredAssertionStatus0(Class javaClass)
pub fn desiredAssertionStatus0(clazz: JavaLangClass) boolean {
    _ = clazz;
    unreachable;
    // // Always disable assertions
    // return FALSE
}

pub fn getDeclaredFields0(this: JavaLangClass, publicOnly: boolean) ArrayRef {
    _ = publicOnly;
    _ = this;
    unreachable;
    // class := this.retrieveType().(*Class)
    // fields := class.GetDeclaredFields(publicOnly.IsTrue())
    // fieldObjectArr := VM.NewArrayOfName("[Ljava/lang/reflect/Field;", Int(len(fields)))
    // for i, field := range fields {
    // 	fieldObjectArr.SetArrayElement(Int(i), VM.NewJavaLangReflectField(field))
    // }

    // return fieldObjectArr
}

pub fn isPrimitive(this: JavaLangClass) boolean {
    _ = this;
    unreachable;
    // type_ := this.retrieveType()
    // if _, ok := type_.(*Class); ok {
    // 	return FALSE
    // }
    // return TRUE
}

pub fn isAssignableFrom(this: JavaLangClass, cls: JavaLangClass) boolean {
    _ = cls;
    _ = this;
    unreachable;
    // thisClass := this.retrieveType().(*Class)
    // clsClass := cls.retrieveType().(*Class)

    // assignable := FALSE
    // if thisClass.IsAssignableFrom(clsClass) {
    // 	assignable = TRUE
    // }
    // return assignable
}

pub fn getName0(this: JavaLangClass) JavaLangString {
    _ = this;
    unreachable;
    // return binaryNameToJavaName(this.retrieveType().Name())
}

pub fn forName0(name: JavaLangString, initialize: boolean, loader: JavaLangClassLoader, caller: JavaLangClass) JavaLangClass {
    _ = caller;
    _ = loader;
    _ = initialize;
    _ = name;
    unreachable;
    // className := javaNameToBinaryName(name)
    // return VM.ResolveClass(className, TRIGGER_BY_JAVA_REFLECTION).ClassObject()
}

pub fn isInterface(this: JavaLangClass) boolean {
    _ = this;
    unreachable;
    // if this.retrieveType().(*Class).IsInterface() {
    // 	return TRUE
    // }
    // return FALSE
}

pub fn getDeclaredConstructors0(this: JavaLangClass, publicOnly: boolean) ArrayRef {
    _ = publicOnly;
    _ = this;
    unreachable;
    // class := this.retrieveType().(*Class)

    // constructors := class.GetConstructors(publicOnly.IsTrue())

    // constructorArr := VM.NewArrayOfName("[Ljava/lang/reflect/Constructor;", Int(len(constructors)))
    // for i, constructor := range constructors {
    // 	constructorArr.SetArrayElement(Int(i), VM.NewJavaLangReflectConstructor(constructor))
    // }

    // return constructorArr
}

pub fn getModifiers(this: JavaLangClass) int {
    _ = this;
    unreachable;
    // return Int(u16toi32(this.retrieveType().(*Class).accessFlags))
}

pub fn getSuperclass(this: JavaLangClass) JavaLangClass {
    _ = this;
    unreachable;
    // class := this.retrieveType().(*Class)
    // if class.name == "java/lang/Object" {
    // 	return NULL
    // }
    // return class.superClass.ClassObject()
}

pub fn isArray(this: JavaLangClass) boolean {
    _ = this;
    unreachable;
    // type0 := this.retrieveType().(Type)
    // switch type0.(type) {
    // case *Class:
    // 	if type0.(*Class).IsArray() {
    // 		return TRUE
    // 	}
    // }
    // return FALSE
}

pub fn getComponentType(this: JavaLangClass) JavaLangClass {
    _ = this;
    unreachable;
    // class := this.retrieveType().(*Class)
    // if !class.IsArray() {
    // 	Fatal("%s is not array type", this.Class().name)
    // }

    // return class.componentType.ClassObject()
}

pub fn getEnclosingMethod0(this: JavaLangClass) ArrayRef {
    _ = this;
    unreachable;

    // //TODO
    // return NULL
}

pub fn getDeclaringClass0(this: JavaLangClass) JavaLangClass {
    _ = this;
    unreachable;

    // //TODO
    // return NULL
}
