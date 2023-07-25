const std = @import("std");
const string = @import("./shared.zig").string;
const concat = @import("./shared.zig").concat;
const Thread = @import("./engine.zig").Thread;
const Frame = @import("./engine.zig").Frame;
const Class = @import("./type.zig").Class;
const Method = @import("./type.zig").Method;
const Value = @import("./type.zig").Value;
const NULL = @import("./type.zig").NULL;
const byte = @import("./type.zig").byte;
const char = @import("./type.zig").char;
const short = @import("./type.zig").short;
const int = @import("./type.zig").int;
const long = @import("./type.zig").long;
const float = @import("./type.zig").float;
const double = @import("./type.zig").double;
const boolean = @import("./type.zig").boolean;
const Reference = @import("./type.zig").Reference;
const ArrayRef = @import("./type.zig").ArrayRef;
const ObjectRef = @import("./type.zig").ObjectRef;
const is = @import("./type.zig").Type.is;
const newObject = @import("./heap.zig").newObject;
const newArray = @import("./heap.zig").newArray;
const make = @import("./shared.zig").make;
const vm_allocator = @import("./shared.zig").vm_allocator;
const resolveClass = @import("./method_area.zig").resolveClass;
const resolveField = @import("./method_area.zig").resolveField;
const resolveMethod = @import("./method_area.zig").resolveMethod;

pub fn fetch(opcode: u8) Instruction {
    return registery[opcode];
}

pub const Instruction = struct {
    mnemonic: string,
    length: u32,
    interpret: *const fn (context: Context) void,
};

const Context = struct {
    t: *Thread,
    f: *Frame,
    c: *const Class,
    m: *const Method,
};

