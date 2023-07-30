const Context = @import("../../native.zig").Context;
const Reference = @import("../../type.zig").Reference;
const JavaLangClass = @import("../../type.zig").JavaLangClass;
const int = @import("../../type.zig").int;
const long = @import("../../type.zig").long;
const boolean = @import("../../type.zig").boolean;
const byte = @import("../../type.zig").byte;

// private static void registerNatives()
pub fn registerNatives(ctx: Context) void {
    _ = ctx;
}

pub fn arrayBaseOffset(ctx: Context, this: Reference, arrayClass: JavaLangClass) int {
    _ = ctx;
    _ = arrayClass;
    _ = this;
    return 0;
    // //todo
    // return Int(0)
}

pub fn arrayIndexScale(ctx: Context, this: Reference, arrayClass: JavaLangClass) int {
    _ = ctx;
    _ = arrayClass;
    _ = this;
    return 1;
    // //todo
    // return Int(1)
}

pub fn addressSize(ctx: Context, this: Reference) int {
    _ = ctx;
    _ = this;
    return 8;
    // //todo
    // return Int(8)
}

pub fn objectFieldOffset(ctx: Context, this: Reference, fieldObject: Reference) long {
    _ = ctx;
    _ = fieldObject;
    _ = this;
    unreachable;
    // slot := fieldObject.GetInstanceVariableByName("slot", "I").(Int)
    // return Long(slot)
}

pub fn compareAndSwapObject(ctx: Context, this: Reference, obj: Reference, offset: long, expected: Reference, newVal: Reference) boolean {
    _ = ctx;
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

pub fn compareAndSwapInt(ctx: Context, this: Reference, obj: Reference, offset: long, expected: int, newVal: int) boolean {
    _ = ctx;
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

pub fn compareAndSwapLong(ctx: Context, this: Reference, obj: Reference, offset: long, expected: long, newVal: long) boolean {
    _ = ctx;
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

pub fn getIntVolatile(ctx: Context, this: Reference, obj: Reference, offset: long) int {
    _ = ctx;
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

pub fn getObjectVolatile(ctx: Context, this: Reference, obj: Reference, offset: long) Reference {
    _ = ctx;
    _ = offset;
    _ = obj;
    _ = this;
    unreachable;
    // slots := obj.oop.slots
    // return slots[offset].(Reference)
}

pub fn putObjectVolatile(ctx: Context, this: Reference, obj: Reference, offset: long, val: Reference) void {
    _ = ctx;
    _ = val;
    _ = offset;
    _ = obj;
    _ = this;
    // slots := obj.oop.slots
    // slots[offset] = val
}

pub fn allocateMemory(ctx: Context, this: Reference, size: long) long {
    _ = ctx;
    _ = size;
    _ = this;
    unreachable;
    // //TODO
    // return size
}

pub fn putLong(ctx: Context, this: Reference, address: long, val: long) void {
    _ = ctx;
    _ = val;
    _ = address;
    _ = this;
    // //TODO
}

pub fn getByte(ctx: Context, this: Reference, address: long) byte {
    _ = ctx;
    _ = address;
    _ = this;
    unreachable;
    // //TODO
    // return Byte(0x08) //0x01 big_endian
}

pub fn freeMemory(ctx: Context, this: Reference, size: long) void {
    _ = ctx;
    _ = size;
    _ = this;
    // // do nothing
}

pub fn ensureClassInitialized(ctx: Context, this: Reference, class: JavaLangClass) void {
    _ = ctx;
    _ = class;
    _ = this;
    // // LOCK ???
    // if class.retrieveType().(*Class).initialized != INITIALIZED {
    // 	VM.Throw("java/lang/AssertionError", "Class has not been initialized")
    // }
}
