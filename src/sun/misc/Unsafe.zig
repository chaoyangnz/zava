const register = @import("../../native.zig").register;
const Reference = @import("../../value.zig").Reference;
const JavaLangClass = @import("../../value.zig").JavaLangClass;
const int = @import("../../value.zig").int;
const long = @import("../../value.zig").long;
const boolean = @import("../../value.zig").boolean;
const byte = @import("../../value.zig").byte;

pub fn init() void {
    register("sun/misc/Unsafe.registerNatives()V", registerNatives);
    register("sun/misc/Unsafe.arrayBaseOffset(Ljava/lang/Class;)I", arrayBaseOffset);
    register("sun/misc/Unsafe.arrayIndexScale(Ljava/lang/Class;)I", arrayIndexScale);
    register("sun/misc/Unsafe.addressSize()I", addressSize);
    register("sun/misc/Unsafe.objectFieldOffset(Ljava/lang/reflect/Field;)J", objectFieldOffset);
    register("sun/misc/Unsafe.compareAndSwapObject(Ljava/lang/Object;JLjava/lang/Object;Ljava/lang/Object;)Z", compareAndSwapObject);
    register("sun/misc/Unsafe.getIntVolatile(Ljava/lang/Object;J)I", getIntVolatile);
    register("sun/misc/Unsafe.getObjectVolatile(Ljava/lang/Object;J)Ljava/lang/Object;", getObjectVolatile);
    register("sun/misc/Unsafe.putObjectVolatile(Ljava/lang/Object;JLjava/lang/Object;)V", putObjectVolatile);

    register("sun/misc/Unsafe.compareAndSwapInt(Ljava/lang/Object;JII)Z", compareAndSwapInt);
    register("sun/misc/Unsafe.compareAndSwapLong(Ljava/lang/Object;JJJ)Z", compareAndSwapLong);
    register("sun/misc/Unsafe.allocateMemory(J)J", allocateMemory);
    register("sun/misc/Unsafe.putLong(JJ)V", putLong);
    register("sun/misc/Unsafe.getByte(J)B", getByte);
    register("sun/misc/Unsafe.freeMemory(J)V", freeMemory);

    register("sun/misc/Unsafe.ensureClassInitialized(Ljava/lang/Class;)V", ensureClassInitialized);
}

// private static void registerNatives()
fn registerNatives() void {}

fn arrayBaseOffset(this: Reference, arrayClass: JavaLangClass) int {
    _ = arrayClass;
    _ = this;
    // //todo
    // return Int(0)
}

fn arrayIndexScale(this: Reference, arrayClass: JavaLangClass) int {
    _ = arrayClass;
    _ = this;
    // //todo
    // return Int(1)
}

fn addressSize(this: Reference) int {
    _ = this;
    // //todo
    // return Int(8)
}

fn objectFieldOffset(this: Reference, fieldObject: Reference) long {
    _ = fieldObject;
    _ = this;
    // slot := fieldObject.GetInstanceVariableByName("slot", "I").(Int)
    // return Long(slot)
}

fn compareAndSwapObject(this: Reference, obj: Reference, offset: long, expected: Reference, newVal: Reference) boolean {
    _ = newVal;
    _ = expected;
    _ = offset;
    _ = obj;
    _ = this;
    // if obj.IsNull() {
    // 	VM.Throw("java/lang/NullPointerException", "")
    // }

    // slots := obj.oop.slots
    // current := slots[offset]
    // if current == expected {
    // 	slots[offset] = newVal
    // 	return TRUE
    // }

    // return FALSE
}

fn compareAndSwapInt(this: Reference, obj: Reference, offset: long, expected: int, newVal: int) boolean {
    _ = newVal;
    _ = expected;
    _ = offset;
    _ = obj;
    _ = this;
    // if obj.IsNull() {
    // 	VM.Throw("java/lang/NullPointerException", "")
    // }

    // slots := obj.oop.slots
    // current := slots[offset]
    // if current == expected {
    // 	slots[offset] = newVal
    // 	return TRUE
    // }

    // return FALSE
}

fn compareAndSwapLong(this: Reference, obj: Reference, offset: long, expected: long, newVal: long) boolean {
    _ = newVal;
    _ = expected;
    _ = offset;
    _ = obj;
    _ = this;
    // if obj.IsNull() {
    // 	VM.Throw("java/lang/NullPointerException", "")
    // }

    // slots := obj.oop.slots
    // current := slots[offset]
    // if current == expected {
    // 	slots[offset] = newVal
    // 	return TRUE
    // }

    // return FALSE
}

fn getIntVolatile(this: Reference, obj: Reference, offset: long) int {
    _ = offset;
    _ = obj;
    _ = this;
    // if obj.IsNull() {
    // 	VM.Throw("java/lang/NullPointerException", "")
    // }

    // slots := obj.oop.slots
    // return slots[offset].(Int)
}

fn getObjectVolatile(this: Reference, obj: Reference, offset: long) Reference {
    _ = offset;
    _ = obj;
    _ = this;
    // slots := obj.oop.slots
    // return slots[offset].(Reference)
}

fn putObjectVolatile(this: Reference, obj: Reference, offset: long, val: Reference) void {
    _ = val;
    _ = offset;
    _ = obj;
    _ = this;
    // slots := obj.oop.slots
    // slots[offset] = val
}

fn allocateMemory(this: Reference, size: long) long {
    _ = size;
    _ = this;
    // //TODO
    // return size
}

fn putLong(this: Reference, address: long, val: long) void {
    _ = val;
    _ = address;
    _ = this;
    // //TODO
}

fn getByte(this: Reference, address: long) byte {
    _ = address;
    _ = this;
    // //TODO
    // return Byte(0x08) //0x01 big_endian
}

fn freeMemory(this: Reference, size: long) void {
    _ = size;
    _ = this;
    // // do nothing
}

fn ensureClassInitialized(this: Reference, class: JavaLangClass) void {
    _ = class;
    _ = this;
    // // LOCK ???
    // if class.retrieveType().(*Class).initialized != INITIALIZED {
    // 	VM.Throw("java/lang/AssertionError", "Class has not been initialized")
    // }
}
