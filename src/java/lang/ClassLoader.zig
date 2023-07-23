const JavaLangClass = @import("../../type.zig").JavaLangClass;
const JavaLangString = @import("../../type.zig").JavaLangString;
const JavaLangClassLoader = @import("../../type.zig").JavaLangClassLoader;
const Reference = @import("../../type.zig").Reference;
const ArrayRef = @import("../../type.zig").ArrayRef;
const int = @import("../../type.zig").int;
const boolean = @import("../../type.zig").boolean;

pub fn registerNatives() void {
    // TODO
}

pub fn findBuiltinLib(name: JavaLangString) JavaLangString {
    _ = name;
    unreachable;
    // return name
}

pub fn NativeLibrary_load(this: JavaLangClassLoader, name: JavaLangString, flag: boolean) void {
    _ = flag;
    _ = name;
    _ = this;
    // DO NOTHING
}
pub fn findLoadedClass0(this: JavaLangClassLoader, className: JavaLangString) JavaLangClass {
    _ = className;
    _ = this;
    unreachable;
    // name := javaNameToBinaryName(className)
    // var C = NULL
    // if class, ok := VM.getInitiatedClass(name, this); ok {
    // 	C = class.ClassObject()
    // }
    // if C.IsNull() {
    // 	VM.Info("  ***findLoadedClass0() %s fail [%s] \n", name, this.Class().name)
    // } else {
    // 	VM.Info("  ***findLoadedClass0() %s success [%s] \n", name, this.Class().name)
    // }
    // return C
}
pub fn findBootstrapClass(this: JavaLangClassLoader, className: JavaLangString) JavaLangClass {
    _ = className;
    _ = this;
    unreachable;
    // name := javaNameToBinaryName(className)
    // var C = NULL
    // if class, ok := VM.GetDefinedClass(name, NULL); ok {
    // 	C = class.ClassObject()
    // 	VM.Info("  ***findBootstrapClass() %s success [%s] *c=%p jc=%p \n", name, this.Class().name, class, class.classObject.oop)
    // } else {
    // 	c := VM.createClass(name, NULL, TRIGGER_BY_CHECK_OBJECT_TYPE)
    // 	if c != nil {
    // 		C = c.ClassObject()
    // 	}
    // }

    // return C
}
pub fn defineClass1(this: JavaLangClassLoader, className: JavaLangString, byteArrRef: ArrayRef, offset: int, length: int, pd: Reference, source: JavaLangString) JavaLangClass {
    _ = source;
    _ = pd;
    _ = length;
    _ = offset;
    _ = byteArrRef;
    _ = className;
    _ = this;
    unreachable;
    // byteArr := byteArrRef.ArrayElements()[offset : offset+length]
    // bytes := make([]byte, length)
    // for i, b := range byteArr {
    // 	bytes[i] = byte(b.(Byte))
    // }

    // C := VM.deriveClass(javaNameToBinaryName(className), this, bytes, TRIGGER_BY_JAVA_CLASSLOADER)
    // //VM.link(C)

    // // associate JavaLangClass object
    // //class.classObject = VM.NewJavaLangClass(class)
    // //// specify its defining classloader
    // C.ClassObject().SetInstanceVariableByName("classLoader", "Ljava/lang/ClassLoader;", this)
    // VM.Info("  ==after java.lang.ClassLoader#defineClass1  %s *c=%p (derived) jc=%p \n", C.name, C, C.ClassObject().oop)

    // //C.sourceFile = source.toNativeString() + C.Name() + ".java"

    // return C.ClassObject()
}
