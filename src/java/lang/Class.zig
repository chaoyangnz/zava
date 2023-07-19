const register = @import("../../native.zig").register;
const JavaLangClass = @import("../../value.zig").JavaLangClass;
const JavaLangString = @import("../../value.zig").JavaLangString;
const JavaLangClassLoader = @import("../../value.zig").JavaLangClassLoader;
const boolean = @import("../../value.zig").boolean;
const int = @import("../../value.zig").int;
const ArrayRef = @import("../../value.zig").ArrayRef;

pub fn init() void {
    register("java/lang/Class.registerNatives()V", registerNatives);
    register("java/lang/Class.getPrimitiveClass(Ljava/lang/String;)Ljava/lang/Class;", getPrimitiveClass);
    register("java/lang/Class.desiredAssertionStatus0(Ljava/lang/Class;)Z", desiredAssertionStatus0);
    register("java/lang/Class.getDeclaredFields0(Z)[Ljava/lang/reflect/Field;", getDeclaredFields0);
    register("java/lang/Class.isPrimitive()Z", isPrimitive);
    register("java/lang/Class.isAssignableFrom(Ljava/lang/Class;)Z", isAssignableFrom);
    register("java/lang/Class.getName0()Ljava/lang/String;", getName0);
    //register("java/lang/Class.forName0(Ljava/lang/String;ZLjava/lang/ClassLoader;Ljava/lang/Class;)Ljava/lang/Class;", forName0);
    register("java/lang/Class.isInterface()Z", isInterface);
    register("java/lang/Class.getDeclaredConstructors0(Z)[Ljava/lang/reflect/Constructor;", getDeclaredConstructors0);
    register("java/lang/Class.getModifiers()I", getModifiers);
    register("java/lang/Class.getSuperclass()Ljava/lang/Class;", getSuperclass);
    register("java/lang/Class.isArray()Z", isArray);
    register("java/lang/Class.getComponentType()Ljava/lang/Class;", getComponentType);
    register("java/lang/Class.getEnclosingMethod0()[Ljava/lang/Object;", getEnclosingMethod0);
    register("java/lang/Class.getDeclaringClass0()Ljava/lang/Class;", getDeclaringClass0);
    register("java/lang/Class.forName0(Ljava/lang/String;ZLjava/lang/ClassLoader;Ljava/lang/Class;)Ljava/lang/Class;", forName0);
}

// private static void registerNatives()
fn registerNatives() void {}

// static Class getPrimitiveClass(String name)
fn getPrimitiveClass(name: JavaLangString) JavaLangClass {
    _ = name;
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
fn desiredAssertionStatus0(clazz: JavaLangClass) boolean {
    _ = clazz;
    // // Always disable assertions
    // return FALSE
}

fn getDeclaredFields0(this: JavaLangClass, publicOnly: boolean) ArrayRef {
    _ = publicOnly;
    _ = this;
    // class := this.retrieveType().(*Class)
    // fields := class.GetDeclaredFields(publicOnly.IsTrue())
    // fieldObjectArr := VM.NewArrayOfName("[Ljava/lang/reflect/Field;", Int(len(fields)))
    // for i, field := range fields {
    // 	fieldObjectArr.SetArrayElement(Int(i), VM.NewJavaLangReflectField(field))
    // }

    // return fieldObjectArr
}

fn isPrimitive(this: JavaLangClass) boolean {
    _ = this;
    // type_ := this.retrieveType()
    // if _, ok := type_.(*Class); ok {
    // 	return FALSE
    // }
    // return TRUE
}

fn isAssignableFrom(this: JavaLangClass, cls: JavaLangClass) boolean {
    _ = cls;
    _ = this;
    // thisClass := this.retrieveType().(*Class)
    // clsClass := cls.retrieveType().(*Class)

    // assignable := FALSE
    // if thisClass.IsAssignableFrom(clsClass) {
    // 	assignable = TRUE
    // }
    // return assignable
}

fn getName0(this: JavaLangClass) JavaLangString {
    _ = this;
    // return binaryNameToJavaName(this.retrieveType().Name())
}

fn forName0(name: JavaLangString, initialize: boolean, loader: JavaLangClassLoader, caller: JavaLangClass) JavaLangClass {
    _ = caller;
    _ = loader;
    _ = initialize;
    _ = name;
    // className := javaNameToBinaryName(name)
    // return VM.ResolveClass(className, TRIGGER_BY_JAVA_REFLECTION).ClassObject()
}

fn isInterface(this: JavaLangClass) boolean {
    _ = this;
    // if this.retrieveType().(*Class).IsInterface() {
    // 	return TRUE
    // }
    // return FALSE
}

fn getDeclaredConstructors0(this: JavaLangClass, publicOnly: boolean) ArrayRef {
    _ = publicOnly;
    _ = this;
    // class := this.retrieveType().(*Class)

    // constructors := class.GetConstructors(publicOnly.IsTrue())

    // constructorArr := VM.NewArrayOfName("[Ljava/lang/reflect/Constructor;", Int(len(constructors)))
    // for i, constructor := range constructors {
    // 	constructorArr.SetArrayElement(Int(i), VM.NewJavaLangReflectConstructor(constructor))
    // }

    // return constructorArr
}

fn getModifiers(this: JavaLangClass) int {
    _ = this;
    // return Int(u16toi32(this.retrieveType().(*Class).accessFlags))
}

fn getSuperclass(this: JavaLangClass) JavaLangClass {
    _ = this;
    // class := this.retrieveType().(*Class)
    // if class.name == "java/lang/Object" {
    // 	return NULL
    // }
    // return class.superClass.ClassObject()
}

fn isArray(this: JavaLangClass) boolean {
    _ = this;
    // type0 := this.retrieveType().(Type)
    // switch type0.(type) {
    // case *Class:
    // 	if type0.(*Class).IsArray() {
    // 		return TRUE
    // 	}
    // }
    // return FALSE
}

fn getComponentType(this: JavaLangClass) JavaLangClass {
    _ = this;
    // class := this.retrieveType().(*Class)
    // if !class.IsArray() {
    // 	Fatal("%s is not array type", this.Class().name)
    // }

    // return class.componentType.ClassObject()
}

fn getEnclosingMethod0(this: JavaLangClass) ArrayRef {
    _ = this;

    // //TODO
    // return NULL
}

fn getDeclaringClass0(this: JavaLangClass) JavaLangClass {
    _ = this;

    // //TODO
    // return NULL
}