const registery = [_]Instruction{
    // ----- CONSTANTS -----------
    //00 (0x00)
    .{ .mnemonic = "nop", .length = 1, .interpret = nop },
    //01 (0x01)
    .{ .mnemonic = "aconst_null", .length = 1, .interpret = aconst_null },
    //02 (0x02)
    .{ .mnemonic = "iconst_m1", .length = 1, .interpret = iconst_m1 },
    //03 (0x03)
    .{ .mnemonic = "iconst_0", .length = 1, .interpret = iconst_0 },
    //04 (0x04)
    .{ .mnemonic = "iconst_1", .length = 1, .interpret = iconst_1 },
    //05 (0x05)
    .{ .mnemonic = "iconst_2", .length = 1, .interpret = iconst_2 },
    //06 (0x06)
    .{ .mnemonic = "iconst_3", .length = 1, .interpret = iconst_3 },
    //07 (0x07)
    .{ .mnemonic = "iconst_4", .length = 1, .interpret = iconst_4 },
    //08 (0x08)
    .{ .mnemonic = "iconst_5", .length = 1, .interpret = iconst_5 },
    //09 (0x09)
    .{ .mnemonic = "lconst_0", .length = 1, .interpret = lconst_0 },
    //10 (0x0A)
    .{ .mnemonic = "lconst_1", .length = 1, .interpret = lconst_1 },
    //11 (0x0B)
    .{ .mnemonic = "fconst_0", .length = 1, .interpret = fconst_0 },
    //12 (0x0C)
    .{ .mnemonic = "fconst_1", .length = 1, .interpret = fconst_1 },
    //13 (0x0D)
    .{ .mnemonic = "fconst_2", .length = 1, .interpret = fconst_2 },
    //14 (0x0E)
    .{ .mnemonic = "dconst_0", .length = 1, .interpret = dconst_0 },
    //15 (0x0F)
    .{ .mnemonic = "dconst_1", .length = 1, .interpret = dconst_1 },
    //16 (0x10)
    .{ .mnemonic = "bipush", .length = 2, .interpret = bipush },
    //17 (0x11)
    .{ .mnemonic = "sipush", .length = 3, .interpret = sipush },
    //18 (0x12)
    .{ .mnemonic = "ldc", .length = 2, .interpret = ldc },
    //19 (0x13)
    .{ .mnemonic = "ldc_w", .length = 3, .interpret = ldc_w },
    //20 (0x14)
    .{ .mnemonic = "ldc2_w", .length = 3, .interpret = ldc2_w },

    //--------LOADS ----------------
    //21 (0x15)
    .{ .mnemonic = "iload", .length = 2, .interpret = iload },
    //22 (0x16)
    .{ .mnemonic = "lload", .length = 2, .interpret = lload },
    //23 (0x17)
    .{ .mnemonic = "fload", .length = 2, .interpret = fload },
    //24 (0x18)
    .{ .mnemonic = "dload", .length = 2, .interpret = dload },
    //25 (0x19)
    .{ .mnemonic = "aload", .length = 2, .interpret = aload },
    //26 (0x1A)
    .{ .mnemonic = "iload_0", .length = 1, .interpret = iload_0 },
    //27 (0x1B)
    .{ .mnemonic = "iload_1", .length = 1, .interpret = iload_1 },
    //28 (0x1C)
    .{ .mnemonic = "iload_2", .length = 1, .interpret = iload_2 },
    //29 (0x1D)
    .{ .mnemonic = "iload_3", .length = 1, .interpret = iload_3 },
    //30 (0x1E)
    .{ .mnemonic = "lload_0", .length = 1, .interpret = lload_0 },
    //31 (0x1F)
    .{ .mnemonic = "lload_1", .length = 1, .interpret = lload_1 },
    //32 (0x20)
    .{ .mnemonic = "lload_2", .length = 1, .interpret = lload_2 },
    //33 (0x21)
    .{ .mnemonic = "lload_3", .length = 1, .interpret = lload_3 },
    //34 (0x22)
    .{ .mnemonic = "fload_0", .length = 1, .interpret = fload_0 },
    //35 (0x23)
    .{ .mnemonic = "fload_1", .length = 1, .interpret = fload_1 },
    //36 (0x24)
    .{ .mnemonic = "fload_2", .length = 1, .interpret = fload_2 },
    //37 (0x25)
    .{ .mnemonic = "fload_3", .length = 1, .interpret = fload_3 },
    //38 (0x26)
    .{ .mnemonic = "dload_0", .length = 1, .interpret = dload_0 },
    //39 (0x27)
    .{ .mnemonic = "dload_1", .length = 1, .interpret = dload_1 },
    //40 (0x28)
    .{ .mnemonic = "dload_2", .length = 1, .interpret = dload_2 },
    //41 (0x29)
    .{ .mnemonic = "dload_3", .length = 1, .interpret = dload_3 },
    //42 (0x2A)
    .{ .mnemonic = "aload_0", .length = 1, .interpret = aload_0 },
    //43 (0x2B)
    .{ .mnemonic = "aload_1", .length = 1, .interpret = aload_1 },
    //44 (0x2C)
    .{ .mnemonic = "aload_2", .length = 1, .interpret = aload_2 },
    //45 (0x2D)
    .{ .mnemonic = "aload_3", .length = 1, .interpret = aload_3 },
    //46 (0x2E)
    .{ .mnemonic = "iaload", .length = 1, .interpret = iaload },
    //47 (0x2F)
    .{ .mnemonic = "laload", .length = 1, .interpret = laload },
    //48 (0x30)
    .{ .mnemonic = "faload", .length = 1, .interpret = faload },
    //49 (0x31)
    .{ .mnemonic = "daload", .length = 1, .interpret = daload },
    //50 (0x32)
    .{ .mnemonic = "aaload", .length = 1, .interpret = aaload },
    //51 (0x33)
    .{ .mnemonic = "baload", .length = 1, .interpret = baload },
    //52 (0x34)
    .{ .mnemonic = "caload", .length = 1, .interpret = caload },
    //53 (0x35)
    .{ .mnemonic = "saload", .length = 1, .interpret = saload },

    //--------STORES ----------------
    //54 (0x36)
    .{ .mnemonic = "istore", .length = 2, .interpret = istore },
    //55 (0x37)
    .{ .mnemonic = "lstore", .length = 2, .interpret = lstore },
    //56 (0x38)
    .{ .mnemonic = "fstore", .length = 2, .interpret = fstore },
    //57 (0x39)
    .{ .mnemonic = "dstore", .length = 2, .interpret = dstore },
    //58 (0x3A)
    .{ .mnemonic = "astore", .length = 2, .interpret = astore },
    //59 (0x3B)
    .{ .mnemonic = "istore_0", .length = 1, .interpret = istore_0 },
    //60 (0x3C)
    .{ .mnemonic = "istore_1", .length = 1, .interpret = istore_1 },
    //61 (0x3D)
    .{ .mnemonic = "istore_2", .length = 1, .interpret = istore_2 },
    //62 (0x3E)
    .{ .mnemonic = "istore_3", .length = 1, .interpret = istore_3 },
    //63 (0x3F)
    .{ .mnemonic = "lstore_0", .length = 1, .interpret = lstore_0 },
    //64 (0x40)
    .{ .mnemonic = "lstore_1", .length = 1, .interpret = lstore_1 },
    //65 (0x41)
    .{ .mnemonic = "lstore_2", .length = 1, .interpret = lstore_2 },
    //66 (0x42)
    .{ .mnemonic = "lstore_3", .length = 1, .interpret = lstore_3 },
    //67 (0x43)
    .{ .mnemonic = "fstore_0", .length = 1, .interpret = fstore_0 },
    //68 (0x44)
    .{ .mnemonic = "fstore_1", .length = 1, .interpret = fstore_1 },
    //69 (0x45)
    .{ .mnemonic = "fstore_2", .length = 1, .interpret = fstore_2 },
    //70 (0x46)
    .{ .mnemonic = "fstore_3", .length = 1, .interpret = fstore_3 },
    //71 (0x47)
    .{ .mnemonic = "dstore_0", .length = 1, .interpret = dstore_0 },
    //72 (0x48)
    .{ .mnemonic = "dstore_1", .length = 1, .interpret = dstore_1 },
    //73 (0x49)
    .{ .mnemonic = "dstore_2", .length = 1, .interpret = dstore_2 },
    //74 (0x4A)
    .{ .mnemonic = "dstore_3", .length = 1, .interpret = dstore_3 },
    //75 (0x4B)
    .{ .mnemonic = "astore_0", .length = 1, .interpret = astore_0 },
    //76 (0x4C)
    .{ .mnemonic = "astore_1", .length = 1, .interpret = astore_1 },
    //77 (0x4D)
    .{ .mnemonic = "astore_2", .length = 1, .interpret = astore_2 },
    //78 (0x4E)
    .{ .mnemonic = "astore_3", .length = 1, .interpret = astore_3 },
    //79 (0x4F)
    .{ .mnemonic = "iastore", .length = 1, .interpret = iastore },
    //80 (0x50)
    .{ .mnemonic = "lastore", .length = 1, .interpret = lastore },
    //81 (0x51)
    .{ .mnemonic = "fastore", .length = 1, .interpret = fastore },
    //82 (0x52)
    .{ .mnemonic = "dastore", .length = 1, .interpret = dastore },
    //83 (0x53)
    .{ .mnemonic = "aastore", .length = 1, .interpret = aastore },
    //84 (0x54)
    .{ .mnemonic = "bastore", .length = 1, .interpret = bastore },
    //85 (0x55)
    .{ .mnemonic = "castore", .length = 1, .interpret = castore },
    //86 (0x56)
    .{ .mnemonic = "sastore", .length = 1, .interpret = sastore },

    //--------STACK---------------
    //87 (0x57)
    .{ .mnemonic = "pop", .length = 1, .interpret = pop },
    //88 (0x58)
    .{ .mnemonic = "pop2", .length = 1, .interpret = pop2 },
    //89 (0x59)
    .{ .mnemonic = "dup", .length = 1, .interpret = dup },
    //90 (0x5A)
    .{ .mnemonic = "dup_x1", .length = 1, .interpret = dup_x1 },
    //91 (0x5B)
    .{ .mnemonic = "dup_x2", .length = 1, .interpret = dup_x2 },
    //92 (0x5C)
    .{ .mnemonic = "dup2", .length = 1, .interpret = dup2 },
    //93 (0x5D)
    .{ .mnemonic = "dup2_x1", .length = 1, .interpret = dup2_x1 },
    //94 (0x5E)
    .{ .mnemonic = "dup2_x2", .length = 1, .interpret = dup2_x2 },
    //95 (0x5F)
    .{ .mnemonic = "swap", .length = 1, .interpret = swap },

    //---------MATH -------------
    //96 (0x60)
    .{ .mnemonic = "iadd", .length = 1, .interpret = iadd },
    //97 (0x61)
    .{ .mnemonic = "ladd", .length = 1, .interpret = ladd },
    //98 (0x62)
    .{ .mnemonic = "fadd", .length = 1, .interpret = fadd },
    //99 (0x63)
    .{ .mnemonic = "dadd", .length = 1, .interpret = dadd },
    //100 (0x64)
    .{ .mnemonic = "isub", .length = 1, .interpret = isub },
    //101 (0x65)
    .{ .mnemonic = "lsub", .length = 1, .interpret = lsub },
    //102 (0x66)
    .{ .mnemonic = "fsub", .length = 1, .interpret = fsub },
    //103 (0x67)
    .{ .mnemonic = "dsub", .length = 1, .interpret = dsub },
    //104 (0x68)
    .{ .mnemonic = "imul", .length = 1, .interpret = imul },
    //105 (0x69)
    .{ .mnemonic = "lmul", .length = 1, .interpret = lmul },
    //106 (0x6A)
    .{ .mnemonic = "fmul", .length = 1, .interpret = fmul },
    //107 (0x6B)
    .{ .mnemonic = "dmul", .length = 1, .interpret = dmul },
    //108 (0x6C)
    .{ .mnemonic = "idiv", .length = 1, .interpret = idiv },
    //109 (0x6D)
    .{ .mnemonic = "ldiv", .length = 1, .interpret = ldiv },
    //110 (0x6E)
    .{ .mnemonic = "fdiv", .length = 1, .interpret = fdiv },
    //111 (0x6F)
    .{ .mnemonic = "ddiv", .length = 1, .interpret = ddiv },
    //112 (0x70)
    .{ .mnemonic = "irem", .length = 1, .interpret = irem },
    //113 (0x71)
    .{ .mnemonic = "lrem", .length = 1, .interpret = lrem },
    //114 (0x72)
    .{ .mnemonic = "frem", .length = 1, .interpret = frem },
    //115 (0x73)
    .{ .mnemonic = "drem", .length = 1, .interpret = drem },
    //116 (0x74)
    .{ .mnemonic = "ineg", .length = 1, .interpret = ineg },
    //117 (0x75)
    .{ .mnemonic = "lneg", .length = 1, .interpret = lneg },
    //118 (0x76)
    .{ .mnemonic = "fneg", .length = 1, .interpret = fneg },
    //119 (0x77)
    .{ .mnemonic = "dneg", .length = 1, .interpret = dneg },
    //120 (0x78)
    .{ .mnemonic = "ishl", .length = 1, .interpret = ishl },
    //121 (0x79)
    .{ .mnemonic = "lshl", .length = 1, .interpret = lshl },
    //122 (0x7A)
    .{ .mnemonic = "ishr", .length = 1, .interpret = ishr },
    //123 (0x7B)
    .{ .mnemonic = "lshr", .length = 1, .interpret = lshr },
    //124 (0x7C)
    .{ .mnemonic = "iushr", .length = 1, .interpret = iushr },
    //125 (0x7D)
    .{ .mnemonic = "lushr", .length = 1, .interpret = lushr },
    //126 (0x7E)
    .{ .mnemonic = "iand", .length = 1, .interpret = iand },
    //127 (0x7F)
    .{ .mnemonic = "land", .length = 1, .interpret = land },
    //128 (0x80)
    .{ .mnemonic = "ior", .length = 1, .interpret = ior },
    //129 (0x81)
    .{ .mnemonic = "lor", .length = 1, .interpret = lor },
    //130 (0x82)
    .{ .mnemonic = "ixor", .length = 1, .interpret = ixor },
    //131 (0x83)
    .{ .mnemonic = "lxor", .length = 1, .interpret = lxor },
    //132 (0x84)
    .{ .mnemonic = "iinc", .length = 3, .interpret = iinc },

    //--------CONVERSIONS-----------
    //133 (0x85)
    .{ .mnemonic = "i2l", .length = 1, .interpret = i2l },
    //134 (0x86)
    .{ .mnemonic = "i2f", .length = 1, .interpret = i2f },
    //135 (0x87)
    .{ .mnemonic = "i2d", .length = 1, .interpret = i2d },
    //136 (0x88)
    .{ .mnemonic = "l2i", .length = 1, .interpret = l2i },
    //137 (0x89)
    .{ .mnemonic = "l2f", .length = 1, .interpret = l2f },
    //138 (0x8A)
    .{ .mnemonic = "l2d", .length = 1, .interpret = l2d },
    //139 (0x8B)
    .{ .mnemonic = "f2i", .length = 1, .interpret = f2i },
    //140 (0x8C)
    .{ .mnemonic = "f2l", .length = 1, .interpret = f2l },
    //141 (0x8D)
    .{ .mnemonic = "f2d", .length = 1, .interpret = f2d },
    //142 (0x8E)
    .{ .mnemonic = "d2i", .length = 1, .interpret = d2i },
    //143 (0x8F)
    .{ .mnemonic = "d2l", .length = 1, .interpret = d2l },
    //144 (0x90)
    .{ .mnemonic = "d2f", .length = 1, .interpret = d2f },
    //145 (0x91)
    .{ .mnemonic = "i2b", .length = 1, .interpret = i2b },
    //146 (0x92)
    .{ .mnemonic = "i2c", .length = 1, .interpret = i2c },
    //147 (0x93)
    .{ .mnemonic = "i2s", .length = 1, .interpret = i2s },

    //-----------COMPARASON -----------
    //148 (0x94)
    .{ .mnemonic = "lcmp", .length = 1, .interpret = lcmp },
    //149 (0x95)
    .{ .mnemonic = "fcmpl", .length = 1, .interpret = fcmpl },
    //150 (0x96)
    .{ .mnemonic = "fcmpg", .length = 1, .interpret = fcmpg },
    //151 (0x97)
    .{ .mnemonic = "dcmpl", .length = 1, .interpret = dcmpl },
    //152 (0x98)
    .{ .mnemonic = "dcmpg", .length = 1, .interpret = dcmpg },
    //153 (0x99)
    .{ .mnemonic = "ifeq", .length = 3, .interpret = ifeq },
    //154 (0x9A)
    .{ .mnemonic = "ifne", .length = 3, .interpret = ifne },
    //155 (0x9B)
    .{ .mnemonic = "iflt", .length = 3, .interpret = iflt },
    //156 (0x9C)
    .{ .mnemonic = "ifge", .length = 3, .interpret = ifge },
    //157 (0x9D)
    .{ .mnemonic = "ifgt", .length = 3, .interpret = ifgt },
    //158 (0x9E)
    .{ .mnemonic = "ifle", .length = 3, .interpret = ifle },
    //159 (0x9F)
    .{ .mnemonic = "if_icmpeq", .length = 3, .interpret = if_icmpeq },
    //160 (0xA0)
    .{ .mnemonic = "if_icmpne", .length = 3, .interpret = if_icmpne },
    //161 (0xA1)
    .{ .mnemonic = "if_icmplt", .length = 3, .interpret = if_icmplt },
    //162 (0xA2)
    .{ .mnemonic = "if_icmpge", .length = 3, .interpret = if_icmpge },
    //163 (0xA3)
    .{ .mnemonic = "if_icmpgt", .length = 3, .interpret = if_icmpgt },
    //164 (0xA4)
    .{ .mnemonic = "if_icmple", .length = 3, .interpret = if_icmple },
    //165 (0xA5)
    .{ .mnemonic = "if_acmpeq", .length = 3, .interpret = if_acmpeq },
    //166 (0xA6)
    .{ .mnemonic = "if_acmpne", .length = 3, .interpret = if_acmpne },

    //---------REFERENCES -------------
    //167 (0xA7)
    .{ .mnemonic = "goto", .length = 3, .interpret = goto },
    //168 (0xA8)
    .{ .mnemonic = "jsr", .length = 3, .interpret = jsr },
    //169 (0xA9)
    .{ .mnemonic = "ret", .length = 2, .interpret = ret },
    //170 (0xAA)
    .{ .mnemonic = "tableswitch", .length = 99, .interpret = tableswitch }, // variable bytecode length
    //171 (0xAB)
    .{ .mnemonic = "lookupswitch", .length = 99, .interpret = lookupswitch },
    //172 (0xAC)
    .{ .mnemonic = "ireturn", .length = 1, .interpret = ireturn },
    //173 (0xAD)
    .{ .mnemonic = "lreturn", .length = 1, .interpret = lreturn },
    //174 (0xAE)
    .{ .mnemonic = "freturn", .length = 1, .interpret = freturn },
    //175 (0xAF)
    .{ .mnemonic = "dreturn", .length = 1, .interpret = dreturn },
    //176 (0xB0)
    .{ .mnemonic = "areturn", .length = 1, .interpret = areturn },
    //177 (0xB1)
    .{ .mnemonic = "return", .length = 1, .interpret = return_ },

    //-------CONTROLS------------------
    //178 (0xB2)
    .{ .mnemonic = "getstatic", .length = 3, .interpret = getstatic },
    //179 (0xB3)
    .{ .mnemonic = "putstatic", .length = 3, .interpret = putstatic },
    //180 (0xB4)
    .{ .mnemonic = "getfield", .length = 3, .interpret = getfield },
    //181 (0xB5)
    .{ .mnemonic = "putfield", .length = 3, .interpret = putfield },
    //182 (0xB6)
    .{ .mnemonic = "invokevirtual", .length = 3, .interpret = invokevirtual },
    //183 (0xB7)
    .{ .mnemonic = "invokespecial", .length = 3, .interpret = invokespecial },
    //184 (0xB8)
    .{ .mnemonic = "invokestatic", .length = 3, .interpret = invokestatic },
    //185 (0xB9)
    .{ .mnemonic = "invokeinterface", .length = 5, .interpret = invokeinterface },
    //186 (0xBA)
    .{ .mnemonic = "invokedynamic", .length = 5, .interpret = invokedynamic },
    //187 (0xBB)
    .{ .mnemonic = "new", .length = 3, .interpret = new },
    //188 (0xBC)
    .{ .mnemonic = "newarray", .length = 2, .interpret = newarray },
    //189 (0xBD)
    .{ .mnemonic = "anewarray", .length = 3, .interpret = anewarray },
    //190 (0xBE)
    .{ .mnemonic = "arraylength", .length = 1, .interpret = arraylength },
    //191 (0xBF)
    .{ .mnemonic = "athrow", .length = 1, .interpret = athrow },
    //192 (0xC0)
    .{ .mnemonic = "checkcast", .length = 3, .interpret = checkcast },
    //193 (0xC1)
    .{ .mnemonic = "instanceof", .length = 3, .interpret = instanceof },
    //194 (0xC2)
    .{ .mnemonic = "monitorenter", .length = 1, .interpret = monitorenter },
    //195 (0xC3)
    .{ .mnemonic = "monitorexit", .length = 1, .interpret = monitorexit },

    //--------EXTENDED-----------------
    //196 (0xC4)
    .{ .mnemonic = "wide", .length = 0, .interpret = wide },
    //197 (0xC5)
    .{ .mnemonic = "multianewarray", .length = 4, .interpret = multianewarray },
    //198 (0xC6)
    .{ .mnemonic = "ifnull", .length = 3, .interpret = ifnull },
    //199 (0xC7)
    .{ .mnemonic = "ifnonnull", .length = 3, .interpret = ifnonnull },
    //200 (0xC8)
    .{ .mnemonic = "goto_w", .length = 5, .interpret = goto_w },
    //201 (0xC9)
    .{ .mnemonic = "jsr_w", .length = 5, .interpret = jsr_w },

    //----------RESERVED ---------------
    //202 (0xCA)
    .{ .mnemonic = "breakpoint", .length = 1, .interpret = breakpoint },
    ////254 (0xFE)
    // .{ .mnemonic = "impdep1", .length = 1, .interpret = impdep1 },
    ////255 (0xFF)
    // .{ .mnemonic = "impdep2", .length = 1, .interpret = impdep2 },
};

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.nop
/// Operation
///    Do nothing
/// Format
///    nop
/// Forms
///    nop = 0 (0x0)
/// Operand Stack
///    No change
/// Description
///    Do nothing.
fn nop(ctx: Context) void {
    _ = ctx;
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.aconst_null
/// Operation
///    Push null
/// Format
///    aconst_null
/// Forms
///    aconst_null = 1 (0x1)
/// Operand Stack
///    ... →
///    ..., null
/// Description
///    Push the null object reference onto the operand stack.
/// Notes
///    The Java Virtual Machine does not mandate a concrete value for null.
fn aconst_null(ctx: Context) void {
    ctx.f.push(.{ .ref = NULL });
}

fn iconst_m1(ctx: Context) void {
    ctx.f.push(.{ .int = -1 });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.iconst_i
/// Operation
///    Push int constant
/// Format
///    iconst_<i>
/// Forms
///    iconst_m1 = 2 (0x2)
///    iconst_0 = 3 (0x3)
///    iconst_1 = 4 (0x4)
///    iconst_2 = 5 (0x5)
///    iconst_3 = 6 (0x6)
///    iconst_4 = 7 (0x7)
///    iconst_5 = 8 (0x8)
/// Operand Stack
///    ... →
///    ..., <i>
/// Description
///    Push the int constant <i> (-1, 0, 1, 2, 3, 4 or 5)
///    onto the operand stack.
/// Notes
///    Each of this family of instructions is equivalent to bipush
///    <i> for the respective value of <i>, except
///    that the operand <i> is implicit.
fn iconst_0(ctx: Context) void {
    ctx.f.push(.{ .int = 0 });
}

fn iconst_1(ctx: Context) void {
    ctx.f.push(.{ .int = 1 });
}

fn iconst_2(ctx: Context) void {
    ctx.f.push(.{ .int = 2 });
}

fn iconst_3(ctx: Context) void {
    ctx.f.push(.{ .int = 3 });
}

fn iconst_4(ctx: Context) void {
    ctx.f.push(.{ .int = 4 });
}

fn iconst_5(ctx: Context) void {
    ctx.f.push(.{ .int = 5 });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.lconst_l
/// Operation
///    Push long constant
/// Format
///    lconst_<l>
/// Forms
///    lconst_0 = 9 (0x9)
///    lconst_1 = 10 (0xa)
/// Operand Stack
///    ... →
///    ..., <l>
/// Description
///    Push the long constant <l> (0 or 1) onto the operand
///    stack.
fn lconst_0(ctx: Context) void {
    ctx.f.push(.{ .long = 0 });
}

fn lconst_1(ctx: Context) void {
    ctx.f.push(.{ .long = 1 });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.fconst_f
/// Operation
///    Push float
/// Format
///    fconst_<f>
/// Forms
///    fconst_0 = 11 (0xb)
///    fconst_1 = 12 (0xc)
///    fconst_2 = 13 (0xd)
/// Operand Stack
///    ... →
///    ..., <f>
/// Description
///    Push the float constant <f> (0.0, 1.0, or 2.0) onto
///    the operand stack.
fn fconst_0(ctx: Context) void {
    ctx.f.push(.{ .float = 0.0 });
}

fn fconst_1(ctx: Context) void {
    ctx.f.push(.{ .float = 1.0 });
}

fn fconst_2(ctx: Context) void {
    ctx.f.push(.{ .float = 2.0 });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.dconst_d
/// Operation
///    Push double
/// Format
///    dconst_<d>
/// Forms
///    dconst_0 = 14 (0xe)
///    dconst_1 = 15 (0xf)
/// Operand Stack
///    ... →
///    ..., <d>
/// Description
///    Push the double constant <d> (0.0 or 1.0) onto the
///    operand stack.
fn dconst_0(ctx: Context) void {
    ctx.f.push(.{ .double = 0.0 });
}

fn dconst_1(ctx: Context) void {
    ctx.f.push(.{ .double = 1.0 });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.bipush
/// Operation
///    Push byte
/// Format
///    bipush
///    byte
/// Forms
///    bipush = 16 (0x10)
/// Operand Stack
///    ... →
///    ..., value
/// Description
///    The immediate byte is sign-extended to an
///    int value. That value is pushed onto the operand
///    stack.
fn bipush(ctx: Context) void {
    ctx.f.push(.{ .int = ctx.f.immidiate(i8) });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.sipush
/// Operation
///    Push short
/// Format
///    sipush
///    byte1
///    byte2
/// Forms
///    sipush = 17 (0x11)
/// Operand Stack
///    ... →
///    ..., value
/// Description
///    The immediate unsigned byte1
///    and byte2 values are assembled into an
///    intermediate short, where the value of the short is
///    (byte1 << 8)
///    | byte2. The intermediate value is then
///    sign-extended to an int value. That value is pushed onto the
///    operand stack.
fn sipush(ctx: Context) void {
    ctx.f.push(.{ .int = ctx.f.immidiate(i16) });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.ldc
/// Operation
///    Push item from run-time constant pool
/// Format
///    ldc
///    index
/// Forms
///    ldc = 18 (0x12)
/// Operand Stack
///    ... →
///    ..., value
/// Description
///    The index is an unsigned byte that must be a valid index into
///    the run-time constant pool of the current class
///    (§2.6). The run-time constant pool entry at
///    index either must be a run-time constant of type int or
///    float, or a reference to a string literal, or a symbolic reference
///    to a class, method type, or method handle
///    (§5.1).
///    If the run-time constant pool entry is a run-time constant of type
///    int or float, the numeric value of that run-time constant is
///    pushed onto the operand stack as an int or float,
///    respectively.
///    Otherwise, if the run-time constant pool entry is a reference to an
///    instance of class String representing a string literal
///    (§5.1), then a reference to that instance,
///    value, is pushed onto the operand stack.
///    Otherwise, if the run-time constant pool entry is a symbolic
///    reference to a class (§5.1), then the named
///    class is resolved (§5.4.3.1) and a reference to
///    the Class object representing that class, value, is pushed
///    onto the operand stack.
///    Otherwise, the run-time constant pool entry must be a symbolic
///    reference to a method type or a method handle
///    (§5.1). The method type or method handle is
///    resolved (§5.4.3.5) and a reference to the
///    resulting instance of java.lang.invoke.MethodType or java.lang.invoke.MethodHandle, value, is
///    pushed onto the operand stack.
/// Linking Exceptions
///    During resolution of a symbolic reference to a  class, any of the exceptions pertaining to class
///    resolution (§5.4.3.1) can be thrown.
///    During resolution of a symbolic reference to a method type or
///    method handle, any of the exception pertaining to method type or
///    method handle resolution (§5.4.3.5) can be
///    thrown.
/// Notes
///    The ldc instruction can only be used to push a value of type
///    float taken from the float value set
///    (§2.3.2) because a constant of type float
///    in the constant pool (§4.4.4) must be taken
///    from the float value set.
fn ldc(ctx: Context) void {
    const index = ctx.f.immidiate(u8);
    const constant = ctx.c.constantPool[index];
    switch (constant) {
        .integer => |c| ctx.f.push(.{ .int = c.value }),
        .float => |c| ctx.f.push(.{ .float = c.value }),
        // TODO
        // .String => |c| ctx.f.push(.{ .double = c.value }),
        else => std.debug.panic("ldc constant {}", .{constant}),
    }
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.ldc_w
/// Operation
///    Push item from run-time constant pool (wide index)
/// Format
///    ldc_w
///    indexbyte1
///    indexbyte2
/// Forms
///    ldc_w = 19 (0x13)
/// Operand Stack
///    ... →
///    ..., value
/// Description
///    The unsigned indexbyte1 and indexbyte2 are assembled into an
///    unsigned 16-bit index into the run-time constant pool of the
///    current class (§2.6), where the value of the
///    index is calculated as (indexbyte1 << 8) |
///    indexbyte2. The index must be a valid index into the run-time
///    constant pool of the current class. The run-time constant pool
///    entry at the index either must be a run-time constant of type
///    int or float, or a reference to a string literal, or a symbolic
///    reference to a class, method type, or method handle
///    (§5.1).
///    If the run-time constant pool entry is a run-time constant of type
///    int or float, the numeric value of that run-time constant is
///    pushed onto the operand stack as an int or float,
///    respectively.
///    Otherwise, if the run-time constant pool entry is a reference to an
///    instance of class String representing a string literal
///    (§5.1), then a reference to that instance,
///    value, is pushed onto the operand stack.
///    Otherwise, if the run-time constant pool entry is a symbolic
///    reference to a class (§4.4.1). The named
///    class is resolved (§5.4.3.1) and a reference to
///    the Class object representing that class, value, is pushed
///    onto the operand stack.
///    Otherwise, the run-time constant pool entry must be a symbolic
///    reference to a method type or a method handle
///    (§5.1). The method type or method handle is
///    resolved (§5.4.3.5) and a reference to the
///    resulting instance of java.lang.invoke.MethodType or java.lang.invoke.MethodHandle, value, is
///    pushed onto the operand stack.
/// Linking Exceptions
///    During resolution of the symbolic reference to a  class, any of the exceptions pertaining to class
///    resolution (§5.4.3.1) can be thrown.
///    During resolution of a symbolic reference to a method type or
///    method handle, any of the exception pertaining to method type or
///    method handle resolution (§5.4.3.5) can be
///    thrown.
/// Notes
///    The ldc_w instruction is identical to the ldc instruction
///    (§ldc) except for its wider run-time
///    constant pool index.
///    The ldc_w instruction can only be used to push a value of type
///    float taken from the float value set
///    (§2.3.2) because a constant of type float
///    in the constant pool (§4.4.4) must be taken
///    from the float value set.
fn ldc_w(ctx: Context) void {
    const index = ctx.f.immidiate(u16);
    const constant = ctx.c.constantPool[index];
    switch (constant) {
        .integer => |c| ctx.f.push(.{ .int = c.value }),
        .float => |c| ctx.f.push(.{ .float = c.value }),
        // TODO
        // .String => |c| ctx.f.push(.{ .double = c.value }),
        else => unreachable,
    }
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.ldc2_w
/// Operation
///    Push long or double from run-time constant pool (wide index)
/// Format
///    ldc2_w
///    indexbyte1
///    indexbyte2
/// Forms
///    ldc2_w = 20 (0x14)
/// Operand Stack
///    ... →
///    ..., value
/// Description
///    The unsigned indexbyte1 and indexbyte2 are assembled into an
///    unsigned 16-bit index into the run-time constant pool of the
///    current class (§2.6), where the value of the
///    index is calculated as (indexbyte1 << 8) |
///    indexbyte2. The index must be a valid index into the run-time
///    constant pool of the current class. The run-time constant pool
///    entry at the index must be a run-time constant of type long or
///    double (§5.1). The numeric value of that
///    run-time constant is pushed onto the operand stack as a long or
///    double, respectively.
/// Notes
///    Only a wide-index version of the ldc2_w instruction exists;
///    there is no ldc2 instruction that pushes a
///    long or double with a single-byte index.
///    The ldc2_w instruction can only be used to push a value of type
///    double taken from the double value set
///    (§2.3.2) because a constant of type double
///    in the constant pool (§4.4.5) must be taken
///    from the double value set.
fn ldc2_w(ctx: Context) void {
    const index = ctx.f.immidiate(u16);
    const constant = ctx.c.constantPool[index];
    switch (constant) {
        .long => |c| ctx.f.push(.{ .long = c.value }),
        .double => |c| ctx.f.push(.{ .double = c.value }),
        else => unreachable,
    }
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.iload
/// Operation
///    Load int from local variable
/// Format
///    iload
///    index
/// Forms
///    iload = 21 (0x15)
/// Operand Stack
///    ... →
///    ..., value
/// Description
///    The index is an unsigned byte that must be an index into the
///    local variable array of the current frame
///    (§2.6). The local variable at index must
///    contain an int. The value of the local variable at index is
///    pushed onto the operand stack.
/// Notes
///    The iload opcode can be used in conjunction with the wide
///    instruction (§wide) to access a local
///    variable using a two-byte unsigned index.
fn iload(ctx: Context) void {
    const index = ctx.f.immidiate(u8);
    ctx.f.push(ctx.f.load(index).as(int));
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.lload
/// Operation
///    Load long from local variable
/// Format
///    lload
///    index
/// Forms
///    lload = 22 (0x16)
/// Operand Stack
///    ... →
///    ..., value
/// Description
///    The index is an unsigned byte. Both index and index+1 must
///    be indices into the local variable array of the current frame
///    (§2.6). The local variable at index must
///    contain a long. The value of the local variable at index is
///    pushed onto the operand stack.
/// Notes
///    The lload opcode can be used in conjunction with the wide
///    instruction (§wide) to access a local
///    variable using a two-byte unsigned index.
fn lload(ctx: Context) void {
    const index = ctx.f.immidiate(u8);
    ctx.f.push(ctx.f.load(index).as(long));
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.fload
/// Operation
///    Load float from local variable
/// Format
///    fload
///    index
/// Forms
///    fload = 23 (0x17)
/// Operand Stack
///    ... →
///    ..., value
/// Description
///    The index is an unsigned byte that must be an index into the
///    local variable array of the current frame
///    (§2.6). The local variable at index must
///    contain a float. The value of the local variable at index is
///    pushed onto the operand stack.
/// Notes
///    The fload opcode can be used in conjunction with the wide
///    instruction (§wide) to access a local
///    variable using a two-byte unsigned index.
fn fload(ctx: Context) void {
    const index = ctx.f.immidiate(u8);
    ctx.f.push(ctx.f.load(index).as(float));
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.dload
/// Operation
///    Load double from local variable
/// Format
///    dload
///    index
/// Forms
///    dload = 24 (0x18)
/// Operand Stack
///    ... →
///    ..., value
/// Description
///    The index is an unsigned byte. Both index and index+1 must
///    be indices into the local variable array of the current frame
///    (§2.6). The local variable at index must
///    contain a double. The value of the local variable at index
///    is pushed onto the operand stack.
/// Notes
///    The dload opcode can be used in conjunction with the wide
///    instruction (§wide) to access a local
///    variable using a two-byte unsigned index.
fn dload(ctx: Context) void {
    const index = ctx.f.immidiate(u8);
    ctx.f.push(ctx.f.load(index).as(double));
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.aload
/// Operation
///    Load reference from local variable
/// Format
///    aload
///    index
/// Forms
///    aload = 25 (0x19)
/// Operand Stack
///    ... →
///    ..., objectref
/// Description
///    The index is an unsigned byte that must be an index into the
///    local variable array of the current frame
///    (§2.6). The local variable at index must
///    contain a reference. The objectref in the local variable at index
///    is pushed onto the operand stack.
/// Notes
///    The aload instruction cannot be used to load a value of type
///    returnAddress from a local variable onto the operand stack. This
///    asymmetry with the astore instruction
///    (§astore) is intentional.
///    The aload opcode can be used in conjunction with the wide
///    instruction (§wide) to access a local
///    variable using a two-byte unsigned index.
fn aload(ctx: Context) void {
    const index = ctx.f.immidiate(u8);
    ctx.f.push(ctx.f.load(index).as(Reference));
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.iload_n
/// Operation
///    Load int from local variable
/// Format
///    iload_<n>
/// Forms
///    iload_0 = 26 (0x1a)
///    iload_1 = 27 (0x1b)
///    iload_2 = 28 (0x1c)
///    iload_3 = 29 (0x1d)
/// Operand Stack
///    ... →
///    ..., value
/// Description
///    The <n> must be an index into the local variable array
///    of the current frame (§2.6). The local
///    variable at <n> must contain an int. The value of
///    the local variable at <n> is pushed onto the operand
///    stack.
/// Notes
///    Each of the iload_<n> instructions is the same as iload with an
///    index of <n>, except that the operand <n>
///    is implicit.
fn iload_0(ctx: Context) void {
    ctx.f.push(ctx.f.load(0).as(int));
}

fn iload_1(ctx: Context) void {
    ctx.f.push(ctx.f.load(1).as(int));
}

fn iload_2(ctx: Context) void {
    ctx.f.push(ctx.f.load(2).as(int));
}

fn iload_3(ctx: Context) void {
    ctx.f.push(ctx.f.load(3).as(int));
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.lload_n
/// Operation
///    Load long from local variable
/// Format
///    lload_<n>
/// Forms
///    lload_0 = 30 (0x1e)
///    lload_1 = 31 (0x1f)
///    lload_2 = 32 (0x20)
///    lload_3 = 33 (0x21)
/// Operand Stack
///    ... →
///    ..., value
/// Description
///    Both <n> and <n>+1 must be indices into the
///    local variable array of the current frame
///    (§2.6). The local variable at <n>
///    must contain a long. The value of the local variable at
///    <n> is pushed onto the operand stack.
/// Notes
///    Each of the lload_<n> instructions is the same as lload with an
///    index of <n>, except that the operand <n>
///    is implicit.
fn lload_0(ctx: Context) void {
    ctx.f.push(ctx.f.load(0).as(long));
}

fn lload_1(ctx: Context) void {
    ctx.f.push(ctx.f.load(1).as(long));
}

fn lload_2(ctx: Context) void {
    ctx.f.push(ctx.f.load(2).as(long));
}

fn lload_3(ctx: Context) void {
    ctx.f.push(ctx.f.load(3).as(long));
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.fload_n
/// Operation
///    Load float from local variable
/// Format
///    fload_<n>
/// Forms
///    fload_0 = 34 (0x22)
///    fload_1 = 35 (0x23)
///    fload_2 = 36 (0x24)
///    fload_3 = 37 (0x25)
/// Operand Stack
///    ... →
///    ..., value
/// Description
///    The <n> must be an index into the local variable array
///    of the current frame (§2.6). The local
///    variable at <n> must contain a float. The value of
///    the local variable at <n> is pushed onto the operand
///    stack.
/// Notes
///    Each of the fload_<n> instructions is the same as fload with an
///    index of <n>, except that the operand <n>
///    is implicit.
fn fload_0(ctx: Context) void {
    ctx.f.push(ctx.f.load(0).as(float));
}

fn fload_1(ctx: Context) void {
    ctx.f.push(ctx.f.load(1).as(float));
}

fn fload_2(ctx: Context) void {
    ctx.f.push(ctx.f.load(2).as(float));
}

fn fload_3(ctx: Context) void {
    ctx.f.push(ctx.f.load(3).as(float));
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.dload_n
/// Operation
///    Load double from local variable
/// Format
///    dload_<n>
/// Forms
///    dload_0 = 38 (0x26)
///    dload_1 = 39 (0x27)
///    dload_2 = 40 (0x28)
///    dload_3 = 41 (0x29)
/// Operand Stack
///    ... →
///    ..., value
/// Description
///    Both <n> and <n>+1 must be indices into the
///    local variable array of the current frame
///    (§2.6). The local variable at <n>
///    must contain a double. The value of the local variable at
///    <n> is pushed onto the operand stack.
/// Notes
///    Each of the dload_<n> instructions is the same as dload with an
///    index of <n>, except that the operand <n>
///    is implicit.
fn dload_0(ctx: Context) void {
    ctx.f.push(ctx.f.load(0).as(double));
}

fn dload_1(ctx: Context) void {
    ctx.f.push(ctx.f.load(1).as(double));
}

fn dload_2(ctx: Context) void {
    ctx.f.push(ctx.f.load(2).as(double));
}

fn dload_3(ctx: Context) void {
    ctx.f.push(ctx.f.load(3).as(double));
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.aload_n
/// Operation
///    Load reference from local variable
/// Format
///    aload_<n>
/// Forms
///    aload_0 = 42 (0x2a)
///    aload_1 = 43 (0x2b)
///    aload_2 = 44 (0x2c)
///    aload_3 = 45 (0x2d)
/// Operand Stack
///    ... →
///    ..., objectref
/// Description
///    The <n> must be an index into the local variable array
///    of the current frame (§2.6). The local
///    variable at <n> must contain a reference. The objectref
///    in the local variable at <n> is pushed onto the operand
///    stack.
/// Notes
///    An aload_<n> instruction cannot be used to load a value of type
///    returnAddress from a local variable onto the operand stack. This
///    asymmetry with the corresponding astore_<n> instruction
///    (§astore_<n>) is intentional.
///    Each of the aload_<n> instructions is the same as aload with an
///    index of <n>, except that the operand <n>
///    is implicit.
fn aload_0(ctx: Context) void {
    ctx.f.push(ctx.f.load(0).as(Reference));
}

fn aload_1(ctx: Context) void {
    ctx.f.push(ctx.f.load(1).as(Reference));
}

fn aload_2(ctx: Context) void {
    ctx.f.push(ctx.f.load(2).as(Reference));
}

fn aload_3(ctx: Context) void {
    ctx.f.push(ctx.f.load(3).as(Reference));
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.iaload
/// Operation
///    Load int from array
/// Format
///    iaload
/// Forms
///    iaload = 46 (0x2e)
/// Operand Stack
///    ..., arrayref, index →
///    ..., value
/// Description
///    The arrayref must be of type reference and must refer to an array
///    whose components are of type int. The index must be of type
///    int. Both arrayref and index are popped from the operand
///    stack. The int value in the component of the array at index
///    is retrieved and pushed onto the operand stack.
/// Run-time Exceptions
///    If arrayref is null, iaload throws a NullPointerException.
///    Otherwise, if index is not within the bounds of the array
///    referenced by arrayref, the iaload instruction throws an
///    ArrayIndexOutOfBoundsException.
fn iaload(ctx: Context) void {
    const index = ctx.f.pop().as(int).int;
    const arrayref = ctx.f.pop().as(ArrayRef).ref;
    if (arrayref.isNull()) {
        ctx.f.vm_throw("java/lang/NullPointerException");
    }
    if (!arrayref.class().isArray) {
        unreachable;
    }
    if (!is(arrayref.class().componentType, int)) {
        unreachable;
    }
    if (index < 0 or index >= arrayref.len()) {
        unreachable;
    }

    ctx.f.push(arrayref.get(index).as(int));
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.laload
/// Operation
///    Load long from array
/// Format
///    laload
/// Forms
///    laload = 47 (0x2f)
/// Operand Stack
///    ..., arrayref, index →
///    ..., value
/// Description
///    The arrayref must be of type reference and must refer to an array
///    whose components are of type long. The index must be of type
///    int. Both arrayref and index are popped from the operand
///    stack. The long value in the component of the array at index
///    is retrieved and pushed onto the operand stack.
/// Run-time Exceptions
///    If arrayref is null, laload throws a NullPointerException.
///    Otherwise, if index is not within the bounds of the array
///    referenced by arrayref, the laload instruction throws an
///    ArrayIndexOutOfBoundsException.
fn laload(ctx: Context) void {
    const index = ctx.f.pop().as(int).int;
    const arrayref = ctx.f.pop().as(ArrayRef).ref;
    if (arrayref.isNull()) {
        ctx.f.vm_throw("java/lang/NullPointerException");
    }
    if (!arrayref.class().isArray) {
        unreachable;
    }
    if (!is(arrayref.class().componentType, long)) {
        unreachable;
    }
    if (index < 0 or index >= arrayref.len()) {
        unreachable;
    }

    ctx.f.push(arrayref.get(index).as(long));
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.faload
/// Operation
///    Load float from array
/// Format
///    faload
/// Forms
///    faload = 48 (0x30)
/// Operand Stack
///    ..., arrayref, index →
///    ..., value
/// Description
///    The arrayref must be of type reference and must refer to an array
///    whose components are of type float. The index must be of type
///    int. Both arrayref and index are popped from the operand
///    stack. The float value in the component of the array at index
///    is retrieved and pushed onto the operand stack.
/// Run-time Exceptions
///    If arrayref is null, faload throws a NullPointerException.
///    Otherwise, if index is not within the bounds of the array
///    referenced by arrayref, the faload instruction throws an
///    ArrayIndexOutOfBoundsException.
fn faload(ctx: Context) void {
    const index = ctx.f.pop().as(int).int;
    const arrayref = ctx.f.pop().as(ArrayRef).ref;
    if (arrayref.isNull()) {
        ctx.f.vm_throw("java/lang/NullPointerException");
    }
    if (!arrayref.class().isArray) {
        unreachable;
    }
    if (!is(arrayref.class().componentType, float)) {
        unreachable;
    }
    if (index < 0 or index >= arrayref.len()) {
        unreachable;
    }

    ctx.f.push(arrayref.get(index).as(float));
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.daload
/// Operation
///    Load double from array
/// Format
///    daload
/// Forms
///    daload = 49 (0x31)
/// Operand Stack
///    ..., arrayref, index →
///    ..., value
/// Description
///    The arrayref must be of type reference and must refer to an array
///    whose components are of type double. The index must be of type
///    int. Both arrayref and index are popped from the operand
///    stack. The double value in the component of the array at index
///    is retrieved and pushed onto the operand stack.
/// Run-time Exceptions
///    If arrayref is null, daload throws a NullPointerException.
///    Otherwise, if index is not within the bounds of the array
///    referenced by arrayref, the daload instruction throws an
///    ArrayIndexOutOfBoundsException.
fn daload(ctx: Context) void {
    const index = ctx.f.pop().as(int).int;
    const arrayref = ctx.f.pop().as(ArrayRef).ref;
    if (arrayref.isNull()) {
        ctx.f.vm_throw("java/lang/NullPointerException");
    }
    if (!arrayref.class().isArray) {
        unreachable;
    }
    if (!is(arrayref.class().componentType, double)) {
        unreachable;
    }
    if (index < 0 or index >= arrayref.len()) {
        unreachable;
    }

    ctx.f.push(arrayref.get(index).as(double));
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.aaload
/// Operation
///    Load reference from array
/// Format
///    aaload
/// Forms
///    aaload = 50 (0x32)
/// Operand Stack
///    ..., arrayref, index →
///    ..., value
/// Description
///    The arrayref must be of type reference and must refer to an array
///    whose components are of type reference. The index must be of type
///    int. Both arrayref and index are popped from the operand
///    stack. The reference value in the component of the array at index
///    is retrieved and pushed onto the operand stack.
/// Run-time Exceptions
///    If arrayref is null, aaload throws a NullPointerException.
///    Otherwise, if index is not within the bounds of the array
///    referenced by arrayref, the aaload instruction throws an
///    ArrayIndexOutOfBoundsException.
fn aaload(ctx: Context) void {
    const index = ctx.f.pop().as(int).int;
    const arrayref = ctx.f.pop().as(ArrayRef).ref;
    if (arrayref.isNull()) {
        ctx.f.vm_throw("java/lang/NullPointerException");
    }
    if (!arrayref.class().isArray) {
        unreachable;
    }
    if (!is(arrayref.class().componentType, Reference)) {
        unreachable;
    }
    if (index < 0 or index >= arrayref.len()) {
        unreachable;
    }

    ctx.f.push(arrayref.get(index).as(Reference));
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.baload
/// Operation
///    Load byte or boolean from array
/// Format
///    baload
/// Forms
///    baload = 51 (0x33)
/// Operand Stack
///    ..., arrayref, index →
///    ..., value
/// Description
///    The arrayref must be of type reference and must refer to an array
///    whose components are of type byte or of type boolean. The
///    index must be of type int. Both arrayref and index are
///    popped from the operand stack. The byte value in the component
///    of the array at index is retrieved, sign-extended to an int
///    value, and pushed onto the top of the operand stack.
/// Run-time Exceptions
///    If arrayref is null, baload throws a NullPointerException.
///    Otherwise, if index is not within the bounds of the array
///    referenced by arrayref, the baload instruction throws an
///    ArrayIndexOutOfBoundsException.
/// Notes
///    The baload instruction is used to load values from both byte
///    and boolean arrays. In Oracle's Java Virtual Machine implementation, boolean
///    arrays - that is, arrays of type T_BOOLEAN
///    (§2.2, §newarray)
///    - are implemented as arrays of 8-bit values. Other implementations
///    may implement packed boolean arrays; the baload instruction of
///    such implementations must be used to access those arrays.
fn baload(ctx: Context) void {
    const index = ctx.f.pop().as(int).int;
    const arrayref = ctx.f.pop().as(ArrayRef).ref;
    if (arrayref.isNull()) {
        ctx.f.vm_throw("java/lang/NullPointerException");
    }
    if (!arrayref.class().isArray) {
        unreachable;
    }
    if (index < 0 or index >= arrayref.len()) {
        unreachable;
    }
    if (!is(arrayref.class().componentType, byte) and !is(arrayref.class().componentType, boolean)) {
        unreachable;
    }
    ctx.f.push(arrayref.get(index).as(int));
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.caload
/// Operation
///    Load char from array
/// Format
///    caload
/// Forms
///    caload = 52 (0x34)
/// Operand Stack
///    ..., arrayref, index →
///    ..., value
/// Description
///    The arrayref must be of type reference and must refer to an array
///    whose components are of type char. The index must be of type
///    int. Both arrayref and index are popped from the operand
///    stack. The component of the array at index is retrieved and
///    zero-extended to an int value. That value is pushed onto the
///    operand stack.
/// Run-time Exceptions
///    If arrayref is null, caload throws a NullPointerException.
///    Otherwise, if index is not within the bounds of the array
///    referenced by arrayref, the caload instruction throws an
///    ArrayIndexOutOfBoundsException.
fn caload(ctx: Context) void {
    _ = ctx;
    @panic("instruction not implemented");
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.saload
/// Operation
///    Load short from array
/// Format
///    saload
/// Forms
///    saload = 53 (0x35)
/// Operand Stack
///    ..., arrayref, index →
///    ..., value
/// Description
///    The arrayref must be of type reference and must refer to an array
///    whose components are of type short. The index must be of type
///    int. Both arrayref and index are popped from the operand
///    stack. The component of the array at index is retrieved and
///    sign-extended to an int value. That value is pushed onto the
///    operand stack.
/// Run-time Exceptions
///    If arrayref is null, saload throws a NullPointerException.
///    Otherwise, if index is not within the bounds of the array
///    referenced by arrayref, the saload instruction throws an
///    ArrayIndexOutOfBoundsException.
fn saload(ctx: Context) void {
    _ = ctx;
    @panic("instruction not implemented");
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.istore
/// Operation
///    Store int into local variable
/// Format
///    istore
///    index
/// Forms
///    istore = 54 (0x36)
/// Operand Stack
///    ..., value →
///    ...
/// Description
///    The index is an unsigned byte that must be an index into the
///    local variable array of the current frame
///    (§2.6). The value on the top of the
///    operand stack must be of type int. It is popped from the operand
///    stack, and the value of the local variable at index is set to
///    value.
/// Notes
///    The istore opcode can be used in conjunction with the wide
///    instruction (§wide) to access a local
///    variable using a two-byte unsigned index.
fn istore(ctx: Context) void {
    const index = ctx.f.immidiate(u8);
    ctx.f.store(index, ctx.f.pop().as(int));
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.lstore
/// Operation
///    Store long into local variable
/// Format
///    lstore
///    index
/// Forms
///    lstore = 55 (0x37)
/// Operand Stack
///    ..., value →
///    ...
/// Description
///    The index is an unsigned byte. Both index and index+1 must
///    be indices into the local variable array of the current frame
///    (§2.6). The value on the top of the
///    operand stack must be of type long. It is popped from the
///    operand stack, and the local variables at index and index+1
///    are set to value.
/// Notes
///    The lstore opcode can be used in conjunction with the wide
///    instruction (§wide) to access a local
///    variable using a two-byte unsigned index.
fn lstore(ctx: Context) void {
    const index = ctx.f.immidiate(u8);
    ctx.f.store(index, ctx.f.pop().as(long));
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.fstore
/// Operation
///    Store float into local variable
/// Format
///    fstore
///    index
/// Forms
///    fstore = 56 (0x38)
/// Operand Stack
///    ..., value →
///    ...
/// Description
///    The index is an unsigned byte that must be an index into the
///    local variable array of the current frame
///    (§2.6). The value on the top of the
///    operand stack must be of type float. It is popped from the
///    operand stack and undergoes value set conversion
///    (§2.8.3), resulting in value'. The value
///    of the local variable at index is set to value'.
/// Notes
///    The fstore opcode can be used in conjunction with the wide
///    instruction (§wide) to access a local
///    variable using a two-byte unsigned index.
fn fstore(ctx: Context) void {
    const index = ctx.f.immidiate(u8);
    ctx.f.store(index, ctx.f.pop().as(float));
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.dstore
/// Operation
///    Store double into local variable
/// Format
///    dstore
///    index
/// Forms
///    dstore = 57 (0x39)
/// Operand Stack
///    ..., value →
///    ...
/// Description
///    The index is an unsigned byte. Both index and index+1 must
///    be indices into the local variable array of the current frame
///    (§2.6). The value on the top of the
///    operand stack must be of type double. It is popped from the
///    operand stack and undergoes value set conversion
///    (§2.8.3), resulting in value'. The local
///    variables at index and index+1 are set to value'.
/// Notes
///    The dstore opcode can be used in conjunction with the wide
///    instruction (§wide) to access a local
///    variable using a two-byte unsigned index.
fn dstore(ctx: Context) void {
    const index = ctx.f.immidiate(u8);
    ctx.f.store(index, ctx.f.pop().as(double));
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.astore
/// Operation
///    Store reference into local variable
/// Format
///    astore
///    index
/// Forms
///    astore = 58 (0x3a)
/// Operand Stack
///    ..., objectref →
///    ...
/// Description
///    The index is an unsigned byte that must be an index into the
///    local variable array of the current frame
///    (§2.6). The objectref on the top of the
///    operand stack must be of type returnAddress or of type reference. It
///    is popped from the operand stack, and the value of the local
///    variable at index is set to objectref.
/// Notes
///    The astore instruction is used with an objectref of type
///    returnAddress when implementing the finally clause of the
///    Java programming language (§3.13).
///    The aload instruction (§aload) cannot
///    be used to load a value of type returnAddress from a local
///    variable onto the operand stack. This asymmetry with the astore
///    instruction is intentional.
///    The astore opcode can be used in conjunction with the wide
///    instruction (§wide) to access a local
///    variable using a two-byte unsigned index.
fn astore(ctx: Context) void {
    const index = ctx.f.immidiate(u8);
    const value = ctx.f.pop();
    switch (value) {
        .ref, .returnAddress => ctx.f.store(index, value),
        else => unreachable,
    }
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.istore_n
/// Operation
///    Store int into local variable
/// Format
///    istore_<n>
/// Forms
///    istore_0 = 59 (0x3b)
///    istore_1 = 60 (0x3c)
///    istore_2 = 61 (0x3d)
///    istore_3 = 62 (0x3e)
/// Operand Stack
///    ..., value →
///    ...
/// Description
///    The <n> must be an index into the local variable array
///    of the current frame (§2.6). The value on
///    the top of the operand stack must be of type int. It is popped
///    from the operand stack, and the value of the local variable at
///    <n> is set to value.
/// Notes
///    Each of the istore_<n> instructions is the same as istore with
///    an index of <n>, except that the operand
///    <n> is implicit.
fn istore_0(ctx: Context) void {
    ctx.f.store(0, ctx.f.pop().as(int));
}

fn istore_1(ctx: Context) void {
    ctx.f.store(1, ctx.f.pop().as(int));
}

fn istore_2(ctx: Context) void {
    ctx.f.store(2, ctx.f.pop().as(int));
}

fn istore_3(ctx: Context) void {
    ctx.f.store(3, ctx.f.pop().as(int));
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.lstore_n
/// Operation
///    Store long into local variable
/// Format
///    lstore_<n>
/// Forms
///    lstore_0 = 63 (0x3f)
///    lstore_1 = 64 (0x40)
///    lstore_2 = 65 (0x41)
///    lstore_3 = 66 (0x42)
/// Operand Stack
///    ..., value →
///    ...
/// Description
///    Both <n> and <n>+1 must be indices into the
///    local variable array of the current frame
///    (§2.6). The value on the top of the
///    operand stack must be of type long. It is popped from the
///    operand stack, and the local variables at <n> and
///    <n>+1 are set to value.
/// Notes
///    Each of the lstore_<n> instructions is the same as lstore with
///    an index of <n>, except that the operand
///    <n> is implicit.
fn lstore_0(ctx: Context) void {
    ctx.f.store(0, ctx.f.pop().as(long));
}

fn lstore_1(ctx: Context) void {
    ctx.f.store(1, ctx.f.pop().as(long));
}

fn lstore_2(ctx: Context) void {
    ctx.f.store(2, ctx.f.pop().as(long));
}

fn lstore_3(ctx: Context) void {
    ctx.f.store(3, ctx.f.pop().as(long));
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.fstore_n
/// Operation
///    Store float into local variable
/// Format
///    fstore_<n>
/// Forms
///    fstore_0 = 67 (0x43)
///    fstore_1 = 68 (0x44)
///    fstore_2 = 69 (0x45)
///    fstore_3 = 70 (0x46)
/// Operand Stack
///    ..., value →
///    ...
/// Description
///    The <n> must be an index into the local variable array
///    of the current frame (§2.6). The value on
///    the top of the operand stack must be of type float. It is popped
///    from the operand stack and undergoes value set conversion
///    (§2.8.3), resulting in value'. The value
///    of the local variable at <n> is set to value'.
/// Notes
///    Each of the fstore_<n> instructions is the same as fstore with
///    an index of <n>, except that the operand
///    <n> is implicit.
fn fstore_0(ctx: Context) void {
    ctx.f.store(0, ctx.f.pop().as(float));
}

fn fstore_1(ctx: Context) void {
    ctx.f.store(1, ctx.f.pop().as(float));
}

fn fstore_2(ctx: Context) void {
    ctx.f.store(2, ctx.f.pop().as(float));
}

fn fstore_3(ctx: Context) void {
    ctx.f.store(3, ctx.f.pop().as(float));
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.dstore_n
/// Operation
///    Store double into local variable
/// Format
///    dstore_<n>
/// Forms
///    dstore_0 = 71 (0x47)
///    dstore_1 = 72 (0x48)
///    dstore_2 = 73 (0x49)
///    dstore_3 = 74 (0x4a)
/// Operand Stack
///    ..., value →
///    ...
/// Description
///    Both <n> and <n>+1 must be indices into the
///    local variable array of the current frame
///    (§2.6). The value on the top of the
///    operand stack must be of type double. It is popped from the
///    operand stack and undergoes value set conversion
///    (§2.8.3), resulting in value'. The local
///    variables at <n> and <n>+1 are set to
///    value'.
/// Notes
///    Each of the dstore_<n> instructions is the same as dstore with
///    an index of <n>, except that the operand
///    <n> is implicit.
fn dstore_0(ctx: Context) void {
    ctx.f.store(0, ctx.f.pop().as(double));
}

fn dstore_1(ctx: Context) void {
    ctx.f.store(1, ctx.f.pop().as(double));
}

fn dstore_2(ctx: Context) void {
    ctx.f.store(2, ctx.f.pop().as(double));
}

fn dstore_3(ctx: Context) void {
    ctx.f.store(3, ctx.f.pop().as(double));
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.astore_n
/// Operation
///    Store reference into local variable
/// Format
///    astore_<n>
/// Forms
///    astore_0 = 75 (0x4b)
///    astore_1 = 76 (0x4c)
///    astore_2 = 77 (0x4d)
///    astore_3 = 78 (0x4e)
/// Operand Stack
///    ..., objectref →
///    ...
/// Description
///    The <n> must be an index into the local variable array
///    of the current frame (§2.6). The objectref
///    on the top of the operand stack must be of type returnAddress or
///    of type reference. It is popped from the operand stack, and the value
///    of the local variable at <n> is set to
///    objectref.
/// Notes
///    An astore_<n> instruction is used with an objectref of type
///    returnAddress when implementing the finally clauses of the
///    Java programming language (§3.13).
///    An aload_<n> instruction (§aload_<n>)
///    cannot be used to load a value of type returnAddress from a
///    local variable onto the operand stack. This asymmetry with the
///    corresponding astore_<n> instruction is intentional.
///    Each of the astore_<n> instructions is the same as astore with
///    an index of <n>, except that the operand
///    <n> is implicit.
fn astore_0(ctx: Context) void {
    const value = ctx.f.pop();
    switch (value) {
        .ref, .returnAddress => ctx.f.store(0, value),
        else => unreachable,
    }
}

fn astore_1(ctx: Context) void {
    const value = ctx.f.pop();
    switch (value) {
        .ref, .returnAddress => ctx.f.store(1, value),
        else => unreachable,
    }
}

fn astore_2(ctx: Context) void {
    const value = ctx.f.pop();
    switch (value) {
        .ref, .returnAddress => ctx.f.store(2, value),
        else => unreachable,
    }
}

fn astore_3(ctx: Context) void {
    const value = ctx.f.pop();
    switch (value) {
        .ref, .returnAddress => ctx.f.store(3, value),
        else => unreachable,
    }
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.iastore
/// Operation
///    Store into int array
/// Format
///    iastore
/// Forms
///    iastore = 79 (0x4f)
/// Operand Stack
///    ..., arrayref, index, value →
///    ...
/// Description
///    The arrayref must be of type reference and must refer to an array
///    whose components are of type int. Both index and value must
///    be of type int. The arrayref, index, and value are popped
///    from the operand stack. The int value is stored as the
///    component of the array indexed by index.
/// Run-time Exceptions
///    If arrayref is null, iastore throws a NullPointerException.
///    Otherwise, if index is not within the bounds of the array
///    referenced by arrayref, the iastore instruction throws an
///    ArrayIndexOutOfBoundsException.
fn iastore(ctx: Context) void {
    const value = ctx.f.pop().as(int).int;
    const index = ctx.f.pop().as(int).int;
    const arrayref = ctx.f.pop().as(ArrayRef).ref;
    arrayref.set(index, .{ .int = value });
    //TODO check component type and boundary
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.lastore
/// Operation
///    Store into long array
/// Format
///    lastore
/// Forms
///    lastore = 80 (0x50)
/// Operand Stack
///    ..., arrayref, index, value →
///    ...
/// Description
///    The arrayref must be of type reference and must refer to an array
///    whose components are of type long. The index must be of type
///    int, and value must be of type long. The arrayref,
///    index, and value are popped from the operand stack. The long
///    value is stored as the component of the array indexed by
///    index.
/// Run-time Exceptions
///    If arrayref is null, lastore throws a NullPointerException.
///    Otherwise, if index is not within the bounds of the array
///    referenced by arrayref, the lastore instruction throws an
///    ArrayIndexOutOfBoundsException.
fn lastore(ctx: Context) void {
    const value = ctx.f.pop().as(long).long;
    const index = ctx.f.pop().as(int).int;
    const arrayref = ctx.f.pop().as(ArrayRef).ref;
    arrayref.set(index, .{ .long = value });
    //TODO check component type and boundary
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.fastore
/// Operation
///    Store into float array
/// Format
///    fastore
/// Forms
///    fastore = 81 (0x51)
/// Operand Stack
///    ..., arrayref, index, value →
///    ...
/// Description
///    The arrayref must be of type reference and must refer to an array
///    whose components are of type float. The index must be of type
///    int, and the value must be of type float. The arrayref,
///    index, and value are popped from the operand stack. The
///    float value undergoes value set conversion
///    (§2.8.3), resulting in value', and
///    value' is stored as the component of the array indexed by
///    index.
/// Run-time Exceptions
///    If arrayref is null, fastore throws a NullPointerException.
///    Otherwise, if index is not within the bounds of the array
///    referenced by arrayref, the fastore instruction throws an
///    ArrayIndexOutOfBoundsException.
fn fastore(ctx: Context) void {
    const value = ctx.f.pop().as(float).float;
    const index = ctx.f.pop().as(int).int;
    const arrayref = ctx.f.pop().as(ArrayRef).ref;
    arrayref.set(index, .{ .float = value });
    //TODO check component type and boundary
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.dastore
/// Operation
///    Store into double array
/// Format
///    dastore
/// Forms
///    dastore = 82 (0x52)
/// Operand Stack
///    ..., arrayref, index, value →
///    ...
/// Description
///    The arrayref must be of type reference and must refer to an array
///    whose components are of type double. The index must be of type
///    int, and value must be of type double. The arrayref,
///    index, and value are popped from the operand stack. The
///    double value undergoes value set conversion
///    (§2.8.3), resulting in value', which is
///    stored as the component of the array indexed by index.
/// Run-time Exceptions
///    If arrayref is null, dastore throws a NullPointerException.
///    Otherwise, if index is not within the bounds of the array
///    referenced by arrayref, the dastore instruction throws an
///    ArrayIndexOutOfBoundsException.
fn dastore(ctx: Context) void {
    const value = ctx.f.pop().as(double).double;
    const index = ctx.f.pop().as(int).int;
    const arrayref = ctx.f.pop().as(ArrayRef).ref;
    arrayref.set(index, .{ .double = value });
    //TODO check component type and boundary
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.aastore
/// Operation
///    Store into reference array
/// Format
///    aastore
/// Forms
///    aastore = 83 (0x53)
/// Operand Stack
///    ..., arrayref, index, value →
///    ...
/// Description
///    The arrayref must be of type reference and must refer to an array
///    whose components are of type reference. The index must be of type
///    int and value must be of type reference. The arrayref, index,
///    and value are popped from the operand stack. The reference value
///    is stored as the component of the array at index.
///    At run time, the type of value must be compatible with the type
///    of the components of the array referenced by
///    arrayref. Specifically, assignment of a value of reference type
///    S (source) to an array component of reference type T (target)
///    is allowed only if:
///    If S is a class type, then:
///    If T is a class type, then S must be the same class as
///    T, or S must be a subclass of T;
///    If T is an interface type, then S must implement
///    interface T.
///    If S is an interface type, then:
///    If T is a class type, then T must be Object.
///    If T is an interface type, then T must be the same
///    interface as S or a superinterface of S.
///    If S is an array type, namely, the type SC[], that
///    is, an array of components of type SC, then:
///    If T is a class type, then T must be Object.
///    If T is an interface type, then T must be one of the
///    interfaces implemented by arrays (JLS §4.10.3).
///    If T is an array type TC[], that is, an array
///    of components of type TC, then one of the following must
///    be true:
///    TC and SC are the same primitive type.
///    TC and SC are reference types, and type SC is
///    assignable to TC by these run-time rules.
/// Run-time Exceptions
///    If arrayref is null, aastore throws a NullPointerException.
///    Otherwise, if index is not within the bounds of the array
///    referenced by arrayref, the aastore instruction throws an
///    ArrayIndexOutOfBoundsException.
///    Otherwise, if arrayref is not null and the actual type of
///    value is not assignment compatible (JLS §5.2) with the actual
///    type of the components of the array, aastore throws an
///    ArrayStoreException.
fn aastore(ctx: Context) void {
    const value = ctx.f.pop().as(ObjectRef).ref;
    const index = ctx.f.pop().as(int).int;
    const arrayref = ctx.f.pop().as(ArrayRef).ref;
    arrayref.set(index, .{ .ref = value });
    //TODO check component type and boundary
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.bastore
/// Operation
///    Store into byte or boolean array
/// Format
///    bastore
/// Forms
///    bastore = 84 (0x54)
/// Operand Stack
///    ..., arrayref, index, value →
///    ...
/// Description
///    The arrayref must be of type reference and must refer to an array
///    whose components are of type byte or of type boolean. The
///    index and the value must both be of type int. The
///    arrayref, index, and value are popped from the operand
///    stack. The int value is truncated to a byte and stored as
///    the component of the array indexed by index.
/// Run-time Exceptions
///    If arrayref is null, bastore throws a NullPointerException.
///    Otherwise, if index is not within the bounds of the array
///    referenced by arrayref, the bastore instruction throws an
///    ArrayIndexOutOfBoundsException.
/// Notes
///    The bastore instruction is used to store values into both byte
///    and boolean arrays. In Oracle's Java Virtual Machine implementation, boolean
///    arrays - that is, arrays of type T_BOOLEAN
///    (§2.2, §newarray)
///    - are implemented as arrays of 8-bit values. Other implementations
///    may implement packed boolean arrays; in such implementations the
///    bastore instruction must be able to store boolean values into
///    packed boolean arrays as well as byte values into byte
///    arrays.
fn bastore(ctx: Context) void {
    const value = ctx.f.pop().as(int).int;
    const index = ctx.f.pop().as(int).int;
    const arrayref = ctx.f.pop().as(ArrayRef).ref;

    const v: byte = @truncate(value);
    arrayref.set(index, .{ .byte = v });
    //TODO check component type and boundary
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.castore
/// Operation
///    Store into char array
/// Format
///    castore
/// Forms
///    castore = 85 (0x55)
/// Operand Stack
///    ..., arrayref, index, value →
///    ...
/// Description
///    The arrayref must be of type reference and must refer to an array
///    whose components are of type char. The index and the value
///    must both be of type int. The arrayref, index, and value
///    are popped from the operand stack. The int value is truncated
///    to a char and stored as the component of the array indexed by
///    index.
/// Run-time Exceptions
///    If arrayref is null, castore throws a NullPointerException.
///    Otherwise, if index is not within the bounds of the array
///    referenced by arrayref, the castore instruction throws an
///    ArrayIndexOutOfBoundsException.
fn castore(ctx: Context) void {
    const value = ctx.f.pop().as(int).int;
    const index = ctx.f.pop().as(int).int;
    const arrayref = ctx.f.pop().as(ArrayRef).ref;

    const v: u32 = @bitCast(value);
    arrayref.set(index, .{ .char = @truncate(v) });
    //TODO check component type and boundary
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.sastore
/// Operation
///    Store into short array
/// Format
///    sastore
/// Forms
///    sastore = 86 (0x56)
/// Operand Stack
///    ..., arrayref, index, value →
///    ...
/// Description
///    The arrayref must be of type reference and must refer to an array
///    whose components are of type short. Both index and value
///    must be of type int. The arrayref, index, and value are
///    popped from the operand stack. The int value is truncated to a
///    short and stored as the component of the array indexed by
///    index.
/// Run-time Exceptions
///    If arrayref is null, sastore throws a NullPointerException.
///    Otherwise, if index is not within the bounds of the array
///    referenced by arrayref, the sastore instruction throws an
///    ArrayIndexOutOfBoundsException.
fn sastore(ctx: Context) void {
    const value = ctx.f.pop().as(int).int;
    const index = ctx.f.pop().as(int).int;
    const arrayref = ctx.f.pop().as(ArrayRef).ref;

    const v: short = @truncate(value);
    arrayref.set(index, .{ .short = v });
    //TODO check component type and boundary
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.pop
/// Operation
///    Pop the top operand stack value
/// Format
///    pop
/// Forms
///    pop = 87 (0x57)
/// Operand Stack
///    ..., value →
///    ...
/// Description
///    Pop the top value from the operand stack.
///    The pop instruction must not be used unless value is a value
///    of a category 1 computational type
///    (§2.11.1).
fn pop(ctx: Context) void {
    _ = ctx.f.pop();
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.pop2
/// Operation
///    Pop the top one or two operand stack values
/// Format
///    pop2
/// Forms
///    pop2 = 88 (0x58)
/// Operand Stack
///    Form 1:
///    ..., value2, value1 →
///    ...
///    where each of value1 and value2 is a value of a category 1
///    computational type (§2.11.1).
///    Form 2:
///    ..., value →
///    ...
///    where value is a value of a category 2 computational type
///    (§2.11.1).
/// Description
///    Pop the top one or two values from the operand stack.
fn pop2(ctx: Context) void {
    // TODO ???
    _ = ctx.f.pop();
    _ = ctx.f.pop();
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.dup
/// Operation
///    Duplicate the top operand stack value
/// Format
///    dup
/// Forms
///    dup = 89 (0x59)
/// Operand Stack
///    ..., value →
///    ..., value, value
/// Description
///    Duplicate the top value on the operand stack and push the
///    duplicated value onto the operand stack.
///    The dup instruction must not be used unless value is a value
///    of a category 1 computational type
///    (§2.11.1).
fn dup(ctx: Context) void {
    const value = ctx.f.pop();
    ctx.f.push(value);
    ctx.f.push(value);
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.dup_x1
/// Operation
///    Duplicate the top operand stack value and insert two values down
/// Format
///    dup_x1
/// Forms
///    dup_x1 = 90 (0x5a)
/// Operand Stack
///    ..., value2, value1 →
///    ..., value1, value2, value1
/// Description
///    Duplicate the top value on the operand stack and insert the
///    duplicated value two values down in the operand stack.
///    The dup_x1 instruction must not be used unless both value1 and
///    value2 are values of a category 1 computational type
///    (§2.11.1).
fn dup_x1(ctx: Context) void {
    const value1 = ctx.f.pop();
    const value2 = ctx.f.pop();
    ctx.f.push(value1);
    ctx.f.push(value2);
    ctx.f.push(value1);
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.dup_x2
/// Operation
///    Duplicate the top operand stack value and insert two or three values down
/// Format
///    dup_x2
/// Forms
///    dup_x2 = 91 (0x5b)
/// Operand Stack
///    Form 1:
///    ..., value3, value2, value1 →
///    ..., value1, value3, value2, value1
///    where value1, value2, and value3 are all values of a
///    category 1 computational type
///    (§2.11.1).
///    Form 2:
///    ..., value2, value1 →
///    ..., value1, value2, value1
///    where value1 is a value of a category 1 computational type and
///    value2 is a value of a category 2 computational type
///    (§2.11.1).
/// Description
///    Duplicate the top value on the operand stack and insert the
///    duplicated value two or three values down in the operand
///    stack.
fn dup_x2(ctx: Context) void {
    const value1 = ctx.f.pop();

    switch (value1) {
        .long, .double => {
            ctx.f.push(value1);
            ctx.f.push(value1);
        },
        else => {
            const value2 = ctx.f.pop();
            ctx.f.push(value2);
            ctx.f.push(value1);
            ctx.f.push(value2);
            ctx.f.push(value1);
        },
    }
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.dup2
/// Operation
///    Duplicate the top one or two operand stack values
/// Format
///    dup2
/// Forms
///    dup2 = 92 (0x5c)
/// Operand Stack
///    Form 1:
///    ..., value2, value1 →
///    ..., value2, value1, value2, value1
///    where both value1 and value2 are values of a category 1
///    computational type (§2.11.1).
///    Form 2:
///    ..., value →
///    ..., value, value
///    where value is a value of a category 2 computational type
///    (§2.11.1).
/// Description
///    Duplicate the top one or two values on the operand stack and push
///    the duplicated value or values back onto the operand stack in the
///    original order.
fn dup2(ctx: Context) void {
    _ = ctx;
    @panic("instruction not implemented");
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.dup2_x1
/// Operation
///    Duplicate the top one or two operand stack values and insert two or three values down
/// Format
///    dup2_x1
/// Forms
///    dup2_x1 = 93 (0x5d)
/// Operand Stack
///    Form 1:
///    ..., value3, value2, value1 →
///    ..., value2, value1, value3, value2, value1
///    where value1, value2, and value3 are all values of a
///    category 1 computational type
///    (§2.11.1).
///    Form 2:
///    ..., value2, value1 →
///    ..., value1, value2, value1
///    where value1 is a value of a category 2 computational type and
///    value2 is a value of a category 1 computational type
///    (§2.11.1).
/// Description
///    Duplicate the top one or two values on the operand stack and
///    insert the duplicated values, in the original order, one value
///    beneath the original value or values in the operand stack.
fn dup2_x1(ctx: Context) void {
    _ = ctx;
    @panic("instruction not implemented");
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.dup2_x2
/// Operation
///    Duplicate the top one or two operand stack values and insert two, three, or four values down
/// Format
///    dup2_x2
/// Forms
///    dup2_x2 = 94 (0x5e)
/// Operand Stack
///    Form 1:
///    ..., value4, value3, value2, value1 →
///    ..., value2, value1, value4, value3, value2, value1
///    where value1, value2, value3, and value4 are all values of
///    a category 1 computational type
///    (§2.11.1).
///    Form 2:
///    ..., value3, value2, value1 →
///    ..., value1, value3, value2, value1
///    where value1 is a value of a category 2 computational type and
///    value2 and value3 are both values of a category 1
///    computational type (§2.11.1).
///    Form 3:
///    ..., value3, value2, value1 →
///    ..., value2, value1, value3, value2, value1
///    where value1 and value2 are both values of a category 1
///    computational type and value3 is a value of a category 2
///    computational type (§2.11.1).
///    Form 4:
///    ..., value2, value1 →
///    ..., value1, value2, value1
///    where value1 and value2 are both values of a category 2
///    computational type (§2.11.1).
/// Description
///    Duplicate the top one or two values on the operand stack and
///    insert the duplicated values, in the original order, into the
///    operand stack.
fn dup2_x2(ctx: Context) void {
    _ = ctx;
    @panic("instruction not implemented");
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.swap
/// Operation
///    Swap the top two operand stack values
/// Format
///    swap
/// Forms
///    swap = 95 (0x5f)
/// Operand Stack
///    ..., value2, value1 →
///    ..., value1, value2
/// Description
///    Swap the top two values on the operand stack.
///    The swap instruction must not be used unless value1 and
///    value2 are both values of a category 1 computational type
///    (§2.11.1).
/// Notes
///    The Java Virtual Machine does not provide an instruction implementing a swap on
///    operands of category 2 computational types.
fn swap(ctx: Context) void {
    const value1 = ctx.f.pop();
    const value2 = ctx.f.pop();
    ctx.f.push(value1);
    ctx.f.push(value2);
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.iadd
/// Operation
///    Add int
/// Format
///    iadd
/// Forms
///    iadd = 96 (0x60)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type int. The values are
///    popped from the operand stack. The int result is value1 +
///    value2. The result is pushed onto the operand stack.
///    The result is the 32 low-order bits of the true mathematical
///    result in a sufficiently wide two's-complement format, represented
///    as a value of type int. If overflow occurs, then the sign of the
///    result may not be the same as the sign of the mathematical sum of
///    the two values.
///    Despite the fact that overflow may occur, execution of an iadd
///    instruction never throws a run-time exception.
fn iadd(ctx: Context) void {
    const value2 = ctx.f.pop().as(int).int;
    const value1 = ctx.f.pop().as(int).int;
    ctx.f.push(.{ .int = value1 +% value2 });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.ladd
/// Operation
///    Add long
/// Format
///    ladd
/// Forms
///    ladd = 97 (0x61)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type long. The values are
///    popped from the operand stack. The long result is value1 +
///    value2. The result is pushed onto the operand stack.
///    The result is the 64 low-order bits of the true mathematical
///    result in a sufficiently wide two's-complement format, represented
///    as a value of type long. If overflow occurs, the sign of the
///    result may not be the same as the sign of the mathematical sum of
///    the two values.
///    Despite the fact that overflow may occur, execution of an ladd
///    instruction never throws a run-time exception.
fn ladd(ctx: Context) void {
    const value2 = ctx.f.pop().as(long).long;
    const value1 = ctx.f.pop().as(long).long;
    ctx.f.push(.{ .long = value1 +% value2 });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.fadd
/// Operation
///    Add float
/// Format
///    fadd
/// Forms
///    fadd = 98 (0x62)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type float. The values are
///    popped from the operand stack and undergo value set conversion
///    (§2.8.3), resulting in value1' and
///    value2'. The float result is value1' + value2'. The
///    result is pushed onto the operand stack.
///    The result of an fadd instruction is governed by the rules of
///    IEEE arithmetic:
///    If either value1' or value2' is NaN, the result is NaN.
///    The sum of two infinities of opposite sign is NaN.
///    The sum of two infinities of the same sign is the infinity of
///    that sign.
///    The sum of an infinity and any finite value is equal to the
///    infinity.
///    The sum of two zeroes of opposite sign is positive
///    zero.
///    The sum of two zeroes of the same sign is the zero of that
///    sign.
///    The sum of a zero and a nonzero finite value is equal to the
///    nonzero value.
///    The sum of two nonzero finite values of the same magnitude and
///    opposite sign is positive zero.
///    In the remaining cases, where neither operand is an infinity,
///    a zero, or NaN and the values have the same sign or have
///    different magnitudes, the sum is computed and rounded to the
///    nearest representable value using IEEE 754 round to nearest
///    mode. If the magnitude is too large to represent as a float,
///    we say the operation overflows; the result is then an infinity
///    of appropriate sign. If the magnitude is too small to
///    represent as a float, we say the operation underflows; the
///    result is then a zero of appropriate sign.
///    The Java Virtual Machine requires support of gradual underflow as defined by IEEE
///    754. Despite the fact that overflow, underflow, or loss of
///    precision may occur, execution of an fadd instruction never
///    throws a run-time exception.
fn fadd(ctx: Context) void {
    const value2 = ctx.f.pop().as(float).float;
    const value1 = ctx.f.pop().as(float).float;
    ctx.f.push(.{ .float = value1 - value2 });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.dadd
/// Operation
///    Add double
/// Format
///    dadd
/// Forms
///    dadd = 99 (0x63)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type double. The values
///    are popped from the operand stack and undergo value set conversion
///    (§2.8.3), resulting in value1' and
///    value2'. The double result is value1' + value2'. The
///    result is pushed onto the operand stack.
///    The result of a dadd instruction is governed by the rules of
///    IEEE arithmetic:
///    If either value1' or value2' is NaN, the result is NaN.
///    The sum of two infinities of opposite sign is NaN.
///    The sum of two infinities of the same sign is the infinity of that sign.
///    The sum of an infinity and any finite value is equal to the infinity.
///    The sum of two zeroes of opposite sign is positive zero.
///    The sum of two zeroes of the same sign is the zero of that sign.
///    The sum of a zero and a nonzero finite value is equal to the nonzero value.
///    The sum of two nonzero finite values of the same magnitude and opposite sign is positive zero.
///    In the remaining cases, where neither operand is an infinity,
///    a zero, or NaN and the values have the same sign or have
///    different magnitudes, the sum is computed and rounded to the
///    nearest representable value using IEEE 754 round to nearest
///    mode. If the magnitude is too large to represent as a
///    double, we say the operation overflows; the result is then
///    an infinity of appropriate sign. If the magnitude is too small
///    to represent as a double, we say the operation underflows;
///    the result is then a zero of appropriate sign.
///    The Java Virtual Machine requires support of gradual underflow as defined by IEEE
///    754. Despite the fact that overflow, underflow, or loss of
///    precision may occur, execution of a dadd instruction never
///    throws a run-time exception.
fn dadd(ctx: Context) void {
    const value2 = ctx.f.pop().as(double).double;
    const value1 = ctx.f.pop().as(double).double;
    ctx.f.push(.{ .double = value1 + value2 });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.isub
/// Operation
///    Subtract int
/// Format
///    isub
/// Forms
///    isub = 100 (0x64)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type int. The values are
///    popped from the operand stack. The int result is value1 -
///    value2. The result is pushed onto the operand stack.
///    For int subtraction, a-b produces the same
///    result as a+(-b). For int values, subtraction
///    from zero is the same as negation.
///    The result is the 32 low-order bits of the true mathematical
///    result in a sufficiently wide two's-complement format, represented
///    as a value of type int. If overflow occurs, then the sign of the
///    result may not be the same as the sign of the mathematical
///    difference of the two values.
///    Despite the fact that overflow may occur, execution of an isub
///    instruction never throws a run-time exception.
fn isub(ctx: Context) void {
    const value2 = ctx.f.pop().as(int).int;
    const value1 = ctx.f.pop().as(int).int;
    ctx.f.push(.{ .int = value1 -% value2 });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.lsub
/// Operation
///    Subtract long
/// Format
///    lsub
/// Forms
///    lsub = 101 (0x65)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type long. The values are
///    popped from the operand stack. The long result is value1 -
///    value2. The result is pushed onto the operand stack.
///    For long subtraction, a-b produces the same
///    result as a+(-b). For long values,
///    subtraction from zero is the same as negation.
///    The result is the 64 low-order bits of the true mathematical
///    result in a sufficiently wide two's-complement format, represented
///    as a value of type long. If overflow occurs, then the sign of
///    the result may not be the same as the sign of the
///    mathematical difference of the two values.
///    Despite the fact that overflow may occur, execution of an lsub
///    instruction never throws a run-time exception.
fn lsub(ctx: Context) void {
    const value2 = ctx.f.pop().as(long).long;
    const value1 = ctx.f.pop().as(long).long;
    ctx.f.push(.{ .long = value1 -% value2 });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.fsub
/// Operation
///    Subtract float
/// Format
///    fsub
/// Forms
///    fsub = 102 (0x66)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type float. The values are
///    popped from the operand stack and undergo value set conversion
///    (§2.8.3), resulting in value1' and
///    value2'. The float result is value1' - value2'. The
///    result is pushed onto the operand stack.
///    For float subtraction, it is always the case
///    that a-b produces the same result
///    as a+(-b). However, for the fsub instruction,
///    subtraction from zero is not the same as negation, because
///    if x is +0.0,
///    then 0.0-x equals +0.0,
///    but -x equals -0.0.
///    The Java Virtual Machine requires support of gradual underflow as defined by IEEE
///    754. Despite the fact that overflow, underflow, or loss of
///    precision may occur, execution of an fsub instruction never
///    throws a run-time exception.
fn fsub(ctx: Context) void {
    const value2 = ctx.f.pop().as(float).float;
    const value1 = ctx.f.pop().as(float).float;
    ctx.f.push(.{ .float = value1 - value2 });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.dsub
/// Operation
///    Subtract double
/// Format
///    dsub
/// Forms
///    dsub = 103 (0x67)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type double. The values
///    are popped from the operand stack and undergo value set conversion
///    (§2.8.3), resulting in value1' and
///    value2'. The double result is value1' - value2'. The
///    result is pushed onto the operand stack.
///    For double subtraction, it is always the case
///    that a-b produces the same result
///    as a+(-b). However, for the dsub instruction,
///    subtraction from zero is not the same as negation, because
///    if x is +0.0,
///    then 0.0-x equals +0.0,
///    but -x equals -0.0.
///    The Java Virtual Machine requires support of gradual underflow as defined by IEEE
///    754. Despite the fact that overflow, underflow, or loss of
///    precision may occur, execution of a dsub instruction never
///    throws a run-time exception.
fn dsub(ctx: Context) void {
    const value2 = ctx.f.pop().as(double).double;
    const value1 = ctx.f.pop().as(double).double;
    ctx.f.push(.{ .double = value1 - value2 });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.imul
/// Operation
///    Multiply int
/// Format
///    imul
/// Forms
///    imul = 104 (0x68)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type int. The values are
///    popped from the operand stack. The int result is value1 *
///    value2. The result is pushed onto the operand stack.
///    The result is the 32 low-order bits of the true mathematical
///    result in a sufficiently wide two's-complement format, represented
///    as a value of type int. If overflow occurs, then the sign of the
///    result may not be the same as the sign of the
///    mathematical multiplication of the two values.
///    Despite the fact that overflow may occur, execution of an imul
///    instruction never throws a run-time exception.
fn imul(ctx: Context) void {
    const value2 = ctx.f.pop().as(int).int;
    const value1 = ctx.f.pop().as(int).int;
    ctx.f.push(.{ .int = value1 *% value2 });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.lmul
/// Operation
///    Multiply long
/// Format
///    lmul
/// Forms
///    lmul = 105 (0x69)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type long. The values are
///    popped from the operand stack. The long result is value1 *
///    value2. The result is pushed onto the operand stack.
///    The result is the 64 low-order bits of the true mathematical
///    result in a sufficiently wide two's-complement format, represented
///    as a value of type long. If overflow occurs, the sign of the
///    result may not be the same as the sign of the
///    mathematical multiplication of the two values.
///    Despite the fact that overflow may occur, execution of an lmul
///    instruction never throws a run-time exception.
fn lmul(ctx: Context) void {
    const value2 = ctx.f.pop().as(long).long;
    const value1 = ctx.f.pop().as(long).long;
    ctx.f.push(.{ .long = value1 *% value2 });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.fmul
/// Operation
///    Multiply float
/// Format
///    fmul
/// Forms
///    fmul = 106 (0x6a)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type float. The values are
///    popped from the operand stack and undergo value set conversion
///    (§2.8.3), resulting in value1' and
///    value2'. The float result is value1' * value2'. The
///    result is pushed onto the operand stack.
///    The result of an fmul instruction is governed by the rules of
///    IEEE arithmetic:
///    If either value1' or value2' is NaN, the result is NaN.
///    If neither value1' nor value2' is NaN, the sign of the
///    result is positive if both values have the same sign, and
///    negative if the values have different signs.
///    Multiplication of an infinity by a zero results in NaN.
///    Multiplication of an infinity by a finite value results in a
///    signed infinity, with the sign-producing rule just
///    given.
///    In the remaining cases, where neither an infinity nor NaN is
///    involved, the product is computed and rounded to the nearest
///    representable value using IEEE 754 round to nearest mode. If
///    the magnitude is too large to represent as a float, we say
///    the operation overflows; the result is then an infinity of
///    appropriate sign. If the magnitude is too small to represent
///    as a float, we say the operation underflows; the result is
///    then a zero of appropriate sign.
///    The Java Virtual Machine requires support of gradual underflow as defined by IEEE
///    754. Despite the fact that overflow, underflow, or loss of
///    precision may occur, execution of an fmul instruction never
///    throws a run-time exception.
fn fmul(ctx: Context) void {
    const value2 = ctx.f.pop().as(float).float;
    const value1 = ctx.f.pop().as(float).float;
    ctx.f.push(.{ .float = value1 * value2 });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.dmul
/// Operation
///    Multiply double
/// Format
///    dmul
/// Forms
///    dmul = 107 (0x6b)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type double. The values
///    are popped from the operand stack and undergo value set conversion
///    (§2.8.3), resulting in value1' and
///    value2'. The double result is value1' * value2'. The
///    result is pushed onto the operand stack.
///    The result of a dmul instruction is governed by the rules of
///    IEEE arithmetic:
///    If either value1' or value2' is NaN, the result is NaN.
///    If neither value1' nor value2' is NaN, the sign of the
///    result is positive if both values have the same sign and
///    negative if the values have different signs.
///    Multiplication of an infinity by a zero results in NaN.
///    Multiplication of an infinity by a finite value results in a
///    signed infinity, with the sign-producing rule just given.
///    In the remaining cases, where neither an infinity nor NaN is
///    involved, the product is computed and rounded to the nearest
///    representable value using IEEE 754 round to nearest mode. If
///    the magnitude is too large to represent as a double, we say
///    the operation overflows; the result is then an infinity of
///    appropriate sign. If the magnitude is too small to represent
///    as a double, we say the operation underflows; the result is
///    then a zero of appropriate sign.
///    The Java Virtual Machine requires support of gradual underflow as defined by IEEE
///    754. Despite the fact that overflow, underflow, or loss of
///    precision may occur, execution of a dmul instruction never
///    throws a run-time exception.
fn dmul(ctx: Context) void {
    const value2 = ctx.f.pop().as(double).double;
    const value1 = ctx.f.pop().as(double).double;
    ctx.f.push(.{ .double = value1 * value2 });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.idiv
/// Operation
///    Divide int
/// Format
///    idiv
/// Forms
///    idiv = 108 (0x6c)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type int. The values are
///    popped from the operand stack. The int result is the value of
///    the Java programming language expression value1 / value2. The result is
///    pushed onto the operand stack.
///    An int division rounds towards 0; that is, the quotient produced
///    for int values in n/d is an int value q whose
///    magnitude is as large as possible while satisfying |d ⋅
///    q| ≤ |n|. Moreover, q is positive when |n|
///    ≥ |d| and n and d have the same sign, but
///    q is negative when |n| ≥ |d| and n and
///    d have opposite signs.
///    There is one special case that does not satisfy this rule: if the
///    dividend is the negative integer of largest possible magnitude for
///    the int type, and the divisor is -1, then overflow occurs, and
///    the result is equal to the dividend. Despite the overflow, no
///    exception is thrown in this case.
/// Run-time Exception
///    If the value of the divisor in an int division is 0, idiv
///    throws an ArithmeticException.
fn idiv(ctx: Context) void {
    const value2 = ctx.f.pop().as(int).int;
    const value1 = ctx.f.pop().as(int).int;
    ctx.f.push(.{ .int = @divTrunc(value1, value2) });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.ldiv
/// Operation
///    Divide long
/// Format
///    ldiv
/// Forms
///    ldiv = 109 (0x6d)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type long. The values are
///    popped from the operand stack. The long result is the value of
///    the Java programming language expression value1 / value2. The result is
///    pushed onto the operand stack.
///    A long division rounds towards 0; that is, the quotient produced
///    for long values in n / d is a long value q
///    whose magnitude is as large as possible while satisfying |d
///    ⋅ q| ≤ |n|. Moreover, q is positive when
///    |n| ≥ |d| and n and d have the same sign,
///    but q is negative when |n| ≥ |d| and n and
///    d have opposite signs.
///    There is one special case that does not satisfy this rule: if the
///    dividend is the negative integer of largest possible magnitude for
///    the long type and the divisor is -1, then overflow occurs and
///    the result is equal to the dividend; despite the overflow, no
///    exception is thrown in this case.
/// Run-time Exception
///    If the value of the divisor in a long division is 0, ldiv
///    throws an ArithmeticException.
fn ldiv(ctx: Context) void {
    const value2 = ctx.f.pop().as(long).long;
    const value1 = ctx.f.pop().as(long).long;
    ctx.f.push(.{ .long = @rem(value1, value2) });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.fdiv
/// Operation
///    Divide float
/// Format
///    fdiv
/// Forms
///    fdiv = 110 (0x6e)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type float. The values are
///    popped from the operand stack and undergo value set conversion
///    (§2.8.3), resulting in value1' and
///    value2'. The float result is value1' / value2'. The
///    result is pushed onto the operand stack.
///    The result of an fdiv instruction is governed by the rules of
///    IEEE arithmetic:
///    If either value1' or value2' is NaN, the result is NaN.
///    If neither value1' nor value2' is NaN, the sign of the
///    result is positive if both values have the same sign, negative
///    if the values have different signs.
///    Division of an infinity by an infinity results in NaN.
///    Division of an infinity by a finite value results in a signed
///    infinity, with the sign-producing rule just given.
///    Division of a finite value by an infinity results in a signed
///    zero, with the sign-producing rule just given.
///    Division of a zero by a zero results in NaN; division of zero
///    by any other finite value results in a signed zero, with the
///    sign-producing rule just given.
///    Division of a nonzero finite value by a zero results in a
///    signed infinity, with the sign-producing rule just
///    given.
///    In the remaining cases, where neither operand is an infinity,
///    a zero, or NaN, the quotient is computed and rounded to the
///    nearest float using IEEE 754 round to nearest mode. If the
///    magnitude is too large to represent as a float, we say the
///    operation overflows; the result is then an infinity of
///    appropriate sign. If the magnitude is too small to represent
///    as a float, we say the operation underflows; the result is
///    then a zero of appropriate sign.
///    The Java Virtual Machine requires support of gradual underflow as defined by IEEE
///    754. Despite the fact that overflow, underflow, division by zero,
///    or loss of precision may occur, execution of an fdiv instruction
///    never throws a run-time exception.
fn fdiv(ctx: Context) void {
    const value2 = ctx.f.pop().as(float).float;
    const value1 = ctx.f.pop().as(float).float;
    ctx.f.push(.{ .float = value1 / value2 });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.ddiv
/// Operation
///    Divide double
/// Format
///    ddiv
/// Forms
///    ddiv = 111 (0x6f)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type double. The values
///    are popped from the operand stack and undergo value set conversion
///    (§2.8.3), resulting in value1' and
///    value2'. The double result is value1' / value2'. The
///    result is pushed onto the operand stack.
///    The result of a ddiv instruction is governed by the rules of
///    IEEE arithmetic:
///    If either value1' or value2' is NaN, the result is NaN.
///    If neither value1' nor value2' is NaN, the sign of the
///    result is positive if both values have the same sign, negative
///    if the values have different signs.
///    Division of an infinity by an infinity results in NaN.
///    Division of an infinity by a finite value results in a signed
///    infinity, with the sign-producing rule just given.
///    Division of a finite value by an infinity results in a signed
///    zero, with the sign-producing rule just given.
///    Division of a zero by a zero results in NaN; division of zero
///    by any other finite value results in a signed zero, with the
///    sign-producing rule just given.
///    Division of a nonzero finite value by a zero results in a
///    signed infinity, with the sign-producing rule just
///    given.
///    In the remaining cases, where neither operand is an infinity,
///    a zero, or NaN, the quotient is computed and rounded to the
///    nearest double using IEEE 754 round to nearest mode. If the
///    magnitude is too large to represent as a double, we say the
///    operation overflows; the result is then an infinity of
///    appropriate sign. If the magnitude is too small to represent
///    as a double, we say the operation underflows; the result is
///    then a zero of appropriate sign.
///    The Java Virtual Machine requires support of gradual underflow as defined by IEEE
///    754. Despite the fact that overflow, underflow, division by zero,
///    or loss of precision may occur, execution of a ddiv instruction
///    never throws a run-time exception.
fn ddiv(ctx: Context) void {
    const value2 = ctx.f.pop().as(double).double;
    const value1 = ctx.f.pop().as(double).double;
    ctx.f.push(.{ .double = value1 / value2 });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.irem
/// Operation
///    Remainder int
/// Format
///    irem
/// Forms
///    irem = 112 (0x70)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type int. The values are
///    popped from the operand stack. The int result is value1 -
///    (value1 / value2) * value2. The result is pushed onto the
///    operand stack.
///    The result of the irem instruction is such that (a/b)*b
///    + (a%b) is equal to a. This identity
///    holds even in the special case in which the dividend is the
///    negative int of largest possible magnitude for its type and the
///    divisor is -1 (the remainder is 0). It follows from this rule that
///    the result of the remainder operation can be negative only if the
///    dividend is negative and can be positive only if the dividend is
///    positive. Moreover, the magnitude of the result is always less
///    than the magnitude of the divisor.
/// Run-time Exception
///    If the value of the divisor for an int remainder operator is 0,
///    irem throws an ArithmeticException.
fn irem(ctx: Context) void {
    const value2 = ctx.f.pop().as(int).int;
    const value1 = ctx.f.pop().as(int).int;
    ctx.f.push(.{ .int = @rem(value1, value2) });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.lrem
/// Operation
///    Remainder long
/// Format
///    lrem
/// Forms
///    lrem = 113 (0x71)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type long. The values are
///    popped from the operand stack. The long result is value1 -
///    (value1 / value2) * value2. The result is pushed onto the
///    operand stack.
///    The result of the lrem instruction is such that
///    (a/b)*b + (a%b) is equal
///    to a. This identity holds even in the special
///    case in which the dividend is the negative long of largest
///    possible magnitude for its type and the divisor is -1 (the
///    remainder is 0). It follows from this rule that the result of the
///    remainder operation can be negative only if the dividend is
///    negative and can be positive only if the dividend is positive;
///    moreover, the magnitude of the result is always less than the
///    magnitude of the divisor.
/// Run-time Exception
///    If the value of the divisor for a long remainder operator is 0,
///    lrem throws an ArithmeticException.
fn lrem(ctx: Context) void {
    const value2 = ctx.f.pop().as(long).long;
    const value1 = ctx.f.pop().as(long).long;
    ctx.f.push(.{ .long = @rem(value1, value2) });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.frem
/// Operation
///    Remainder float
/// Format
///    frem
/// Forms
///    frem = 114 (0x72)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type float. The values are
///    popped from the operand stack and undergo value set conversion
///    (§2.8.3), resulting in value1' and
///    value2'. The result is calculated and pushed onto the operand
///    stack as a float.
///    The result of an frem instruction is not the same as that of
///    the so-called remainder operation defined by IEEE 754. The IEEE
///    754 "remainder" operation computes the remainder from a rounding
///    division, not a truncating division, and so its behavior
///    is not analogous to that of the usual integer
///    remainder operator. Instead, the Java Virtual Machine defines frem to behave in
///    a manner analogous to that of the Java Virtual Machine integer remainder
///    instructions (irem and lrem); this may be compared with the C
///    library function fmod.
///    The result of an frem instruction is governed by these
///    rules:
///    If either value1' or value2' is NaN, the result is NaN.
///    If neither value1' nor value2' is NaN, the sign of the
///    result equals the sign of the dividend.
///    If the dividend is an infinity or the divisor is a zero or
///    both, the result is NaN.
///    If the dividend is finite and the divisor is an infinity, the
///    result equals the dividend.
///    If the dividend is a zero and the divisor is finite, the
///    result equals the dividend.
///    In the remaining cases, where neither operand is an infinity,
///    a zero, or NaN, the floating-point remainder result from a
///    dividend value1' and a divisor value2' is defined by the
///    mathematical relation result = value1' - (value2' *
///    q), where q is an integer that is negative only if
///    value1' / value2' is negative and positive only if
///    value1' / value2' is positive, and whose magnitude is as
///    large as possible without exceeding the magnitude of the true
///    mathematical quotient of value1' and value2'.
///    Despite the fact that division by zero may occur, evaluation of an
///    frem instruction never throws a run-time exception. Overflow,
///    underflow, or loss of precision cannot occur.
/// Notes
///    The IEEE 754 remainder operation may be computed by the library
///    routine Math.IEEEremainder.
fn frem(ctx: Context) void {
    const value2 = ctx.f.pop().as(float).float;
    const value1 = ctx.f.pop().as(float).float;
    ctx.f.push(.{ .float = @rem(value1, value2) });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.drem
/// Operation
///    Remainder double
/// Format
///    drem
/// Forms
///    drem = 115 (0x73)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type double. The values
///    are popped from the operand stack and undergo value set conversion
///    (§2.8.3), resulting in value1' and
///    value2'. The result is calculated and pushed onto the operand
///    stack as a double.
///    The result of a drem instruction is not the same as that of the
///    so-called remainder operation defined by IEEE 754. The IEEE 754
///    "remainder" operation computes the remainder from a rounding
///    division, not a truncating division, and so its behavior
///    is not analogous to that of the usual integer
///    remainder operator. Instead, the Java Virtual Machine defines drem to behave in
///    a manner analogous to that of the Java Virtual Machine integer remainder
///    instructions (irem and lrem); this may be compared with the C
///    library function fmod.
///    The result of a drem instruction is governed by these rules:
///    If either value1' or value2' is NaN, the result is NaN.
///    If neither value1' nor value2' is NaN, the sign of the
///    result equals the sign of the dividend.
///    If the dividend is an infinity or the divisor is a zero or
///    both, the result is NaN.
///    If the dividend is finite and the divisor is an infinity, the
///    result equals the dividend.
///    If the dividend is a zero and the divisor is finite, the
///    result equals the dividend.
///    In the remaining cases, where neither operand is an infinity,
///    a zero, or NaN, the floating-point remainder result from a
///    dividend value1' and a divisor value2' is defined by the
///    mathematical relation result = value1' - (value2' *
///    q), where q is an integer that is negative only if
///    value1' / value2' is negative, and positive only if
///    value1' / value2' is positive, and whose magnitude is as
///    large as possible without exceeding the magnitude of the true
///    mathematical quotient of value1' and value2'.
///    Despite the fact that division by zero may occur, evaluation of a
///    drem instruction never throws a run-time exception. Overflow,
///    underflow, or loss of precision cannot occur.
/// Notes
///    The IEEE 754 remainder operation may be computed by the library
///    routine Math.IEEEremainder.
fn drem(ctx: Context) void {
    const value2 = ctx.f.pop().as(double).double;
    const value1 = ctx.f.pop().as(double).double;
    ctx.f.push(.{ .double = @rem(value1, value2) });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.ineg
/// Operation
///    Negate int
/// Format
///    ineg
/// Forms
///    ineg = 116 (0x74)
/// Operand Stack
///    ..., value →
///    ..., result
/// Description
///    The value must be of type int. It is popped from the operand
///    stack. The int result is the arithmetic negation of value,
///    -value. The result is pushed onto the operand stack.
///    For int values, negation is the same as subtraction from
///    zero. Because the Java Virtual Machine uses two's-complement representation for
///    integers and the range of two's-complement values is not
///    symmetric, the negation of the maximum negative int results in
///    that same maximum negative number. Despite the fact that overflow
///    has occurred, no exception is thrown.
///    For all int values x, -x
///    equals (~x)+1.
fn ineg(ctx: Context) void {
    const value = ctx.f.pop().as(int).int;
    ctx.f.push(.{ .int = -%value });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.lneg
/// Operation
///    Negate long
/// Format
///    lneg
/// Forms
///    lneg = 117 (0x75)
/// Operand Stack
///    ..., value →
///    ..., result
/// Description
///    The value must be of type long. It is popped from the operand
///    stack. The long result is the arithmetic negation of value,
///    -value. The result is pushed onto the operand stack.
///    For long values, negation is the same as subtraction from
///    zero. Because the Java Virtual Machine uses two's-complement representation for
///    integers and the range of two's-complement values is not
///    symmetric, the negation of the maximum negative long results in
///    that same maximum negative number. Despite the fact that overflow
///    has occurred, no exception is thrown.
///    For all long values x, -x
///    equals (~x)+1.
fn lneg(ctx: Context) void {
    const value = ctx.f.pop().as(long).long;
    ctx.f.push(.{ .long = -%value });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.fneg
/// Operation
///    Negate float
/// Format
///    fneg
/// Forms
///    fneg = 118 (0x76)
/// Operand Stack
///    ..., value →
///    ..., result
/// Description
///    The value must be of type float. It is popped from the operand
///    stack and undergoes value set conversion
///    (§2.8.3), resulting in value'. The float
///    result is the arithmetic negation of value'. This result is
///    pushed onto the operand stack.
///    For float values, negation is not the same as subtraction from
///    zero. If x is +0.0,
///    then 0.0-x equals +0.0,
///    but -x equals -0.0. Unary
///    minus merely inverts the sign of a float.
///    Special cases of interest:
///    If the operand is NaN, the result is NaN (recall that NaN has
///    no sign).
///    If the operand is an infinity, the result is the infinity of
///    opposite sign.
///    If the operand is a zero, the result is the zero of opposite
///    sign.
fn fneg(ctx: Context) void {
    const value = ctx.f.pop().as(float).float;
    ctx.f.push(.{ .float = -value });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.dneg
/// Operation
///    Negate double
/// Format
///    dneg
/// Forms
///    dneg = 119 (0x77)
/// Operand Stack
///    ..., value →
///    ..., result
/// Description
///    The value must be of type double. It is popped from the operand
///    stack and undergoes value set conversion
///    (§2.8.3), resulting in value'. The
///    double result is the arithmetic negation of value'. The
///    result is pushed onto the operand stack.
///    For double values, negation is not the same as subtraction from
///    zero. If x is +0.0,
///    then 0.0-x equals +0.0,
///    but -x equals -0.0. Unary
///    minus merely inverts the sign of a double.
///    Special cases of interest:
///    If the operand is NaN, the result is NaN (recall that NaN has
///    no sign).
///    If the operand is an infinity, the result is the infinity of
///    opposite sign.
///    If the operand is a zero, the result is the zero of opposite
///    sign.
fn dneg(ctx: Context) void {
    const value = ctx.f.pop().as(double).double;
    ctx.f.push(.{ .double = -value });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.ishl
/// Operation
///    Shift left int
/// Format
///    ishl
/// Forms
///    ishl = 120 (0x78)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type int. The values are
///    popped from the operand stack. An int result is calculated by
///    shifting value1 left by s bit positions, where s is
///    the value of the low 5 bits of value2. The result is pushed
///    onto the operand stack.
/// Notes
///    This is equivalent (even if overflow occurs) to multiplication by
///    2 to the power s. The shift distance actually used is always
///    in the range 0 to 31, inclusive, as if value2 were subjected to
///    a bitwise logical AND with the mask value 0x1f.
fn ishl(ctx: Context) void {
    const value2 = ctx.f.pop().as(int).int;
    const value1 = ctx.f.pop().as(int).int;

    const mask: int = 0x1F;
    const v: u32 = @bitCast(value2 & mask);
    const shift: u5 = @truncate(v);
    ctx.f.push(.{ .int = value1 << shift });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.lshl
/// Operation
///    Shift left long
/// Format
///    lshl
/// Forms
///    lshl = 121 (0x79)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    The value1 must be of type long, and value2 must be of type
///    int. The values are popped from the operand stack. A long
///    result is calculated by shifting value1 left by s bit
///    positions, where s is the low 6 bits of value2. The
///    result is pushed onto the operand stack.
/// Notes
///    This is equivalent (even if overflow occurs) to multiplication by
///    2 to the power s. The shift distance actually used is
///    therefore always in the range 0 to 63, inclusive, as if value2
///    were subjected to a bitwise logical AND with the mask value
///    0x3f.
fn lshl(ctx: Context) void {
    const value2 = ctx.f.pop().as(int).int;
    const value1 = ctx.f.pop().as(long).long;

    const mask: long = 0x3F;
    const v: u64 = @bitCast(value2 & mask);
    const shift: u6 = @truncate(v);
    ctx.f.push(.{ .long = value1 << shift });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.ishr
/// Operation
///    Arithmetic shift right int
/// Format
///    ishr
/// Forms
///    ishr = 122 (0x7a)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type int. The values are
///    popped from the operand stack. An int result is calculated by
///    shifting value1 right by s bit positions, with sign
///    extension, where s is the value of the low 5 bits of
///    value2. The result is pushed onto the operand stack.
/// Notes
///    The resulting value is floor(value1 /
///    2s), where s is value2
///    & 0x1f. For non-negative value1, this is equivalent to
///    truncating int division by 2 to the power s. The shift
///    distance actually used is always in the range 0 to 31, inclusive,
///    as if value2 were subjected to a bitwise logical AND with the
///    mask value 0x1f.
fn ishr(ctx: Context) void {
    const value2 = ctx.f.pop().as(int).int;
    const value1 = ctx.f.pop().as(int).int;

    const mask: int = 0x1F;
    const v: u32 = @bitCast(value2 & mask);
    const shift: u5 = @truncate(v);
    ctx.f.push(.{ .int = value1 >> shift });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.lshr
/// Operation
///    Arithmetic shift right long
/// Format
///    lshr
/// Forms
///    lshr = 123 (0x7b)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    The value1 must be of type long, and value2 must be of type
///    int. The values are popped from the operand stack. A long
///    result is calculated by shifting value1 right by s bit
///    positions, with sign extension, where s is the value of the
///    low 6 bits of value2. The result is pushed onto the operand
///    stack.
/// Notes
///    The resulting value is floor(value1 /
///    2s), where s is value2
///    & 0x3f. For non-negative value1, this is equivalent to
///    truncating long division by 2 to the power s. The shift
///    distance actually used is therefore always in the range 0 to 63,
///    inclusive, as if value2 were subjected to a bitwise logical AND
///    with the mask value 0x3f.
fn lshr(ctx: Context) void {
    const value2 = ctx.f.pop().as(int).int;
    const value1 = ctx.f.pop().as(long).long;

    const mask: long = 0x3F;
    const v: u64 = @bitCast(value2 & mask);
    const shift: u6 = @truncate(v);
    ctx.f.push(.{ .long = value1 >> shift });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.iushr
/// Operation
///    Logical shift right int
/// Format
///    iushr
/// Forms
///    iushr = 124 (0x7c)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type int. The values are
///    popped from the operand stack. An int result is calculated by
///    shifting value1 right by s bit positions, with zero
///    extension, where s is the value of the low 5 bits of
///    value2. The result is pushed onto the operand stack.
/// Notes
///    If value1 is positive and s is value2 & 0x1f, the
///    result is the same as that of value1 >> s; if
///    value1 is negative, the result is equal to the value of the
///    expression (value1 >> s) + (2 << ~s). The
///    addition of the (2 << ~s) term cancels out the
///    propagated sign bit. The shift distance actually used is always in
///    the range 0 to 31, inclusive.
fn iushr(ctx: Context) void {
    const value2 = ctx.f.pop().as(int).int;
    const value1 = ctx.f.pop().as(int).int;

    const mask: int = 0x1F;
    const s: u32 = @bitCast(value2 & mask);
    const shift: u5 = @truncate(s);
    const v: u32 = @bitCast(value1);
    ctx.f.push(.{ .int = @bitCast(v >> shift) });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.lushr
/// Operation
///    Logical shift right long
/// Format
///    lushr
/// Forms
///    lushr = 125 (0x7d)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    The value1 must be of type long, and value2 must be of type
///    int. The values are popped from the operand stack. A long
///    result is calculated by shifting value1 right
///    logically  by s bit positions, with zero
///    extension, where s is the value of the low 6 bits of
///    value2. The result is pushed onto the operand stack.
/// Notes
///    If value1 is positive and s is value2 & 0x3f, the
///    result is the same as that of value1 >> s; if
///    value1 is negative, the result is equal to the value of the
///    expression (value1 >> s) + (2L << ~s). The
///    addition of the (2L << ~s) term cancels out the
///    propagated sign bit. The shift distance actually used is always in
///    the range 0 to 63, inclusive.
fn lushr(ctx: Context) void {
    const value2 = ctx.f.pop().as(int).int;
    const value1 = ctx.f.pop().as(long).long;

    const mask: long = 0x3F;
    const s: u64 = @bitCast(value2 & mask);
    const shift: u6 = @truncate(s);
    const v: u64 = @bitCast(value1);
    ctx.f.push(.{ .long = @bitCast(v >> shift) });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.iand
/// Operation
///    Boolean AND int
/// Format
///    iand
/// Forms
///    iand = 126 (0x7e)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type int. They are popped
///    from the operand stack. An int result is calculated by taking
///    the bitwise AND (conjunction) of value1 and value2. The
///    result is pushed onto the operand stack.
fn iand(ctx: Context) void {
    const value2 = ctx.f.pop().as(int).int;
    const value1 = ctx.f.pop().as(int).int;

    ctx.f.push(.{ .int = value1 & value2 });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.land
/// Operation
///    Boolean AND long
/// Format
///    land
/// Forms
///    land = 127 (0x7f)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type long. They are popped
///    from the operand stack. A long result is calculated by taking
///    the bitwise AND of value1 and value2. The result is pushed
///    onto the operand stack.
fn land(ctx: Context) void {
    const value2 = ctx.f.pop().as(long).long;
    const value1 = ctx.f.pop().as(long).long;

    ctx.f.push(.{ .long = value1 & value2 });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.ior
/// Operation
///    Boolean OR int
/// Format
///    ior
/// Forms
///    ior = 128 (0x80)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type int. They are popped
///    from the operand stack. An int result is calculated by taking
///    the bitwise inclusive OR of value1 and value2. The result is
///    pushed onto the operand stack.
fn ior(ctx: Context) void {
    const value2 = ctx.f.pop().as(int).int;
    const value1 = ctx.f.pop().as(int).int;

    ctx.f.push(.{ .int = value1 | value2 });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.lor
/// Operation
///    Boolean OR long
/// Format
///    lor
/// Forms
///    lor = 129 (0x81)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type long. They are popped
///    from the operand stack. A long result is calculated by taking
///    the bitwise inclusive OR of value1 and value2. The result is
///    pushed onto the operand stack.
fn lor(ctx: Context) void {
    const value2 = ctx.f.pop().as(long).long;
    const value1 = ctx.f.pop().as(long).long;

    ctx.f.push(.{ .long = value1 | value2 });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.ixor
/// Operation
///    Boolean XOR int
/// Format
///    ixor
/// Forms
///    ixor = 130 (0x82)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type int. They are popped
///    from the operand stack. An int result is calculated by taking
///    the bitwise exclusive OR of value1 and value2. The result is
///    pushed onto the operand stack.
fn ixor(ctx: Context) void {
    const value2 = ctx.f.pop().as(int).int;
    const value1 = ctx.f.pop().as(int).int;

    ctx.f.push(.{ .int = value1 ^ value2 });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.lxor
/// Operation
///    Boolean XOR long
/// Format
///    lxor
/// Forms
///    lxor = 131 (0x83)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type long. They are popped
///    from the operand stack. A long result is calculated by taking
///    the bitwise exclusive OR of value1 and value2. The result is
///    pushed onto the operand stack.
fn lxor(ctx: Context) void {
    const value2 = ctx.f.pop().as(long).long;
    const value1 = ctx.f.pop().as(long).long;

    ctx.f.push(.{ .long = value1 ^ value2 });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.iinc
/// Operation
///    Increment local variable by constant
/// Format
///    iinc
///    index
///    const
/// Forms
///    iinc = 132 (0x84)
/// Operand Stack
///    No change
/// Description
///    The index is an unsigned byte that must be an index into the
///    local variable array of the current frame
///    (§2.6). The const is an
///    immediate signed byte. The local variable at index must contain
///    an int. The value const is first
///    sign-extended to an int, and then the local variable at index
///    is incremented by that amount.
/// Notes
///    The iinc opcode can be used in conjunction with the wide
///    instruction (§wide) to access a local
///    variable using a two-byte unsigned index and to increment it by a
///    two-byte immediate signed value.
fn iinc(ctx: Context) void {
    const index = ctx.f.immidiate(u8);
    const inc = ctx.f.immidiate(i8);
    const value = ctx.f.load(index).as(int).int;

    ctx.f.store(index, .{ .int = value + inc });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.i2l
/// Operation
///    Convert int to long
/// Format
///    i2l
/// Forms
///    i2l = 133 (0x85)
/// Operand Stack
///    ..., value →
///    ..., result
/// Description
///    The value on the top of the operand stack must be of type
///    int. It is popped from the operand stack and sign-extended to a
///    long result. That result is pushed onto the operand
///    stack.
/// Notes
///    The i2l instruction performs a widening primitive conversion
///    (JLS §5.1.2). Because all values of type int are exactly
///    representable by type long, the conversion is exact.
fn i2l(ctx: Context) void {
    const value = ctx.f.pop().as(int).int;

    ctx.f.push(.{ .long = value });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.i2f
/// Operation
///    Convert int to float
/// Format
///    i2f
/// Forms
///    i2f = 134 (0x86)
/// Operand Stack
///    ..., value →
///    ..., result
/// Description
///    The value on the top of the operand stack must be of type
///    int. It is popped from the operand stack and converted to the
///    float result using IEEE 754 round to nearest mode. The
///    result is pushed onto the operand stack.
/// Notes
///    The i2f instruction performs a widening primitive conversion
///    (JLS §5.1.2), but may result in a loss of precision because values
///    of type float have only 24 significand bits.
fn i2f(ctx: Context) void {
    const value = ctx.f.pop().as(int).int;

    ctx.f.push(.{ .float = @bitCast(value) });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.i2d
/// Operation
///    Convert int to double
/// Format
///    i2d
/// Forms
///    i2d = 135 (0x87)
/// Operand Stack
///    ..., value →
///    ..., result
/// Description
///    The value on the top of the operand stack must be of type
///    int. It is popped from the operand stack and converted to a
///    double result. The result is pushed onto the operand
///    stack.
/// Notes
///    The i2d instruction performs a widening primitive conversion
///    (JLS §5.1.2). Because all values of type int are exactly
///    representable by type double, the conversion is exact.
fn i2d(ctx: Context) void {
    const value = ctx.f.pop().as(int).int;

    const v: i64 = value;
    ctx.f.push(.{ .double = @bitCast(v) });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.l2i
/// Operation
///    Convert long to int
/// Format
///    l2i
/// Forms
///    l2i = 136 (0x88)
/// Operand Stack
///    ..., value →
///    ..., result
/// Description
///    The value on the top of the operand stack must be of type
///    long. It is popped from the operand stack and converted to an
///    int result by taking the low-order 32 bits of the long value
///    and discarding the high-order 32 bits. The result is pushed onto
///    the operand stack.
/// Notes
///    The l2i instruction performs a narrowing primitive conversion
///    (JLS §5.1.3). It may lose information about the overall magnitude
///    of value. The result may also not have the same sign as
///    value.
fn l2i(ctx: Context) void {
    const value = ctx.f.pop().as(long).long;

    ctx.f.push(.{ .int = @truncate(value) });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.l2f
/// Operation
///    Convert long to float
/// Format
///    l2f
/// Forms
///    l2f = 137 (0x89)
/// Operand Stack
///    ..., value →
///    ..., result
/// Description
///    The value on the top of the operand stack must be of type
///    long. It is popped from the operand stack and converted to a
///    float result using IEEE 754 round to nearest mode. The
///    result is pushed onto the operand stack.
/// Notes
///    The l2f instruction performs a widening primitive conversion
///    (JLS §5.1.2) that may lose precision because values of type
///    float have only 24 significand bits.
fn l2f(ctx: Context) void {
    const value = ctx.f.pop().as(long).long;

    const f: i32 = @truncate(value);
    ctx.f.push(.{ .float = @bitCast(f) });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.l2d
/// Operation
///    Convert long to double
/// Format
///    l2d
/// Forms
///    l2d = 138 (0x8a)
/// Operand Stack
///    ..., value →
///    ..., result
/// Description
///    The value on the top of the operand stack must be of type
///    long. It is popped from the operand stack and converted to a
///    double result using IEEE 754 round to nearest mode. The
///    result is pushed onto the operand stack.
/// Notes
///    The l2d instruction performs a widening primitive conversion
///    (JLS §5.1.2) that may lose precision because values of type
///    double have only 53 significand bits.
fn l2d(ctx: Context) void {
    const value = ctx.f.pop().as(long).long;

    ctx.f.push(.{ .double = @bitCast(value) });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.f2i
/// Operation
///    Convert float to int
/// Format
///    f2i
/// Forms
///    f2i = 139 (0x8b)
/// Operand Stack
///    ..., value →
///    ..., result
/// Description
///    The value on the top of the operand stack must be of type
///    float. It is popped from the operand stack and undergoes value
///    set conversion (§2.8.3), resulting in
///    value'. Then value' is converted to an int result. This
///    result is pushed onto the operand stack:
///    If the value' is NaN, the result of the conversion is an
///    int 0.
///    Otherwise, if the value' is not an infinity, it is rounded
///    to an integer value V, rounding towards zero using IEEE 754
///    round towards zero mode. If this integer value V can be
///    represented as an int, then the result is the int value
///    V.
///    Otherwise, either the value' must be too small (a negative
///    value of large magnitude or negative infinity), and the
///    result is the smallest representable value of type int, or
///    the value' must be too large (a positive value of large
///    magnitude or positive infinity), and the result is the
///    largest representable value of type int.
/// Notes
///    The f2i instruction performs a narrowing primitive conversion
///    (JLS §5.1.3). It may lose information about the overall magnitude
///    of value' and may also lose precision.
fn f2i(ctx: Context) void {
    const value = ctx.f.pop().as(float).float;

    ctx.f.push(.{ .int = @bitCast(value) });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.f2l
/// Operation
///    Convert float to long
/// Format
///    f2l
/// Forms
///    f2l = 140 (0x8c)
/// Operand Stack
///    ..., value →
///    ..., result
/// Description
///    The value on the top of the operand stack must be of type
///    float. It is popped from the operand stack and undergoes value
///    set conversion (§2.8.3), resulting in
///    value'. Then value' is converted to a long result. This
///    result is pushed onto the operand stack:
///    If the value' is NaN, the result of the conversion is a
///    long 0.
///    Otherwise, if the value' is not an infinity, it is rounded
///    to an integer value V, rounding towards zero using IEEE 754
///    round towards zero mode. If this integer value V can be
///    represented as a long, then the result is the long value
///    V.
///    Otherwise, either the value' must be too small (a negative
///    value of large magnitude or negative infinity), and the
///    result is the smallest representable value of type long,
///    or the value' must be too large (a positive value of large
///    magnitude or positive infinity), and the result is the
///    largest representable value of type long.
/// Notes
///    The f2l instruction performs a narrowing primitive conversion
///    (JLS §5.1.3). It may lose information about the overall magnitude
///    of value' and may also lose precision.
fn f2l(ctx: Context) void {
    const value = ctx.f.pop().as(float).float;

    ctx.f.push(.{ .long = @as(i32, @bitCast(value)) });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.f2d
/// Operation
///    Convert float to double
/// Format
///    f2d
/// Forms
///    f2d = 141 (0x8d)
/// Operand Stack
///    ..., value →
///    ..., result
/// Description
///    The value on the top of the operand stack must be of type
///    float. It is popped from the operand stack and undergoes value
///    set conversion (§2.8.3), resulting in
///    value'. Then value' is converted to a double result. This
///    result is pushed onto the operand stack.
/// Notes
///    Where an f2d instruction is FP-strict
///    (§2.8.2) it performs a widening primitive
///    conversion (JLS §5.1.2). Because all values of the float value set
///    (§2.3.2) are exactly representable by values
///    of the double value set (§2.3.2), such a
///    conversion is exact.
///    Where an f2d instruction is not FP-strict, the result of the
///    conversion may be taken from the double-extended-exponent value
///    set; it is not necessarily rounded to the nearest representable
///    value in the double value set. However, if the operand value is
///    taken from the float-extended-exponent value set and the target
///    result is constrained to the double value set, rounding of value
///    may be required.
fn f2d(ctx: Context) void {
    const value = ctx.f.pop().as(float).float;

    ctx.f.push(.{ .double = value });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.d2i
/// Operation
///    Convert double to int
/// Format
///    d2i
/// Forms
///    d2i = 142 (0x8e)
/// Operand Stack
///    ..., value →
///    ..., result
/// Description
///    The value on the top of the operand stack must be of type
///    double. It is popped from the operand stack and undergoes value
///    set conversion (§2.8.3) resulting in
///    value'. Then value' is converted to an int. The result is
///    pushed onto the operand stack:
///    If the value' is NaN, the result of the conversion is an
///    int 0.
///    Otherwise, if the value' is not an infinity, it is rounded
///    to an integer value V, rounding towards zero using IEEE 754
///    round towards zero mode. If this integer value V can be
///    represented as an int, then the result is the int value
///    V.
///    Otherwise, either the value' must be too small (a negative
///    value of large magnitude or negative infinity), and the
///    result is the smallest representable value of type int, or
///    the value' must be too large (a positive value of large
///    magnitude or positive infinity), and the result is the
///    largest representable value of type int.
/// Notes
///    The d2i instruction performs a narrowing primitive conversion
///    (JLS §5.1.3). It may lose information about the overall magnitude
///    of value' and may also lose precision.
fn d2i(ctx: Context) void {
    const value = ctx.f.pop().as(double).double;

    const v: i64 = @bitCast(value);
    ctx.f.push(.{ .int = @truncate(v) });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.d2l
/// Operation
///    Convert double to long
/// Format
///    d2l
/// Forms
///    d2l = 143 (0x8f)
/// Operand Stack
///    ..., value →
///    ..., result
/// Description
///    The value on the top of the operand stack must be of type
///    double. It is popped from the operand stack and undergoes value
///    set conversion (§2.8.3) resulting in
///    value'. Then value' is converted to a long. The result is
///    pushed onto the operand stack:
///    If the value' is NaN, the result of the conversion is a
///    long 0.
///    Otherwise, if the value' is not an infinity, it is rounded
///    to an integer value V, rounding towards zero using IEEE 754
///    round towards zero mode. If this integer value V can be
///    represented as a long, then the result is the long value
///    V.
///    Otherwise, either the value' must be too small (a negative
///    value of large magnitude or negative infinity), and the result
///    is the smallest representable value of type long, or the
///    value' must be too large (a positive value of large magnitude
///    or positive infinity), and the result is the largest
///    representable value of type long.
/// Notes
///    The d2l instruction performs a narrowing primitive conversion
///    (JLS §5.1.3). It may lose information about the overall magnitude
///    of value' and may also lose precision.
fn d2l(ctx: Context) void {
    const value = ctx.f.pop().as(double).double;

    ctx.f.push(.{ .long = @bitCast(value) });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.d2f
/// Operation
///    Convert double to float
/// Format
///    d2f
/// Forms
///    d2f = 144 (0x90)
/// Operand Stack
///    ..., value →
///    ..., result
/// Description
///    The value on the top of the operand stack must be of type
///    double. It is popped from the operand stack and undergoes value
///    set conversion (§2.8.3) resulting in
///    value'. Then value' is converted to a float result using
///    IEEE 754 round to nearest mode. The result is pushed onto the
///    operand stack.
///    Where an d2f instruction is FP-strict
///    (§2.8.2), the result of the conversion is
///    always rounded to the nearest representable value in the float
///    value set (§2.3.2).
///    Where an d2f instruction is not FP-strict, the result of the
///    conversion may be taken from the float-extended-exponent value set
///    (§2.3.2); it is not necessarily rounded to
///    the nearest representable value in the float value set.
///    A finite value' too small to be represented as a float is
///    converted to a zero of the same sign; a finite value' too large
///    to be represented as a float is converted to an infinity of the
///    same sign. A double NaN is converted to a float NaN.
/// Notes
///    The d2f instruction performs a narrowing primitive conversion
///    (JLS §5.1.3). It may lose information about the overall magnitude
///    of value' and may also lose precision.
fn d2f(ctx: Context) void {
    const value = ctx.f.pop().as(double).double;

    const d: i64 = @bitCast(value);
    const f: i32 = @truncate(d);
    ctx.f.push(.{ .float = @bitCast(f) });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.i2b
/// Operation
///    Convert int to byte
/// Format
///    i2b
/// Forms
///    i2b = 145 (0x91)
/// Operand Stack
///    ..., value →
///    ..., result
/// Description
///    The value on the top of the operand stack must be of type
///    int. It is popped from the operand stack, truncated to a byte,
///    then sign-extended to an int result. That result is pushed
///    onto the operand stack.
/// Notes
///    The i2b instruction performs a narrowing primitive conversion
///    (JLS §5.1.3). It may lose information about the overall magnitude
///    of value. The result may also not have the same sign as
///    value.
fn i2b(ctx: Context) void {
    const value = ctx.f.pop().as(int).int;

    ctx.f.push(.{ .byte = @truncate(value) });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.i2c
/// Operation
///    Convert int to char
/// Format
///    i2c
/// Forms
///    i2c = 146 (0x92)
/// Operand Stack
///    ..., value →
///    ..., result
/// Description
///    The value on the top of the operand stack must be of type
///    int. It is popped from the operand stack, truncated to char,
///    then zero-extended to an int result. That result is pushed
///    onto the operand stack.
/// Notes
///    The i2c instruction performs a narrowing primitive conversion
///    (JLS §5.1.3). It may lose information about the overall magnitude
///    of value. The result (which is always positive) may also not
///    have the same sign as value.
fn i2c(ctx: Context) void {
    const value = ctx.f.pop().as(int).int;

    const v: u32 = @bitCast(value);
    const ch: char = @truncate(v);
    ctx.f.push(.{ .int = ch });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.i2s
/// Operation
///    Convert int to short
/// Format
///    i2s
/// Forms
///    i2s = 147 (0x93)
/// Operand Stack
///    ..., value →
///    ..., result
/// Description
///    The value on the top of the operand stack must be of type
///    int. It is popped from the operand stack, truncated to a
///    short, then sign-extended to an int result. That result is
///    pushed onto the operand stack.
/// Notes
///    The i2s instruction performs a narrowing primitive conversion
///    (JLS §5.1.3). It may lose information about the overall magnitude
///    of value. The result may also not have the same sign as
///    value.
fn i2s(ctx: Context) void {
    const value = ctx.f.pop().as(int).int;

    const s: short = @truncate(value);
    ctx.f.push(.{ .int = s });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.lcmp
/// Operation
///    Compare long
/// Format
///    lcmp
/// Forms
///    lcmp = 148 (0x94)
/// Operand Stack
///    ..., value1, value2 →
///    ..., result
/// Description
///    Both value1 and value2 must be of type long. They are both
///    popped from the operand stack, and a signed integer comparison is
///    performed. If value1 is greater than value2, the int value 1
///    is pushed onto the operand stack. If value1 is equal to
///    value2, the int value 0 is pushed onto the operand stack. If
///    value1 is less than value2, the int value -1 is pushed onto
///    the operand stack.
fn lcmp(ctx: Context) void {
    const value2 = ctx.f.pop().long;
    const value1 = ctx.f.pop().long;

    ctx.f.push(.{ .int = if (value1 < value2) -1 else if (value1 == value2) 0 else 1 });
}

fn fcmpl(ctx: Context) void {
    const value2 = ctx.f.pop().float;
    const value1 = ctx.f.pop().float;

    if (std.math.isNan(value1) or std.math.isNan(value2) or value1 < value2) {
        ctx.f.push(.{ .int = -1 });
    } else if (value1 == value2) {
        ctx.f.push(.{ .int = 0 });
    } else {
        ctx.f.push(.{ .int = 1 });
    }
}

fn fcmpg(ctx: Context) void {
    const value2 = ctx.f.pop().float;
    const value1 = ctx.f.pop().float;

    if (std.math.isNan(value1) or std.math.isNan(value2) or value1 > value2) {
        ctx.f.push(.{ .int = 1 });
    } else if (value1 == value2) {
        ctx.f.push(.{ .int = 0 });
    } else {
        ctx.f.push(.{ .int = -1 });
    }
}

fn dcmpl(ctx: Context) void {
    const value2 = ctx.f.pop().double;
    const value1 = ctx.f.pop().double;

    if (std.math.isNan(value1) or std.math.isNan(value2) or value1 < value2) {
        ctx.f.push(.{ .int = -1 });
    } else if (value1 == value2) {
        ctx.f.push(.{ .int = 0 });
    } else {
        ctx.f.push(.{ .int = 1 });
    }
}

fn dcmpg(ctx: Context) void {
    const value2 = ctx.f.pop().double;
    const value1 = ctx.f.pop().double;

    if (std.math.isNan(value1) or std.math.isNan(value2) or value1 > value2) {
        ctx.f.push(.{ .int = 1 });
    } else if (value1 == value2) {
        ctx.f.push(.{ .int = 0 });
    } else {
        ctx.f.push(.{ .int = -1 });
    }
}

fn ifeq(ctx: Context) void {
    const offset = ctx.f.immidiate(i16);
    const value = ctx.f.pop().int;

    if (value == 0) {
        ctx.f.next(offset);
    }
}

fn ifne(ctx: Context) void {
    const offset = ctx.f.immidiate(i16);
    const value = ctx.f.pop().int;

    if (value != 0) {
        ctx.f.next(offset);
    }
}

fn iflt(ctx: Context) void {
    const offset = ctx.f.immidiate(i16);
    const value = ctx.f.pop().int;

    if (value < 0) {
        ctx.f.next(offset);
    }
}

fn ifge(ctx: Context) void {
    const offset = ctx.f.immidiate(i16);
    const value = ctx.f.pop().int;

    if (value >= 0) {
        ctx.f.next(offset);
    }
}

fn ifgt(ctx: Context) void {
    const offset = ctx.f.immidiate(i16);
    const value = ctx.f.pop().int;

    if (value > 0) {
        ctx.f.next(offset);
    }
}

fn ifle(ctx: Context) void {
    const offset = ctx.f.immidiate(i16);
    const value = ctx.f.pop().int;

    if (value <= 0) {
        ctx.f.next(offset);
    }
}

fn if_icmpeq(ctx: Context) void {
    const offset = ctx.f.immidiate(i16);
    const value2 = ctx.f.pop().int;
    const value1 = ctx.f.pop().int;

    if (value1 == value2) {
        ctx.f.next(offset);
    }
}

fn if_icmpne(ctx: Context) void {
    const offset = ctx.f.immidiate(i16);
    const value2 = ctx.f.pop().int;
    const value1 = ctx.f.pop().int;

    if (value1 != value2) {
        ctx.f.next(offset);
    }
}

fn if_icmplt(ctx: Context) void {
    const offset = ctx.f.immidiate(i16);
    const value2 = ctx.f.pop().int;
    const value1 = ctx.f.pop().int;

    if (value1 < value2) {
        ctx.f.next(offset);
    }
}

fn if_icmpge(ctx: Context) void {
    const offset = ctx.f.immidiate(i16);
    const value2 = ctx.f.pop().int;
    const value1 = ctx.f.pop().int;

    if (value1 >= value2) {
        ctx.f.next(offset);
    }
}

fn if_icmpgt(ctx: Context) void {
    const offset = ctx.f.immidiate(i16);
    const value2 = ctx.f.pop().int;
    const value1 = ctx.f.pop().int;

    if (value1 > value2) {
        ctx.f.next(offset);
    }
}

fn if_icmple(ctx: Context) void {
    const offset = ctx.f.immidiate(i16);
    const value2 = ctx.f.pop().int;
    const value1 = ctx.f.pop().int;

    if (value1 <= value2) {
        ctx.f.next(offset);
    }
}

fn if_acmpeq(ctx: Context) void {
    const offset = ctx.f.immidiate(i16);
    const value2 = ctx.f.pop().ref;
    const value1 = ctx.f.pop().ref;

    if (value1.ptr == value2.ptr) {
        ctx.f.next(offset);
    }
}

fn if_acmpne(ctx: Context) void {
    const offset = ctx.f.immidiate(i16);
    const value2 = ctx.f.pop().ref;
    const value1 = ctx.f.pop().ref;

    if (value1.ptr != value2.ptr) {
        ctx.f.next(offset);
    }
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.goto
/// Operation
///    Branch always
/// Format
///    goto
///    branchbyte1
///    branchbyte2
/// Forms
///    goto = 167 (0xa7)
/// Operand Stack
///    No change
/// Description
///    The unsigned bytes branchbyte1 and branchbyte2 are used to
///    construct a signed 16-bit branchoffset, where branchoffset is
///    (branchbyte1 << 8) | branchbyte2. Execution proceeds at
///    that offset from the address of the opcode of this goto
///    instruction. The target address must be that of an opcode of an
///    instruction within the method that contains this goto
///    instruction.
fn goto(ctx: Context) void {
    const offset = ctx.f.immidiate(i16);

    ctx.f.next(offset);
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.jsr
/// Operation
///    Jump subroutine
/// Format
///    jsr
///    branchbyte1
///    branchbyte2
/// Forms
///    jsr = 168 (0xa8)
/// Operand Stack
///    ... →
///    ..., address
/// Description
///    The address of the opcode of the instruction immediately
///    following this jsr instruction is pushed onto the operand stack
///    as a value of type returnAddress. The unsigned branchbyte1 and
///    branchbyte2 are used to construct a signed 16-bit offset, where
///    the offset is (branchbyte1 << 8) |
///    branchbyte2. Execution proceeds at that offset from the address
///    of this jsr instruction. The target address must be that of an
///    opcode of an instruction within the method that contains this
///    jsr instruction.
/// Notes
///    Note that jsr pushes the address onto the operand stack and
///    ret (§ret) gets it out of a local
///    variable. This asymmetry is intentional.
///    In Oracle's implementation of a compiler for the Java programming language prior
///    to Java SE 6, the jsr instruction was used with the ret
///    instruction in the implementation of the finally clause
///    (§3.13, §4.10.2.5).
fn jsr(ctx: Context) void {
    _ = ctx;
    @panic("instruction not implemented");
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.ret
/// Operation
///    Return from subroutine
/// Format
///    ret
///    index
/// Forms
///    ret = 169 (0xa9)
/// Operand Stack
///    No change
/// Description
///    The index is an unsigned byte between 0 and 255, inclusive. The
///    local variable at index in the current frame
///    (§2.6) must contain a value of type
///    returnAddress. The contents of the local variable are written
///    into the Java Virtual Machine's pc register, and execution continues
///    there.
/// Notes
///    Note that jsr (§jsr) pushes the
///    address onto the operand stack and ret gets it out of a local
///    variable. This asymmetry is intentional.
///    In Oracle's implementation of a compiler for the Java programming language prior
///    to Java SE 6, the ret instruction was used with the jsr and
///    jsr_w instructions (§jsr,
///    §jsr_w) in the implementation of the
///    finally clause (§3.13,
///    §4.10.2.5).
///    The ret instruction should not be confused with the return
///    instruction (§return). A return
///    instruction returns control from a method to its invoker, without
///    passing any value back to the invoker.
///    The ret opcode can be used in conjunction with the wide
///    instruction (§wide) to access a local
///    variable using a two-byte unsigned index.
fn ret(ctx: Context) void {
    _ = ctx;
    @panic("instruction not implemented");
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.tableswitch
/// Operation
///    Access jump table by index and jump
/// Format
///    tableswitch
///    <0-3 byte pad>
///    defaultbyte1
///    defaultbyte2
///    defaultbyte3
///    defaultbyte4
///    lowbyte1
///    lowbyte2
///    lowbyte3
///    lowbyte4
///    highbyte1
///    highbyte2
///    highbyte3
///    highbyte4
///    jump offsets...
/// Forms
///    tableswitch = 170 (0xaa)
/// Operand Stack
///    ..., index →
///    ...
/// Description
///    A tableswitch is a variable-length instruction. Immediately
///    after the tableswitch opcode, between zero and three bytes must
///    act as padding, such that defaultbyte1 begins
///    at an address that is a multiple of four bytes from the start of
///    the current method (the opcode of its first
///    instruction). Immediately after the padding are bytes constituting
///    three signed 32-bit values: default,
///    low, and high.
///    Immediately following are bytes constituting a series
///    of high - low + 1 signed
///    32-bit offsets. The value low must be less
///    than or equal to high.
///    The high - low + 1
///    signed 32-bit offsets are treated as a 0-based jump table. Each of
///    these signed 32-bit values is constructed as
///    (byte1 << 24) |
///    (byte2 << 16) |
///    (byte3 << 8)
///    | byte4.
///    The index must be of type int and is popped from the operand
///    stack. If index is less than low or index
///    is greater than high, then a target address
///    is calculated by adding default to the
///    address of the opcode of this tableswitch
///    instruction. Otherwise, the offset at position
///    index - low of the jump
///    table is extracted. The target address is calculated by adding
///    that offset to the address of the opcode of this tableswitch
///    instruction. Execution then continues at the target
///    address.
///    The target address that can be calculated from each jump table
///    offset, as well as the one that can be calculated
///    from default, must be the address of an
///    opcode of an instruction within the method that contains this
///    tableswitch instruction.
/// Notes
///    The alignment required of the 4-byte operands of the tableswitch
///    instruction guarantees 4-byte alignment of those operands if and
///    only if the method that contains the tableswitch starts on a
///    4-byte boundary.
fn tableswitch(ctx: Context) void {
    ctx.f.padding();

    const defaultOffset = ctx.f.immidiate(i32);
    const low = ctx.f.immidiate(i32);
    const high = ctx.f.immidiate(i32);

    const offsets = make(i32, @intCast(high - low + 1), vm_allocator);
    for (0..offsets.len) |i| {
        offsets[i] = ctx.f.immidiate(i32);
    }

    const index = ctx.f.pop().int;

    if (index < low or index > high) {
        ctx.f.next(defaultOffset);
    } else {
        ctx.f.next(offsets[@intCast(index - low)]);
    }
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.lookupswitch
/// Operation
///    Access jump table by key match and jump
/// Format
///    lookupswitch
///    <0-3 byte pad>
///    defaultbyte1
///    defaultbyte2
///    defaultbyte3
///    defaultbyte4
///    npairs1
///    npairs2
///    npairs3
///    npairs4
///    match-offset pairs...
/// Forms
///    lookupswitch = 171 (0xab)
/// Operand Stack
///    ..., key →
///    ...
/// Description
///    A lookupswitch is a variable-length instruction. Immediately
///    after the lookupswitch opcode, between zero and three bytes must
///    act as padding, such that defaultbyte1 begins
///    at an address that is a multiple of four bytes from the start of
///    the current method (the opcode of its first
///    instruction). Immediately after the padding follow a series of
///    signed 32-bit
///    values: default, npairs,
///    and then npairs pairs of signed 32-bit
///    values. The npairs must be greater than or
///    equal to 0. Each of the npairs pairs consists
///    of an int match and a signed
///    32-bit offset. Each of these signed 32-bit
///    values is constructed from four unsigned bytes as
///    (byte1 << 24) |
///    (byte2 << 16) |
///    (byte3 << 8)
///    | byte4.
///    The table match-offset pairs of the
///    lookupswitch instruction must be sorted in increasing numerical
///    order by match.
///    The key must be of type int and is popped
///    from the operand stack. The key is compared
///    against the match values. If it is equal to
///    one of them, then a target address is calculated by adding the
///    corresponding offset to the address of the
///    opcode of this lookupswitch instruction. If
///    the key does not match any of
///    the match values, the target address is
///    calculated by adding default to the address
///    of the opcode of this lookupswitch instruction. Execution then
///    continues at the target address.
///    The target address that can be calculated from the
///    offset of
///    each match-offset pair, as well as the one
///    calculated from default, must be the address
///    of an opcode of an instruction within the method that contains
///    this lookupswitch instruction.
/// Notes
///    The alignment required of the 4-byte operands of the
///    lookupswitch instruction guarantees 4-byte alignment of those
///    operands if and only if the method that contains the
///    lookupswitch is positioned on a 4-byte boundary.
///    The match-offset pairs are sorted to support
///    lookup routines that are quicker than linear search.
fn lookupswitch(ctx: Context) void {
    ctx.f.padding();

    const defaultOffset = ctx.f.immidiate(i32);
    const npairs = ctx.f.immidiate(i32);

    const matches = make(i32, @intCast(npairs), vm_allocator);
    const offsets = make(i32, @intCast(npairs), vm_allocator);

    for (0..@intCast(npairs)) |i| {
        matches[i] = ctx.f.immidiate(i32);
        offsets[i] = ctx.f.immidiate(i32);
    }

    const key = ctx.f.pop().int;

    var matched = false;
    for (0..@intCast(npairs)) |i| {
        if (key == matches[i]) {
            ctx.f.next(offsets[i]);
            matched = true;
            break;
        }
    }

    if (!matched) {
        ctx.f.next(defaultOffset);
    }
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.ireturn
/// Operation
///    Return int from method
/// Format
///    ireturn
/// Forms
///    ireturn = 172 (0xac)
/// Operand Stack
///    ..., value →
///    [empty]
/// Description
///    The current method must have return type boolean, byte,
///    short, char, or int. The value must be of type int. If
///    the current method is a synchronized method, the monitor entered
///    or reentered on invocation of the method is updated and possibly
///    exited as if by execution of a monitorexit instruction
///    (§monitorexit) in the current thread. If
///    no exception is thrown, value is popped from the operand stack
///    of the current frame (§2.6) and pushed onto
///    the operand stack of the frame of the invoker. Any other values on
///    the operand stack of the current method are discarded.
///    The interpreter then returns control to the invoker of the method,
///    reinstating the frame of the invoker.
/// Run-time Exceptions
///    If the Java Virtual Machine implementation does not enforce the rules on
///    structured locking described in §2.11.10,
///    then if the current method is a synchronized method and the
///    current thread is not the owner of the monitor entered or
///    reentered on invocation of the method, ireturn throws an
///    IllegalMonitorStateException. This can happen, for example, if a
///    synchronized method contains a monitorexit instruction, but no
///    monitorenter instruction, on the object on which the method is
///    synchronized.
///    Otherwise, if the Java Virtual Machine implementation enforces the rules on
///    structured locking described in §2.11.10 and
///    if the first of those rules is violated during invocation of the
///    current method, then ireturn throws an
///    IllegalMonitorStateException.
fn ireturn(ctx: Context) void {
    ctx.f.return_(.{ .int = ctx.f.pop().int });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.lreturn
/// Operation
///    Return long from method
/// Format
///    lreturn
/// Forms
///    lreturn = 173 (0xad)
/// Operand Stack
///    ..., value →
///    [empty]
/// Description
///    The current method must have return type long. The value must
///    be of type long. If the current method is a synchronized
///    method, the monitor entered or reentered on invocation of the
///    method is updated and possibly exited as if by execution of a
///    monitorexit instruction (§monitorexit)
///    in the current thread. If no exception is thrown, value is
///    popped from the operand stack of the current frame
///    (§2.6) and pushed onto the operand stack of
///    the frame of the invoker. Any other values on the operand stack of
///    the current method are discarded.
///    The interpreter then returns control to the invoker of the method,
///    reinstating the frame of the invoker.
/// Run-time Exceptions
///    If the Java Virtual Machine implementation does not enforce the rules on
///    structured locking described in §2.11.10,
///    then if the current method is a synchronized method and the
///    current thread is not the owner of the monitor entered or
///    reentered on invocation of the method, lreturn throws an
///    IllegalMonitorStateException. This can happen, for example, if a
///    synchronized method contains a monitorexit instruction, but no
///    monitorenter instruction, on the object on which the method is
///    synchronized.
///    Otherwise, if the Java Virtual Machine implementation enforces the rules on
///    structured locking described in §2.11.10 and
///    if the first of those rules is violated during invocation of the
///    current method, then lreturn throws an
///    IllegalMonitorStateException.
fn lreturn(ctx: Context) void {
    ctx.f.return_(.{ .long = ctx.f.pop().long });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.freturn
/// Operation
///    Return float from method
/// Format
///    freturn
/// Forms
///    freturn = 174 (0xae)
/// Operand Stack
///    ..., value →
///    [empty]
/// Description
///    The current method must have return type float. The value must
///    be of type float. If the current method is a synchronized
///    method, the monitor entered or reentered on invocation of the
///    method is updated and possibly exited as if by execution of a
///    monitorexit instruction (§monitorexit)
///    in the current thread. If no exception is thrown, value is
///    popped from the operand stack of the current frame
///    (§2.6) and undergoes value set conversion
///    (§2.8.3), resulting in value'. The
///    value' is pushed onto the operand stack of the frame of the
///    invoker. Any other values on the operand stack of the current
///    method are discarded.
///    The interpreter then returns control to the invoker of the method,
///    reinstating the frame of the invoker.
/// Run-time Exceptions
///    If the Java Virtual Machine implementation does not enforce the rules on
///    structured locking described in §2.11.10,
///    then if the current method is a synchronized method and the
///    current thread is not the owner of the monitor entered or
///    reentered on invocation of the method, freturn throws an
///    IllegalMonitorStateException. This can happen, for example, if a
///    synchronized method contains a monitorexit instruction, but no
///    monitorenter instruction, on the object on which the method is
///    synchronized.
///    Otherwise, if the Java Virtual Machine implementation enforces the rules on
///    structured locking described in §2.11.10 and
///    if the first of those rules is violated during invocation of the
///    current method, then freturn throws an
///    IllegalMonitorStateException.
fn freturn(ctx: Context) void {
    ctx.f.return_(.{ .float = ctx.f.pop().float });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.dreturn
/// Operation
///    Return double from method
/// Format
///    dreturn
/// Forms
///    dreturn = 175 (0xaf)
/// Operand Stack
///    ..., value →
///    [empty]
/// Description
///    The current method must have return type double. The value
///    must be of type double. If the current method is a
///    synchronized method, the monitor entered or reentered on
///    invocation of the method is updated and possibly exited as if by
///    execution of a monitorexit instruction
///    (§monitorexit) in the current thread. If
///    no exception is thrown, value is popped from the operand stack
///    of the current frame (§2.6) and undergoes
///    value set conversion (§2.8.3), resulting in
///    value'. The value' is pushed onto the operand stack of the
///    frame of the invoker. Any other values on the operand stack of the
///    current method are discarded.
///    The interpreter then returns control to the invoker of the method,
///    reinstating the frame of the invoker.
/// Run-time Exceptions
///    If the Java Virtual Machine implementation does not enforce the rules on
///    structured locking described in §2.11.10,
///    then if the current method is a synchronized method and the
///    current thread is not the owner of the monitor entered or
///    reentered on invocation of the method, dreturn throws an
///    IllegalMonitorStateException. This can happen, for example, if a
///    synchronized method contains a monitorexit instruction, but no
///    monitorenter instruction, on the object on which the method is
///    synchronized.
///    Otherwise, if the Java Virtual Machine implementation enforces the rules on
///    structured locking described in §2.11.10 and
///    if the first of those rules is violated during invocation of the
///    current method, then dreturn throws an
///    IllegalMonitorStateException.
fn dreturn(ctx: Context) void {
    ctx.f.return_(.{ .double = ctx.f.pop().double });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.areturn
/// Operation
///    Return reference from method
/// Format
///    areturn
/// Forms
///    areturn = 176 (0xb0)
/// Operand Stack
///    ..., objectref →
///    [empty]
/// Description
///    The objectref must be of type reference and must refer to an object
///    of a type that is assignment compatible (JLS §5.2) with the type
///    represented by the return descriptor
///    (§4.3.3) of the current method. If the
///    current method is a synchronized method, the monitor entered or
///    reentered on invocation of the method is updated and possibly
///    exited as if by execution of a monitorexit instruction
///    (§monitorexit) in the current thread. If
///    no exception is thrown, objectref is popped from the operand
///    stack of the current frame (§2.6) and pushed
///    onto the operand stack of the frame of the invoker. Any other
///    values on the operand stack of the current method are
///    discarded.
///    The interpreter then reinstates the frame of the invoker and
///    returns control to the invoker.
/// Run-time Exceptions
///    If the Java Virtual Machine implementation does not enforce the rules on
///    structured locking described in §2.11.10,
///    then if the current method is a synchronized method and the
///    current thread is not the owner of the monitor entered or
///    reentered on invocation of the method, areturn throws an
///    IllegalMonitorStateException. This can happen, for example, if a
///    synchronized method contains a monitorexit instruction, but no
///    monitorenter instruction, on the object on which the method is
///    synchronized.
///    Otherwise, if the Java Virtual Machine implementation enforces the rules on
///    structured locking described in §2.11.10 and
///    if the first of those rules is violated during invocation of the
///    current method, then areturn throws an
///    IllegalMonitorStateException.
fn areturn(ctx: Context) void {
    ctx.f.return_(.{ .ref = ctx.f.pop().ref });
}

/// void return
fn return_(ctx: Context) void {
    ctx.f.return_(null);
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.getstatic
/// Operation
///    Get static field from class
/// Format
///    getstatic
///    indexbyte1
///    indexbyte2
/// Forms
///    getstatic = 178 (0xb2)
/// Operand Stack
///    ..., →
///    ..., value
/// Description
///    The unsigned indexbyte1 and indexbyte2 are used to construct
///    an index into the run-time constant pool of the current class
///    (§2.6), where the value of the index is
///    (indexbyte1 << 8) | indexbyte2. The run-time constant
///    pool item at that index must be a symbolic reference to a field
///    (§5.1), which gives the name and descriptor
///    of the field as well as a symbolic reference to the class or
///    interface in which the field is to be found. The referenced field
///    is resolved (§5.4.3.2).
///    On successful resolution of the field, the class or interface that
///    declared the resolved field is initialized
///    (§5.5) if that class or interface has not
///    already been initialized.
///    The value of the class or interface field is fetched and pushed
///    onto the operand stack.
/// Linking Exceptions
///    During resolution of the symbolic reference to the class or
///    interface field, any of the exceptions pertaining to field
///    resolution (§5.4.3.2) can be thrown.
///    Otherwise, if the resolved field is not a static (class) field
///    or an interface field, getstatic throws an IncompatibleClassChangeError.
/// Run-time Exception
///    Otherwise, if execution of this getstatic instruction causes
///    initialization of the referenced class or interface, getstatic
///    may throw an Error as detailed in §5.5.
fn getstatic(ctx: Context) void {
    const index = ctx.f.immidiate(u16);

    const fieldref = ctx.c.constant(index).fieldref;
    const class = resolveClass(ctx.c, fieldref.class);
    const field = class.field(fieldref.name, fieldref.descriptor, true);
    if (field == null) {
        unreachable;
    }
    ctx.f.push(class.get(field.?.slot));
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.putstatic
/// Operation
///    Set static field in class
/// Format
///    putstatic
///    indexbyte1
///    indexbyte2
/// Forms
///    putstatic = 179 (0xb3)
/// Operand Stack
///    ..., value →
///    ...
/// Description
///    The unsigned indexbyte1 and indexbyte2 are used to construct
///    an index into the run-time constant pool of the current class
///    (§2.6), where the value of the index is
///    (indexbyte1 << 8) | indexbyte2. The run-time constant
///    pool item at that index must be a symbolic reference to a field
///    (§5.1), which gives the name and descriptor
///    of the field as well as a symbolic reference to the class or
///    interface in which the field is to be found. The referenced field
///    is resolved (§5.4.3.2).
///    On successful resolution of the field, the class or interface that
///    declared the resolved field is initialized
///    (§5.5) if that class or interface has not
///    already been initialized.
///    The type of a value stored by a putstatic instruction must be
///    compatible with the descriptor of the referenced field
///    (§4.3.2). If the field descriptor type is
///    boolean, byte, char, short, or int, then the value
///    must be an int. If the field descriptor type is float, long,
///    or double, then the value must be a float, long, or
///    double, respectively. If the field descriptor type is a
///    reference type, then the value must be of a type that is
///    assignment compatible (JLS §5.2) with the field descriptor
///    type. If the field is final, it must be declared in the current
///    class, and the instruction must occur in the <clinit> method of
///    the current class (§2.9).
///    The value is popped from the operand stack and undergoes value
///    set conversion (§2.8.3), resulting in
///    value'. The class field is set to value'.
/// Linking Exceptions
///    During resolution of the symbolic reference to the class or
///    interface field, any of the exceptions pertaining to field
///    resolution (§5.4.3.2) can be thrown.
///    Otherwise, if the resolved field is not a static (class) field
///    or an interface field, putstatic throws an IncompatibleClassChangeError.
///    Otherwise, if the field is final, it must be declared in the
///    current class, and the instruction must occur in the <clinit>
///    method of the current class. Otherwise, an IllegalAccessError is thrown.
/// Run-time Exception
///    Otherwise, if execution of this putstatic instruction causes
///    initialization of the referenced class or interface, putstatic
///    may throw an Error as detailed in
///    §5.5.
/// Notes
///    A putstatic instruction may be used only to set the value of an
///    interface field on the initialization of that field. Interface
///    fields may be assigned to only once, on execution of an interface
///    variable initialization expression when the interface is
///    initialized (§5.5, JLS §9.3.1).
fn putstatic(ctx: Context) void {
    const index = ctx.f.immidiate(u16);
    const value = ctx.f.pop();

    const fieldref = ctx.c.constant(index).fieldref;
    const class = resolveClass(ctx.c, fieldref.class);
    const field = class.field(fieldref.name, fieldref.descriptor, true);
    if (field == null) {
        unreachable;
    }
    class.set(field.?.slot, value);
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.getfield
/// Operation
///    Fetch field from object
/// Format
///    getfield
///    indexbyte1
///    indexbyte2
/// Forms
///    getfield = 180 (0xb4)
/// Operand Stack
///    ..., objectref →
///    ..., value
/// Description
///    The objectref, which must be of type reference, is popped from the
///    operand stack. The unsigned indexbyte1 and indexbyte2 are used
///    to construct an index into the run-time constant pool of the
///    current class (§2.6), where the value of the
///    index is (indexbyte1 << 8) | indexbyte2. The run-time
///    constant pool item at that index must be a symbolic reference to a
///    field (§5.1), which gives the name and
///    descriptor of the field as well as a symbolic reference to the
///    class in which the field is to be found. The referenced field is
///    resolved (§5.4.3.2). The value of the
///    referenced field in objectref is fetched and pushed onto the
///    operand stack.
///    The type of objectref must not be an array type. If the field is
///    protected, and it is a member of a superclass of the current
///    class, and the field is not declared in the same run-time package
///    (§5.3) as the current class, then the class
///    of objectref must be either the current class or a subclass of
///    the current class.
/// Linking Exceptions
///    During resolution of the symbolic reference to the field, any of
///    the errors pertaining to field resolution
///    (§5.4.3.2) can be thrown.
///    Otherwise, if the resolved field is a static field, getfield
///    throws an IncompatibleClassChangeError.
/// Run-time Exception
///    Otherwise, if objectref is null, the getfield instruction
///    throws a NullPointerException.
/// Notes
///    The getfield instruction cannot be used to access the length
///    field of an array. The arraylength instruction
///    (§arraylength) is used instead.
fn getfield(ctx: Context) void {
    const index = ctx.f.immidiate(u16);
    const objectref = ctx.f.pop().ref;

    if (objectref.isNull()) {
        unreachable;
    }

    const fieldref = ctx.c.constant(index).fieldref;
    const slot = resolveField(ctx.c, objectref.class(), fieldref);
    if (slot == null) {
        unreachable;
    }

    ctx.f.push(objectref.get(slot.?));
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.putfield
/// Operation
///    Set field in object
/// Format
///    putfield
///    indexbyte1
///    indexbyte2
/// Forms
///    putfield = 181 (0xb5)
/// Operand Stack
///    ..., objectref, value →
///    ...
/// Description
///    The unsigned indexbyte1 and indexbyte2 are used to construct
///    an index into the run-time constant pool of the current class
///    (§2.6), where the value of the index is
///    (indexbyte1 << 8) | indexbyte2. The run-time constant
///    pool item at that index must be a symbolic reference to a field
///    (§5.1), which gives the name and descriptor
///    of the field as well as a symbolic reference to the class in which
///    the field is to be found. The class of objectref must not be an
///    array. If the field is protected, and it is a member of a
///    superclass of the current class, and the field is not declared in
///    the same run-time package (§5.3) as the
///    current class, then the class of objectref must be either the
///    current class or a subclass of the current class.
///    The referenced field is resolved (§5.4.3.2).
///    The type of a value stored by a putfield instruction must be
///    compatible with the descriptor of the referenced field
///    (§4.3.2). If the field descriptor type is
///    boolean, byte, char, short, or int, then the value
///    must be an int. If the field descriptor type is float, long,
///    or double, then the value must be a float, long, or
///    double, respectively. If the field descriptor type is a
///    reference type, then the value must be of a type that is
///    assignment compatible (JLS §5.2) with the field descriptor
///    type. If the field is final, it must be declared in the current
///    class, and the instruction must occur in an instance
///    initialization method (<init>) of the current class
///    (§2.9).
///    The value and objectref are popped from the operand stack. The
///    objectref must be of type reference. The value undergoes value set
///    conversion (§2.8.3), resulting in value',
///    and the referenced field in objectref is set to value'.
/// Linking Exceptions
///    During resolution of the symbolic reference to the field, any of
///    the exceptions pertaining to field resolution
///    (§5.4.3.2) can be thrown.
///    Otherwise, if the resolved field is a static field, putfield
///    throws an IncompatibleClassChangeError.
///    Otherwise, if the field is final, it must be declared in the
///    current class, and the instruction must occur in an instance
///    initialization method (<init>) of the current class. Otherwise, an
///    IllegalAccessError is thrown.
/// Run-time Exception
///    Otherwise, if objectref is null, the putfield instruction
///    throws a NullPointerException.
fn putfield(ctx: Context) void {
    const index = ctx.f.immidiate(u16);
    const value = ctx.f.pop();
    const objectref = ctx.f.pop().ref;

    if (objectref.isNull()) {
        unreachable;
    }

    const fieldref = ctx.c.constant(index).fieldref;
    const slot = resolveField(ctx.c, objectref.class(), fieldref);
    if (slot == null) {
        unreachable;
    }

    objectref.set(slot.?, value);
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.invokevirtual
/// Operation
///    Invoke instance method; dispatch based on class
/// Format
///    invokevirtual
///    indexbyte1
///    indexbyte2
/// Forms
///    invokevirtual = 182 (0xb6)
/// Operand Stack
///    ..., objectref, [arg1, [arg2 ...]] →
///    ...
/// Description
///    The unsigned indexbyte1 and indexbyte2 are used to construct
///    an index into the run-time constant pool of the current class
///    (§2.6), where the value of the index is
///    (indexbyte1 << 8) | indexbyte2. The run-time constant
///    pool item at that index must be a symbolic reference to a method
///    (§5.1), which gives the name and descriptor
///    (§4.3.3) of the method as well as a symbolic
///    reference to the class in which the method is to be found. The
///    named method is resolved (§5.4.3.3).
///    The resolved method must not be an instance initialization method,
///    or the class or interface initialization method
///    (§2.9).
///    If the resolved method is protected, and it is a member of a
///    superclass of the current class, and the method is not declared in
///    the same run-time package (§5.3) as the
///    current class, then the class of objectref must be either the
///    current class or a subclass of the current class.
///    If the resolved method is not signature
///    polymorphic (§2.9), then the
///    invokevirtual instruction proceeds as follows.
///    Let C be the class of objectref. The actual method to be
///    invoked is selected by the following lookup procedure:
///    If C contains a declaration for an instance method m that
///    overrides (§5.4.5) the resolved method,
///    then m is the method to be invoked.
///    Otherwise, if C has a superclass, a search for a declaration
///    of an instance method that overrides the resolved method is
///    performed, starting with the direct superclass of C and
///    continuing with the direct superclass of that class, and so
///    forth, until an overriding method is found or no further
///    superclasses exist.  If an overriding method is found, it is
///    the method to be invoked.
///    Otherwise, if there is exactly one maximally-specific method
///    (§5.4.3.3) in the superinterfaces of C
///    that matches the resolved method's name and descriptor and is
///    not abstract, then it is the method to be invoked.
///    The objectref must be followed on the operand stack by nargs
///    argument values, where the number, type, and order of the values
///    must be consistent with the descriptor of the selected instance
///    method.
///    If the method is synchronized, the monitor associated with
///    objectref is entered or reentered as if by execution of a
///    monitorenter instruction
///    (§monitorenter) in the current
///    thread.
///    If the method is not native, the nargs argument values and
///    objectref are popped from the operand stack. A new frame is
///    created on the Java Virtual Machine stack for the method being invoked. The
///    objectref and the argument values are consecutively made the
///    values of local variables of the new frame, with objectref in
///    local variable 0, arg1 in local variable 1 (or, if arg1 is of
///    type long or double, in local variables 1 and 2), and so
///    on. Any argument value that is of a floating-point type undergoes
///    value set conversion (§2.8.3) prior to being
///    stored in a local variable. The new frame is then made current,
///    and the Java Virtual Machine pc is set to the opcode of the first instruction
///    of the method to be invoked. Execution continues with the first
///    instruction of the method.
///    If the method is native and the platform-dependent code that
///    implements it has not yet been bound (§5.6)
///    into the Java Virtual Machine, that is done. The nargs argument values and
///    objectref are popped from the operand stack and are passed as
///    parameters to the code that implements the method. Any argument
///    value that is of a floating-point type undergoes value set
///    conversion (§2.8.3) prior to being passed as
///    a parameter. The parameters are passed and the code is invoked in
///    an implementation-dependent manner. When the platform-dependent
///    code returns, the following take place:
///    If the native method is synchronized, the monitor
///    associated with objectref is updated and possibly exited as
///    if by execution of a monitorexit instruction
///    (§monitorexit) in the current
///    thread.
///    If the native method returns a value, the return value of
///    the platform-dependent code is converted in an
///    implementation-dependent way to the return type of the
///    native method and pushed onto the operand stack.
///    If the resolved method is signature
///    polymorphic (§2.9), then the
///    invokevirtual instruction proceeds as follows.
///    First, a reference to an instance of java.lang.invoke.MethodType is obtained as if by
///    resolution of a symbolic reference to a method type
///    (§5.4.3.5) with the same parameter and
///    return types as the descriptor of the method referenced by the
///    invokevirtual instruction.
///    If the named method is invokeExact, the instance of
///    java.lang.invoke.MethodType must be semantically equal to the type descriptor
///    of the receiving method handle
///    objectref. The method handle to be
///    invoked is objectref.
///    If the named method is invoke, and the instance of
///    java.lang.invoke.MethodType is semantically equal to the type descriptor of
///    the receiving method handle objectref, then
///    the method handle to be invoked is
///    objectref.
///    If the named method is invoke, and the instance of
///    java.lang.invoke.MethodType is not semantically equal to the type descriptor
///    of the receiving method handle objectref, then the Java Virtual Machine
///    attempts to adjust the type descriptor of the receiving method
///    handle, as if by a call to java.lang.invoke.MethodHandle.asType, to obtain an
///    exactly invokable method handle m. The method
///    handle to be invoked is m.
///    The objectref must be followed on the operand stack by nargs
///    argument values, where the number, type, and order of the values
///    must be consistent with the type descriptor of the method handle
///    to be invoked. (This type descriptor will correspond to the method
///    descriptor appropriate for the kind of the method handle to be
///    invoked, as specified in §5.4.3.5.)
///    Then, if the method handle to be invoked has bytecode behavior,
///    the Java Virtual Machine invokes the method handle as if by execution of the
///    bytecode behavior associated with the method handle's kind. If the
///    kind is 5 (REF_invokeVirtual), 6 (REF_invokeStatic), 7
///    (REF_invokeSpecial), 8 (REF_newInvokeSpecial), or 9
///    (REF_invokeInterface), then a frame will be created and made
///    current in the course of executing the bytecode
///    behavior; when the method invoked by the bytecode
///    behavior completes (normally or abruptly), the frame of
///    its invoker is considered to be the frame for the
///    method containing this invokevirtual instruction.
///    The frame in which the bytecode behavior itself
///    executes is not visible.
///    Otherwise, if the method handle to be invoked has no bytecode
///    behavior, the Java Virtual Machine invokes it in an implementation-dependent
///    manner.
/// Linking Exceptions
///    During resolution of the symbolic reference to the method, any of
///    the exceptions pertaining to method resolution
///    (§5.4.3.3) can be thrown.
///    Otherwise, if the resolved method is a class (static) method,
///    the invokevirtual instruction throws an IncompatibleClassChangeError.
///    Otherwise, if the resolved method is signature polymorphic, then
///    during resolution of the method type derived from the descriptor
///    in the symbolic reference to the method, any of the exceptions
///    pertaining to method type resolution
///    (§5.4.3.5) can be thrown.
/// Run-time Exceptions
///    Otherwise, if objectref is null, the invokevirtual
///    instruction throws a NullPointerException.
///    Otherwise, if the resolved method is a protected method of a
///    superclass of the current class, declared in a different run-time
///    package, and the class of objectref is not the current class or
///    a subclass of the current class, then invokevirtual throws an
///    IllegalAccessError.
///    Otherwise, if the resolved method is not signature
///    polymorphic:
///    If step 1 or step 2 of the lookup procedure selects an abstract
///    method, invokevirtual throws an AbstractMethodError.
///    Otherwise, if step 1 or step 2 of the lookup procedure selects a
///    native method and the code that implements the method cannot
///    be bound, invokevirtual throws an UnsatisfiedLinkError.
///    Otherwise, if step 3 of the lookup procedure determines there
///    are multiple maximally-specific methods in the superinterfaces
///    of C that match the resolved method's name and descriptor
///    and are not abstract, invokevirtual throws an IncompatibleClassChangeError
///    Otherwise, if step 3 of the lookup procedure determines there
///    are zero maximally-specific methods in the superinterfaces of
///    C that match the resolved method's name and descriptor and
///    are not abstract, invokevirtual throws an AbstractMethodError.
///    Otherwise, if the resolved method is signature polymorphic,
///    then:
///    If the method name is invokeExact, and the obtained instance
///    of java.lang.invoke.MethodType is not semantically equal to the type
///    descriptor of the receiving method handle, the invokevirtual
///    instruction throws a java.lang.invoke.WrongMethodTypeException.
///    If the method name is invoke, and the obtained instance of
///    java.lang.invoke.MethodType is not a valid argument to the
///    java.lang.invoke.MethodHandle.asType method invoked on the receiving method
///    handle, the invokevirtual instruction throws a
///    java.lang.invoke.WrongMethodTypeException.
/// Notes
///    The nargs argument values and objectref are not one-to-one
///    with the first nargs+1 local variables. Argument values of types
///    long and double must be stored in two consecutive local
///    variables, thus more than nargs local variables may be required
///    to pass nargs argument values to the invoked method.
///    It is possible that the symbolic reference of an invokevirtual
///    instruction resolves to an interface method. In this case, it is
///    possible that there is no overriding method in the class
///    hierarchy, but that a non-abstract interface method matches the
///    resolved method's descriptor. The selection logic matches such a
///    method, using the same rules as for invokeinterface.
fn invokevirtual(ctx: Context) void {
    const index = ctx.f.immidiate(u16);
    const methodref = ctx.c.constant(index).methodref;
    const class = resolveClass(ctx.c, methodref.class);
    const method = class.method(methodref.name, methodref.descriptor, false);

    if (method == null) {
        unreachable;
    }
    var len = method.?.parameterDescriptors.len + 1;
    const args = make(Value, len, vm_allocator);
    for (0..args.len) |i| {
        args[args.len - 1 - i] = ctx.f.pop();
    }
    const objectref: ObjectRef = args[0].ref; // the actual object instance
    // this.class() is supposed to be a subclass of class or the same
    if (objectref.isNull() or !class.isAssignableFrom(objectref.class())) {
        unreachable;
    }

    const overridenMethod = resolveMethod(ctx.c, objectref.class(), methodref);
    if (overridenMethod == null) {
        unreachable;
    }
    ctx.t.invoke(objectref.class(), overridenMethod.?, args);
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.invokespecial
/// Operation
///    Invoke instance method; special handling for
///    superclass, private, and instance initialization method invocations
/// Format
///    invokespecial
///    indexbyte1
///    indexbyte2
/// Forms
///    invokespecial = 183 (0xb7)
/// Operand Stack
///    ..., objectref, [arg1, [arg2 ...]] →
///    ...
/// Description
///    The
///    unsigned indexbyte1 and indexbyte2 are used to construct an
///    index into the run-time constant pool of the current class
///    (§2.6), where the value of the index is
///    (indexbyte1 << 8) | indexbyte2. The run-time constant
///    pool item at that index must be a symbolic reference to a method
///    or an interface method (§5.1), which gives
///    the name and descriptor (§4.3.3) of the
///    method as well as a symbolic reference to the class or interface
///    in which the method is to be found. The named method is resolved
///    (§5.4.3.3,
///    §5.4.3.4).
///    If the resolved method is protected, and it is a member of a
///    superclass of the current class, and the method is not declared in
///    the same run-time package (§5.3) as the
///    current class, then the class of objectref must be either the
///    current class or a subclass of the current class.
///    If all of the following are true, let C be the direct superclass
///    of the current class:
///    The resolved method is not an instance initialization method
///    (§2.9).
///    If the symbolic reference names a class (not an interface),
///    then that class is a superclass of the current class.
///    The ACC_SUPER flag is set for the class file
///    (§4.1).
///    Otherwise,  let C be the class or interface named by the
///    symbolic reference.
///    The actual method to be invoked is selected by the following
///    lookup procedure:
///    If C contains a declaration for an instance method with the
///    same name and descriptor as the resolved method, then it is
///    the method to be invoked.
///    Otherwise, if C is a class and has a superclass, a search
///    for a declaration of an instance method with the same name
///    and descriptor as the resolved method is performed, starting
///    with the direct superclass of C and continuing with the
///    direct superclass of that class, and so forth, until a match
///    is found or no further superclasses exist. If a match is
///    found, then it is the method to be invoked.
///    Otherwise, if C is an interface and the class Object
///    contains a declaration of a public instance method with the
///    same name and descriptor as the resolved method, then it is
///    the method to be invoked.
///    Otherwise, if there is exactly one maximally-specific method
///    (§5.4.3.3) in the superinterfaces of C
///    that matches the resolved method's name and descriptor and is
///    not abstract, then it is the method to be invoked.
///    The objectref must be of type reference and must be followed on the
///    operand stack by nargs argument values, where the number, type,
///    and order of the values must be consistent with the descriptor of
///    the selected instance method.
///    If the method is synchronized, the monitor associated with
///    objectref is entered or reentered as if by execution of a
///    monitorenter instruction
///    (§monitorenter) in the current
///    thread.
///    If the method is not native, the nargs argument values and
///    objectref are popped from the operand stack. A new frame is
///    created on the Java Virtual Machine stack for the method being invoked. The
///    objectref and the argument values are consecutively made the
///    values of local variables of the new frame, with objectref in
///    local variable 0, arg1 in local variable 1 (or, if arg1 is of
///    type long or double, in local variables 1 and 2), and so
///    on. Any argument value that is of a floating-point type undergoes
///    value set conversion (§2.8.3) prior to being
///    stored in a local variable. The new frame is then made current,
///    and the Java Virtual Machine pc is set to the opcode of the first instruction
///    of the method to be invoked. Execution continues with the first
///    instruction of the method.
///    If the method is native and the platform-dependent code that
///    implements it has not yet been bound (§5.6)
///    into the Java Virtual Machine, that is done. The nargs argument values and
///    objectref are popped from the operand stack and are passed as
///    parameters to the code that implements the method. Any argument
///    value that is of a floating-point type undergoes value set
///    conversion (§2.8.3) prior to being passed as
///    a parameter. The parameters are passed and the code is invoked in
///    an implementation-dependent manner. When the platform-dependent
///    code returns, the following take place:
///    If the native method is synchronized, the monitor
///    associated with objectref is updated and possibly exited as
///    if by execution of a monitorexit instruction
///    (§monitorexit) in the current
///    thread.
///    If the native method returns a value, the return value of
///    the platform-dependent code is converted in an
///    implementation-dependent way to the return type of the
///    native method and pushed onto the operand stack.
/// Linking Exceptions
///    During resolution of the symbolic reference to the method, any of
///    the exceptions pertaining to method resolution
///    (§5.4.3.3) can be thrown.
///    Otherwise, if the resolved method is an instance initialization
///    method, and the class in which it is declared is not the class
///    symbolically referenced by the instruction, a NoSuchMethodError is
///    thrown.
///    Otherwise, if the resolved method is a class (static) method,
///    the invokespecial instruction throws an IncompatibleClassChangeError.
/// Run-time Exceptions
///    Otherwise, if objectref is null, the invokespecial
///    instruction throws a NullPointerException.
///    Otherwise, if the resolved method is a protected method of a
///    superclass of the current class, declared in a different run-time
///    package, and the class of objectref is not the current class or
///    a subclass of the current class, then invokespecial throws an
///    IllegalAccessError.
///    Otherwise, if step 1, step 2, or step 3 of the lookup procedure
///    selects an abstract method, invokespecial throws an
///    AbstractMethodError.
///    Otherwise, if step 1, step 2, or step 3 of the lookup procedure
///    selects a native method and the code that implements the method
///    cannot be bound, invokespecial throws an
///    UnsatisfiedLinkError.
///    Otherwise, if step 4 of the lookup procedure determines there are
///    multiple maximally-specific methods in the superinterfaces of C
///    that match the resolved method's name and descriptor and are not
///    abstract, invokespecial throws an IncompatibleClassChangeError
///    Otherwise, if step 4 of the lookup procedure determines there are
///    zero maximally-specific methods in the superinterfaces of C that
///    match the resolved method's name and descriptor and are not
///    abstract, invokespecial throws an AbstractMethodError.
/// Notes
///    The difference between the invokespecial instruction and the
///    invokevirtual instruction
///    (§invokevirtual) is that invokevirtual
///    invokes a method based on the class of the object. The
///    invokespecial instruction is used to invoke instance
///    initialization methods (§2.9) as well as
///    private methods and methods of a superclass of the current
///    class.
///    The invokespecial instruction was
///    named invokenonvirtual prior to JDK release
///    1.0.2.
///    The nargs argument values and objectref are not one-to-one
///    with the first nargs+1 local variables. Argument values of types
///    long and double must be stored in two consecutive local
///    variables, thus more than nargs local variables may be required
///    to pass nargs argument values to the invoked method.
///    The invokespecial instruction handles invocation of a private
///    interface method, a non-abstract interface method referenced via
///    a direct superinterface, and a non-abstract interface method
///    referenced via a superclass. In these cases, the rules for
///    selection are essentially the same as those for invokeinterface
///    (except that the search starts from a different class).
fn invokespecial(ctx: Context) void {
    const index = ctx.f.immidiate(u16);
    const methodref = ctx.c.constant(index).methodref;
    const class = resolveClass(ctx.c, methodref.class);
    const method = class.method(methodref.name, methodref.descriptor, false);

    if (method == null) {
        unreachable;
    }
    var len = method.?.parameterDescriptors.len + 1;
    const args = make(Value, len, vm_allocator);
    for (0..args.len) |i| {
        args[args.len - 1 - i] = ctx.f.pop();
    }

    ctx.t.invoke(class, method.?, args);
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.invokestatic
/// Operation
///    Invoke a class (static) method
/// Format
///    invokestatic
///    indexbyte1
///    indexbyte2
/// Forms
///    invokestatic = 184 (0xb8)
/// Operand Stack
///    ..., [arg1, [arg2 ...]] →
///    ...
/// Description
///    The unsigned indexbyte1 and indexbyte2 are used to construct
///    an index into the run-time constant pool of the current class
///    (§2.6), where the value of the index is
///    (indexbyte1 << 8) | indexbyte2. The run-time constant
///    pool item at that index must be a symbolic reference to a method
///    or an interface method (§5.1), which gives
///    the name and descriptor (§4.3.3) of the
///    method as well as a symbolic reference to the class or interface
///    in which the method is to be found. The named method is resolved
///    (§5.4.3.3).
///    The resolved method must not be an instance initialization method,
///    or the class or interface initialization method
///    (§2.9).
///    The resolved method must be static, and therefore cannot be
///    abstract.
///    On successful resolution of the method, the class or interface
///    that declared the resolved method is initialized
///    (§5.5) if that class or interface has not
///    already been initialized.
///    The operand stack must contain nargs argument values, where the
///    number, type, and order of the values must be consistent with the
///    descriptor of the resolved method.
///    If the method is synchronized, the monitor associated with the
///    resolved Class object is entered or reentered as if by execution
///    of a monitorenter instruction
///    (§monitorenter) in the current
///    thread.
///    If the method is not native, the nargs argument values are
///    popped from the operand stack. A new frame is created on the Java Virtual Machine
///    stack for the method being invoked. The nargs argument values
///    are consecutively made the values of local variables of the new
///    frame, with arg1 in local variable 0 (or, if arg1 is of type
///    long or double, in local variables 0 and 1) and so on. Any
///    argument value that is of a floating-point type undergoes value
///    set conversion (§2.8.3) prior to being
///    stored in a local variable. The new frame is then made current,
///    and the Java Virtual Machine pc is set to the opcode of the first instruction
///    of the method to be invoked. Execution continues with the first
///    instruction of the method.
///    If the method is native and the platform-dependent code that
///    implements it has not yet been bound (§5.6)
///    into the Java Virtual Machine, that is done. The nargs argument values are
///    popped from the operand stack and are passed as parameters to the
///    code that implements the method. Any argument value that is of a
///    floating-point type undergoes value set conversion
///    (§2.8.3) prior to being passed as a
///    parameter. The parameters are passed and the code is invoked in an
///    implementation-dependent manner. When the platform-dependent code
///    returns, the following take place:
///    If the native method is synchronized, the monitor
///    associated with the resolved Class object is updated and
///    possibly exited as if by execution of a monitorexit
///    instruction (§monitorexit) in the
///    current thread.
///    If the native method returns a value, the return value of
///    the platform-dependent code is converted in an
///    implementation-dependent way to the return type of the
///    native method and pushed onto the operand stack.
/// Linking Exceptions
///    During resolution of the symbolic reference to the method, any of
///    the exceptions pertaining to method resolution
///    (§5.4.3.3) can be thrown.
///    Otherwise, if the resolved method is an instance method, the
///    invokestatic instruction throws an IncompatibleClassChangeError.
/// Run-time Exceptions
///    Otherwise, if execution of this invokestatic instruction causes
///    initialization of the referenced class or interface,
///    invokestatic may throw an Error as detailed in
///    §5.5.
///    Otherwise, if the resolved method is native and the code that
///    implements the method cannot be bound, invokestatic throws an
///    UnsatisfiedLinkError.
/// Notes
///    The nargs argument values are not one-to-one with the first
///    nargs local variables. Argument values of types long and
///    double must be stored in two consecutive local variables, thus
///    more than nargs local variables may be required to pass nargs
///    argument values to the invoked method.
fn invokestatic(ctx: Context) void {
    const index = ctx.f.immidiate(u16);
    const methodref = ctx.c.constant(index).methodref;
    const class = resolveClass(ctx.c, methodref.class);
    const method = class.method(methodref.name, methodref.descriptor, true);

    if (method == null) {
        unreachable;
    }
    var len = method.?.parameterDescriptors.len;
    const args = make(Value, len, vm_allocator);
    for (0..args.len) |i| {
        args[args.len - 1 - i] = ctx.f.pop();
    }
    ctx.t.invoke(class, method.?, args);
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.invokeinterface
/// Operation
///    Invoke interface method
/// Format
///    invokeinterface
///    indexbyte1
///    indexbyte2
///    count
///    0
/// Forms
///    invokeinterface = 185 (0xb9)
/// Operand Stack
///    ..., objectref, [arg1, [arg2 ...]] →
///    ...
/// Description
///    The unsigned indexbyte1 and indexbyte2 are used to construct
///    an index into the run-time constant pool of the current class
///    (§2.6), where the value of the index is
///    (indexbyte1 << 8) | indexbyte2. The run-time constant
///    pool item at that index must be a symbolic reference to an
///    interface method (§5.1), which gives the
///    name and descriptor (§4.3.3) of the
///    interface method as well as a symbolic reference to the interface
///    in which the interface method is to be found. The named interface
///    method is resolved (§5.4.3.4).
///    The resolved interface method must not be an instance
///    initialization method, or the class or interface initialization
///    method (§2.9).
///    The count operand is an unsigned byte that must not be zero. The
///    objectref must be of type reference and must be followed on the
///    operand stack by nargs argument values, where the number, type,
///    and order of the values must be consistent with the descriptor of
///    the resolved interface method. The value of the fourth operand
///    byte must always be zero.
///    Let C be the class of objectref. The actual method to be
///    invoked is selected by the following lookup procedure:
///    If C contains a declaration for an instance method with the
///    same name and descriptor as the resolved method, then it is
///    the method to be invoked.
///    Otherwise, if C has a superclass, a search for a declaration
///    of an instance method with the same name and descriptor as the
///    resolved method is performed, starting with the direct
///    superclass of C and continuing with the direct superclass of
///    that class, and so forth, until a match is found or no further
///    superclasses exist. If a match is found, then it is the method to
///    be invoked.
///    Otherwise, if there is exactly one maximally-specific method
///    (§5.4.3.3) in the superinterfaces of C
///    that matches the resolved method's name and descriptor and is
///    not abstract, then it is the method to be invoked.
///    If the method is synchronized, the monitor associated with
///    objectref is entered or reentered as if by execution of a
///    monitorenter instruction
///    (§monitorenter) in the current
///    thread.
///    If the method is not native, the nargs argument values and
///    objectref are popped from the operand stack. A new frame is
///    created on the Java Virtual Machine stack for the method being invoked. The
///    objectref and the argument values are consecutively made the
///    values of local variables of the new frame, with objectref in
///    local variable 0, arg1 in local variable 1 (or, if arg1 is of
///    type long or double, in local variables 1 and 2), and so
///    on. Any argument value that is of a floating-point type undergoes
///    value set conversion (§2.8.3) prior to being
///    stored in a local variable. The new frame is then made current,
///    and the Java Virtual Machine pc is set to the opcode of the first instruction
///    of the method to be invoked. Execution continues with the first
///    instruction of the method.
///    If the method is native and the platform-dependent code that
///    implements it has not yet been bound (§5.6)
///    into the Java Virtual Machine, that is done. The nargs argument values and
///    objectref are popped from the operand stack and are passed as
///    parameters to the code that implements the method. Any argument
///    value that is of a floating-point type undergoes value set
///    conversion (§2.8.3) prior to being passed as
///    a parameter. The parameters are passed and the code is invoked in
///    an implementation-dependent manner. When the platform-dependent
///    code returns:
///    If the native method is synchronized, the monitor
///    associated with objectref is updated and possibly exited as
///    if by execution of a monitorexit instruction
///    (§monitorexit) in the current
///    thread.
///    If the native method returns a value, the return value of
///    the platform-dependent code is converted in an
///    implementation-dependent way to the return type of the
///    native method and pushed onto the operand stack.
/// Linking Exceptions
///    During resolution of the symbolic reference to the interface
///    method, any of the exceptions pertaining to interface method
///    resolution (§5.4.3.4) can be thrown.
///    Otherwise, if the resolved method is static or private, the
///    invokeinterface instruction throws an IncompatibleClassChangeError.
/// Run-time Exceptions
///    Otherwise, if objectref is null, the invokeinterface
///    instruction throws a NullPointerException.
///    Otherwise, if the class of objectref does not implement the
///    resolved interface, invokeinterface throws an IncompatibleClassChangeError.
///    Otherwise, if step 1 or step 2 of the lookup procedure selects a
///    method that is not public, invokeinterface throws an
///    IllegalAccessError.
///    Otherwise, if step 1 or step 2 of the lookup procedure selects an
///    abstract method, invokeinterface throws an AbstractMethodError.
///    Otherwise, if step 1 or step 2 of the lookup procedure selects a
///    native method and the code that implements the method cannot be
///    bound, invokeinterface throws an UnsatisfiedLinkError.
///    Otherwise, if step 3 of the lookup procedure determines there are
///    multiple maximally-specific methods in the superinterfaces of C
///    that match the resolved method's name and descriptor and are not
///    abstract, invokeinterface throws an IncompatibleClassChangeError
///    Otherwise, if step 3 of the lookup procedure determines there are
///    zero maximally-specific methods in the superinterfaces of C that
///    match the resolved method's name and descriptor and are not
///    abstract, invokeinterface throws an AbstractMethodError.
/// Notes
///    The count operand of the invokeinterface instruction records a
///    measure of the number of argument values, where an argument value
///    of type long or type double contributes two units to the
///    count value and an argument of any other type contributes one
///    unit. This information can also be derived from the descriptor of
///    the selected method. The redundancy is historical.
///    The fourth operand byte exists to reserve space for an additional
///    operand used in certain of Oracle's Java Virtual Machine implementations, which
///    replace the invokeinterface instruction by a specialized
///    pseudo-instruction at run time. It must be retained for backwards
///    compatibility.
///    The nargs argument values and objectref are not one-to-one
///    with the first nargs+1 local variables. Argument values of types
///    long and double must be stored in two consecutive local
///    variables, thus more than nargs local variables may be required
///    to pass nargs argument values to the invoked method.
///    The selection logic allows a non-abstract method declared in a
///    superinterface to be selected. Methods in interfaces are only
///    considered if there is no matching method in the class
///    hierarchy. In the event that there are two non-abstract methods
///    in the superinterface hierarchy, with neither more specific than
///    the other, an error occurs; there is no attempt to disambiguate
///    (for example, one may be the referenced method and one may be
///    unrelated, but we do not prefer the referenced method). On the
///    other hand, if there are many abstract methods but only one
///    non-abstract method, the non-abstract method is selected
///    (unless an abstract method is more specific).
fn invokeinterface(ctx: Context) void {
    const index = ctx.f.immidiate(u16);
    const methodref = ctx.c.constant(index).methodref;
    const class = resolveClass(ctx.c, methodref.class);
    const method = class.method(methodref.name, methodref.descriptor, false);

    if (method == null) {
        unreachable;
    }
    var len = method.?.parameterDescriptors.len + 1;
    const args = make(Value, len, vm_allocator);
    for (0..args.len) |i| {
        args[args.len - 1 - i] = ctx.f.pop();
    }
    const this = args[0].ref;
    if (this.isNull() or !class.isAssignableFrom(this.class())) {
        unreachable;
    }
    const overridenMethod = this.class().method(methodref.name, methodref.descriptor, false);
    if (overridenMethod == null) {
        unreachable;
    }
    ctx.t.invoke(this.class(), method.?, args);
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.invokedynamic
/// Operation
///    Invoke dynamic method
/// Format
///    invokedynamic
///    indexbyte1
///    indexbyte2
///    0
///    0
/// Forms
///    invokedynamic = 186 (0xba)
/// Operand Stack
///    ..., [arg1, [arg2 ...]] →
///    ...
/// Description
///    Each specific lexical occurrence of an invokedynamic instruction
///    is called a dynamic call site.
///    First, the unsigned indexbyte1 and indexbyte2 are used to
///    construct an index into the run-time constant pool of the current
///    class (§2.6), where the value of the index
///    is (indexbyte1 << 8) | indexbyte2. The run-time constant
///    pool item at that index must be a symbolic reference to a call
///    site specifier (§5.1). The values of the
///    third and fourth operand bytes must always be zero.
///    The call site specifier is resolved (§5.4.3.6)
///    for this specific dynamic call site to obtain
///    a reference to a java.lang.invoke.MethodHandle instance that will serve as the
///    bootstrap method, a reference to a java.lang.invoke.MethodType instance, and references
///    to static arguments.
///    Next, as part of the continuing resolution of the call site
///    specifier, the bootstrap method is invoked as if by execution of
///    an invokevirtual instruction
///    (§invokevirtual) that contains a
///    run-time constant pool index to a symbolic reference R
///    where:
///    R is a symbolic reference to a method of a class
///    (§5.1);
///    for the symbolic reference to the class in which the method is
///    to be found, R specifies java.lang.invoke.MethodHandle;
///    for the name of the method, R specifies invoke;
///    for the descriptor of the method, R specifies a return type
///    of java.lang.invoke.CallSite and parameter types derived from the items
///    pushed on the operand stack.
///    The first three parameter types are java.lang.invoke.MethodHandles.Lookup,
///    String, and java.lang.invoke.MethodType, in that order. If the call site
///    specifier has any static arguments, then a parameter type for
///    each argument is appended to the parameter types of the method
///    descriptor in the order that the arguments were pushed on to
///    the operand stack. These parameter types may be Class,
///    java.lang.invoke.MethodHandle, java.lang.invoke.MethodType, String, int, long,
///    float, or double.
///    and where it is as if the following items were pushed, in order,
///    on the operand stack:
///    the reference to the java.lang.invoke.MethodHandle object for the bootstrap
///    method;
///    a reference to a java.lang.invoke.MethodHandles.Lookup object for the class in
///    which this dynamic call site occurs;
///    a reference to the String for the method name in the call site
///    specifier;
///    the reference to the java.lang.invoke.MethodType object obtained for the method
///    descriptor in the call site specifier;
///    references to classes, method types, method handles, and string
///    literals denoted as static arguments in the call site
///    specifier, and numeric values (§2.3.1,
///    §2.3.2) denoted as static arguments in
///    the call site specifier, in the order in which they appear in
///    the call site specifier. (That is, no boxing occurs for
///    primitive values.)
///    The symbolic reference R describes a method which is signature
///    polymorphic (§2.9). Due to the operation of
///    invokevirtual on a signature polymorphic method called invoke,
///    the type descriptor of the receiving method handle (representing
///    the bootstrap method) need not be semantically equal to the method
///    descriptor specified by R. For example, the first parameter type
///    specified by R could be Object instead of
///    java.lang.invoke.MethodHandles.Lookup, and the return type specified by R could
///    be Object instead of java.lang.invoke.CallSite. As long as the bootstrap method
///    can be invoked by the invoke method without a java.lang.invoke.WrongMethodTypeException being
///    thrown, the type descriptor of the method handle which represents
///    the bootstrap method is arbitrary.
///    If the bootstrap method is a variable arity method, then some or
///    all of the arguments on the operand stack specified above may be
///    collected into a trailing array parameter.
///    The invocation of a bootstrap method occurs within a thread that
///    is attempting resolution of the symbolic reference to the call
///    site specifier of this dynamic call site. If
///    there are several such threads, the bootstrap method may be
///    invoked in several threads concurrently. Therefore, bootstrap
///    methods which access global application data must take the usual
///    precautions against race conditions.
///    The result returned by the bootstrap method must be a reference to an
///    object whose class is java.lang.invoke.CallSite or a subclass of java.lang.invoke.CallSite. This
///    object is known as the call site object. The
///    reference is popped from the operand stack used as if in the execution
///    of an invokevirtual instruction.
///    If several threads simultaneously execute the bootstrap method for
///    the same dynamic call site, the Java Virtual Machine must choose one returned
///    call site object and install it visibly to all threads. Any other
///    bootstrap methods executing for the dynamic call site are allowed
///    to complete, but their results are ignored, and the threads'
///    execution of the dynamic call site proceeds with the chosen call
///    site object.
///    The call site object has a type descriptor (an instance of
///    java.lang.invoke.MethodType) which must be semantically equal to the java.lang.invoke.MethodType
///    object obtained for the method descriptor in the call site
///    specifier.
///    The result of successful call site specifier resolution is a call
///    site object which is permanently bound to the dynamic call
///    site.
///    The method handle represented by the target of the bound call site
///    object is invoked. The invocation occurs as if by execution of an
///    invokevirtual instruction
///    (§invokevirtual) that indicates a
///    run-time constant pool index to a symbolic reference to a method
///    (§5.1) with the following properties:
///    The method's name is invokeExact;
///    The method's descriptor is the method descriptor in the call
///    site specifier; and
///    The method's symbolic reference to the class in which the
///    method is to be found indicates the class
///    java.lang.invoke.MethodHandle.
///    The operand stack will be interpreted as containing a reference to the
///    target of the call site object, followed by nargs argument
///    values, where the number, type, and order of the values must be
///    consistent with the method descriptor in the call site
///    specifier.
/// Linking Exceptions
///    If resolution of the symbolic reference to the call site specifier
///    throws an exception E, the invokedynamic instruction throws a
///    BootstrapMethodError that wraps E.
///    Otherwise, during the continuing resolution of the call site
///    specifier, if invocation of the bootstrap method completes
///    abruptly (§2.6.5) because of a throw of
///    exception E, the invokedynamic instruction throws a BootstrapMethodError that
///    wraps E. (This can occur if the bootstrap method has the wrong
///    arity, parameter type, or return type, causing java.lang.invoke.MethodHandle
///    . invoke to throw java.lang.invoke.WrongMethodTypeException.)
///    Otherwise, during the continuing resolution of the call site
///    specifier, if the result from the bootstrap method invocation is
///    not a reference to an instance of java.lang.invoke.CallSite, the invokedynamic
///    instruction throws a BootstrapMethodError.
///    Otherwise, during the continuing resolution of the call site
///    specifier, if the type descriptor of the target of the call site
///    object is not semantically equal to the method descriptor in the
///    call site specifier, the invokedynamic instruction throws a
///    BootstrapMethodError.
/// Run-time Exceptions
///    If this specific dynamic call site completed resolution of its
///    call site specifier, it implies that a non-null reference to an
///    instance of java.lang.invoke.CallSite is bound to this dynamic call
///    site. Therefore, the operand stack item which represents a reference
///    to the target of the call site object is never null. Similarly,
///    it implies that the method descriptor in the call site specifier
///    is semantically equal to the type descriptor of
///    the method handle to be invoked as if by
///    execution of an invokevirtual instruction. Together, these
///    invariants mean that an invokedynamic instruction which is bound
///    to a call site object never throws a NullPointerException or a java.lang.invoke.WrongMethodTypeException.
fn invokedynamic(ctx: Context) void {
    _ = ctx;
    @panic("instruction not implemented");
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.new
/// Operation
///    Create new object
/// Format
///    new
///    indexbyte1
///    indexbyte2
/// Forms
///    new = 187 (0xbb)
/// Operand Stack
///    ... →
///    ..., objectref
/// Description
///    The unsigned indexbyte1 and indexbyte2 are used to construct
///    an index into the run-time constant pool of the current class
///    (§2.6), where the value of the index is
///    (indexbyte1 << 8) | indexbyte2. The run-time constant
///    pool item at the index must be a symbolic reference to a class or
///    interface type. The named class or interface type is resolved
///    (§5.4.3.1) and should result in a class
///    type. Memory for a new instance of that class is allocated from
///    the garbage-collected heap, and the instance variables of the new
///    object are initialized to their default initial values
///    (§2.3, §2.4). The
///    objectref, a reference to the instance, is pushed onto the operand
///    stack.
///    On successful resolution of the class, it is initialized
///    (§5.5) if it has not already been
///    initialized.
/// Linking Exceptions
///    During resolution of the symbolic reference to the class, array,
///    or interface type, any of the exceptions documented in
///    §5.4.3.1 can be thrown.
///    Otherwise, if the symbolic reference to the class, array, or
///    interface type resolves to an interface or is an abstract class,
///    new throws an InstantiationError.
/// Run-time Exception
///    Otherwise, if execution of this new instruction causes
///    initialization of the referenced class, new may throw an Error
///    as detailed in JLS §15.9.4.
/// Notes
///    The new instruction does not completely create a new instance;
///    instance creation is not completed until an instance
///    initialization method (§2.9) has been
///    invoked on the uninitialized instance.
fn new(ctx: Context) void {
    const index = ctx.f.immidiate(u16);
    const classref = ctx.c.constant(index).classref;

    const objectref = newObject(ctx.c, classref.class);
    ctx.f.push(.{ .ref = objectref });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.newarray
/// Operation
///    Create new array
/// Format
///    newarray
///    atype
/// Forms
///    newarray = 188 (0xbc)
/// Operand Stack
///    ..., count →
///    ..., arrayref
/// Description
///    The count must be of type int. It is popped off the operand
///    stack. The count represents the number of elements in the array
///    to be created.
///    The atype is a code that indicates the type
///    of array to create. It must take one of the following
///    values:
///    Table 6.5.newarray-A. Array type codes
///    A new array whose components are of
///    type atype and of length count is allocated
///    from the garbage-collected heap. A reference arrayref to this new
///    array object is pushed into the operand stack. Each of the
///    elements of the new array is initialized to the default initial
///    value (§2.3, §2.4) for
///    the element type of the array type.
/// Run-time Exception
///    If count is less than zero, newarray throws a
///    NegativeArraySizeException.
/// Notes
///    In Oracle's Java Virtual Machine implementation, arrays of type boolean
///    (atype is T_BOOLEAN) are stored as arrays
///    of 8-bit values and are manipulated using the baload and
///    bastore instructions (§baload,
///    §bastore) which also access arrays of
///    type byte. Other implementations may implement packed boolean
///    arrays; the baload and bastore instructions must still be used
///    to access those arrays.
fn newarray(ctx: Context) void {
    const atype = ctx.f.immidiate(i8);
    const count = ctx.f.pop().as(int).int;

    const descriptor = switch (atype) {
        4 => "[Z",
        5 => "[C",
        6 => "[F",
        7 => "[D",
        8 => "[B",
        9 => "[S",
        10 => "[I",
        11 => "[J",
        else => unreachable,
    };

    const arrayref = newArray(ctx.c, descriptor, &[_]int{count});
    ctx.f.push(.{ .ref = arrayref });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.anewarray
/// Operation
///    Create new array of reference
/// Format
///    anewarray
///    indexbyte1
///    indexbyte2
/// Forms
///    anewarray = 189 (0xbd)
/// Operand Stack
///    ..., count →
///    ..., arrayref
/// Description
///    The count must be of type int. It is popped off the operand
///    stack. The count represents the number of components of the
///    array to be created. The unsigned indexbyte1 and indexbyte2
///    are used to construct an index into the run-time constant pool of
///    the current class (§2.6), where the value of
///    the index is (indexbyte1 << 8) | indexbyte2. The
///    run-time constant pool item at that index must be a symbolic
///    reference to a class, array, or interface type. The named class,
///    array, or interface type is resolved
///    (§5.4.3.1). A new array with components of
///    that type, of length count, is allocated from the
///    garbage-collected heap, and a reference arrayref to this new array
///    object is pushed onto the operand stack. All components of the new
///    array are initialized to null, the default value for reference types
///    (§2.4).
/// Linking Exceptions
///    During resolution of the symbolic reference to the class, array,
///    or interface type, any of the exceptions documented in
///    §5.4.3.1 can be thrown.
/// Run-time Exceptions
///    Otherwise, if count is less than zero, the anewarray
///    instruction throws a NegativeArraySizeException.
/// Notes
///    The anewarray instruction is used to create a single dimension
///    of an array of object references or part of a multidimensional
///    array.
fn anewarray(ctx: Context) void {
    const index = ctx.f.immidiate(u16);
    const count = ctx.f.pop().as(int).int;

    const componentType = ctx.c.constant(index).classref.class;
    const descriptor = concat(&[_]string{ "[", componentType });

    const arrayref = newArray(ctx.c, descriptor, &[_]int{count});
    ctx.f.push(.{ .ref = arrayref });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.arraylength
/// Operation
///    Get length of array
/// Format
///    arraylength
/// Forms
///    arraylength = 190 (0xbe)
/// Operand Stack
///    ..., arrayref →
///    ..., length
/// Description
///    The arrayref must be of type reference and must refer to an
///    array. It is popped from the operand
///    stack. The length of the array it references
///    is determined. That length is pushed onto the
///    operand stack as an int.
/// Run-time Exceptions
///    If the arrayref is null, the arraylength instruction throws
///    a NullPointerException.
fn arraylength(ctx: Context) void {
    const arrayref = ctx.f.pop().as(ArrayRef).ref;

    if (arrayref.isNull()) {
        ctx.f.vm_throw("java/lang/NullPointerException");
    }

    ctx.f.push(.{ .int = arrayref.len() });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.athrow
/// Operation
///    Throw exception or error
/// Format
///    athrow
/// Forms
///    athrow = 191 (0xbf)
/// Operand Stack
///    ..., objectref →
///    objectref
/// Description
///    The objectref must be of type reference and must refer to an object
///    that is an instance of class Throwable or of a subclass of
///    Throwable. It is popped from the operand stack. The objectref
///    is then thrown by searching the current method
///    (§2.6) for the first exception handler that
///    matches the class of objectref, as given by the algorithm in
///    §2.10.
///    If an exception handler that matches objectref is found, it
///    contains the location of the code intended to handle this
///    exception. The pc register is reset to that location, the
///    operand stack of the current frame is cleared, objectref is
///    pushed back onto the operand stack, and execution
///    continues.
///    If no matching exception handler is found in the current frame,
///    that frame is popped. If the current frame represents an
///    invocation of a synchronized method, the monitor entered or
///    reentered on invocation of the method is exited as if by execution
///    of a monitorexit instruction
///    (§monitorexit). Finally, the frame of
///    its invoker is reinstated, if such a frame exists, and the
///    objectref is rethrown. If no such frame exists, the current
///    thread exits.
/// Run-time Exceptions
///    If objectref is null, athrow throws a NullPointerException instead of
///    objectref.
///    Otherwise, if the Java Virtual Machine implementation does not enforce the rules
///    on structured locking described in §2.11.10,
///    then if the method of the current frame is a synchronized method
///    and the current thread is not the owner of the monitor entered or
///    reentered on invocation of the method, athrow throws an
///    IllegalMonitorStateException instead of the object previously
///    being thrown. This can happen, for example, if an abruptly
///    completing synchronized method contains a monitorexit
///    instruction, but no monitorenter instruction, on the object on
///    which the method is synchronized.
///    Otherwise, if the Java Virtual Machine implementation enforces the rules on
///    structured locking described in §2.11.10 and
///    if the first of those rules is violated during invocation of the
///    current method, then athrow throws an
///    IllegalMonitorStateException instead of the object previously
///    being thrown.
/// Notes
///    The operand stack diagram for the athrow instruction may be
///    misleading: If a handler for this exception is matched in the
///    current method, the athrow instruction discards all the values
///    on the operand stack, then pushes the thrown object onto the
///    operand stack. However, if no handler is matched in the current
///    method and the exception is thrown farther up the method
///    invocation chain, then the operand stack of the method (if any)
///    that handles the exception is cleared and objectref is pushed
///    onto that empty operand stack. All intervening frames from the
///    method that threw the exception up to, but not including, the
///    method that handles the exception are discarded.
fn athrow(ctx: Context) void {
    const throwable = ctx.f.pop().as(Reference).ref;

    if (throwable.isNull()) {
        return ctx.f.vm_throw("java/lang/NullPointerException");
    }

    ctx.f.throw(throwable);
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.checkcast
/// Operation
///    Check whether object is of given type
/// Format
///    checkcast
///    indexbyte1
///    indexbyte2
/// Forms
///    checkcast = 192 (0xc0)
/// Operand Stack
///    ..., objectref →
///    ..., objectref
/// Description
///    The objectref must be of type reference. The unsigned indexbyte1
///    and indexbyte2 are used to construct an index into the run-time
///    constant pool of the current class (§2.6),
///    where the value of the index is (indexbyte1 << 8) |
///    indexbyte2. The run-time constant pool item at the index must be
///    a symbolic reference to a class, array, or interface type.
///    If objectref is null, then the operand stack is
///    unchanged.
///    Otherwise, the named class, array, or interface type is resolved
///    (§5.4.3.1). If objectref can be cast to
///    the resolved class, array, or interface type, the operand stack is
///    unchanged; otherwise, the checkcast instruction throws a
///    ClassCastException.
///    The following rules are used to determine whether an objectref
///    that is not null can be cast to the resolved type: if S is the
///    class of the object referred to by objectref and T is the
///    resolved class, array, or interface type, checkcast determines
///    whether objectref can be cast to type T as follows:
///    If S is an ordinary (nonarray) class, then:
///    If T is a class type, then S must be the same class as
///    T, or S must be a subclass of T;
///    If T is an interface type, then S must implement
///    interface T.
///    If S is an interface type, then:
///    If T is a class type, then T must be Object.
///    If T is an interface type, then T must be the same
///    interface as S or a superinterface of S.
///    If S is a class representing the array type SC[],
///    that is, an array of components of type SC, then:
///    If T is a class type, then T must be Object.
///    If T is an interface type, then T must be one of the
///    interfaces implemented by arrays (JLS §4.10.3).
///    If T is an array type TC[], that is, an array
///    of components of type TC, then one of the following must
///    be true:
///    TC and SC are the same primitive type.
///    TC and SC are reference types, and type SC can
///    be cast to TC by recursive application of these
///    rules.
/// Linking Exceptions
///    During resolution of the symbolic reference to the class, array,
///    or interface type, any of the exceptions documented in
///    §5.4.3.1 can be thrown.
/// Run-time Exception
///    Otherwise, if objectref cannot be cast to the resolved class,
///    array, or interface type, the checkcast instruction throws a
///    ClassCastException.
/// Notes
///    The checkcast instruction is very similar to the instanceof
///    instruction (§instanceof). It differs in
///    its treatment of null, its behavior when its test fails
///    (checkcast throws an exception, instanceof pushes a result
///    code), and its effect on the operand stack.
fn checkcast(ctx: Context) void {
    const index = ctx.f.immidiate(u16);
    const objectref = ctx.f.pop().as(Reference).ref;

    if (objectref.isNull()) {
        return ctx.f.push(.{ .ref = objectref });
    }

    const classref = ctx.c.constant(index).classref;
    const class = resolveClass(ctx.c, classref.class);

    if (class.isAssignableFrom(objectref.class())) {
        return ctx.f.push(.{ .ref = objectref });
    }
    ctx.f.vm_throw("java/lang/ClassCastException");
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.instanceof
/// Operation
///    Determine if object is of given type
/// Format
///    instanceof
///    indexbyte1
///    indexbyte2
/// Forms
///    instanceof = 193 (0xc1)
/// Operand Stack
///    ..., objectref →
///    ..., result
/// Description
///    The objectref, which must be of type reference, is popped from the
///    operand stack. The unsigned indexbyte1 and indexbyte2 are used
///    to construct an index into the run-time constant pool of the
///    current class (§2.6), where the value of the
///    index is (indexbyte1 << 8) | indexbyte2. The run-time
///    constant pool item at the index must be a symbolic reference to a
///    class, array, or interface type.
///    If objectref is null, the instanceof instruction pushes an
///    int result of 0 as an int on the operand stack.
///    Otherwise, the named class, array, or interface type is resolved
///    (§5.4.3.1). If objectref is an instance of
///    the resolved class or array or implements the resolved interface,
///    the instanceof instruction pushes an int result of 1 as an
///    int on the operand stack; otherwise, it pushes an int result
///    of 0.
///    The following rules are used to determine whether an objectref
///    that is not null is an instance of the resolved type: If S is
///    the class of the object referred to by objectref and T is the
///    resolved class, array, or interface type, instanceof determines
///    whether objectref is an instance of T as follows:
///    If S is an ordinary (nonarray) class, then:
///    If T is a class type, then S must be the same class as
///    T, or S must be a subclass of T;
///    If T is an interface type, then S must implement
///    interface T.
///    If S is an interface type, then:
///    If T is a class type, then T must be Object.
///    If T is an interface type, then T must be the same
///    interface as S or a superinterface of S.
///    If S is a class representing the array type SC[],
///    that is, an array of components of type SC, then:
///    If T is a class type, then T must be Object.
///    If T is an interface type, then T must be one of the
///    interfaces implemented by arrays (JLS §4.10.3).
///    If T is an array type TC[], that is, an array
///    of components of type TC, then one of the following must
///    be true:
///    TC and SC are the same primitive type.
///    TC and SC are reference types, and type SC can
///    be cast to TC by these run-time rules.
/// Linking Exceptions
///    During resolution of the symbolic reference to the class, array,
///    or interface type, any of the exceptions documented in
///    §5.4.3.1 can be thrown.
/// Notes
///    The instanceof instruction is very similar to the checkcast
///    instruction (§checkcast). It differs in
///    its treatment of null, its behavior when its test fails
///    (checkcast throws an exception, instanceof pushes a result
///    code), and its effect on the operand stack.
fn instanceof(ctx: Context) void {
    const index = ctx.f.immidiate(u16);
    const objectref = ctx.f.pop().as(Reference).ref;

    if (objectref.isNull()) {
        return ctx.f.push(.{ .int = 0 });
    }

    const classref = ctx.c.constant(index).classref;
    const class = resolveClass(ctx.c, classref.class);
    // TODO ???
    if (class.isAssignableFrom(objectref.class())) {
        return ctx.f.push(.{ .int = 1 });
    }

    ctx.f.push(.{ .int = 0 });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.monitorenter
/// Operation
///    Enter monitor for object
/// Format
///    monitorenter
/// Forms
///    monitorenter = 194 (0xc2)
/// Operand Stack
///    ..., objectref →
///    ...
/// Description
///    The objectref must be of type reference.
///    Each object is associated with a monitor. A monitor is locked if
///    and only if it has an owner. The thread that executes
///    monitorenter attempts to gain ownership of the monitor
///    associated with objectref, as follows:
///    If the entry count of the monitor associated with objectref
///    is zero, the thread enters the monitor and sets its entry
///    count to one. The thread is then the owner of the
///    monitor.
///    If the thread already owns the monitor associated with
///    objectref, it reenters the monitor, incrementing its entry
///    count.
///    If another thread already owns the monitor associated with
///    objectref, the thread blocks until the monitor's entry count
///    is zero, then tries again to gain ownership.
/// Run-time Exception
///    If objectref is null, monitorenter throws a NullPointerException.
/// Notes
///    A monitorenter instruction may be used with one or more
///    monitorexit instructions
///    (§monitorexit) to implement a
///    synchronized statement in the Java programming language
///    (§3.14). The monitorenter and
///    monitorexit instructions are not used in the implementation of
///    synchronized methods, although they can be used to provide
///    equivalent locking semantics. Monitor entry on invocation of a
///    synchronized method, and monitor exit on its return, are handled
///    implicitly by the Java Virtual Machine's method invocation and return
///    instructions, as if monitorenter and monitorexit were
///    used.
///    The association of a monitor with an object may be managed in
///    various ways that are beyond the scope of this specification. For
///    instance, the monitor may be allocated and deallocated at the same
///    time as the object. Alternatively, it may be dynamically allocated
///    at the time when a thread attempts to gain exclusive access to the
///    object and freed at some later time when no thread remains in the
///    monitor for the object.
///    The synchronization constructs of the Java programming language require support
///    for operations on monitors besides entry and exit. These include
///    waiting on a monitor (Object.wait) and
///    notifying other threads waiting on a monitor
///    (Object.notifyAll
///    and Object.notify). These operations are
///    supported in the standard package java.lang
///    supplied with the Java Virtual Machine. No explicit support for these operations
///    appears in the instruction set of the Java Virtual Machine.
fn monitorenter(ctx: Context) void {
    _ = ctx;
    @panic("instruction not implemented");
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.monitorexit
/// Operation
///    Exit monitor for object
/// Format
///    monitorexit
/// Forms
///    monitorexit = 195 (0xc3)
/// Operand Stack
///    ..., objectref →
///    ...
/// Description
///    The objectref must be of type reference.
///    The thread that executes monitorexit must be the owner of the
///    monitor associated with the instance referenced by
///    objectref.
///    The thread decrements the entry count of the monitor associated
///    with objectref. If as a result the value of the entry count is
///    zero, the thread exits the monitor and is no longer its
///    owner. Other threads that are blocking to enter the monitor are
///    allowed to attempt to do so.
/// Run-time Exceptions
///    If objectref is null, monitorexit throws a NullPointerException.
///    Otherwise, if the thread that executes monitorexit is not the
///    owner of the monitor associated with the instance referenced by
///    objectref, monitorexit throws an
///    IllegalMonitorStateException.
///    Otherwise, if the Java Virtual Machine implementation enforces the rules on
///    structured locking described in §2.11.10 and
///    if the second of those rules is violated by the execution of this
///    monitorexit instruction, then monitorexit throws an
///    IllegalMonitorStateException.
/// Notes
///    One or more monitorexit instructions may be used with a
///    monitorenter instruction
///    (§monitorenter) to implement a
///    synchronized statement in the Java programming language
///    (§3.14). The monitorenter and
///    monitorexit instructions are not used in the implementation of
///    synchronized methods, although they can be used to provide
///    equivalent locking semantics.
///    The Java Virtual Machine supports exceptions thrown within synchronized methods
///    and synchronized statements differently:
///    Monitor exit on normal synchronized method completion is
///    handled by the Java Virtual Machine's return instructions. Monitor exit on
///    abrupt synchronized method completion is handled implicitly
///    by the Java Virtual Machine's athrow instruction.
///    When an exception is thrown from within a synchronized
///    statement, exit from the monitor entered prior to the
///    execution of the synchronized statement is achieved using
///    the Java Virtual Machine's exception handling mechanism
///    (§3.14).
fn monitorexit(ctx: Context) void {
    _ = ctx;
    @panic("instruction not implemented");
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.wide
/// Operation
///    Extend local variable index by additional bytes
/// Format 1
///    wide
///    <opcode>
///    indexbyte1
///    indexbyte2
///    where <opcode> is one
///    of iload, fload, aload, lload, dload, istore, fstore,
///    astore, lstore, dstore, or ret
/// Format 2
///    wide
///    iinc
///    indexbyte1
///    indexbyte2
///    constbyte1
///    constbyte2
/// Forms
///    wide = 196 (0xc4)
/// Operand Stack
///    Same as modified instruction
/// Description
///    The wide instruction modifies the behavior of another
///    instruction. It takes one of two formats, depending on the
///    instruction being modified. The first form of the wide
///    instruction modifies one of the instructions iload, fload,
///    aload, lload, dload, istore, fstore, astore, lstore,
///    dstore, or ret (§iload,
///    §fload,
///    §aload,
///    §lload,
///    §dload,
///    §istore,
///    §fstore,
///    §astore,
///    §lstore,
///    §dstore,
///    §ret). The second form applies only to
///    the iinc instruction (§iinc).
///    In either case, the wide opcode itself is followed in the
///    compiled code by the opcode of the instruction wide modifies. In
///    either form, two unsigned bytes indexbyte1 and indexbyte2
///    follow the modified opcode and are assembled into a 16-bit
///    unsigned index to a local variable in the current frame
///    (§2.6), where the value of the index is
///    (indexbyte1 << 8) | indexbyte2. The calculated index
///    must be an index into the local variable array of the current
///    frame. Where the wide instruction modifies an lload, dload,
///    lstore, or dstore instruction, the index following the
///    calculated index (index + 1) must also be an index into the local
///    variable array. In the second form, two immediate unsigned bytes
///    constbyte1
///    and constbyte2 follow indexbyte1 and
///    indexbyte2 in the code stream. Those bytes are also assembled
///    into a signed 16-bit constant, where the constant is
///    (constbyte1 << 8)
///    | constbyte2.
///    The widened bytecode operates as normal, except for the use of the
///    wider index and, in the case of the second form, the larger
///    increment range.
/// Notes
///    Although we say that wide "modifies the behavior of another
///    instruction," the wide instruction effectively treats the bytes
///    constituting the modified instruction as operands, denaturing the
///    embedded instruction in the process. In the case of a modified
///    iinc instruction, one of the logical operands of the iinc is
///    not even at the normal offset from the opcode. The embedded
///    instruction must never be executed directly; its opcode must never
///    be the target of any control transfer instruction.
fn wide(ctx: Context) void {
    _ = ctx;
    @panic("instruction not implemented");
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.multianewarray
/// Operation
///    Create new multidimensional array
/// Format
///    multianewarray
///    indexbyte1
///    indexbyte2
///    dimensions
/// Forms
///    multianewarray = 197 (0xc5)
/// Operand Stack
///    ..., count1, [count2, ...] →
///    ..., arrayref
/// Description
///    The dimensions operand is an unsigned byte
///    that must be greater than or equal to 1. It represents the number
///    of dimensions of the array to be created. The operand stack must
///    contain dimensions values. Each such value
///    represents the number of components in a dimension of the array to
///    be created, must be of type int, and must be
///    non-negative. The count1 is the desired
///    length in the first dimension, count2 in the
///    second, etc.
///    All of the count values are popped off the
///    operand stack. The unsigned indexbyte1 and indexbyte2 are used
///    to construct an index into the run-time constant pool of the
///    current class (§2.6), where the value of the
///    index is (indexbyte1 << 8) | indexbyte2. The run-time
///    constant pool item at the index must be a symbolic reference to a
///    class, array, or interface type. The named class, array, or
///    interface type is resolved (§5.4.3.1). The
///    resulting entry must be an array class type of dimensionality
///    greater than or equal to dimensions.
///    A new multidimensional array of the array type is allocated from
///    the garbage-collected heap. If any count
///    value is zero, no subsequent dimensions are allocated. The
///    components of the array in the first dimension are initialized to
///    subarrays of the type of the second dimension, and so on. The
///    components of the last allocated dimension of the array are
///    initialized to the default initial value
///    (§2.3, §2.4) for the
///    element type of the array type. A reference arrayref to the new
///    array is pushed onto the operand stack.
/// Linking Exceptions
///    During resolution of the symbolic reference to the class, array,
///    or interface type, any of the exceptions documented in
///    §5.4.3.1 can be thrown.
///    Otherwise, if the current class does not have permission to access
///    the element type of the resolved array class, multianewarray
///    throws an IllegalAccessError.
/// Run-time Exception
///    Otherwise, if any of the dimensions values on
///    the operand stack are less than zero, the multianewarray
///    instruction throws a NegativeArraySizeException.
/// Notes
///    It may be more efficient to use newarray or anewarray
///    (§newarray,
///    §anewarray) when creating an array of a
///    single dimension.
///    The array class referenced via the run-time constant pool may have
///    more dimensions than the dimensions operand
///    of the multianewarray instruction. In that case, only the
///    first dimensions of the dimensions of the
///    array are created.
fn multianewarray(ctx: Context) void {
    const index = ctx.f.immidiate(u16);
    const dimensions = ctx.f.immidiate(u8);

    if (dimensions < 1) {
        unreachable;
    }

    const counts = make(int, dimensions, vm_allocator);
    for (0..dimensions) |i| {
        const count = ctx.f.pop().as(int).int;
        if (count < 0) {
            return ctx.f.vm_throw("java/lang/NegativeArraySizeException");
        }
        counts[dimensions - 1 - i] = count;
    }

    const classref = ctx.c.constant(index).classref;

    const arrayref = newArray(ctx.c, classref.class, counts);
    ctx.f.push(.{ .ref = arrayref });
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.ifnull
/// Operation
///    Branch if reference is null
/// Format
///    ifnull
///    branchbyte1
///    branchbyte2
/// Forms
///    ifnull = 198 (0xc6)
/// Operand Stack
///    ..., value →
///    ...
/// Description
///    The value must of type reference. It is popped from the operand
///    stack. If value is null, the unsigned branchbyte1 and
///    branchbyte2 are used to construct a signed 16-bit offset, where
///    the offset is calculated to be (branchbyte1 << 8) |
///    branchbyte2. Execution then proceeds at that offset from the
///    address of the opcode of this ifnull instruction. The target
///    address must be that of an opcode of an instruction within the
///    method that contains this ifnull instruction.
///    Otherwise, execution proceeds at the address of the instruction
///    following this ifnull instruction.
fn ifnull(ctx: Context) void {
    const offset = ctx.f.immidiate(i16);
    const value = ctx.f.pop().as(Reference).ref;

    if (value.isNull()) {
        ctx.f.next(offset);
    }
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.ifnonnull
/// Operation
///    Branch if reference not null
/// Format
///    ifnonnull
///    branchbyte1
///    branchbyte2
/// Forms
///    ifnonnull = 199 (0xc7)
/// Operand Stack
///    ..., value →
///    ...
/// Description
///    The value must be of type reference. It is popped from the operand
///    stack. If value is not null, the unsigned branchbyte1 and
///    branchbyte2 are used to construct a signed 16-bit offset, where
///    the offset is calculated to be (branchbyte1 << 8) |
///    branchbyte2. Execution then proceeds at that offset from the
///    address of the opcode of this ifnonnull instruction. The target
///    address must be that of an opcode of an instruction within the
///    method that contains this ifnonnull instruction.
///    Otherwise, execution proceeds at the address of the instruction
///    following this ifnonnull instruction.
fn ifnonnull(ctx: Context) void {
    const offset = ctx.f.immidiate(i16);
    const value = ctx.f.pop().as(Reference).ref;

    if (!value.isNull()) {
        ctx.f.next(offset);
    }
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.goto_w
/// Operation
///    Branch always (wide index)
/// Format
///    goto_w
///    branchbyte1
///    branchbyte2
///    branchbyte3
///    branchbyte4
/// Forms
///    goto_w = 200 (0xc8)
/// Operand Stack
///    No change
/// Description
///    The unsigned bytes branchbyte1, branchbyte2, branchbyte3,
///    and branchbyte4 are used to construct a signed 32-bit
///    branchoffset, where branchoffset is (branchbyte1 <<
///    24) | (branchbyte2 << 16) | (branchbyte3 << 8) |
///    branchbyte4. Execution proceeds at that offset from the address
///    of the opcode of this goto_w instruction. The target address
///    must be that of an opcode of an instruction within the method that
///    contains this goto_w instruction.
/// Notes
///    Although the goto_w instruction takes a 4-byte branch offset,
///    other factors limit the size of a method to 65535 bytes
///    (§4.11). This limit may be raised in a
///    future release of the Java Virtual Machine.
fn goto_w(ctx: Context) void {
    _ = ctx;
    @panic("instruction not implemented");
}

/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.jsr_w
/// Operation
///    Jump subroutine (wide index)
/// Format
///    jsr_w
///    branchbyte1
///    branchbyte2
///    branchbyte3
///    branchbyte4
/// Forms
///    jsr_w = 201 (0xc9)
/// Operand Stack
///    ... →
///    ..., address
/// Description
///    The address of the opcode of the instruction immediately
///    following this jsr_w instruction is pushed onto the operand
///    stack as a value of type returnAddress. The unsigned
///    branchbyte1, branchbyte2, branchbyte3, and branchbyte4 are
///    used to construct a signed 32-bit offset, where the offset is
///    (branchbyte1 << 24) | (branchbyte2 << 16) |
///    (branchbyte3 << 8) | branchbyte4. Execution proceeds at
///    that offset from the address of this jsr_w instruction. The
///    target address must be that of an opcode of an instruction within
///    the method that contains this jsr_w instruction.
/// Notes
///    Note that jsr_w pushes the address onto the operand stack and
///    ret (§ret) gets it out of a local
///    variable. This asymmetry is intentional.
///    In Oracle's implementation of a compiler for the Java programming language prior
///    to Java SE 6, the jsr_w instruction was used with the ret
///    instruction in the implementation of the finally clause
///    (§3.13,
///    §4.10.2.5).
///    Although the jsr_w instruction takes a 4-byte branch offset,
///    other factors limit the size of a method to 65535 bytes
///    (§4.11). This limit may be raised in a
///    future release of the Java Virtual Machine.
fn jsr_w(ctx: Context) void {
    _ = ctx;
    @panic("instruction not implemented");
}

fn breakpoint(ctx: Context) void {
    _ = ctx;
    @panic("instruction not implemented");
}
