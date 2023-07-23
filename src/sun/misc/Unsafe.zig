const Reference = @import("../../type.zig").Reference;
const JavaLangClass = @import("../../type.zig").JavaLangClass;
const int = @import("../../type.zig").int;
const long = @import("../../type.zig").long;
const boolean = @import("../../type.zig").boolean;
const byte = @import("../../type.zig").byte;

// private static void registerNatives()
pub fn registerNatives() void {}

pub fn arrayBaseOffset(this: Reference, arrayClass: JavaLangClass) int {
    _ = arrayClass;
    _ = this;
    unreachable;
    // //todo
    // return Int(0)
}

pub fn arrayIndexScale(this: Reference, arrayClass: JavaLangClass) int {
    _ = arrayClass;
    _ = this;
    unreachable;
    // //todo
    // return Int(1)
}

pub fn addressSize(this: Reference) int {
    _ = this;
    unreachable;
    // //todo
    // return Int(8)
}

pub fn objectFieldOffset(this: Reference, fieldObject: Reference) long {
    _ = fieldObject;
    _ = this;
    unreachable;
    // slot := fieldObject.GetInstanceVariableByName("slot", "I").(Int)
    // return Long(slot)
}

pub fn compareAndSwapObject(this: Reference, obj: Reference, offset: long, expected: Reference, newVal: Reference) boolean {
    _ = newVal;
    _ = expected;
    _ = offset;
    _ = obj;
    _ = this;
    unreachable;
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

pub fn compareAndSwapInt(this: Reference, obj: Reference, offset: long, expected: int, newVal: int) boolean {
    _ = newVal;
    _ = expected;
    _ = offset;
    _ = obj;
    _ = this;
    unreachable;
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

pub fn compareAndSwapLong(this: Reference, obj: Reference, offset: long, expected: long, newVal: long) boolean {
    _ = newVal;
    _ = expected;
    _ = offset;
    _ = obj;
    _ = this;
    unreachable;
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

pub fn getIntVolatile(this: Reference, obj: Reference, offset: long) int {
    _ = offset;
    _ = obj;
    _ = this;
    unreachable;
    // if obj.IsNull() {
    // 	VM.Throw("java/lang/NullPointerException", "")
    // }

    // slots := obj.oop.slots
    // return slots[offset].(Int)
}

pub fn getObjectVolatile(this: Reference, obj: Reference, offset: long) Reference {
    _ = offset;
    _ = obj;
    _ = this;
    unreachable;
    // slots := obj.oop.slots
    // return slots[offset].(Reference)
}

pub fn putObjectVolatile(this: Reference, obj: Reference, offset: long, val: Reference) void {
    _ = val;
    _ = offset;
    _ = obj;
    _ = this;
    // slots := obj.oop.slots
    // slots[offset] = val
}

pub fn allocateMemory(this: Reference, size: long) long {
    _ = size;
    _ = this;
    unreachable;
    // //TODO
    // return size
}

pub fn putLong(this: Reference, address: long, val: long) void {
    _ = val;
    _ = address;
    _ = this;
    // //TODO
}

pub fn getByte(this: Reference, address: long) byte {
    _ = address;
    _ = this;
    unreachable;
    // //TODO
    // return Byte(0x08) //0x01 big_endian
}

pub fn freeMemory(this: Reference, size: long) void {
    _ = size;
    _ = this;
    // // do nothing
}

pub fn ensureClassInitialized(this: Reference, class: JavaLangClass) void {
    _ = class;
    _ = this;
    // // LOCK ???
    // if class.retrieveType().(*Class).initialized != INITIALIZED {
    // 	VM.Throw("java/lang/AssertionError", "Class has not been initialized")
    // }
}
