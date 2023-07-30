const std = @import("std");
const Context = @import("../../native.zig").Context;
const JavaLangClass = @import("../../type.zig").JavaLangClass;
const JavaLangString = @import("../../type.zig").JavaLangString;
const JavaLangClassLoader = @import("../../type.zig").JavaLangClassLoader;
const boolean = @import("../../type.zig").boolean;
const int = @import("../../type.zig").int;
const ArrayRef = @import("../../type.zig").ArrayRef;
const toString = @import("../../intrinsic.zig").toString;
const newJavaLangClass = @import("../../intrinsic.zig").newJavaLangClass;

// private static void registerNatives()
pub fn registerNatives(ctx: Context) void {
    _ = ctx;
}

// static Class getPrimitiveClass(String name)
pub fn getPrimitiveClass(ctx: Context, name: JavaLangString) JavaLangClass {
    _ = ctx;
    const classname = toString(name);
    if (std.mem.eql(u8, classname, "byte")) {
        return newJavaLangClass(null, "byte");
    }
    if (std.mem.eql(u8, classname, "short")) {
        return newJavaLangClass(null, "short");
    }
    if (std.mem.eql(u8, classname, "char")) {
        return newJavaLangClass(null, "char");
    }
    if (std.mem.eql(u8, classname, "int")) {
        return newJavaLangClass(null, "int");
    }
    if (std.mem.eql(u8, classname, "long")) {
        return newJavaLangClass(null, "long");
    }
    if (std.mem.eql(u8, classname, "float")) {
        return newJavaLangClass(null, "float");
    }
    if (std.mem.eql(u8, classname, "double")) {
        return newJavaLangClass(null, "double");
    }
    if (std.mem.eql(u8, classname, "boolean")) {
        return newJavaLangClass(null, "boolean");
    }
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
pub fn desiredAssertionStatus0(ctx: Context, clazz: JavaLangClass) boolean {
    _ = ctx;
    _ = clazz;
    // // Always disable assertions
    return 0;
}

pub fn getDeclaredFields0(ctx: Context, this: JavaLangClass, publicOnly: boolean) ArrayRef {
    _ = ctx;
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

pub fn isPrimitive(ctx: Context, this: JavaLangClass) boolean {
    _ = ctx;
    _ = this;
    unreachable;
    // type_ := this.retrieveType()
    // if _, ok := type_.(*Class); ok {
    // 	return FALSE
    // }
    // return TRUE
}

pub fn isAssignableFrom(ctx: Context, this: JavaLangClass, cls: JavaLangClass) boolean {
    _ = ctx;
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

pub fn getName0(ctx: Context, this: JavaLangClass) JavaLangString {
    _ = ctx;
    _ = this;
    unreachable;
    // return binaryNameToJavaName(this.retrieveType().Name())
}

pub fn forName0(ctx: Context, name: JavaLangString, initialize: boolean, loader: JavaLangClassLoader, caller: JavaLangClass) JavaLangClass {
    _ = caller;
    _ = loader;
    _ = initialize;
    return newJavaLangClass(ctx.c, toString(name));
    // className := javaNameToBinaryName(name)
    // return VM.ResolveClass(className, TRIGGER_BY_JAVA_REFLECTION).ClassObject()
}

pub fn isInterface(ctx: Context, this: JavaLangClass) boolean {
    _ = ctx;
    _ = this;
    unreachable;
    // if this.retrieveType().(*Class).IsInterface() {
    // 	return TRUE
    // }
    // return FALSE
}

pub fn getDeclaredConstructors0(ctx: Context, this: JavaLangClass, publicOnly: boolean) ArrayRef {
    _ = ctx;
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

pub fn getModifiers(ctx: Context, this: JavaLangClass) int {
    _ = ctx;
    _ = this;
    unreachable;
    // return Int(u16toi32(this.retrieveType().(*Class).accessFlags))
}

pub fn getSuperclass(ctx: Context, this: JavaLangClass) JavaLangClass {
    _ = ctx;
    _ = this;
    unreachable;
    // class := this.retrieveType().(*Class)
    // if class.name == "java/lang/Object" {
    // 	return NULL
    // }
    // return class.superClass.ClassObject()
}

pub fn isArray(ctx: Context, this: JavaLangClass) boolean {
    _ = ctx;
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

pub fn getComponentType(ctx: Context, this: JavaLangClass) JavaLangClass {
    _ = ctx;
    _ = this;
    unreachable;
    // class := this.retrieveType().(*Class)
    // if !class.IsArray() {
    // 	Fatal("%s is not array type", this.Class().name)
    // }

    // return class.componentType.ClassObject()
}

pub fn getEnclosingMethod0(ctx: Context, this: JavaLangClass) ArrayRef {
    _ = ctx;
    _ = this;
    unreachable;

    // //TODO
    // return NULL
}

pub fn getDeclaringClass0(ctx: Context, this: JavaLangClass) JavaLangClass {
    _ = ctx;
    _ = this;
    unreachable;

    // //TODO
    // return NULL
}
