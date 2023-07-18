const string = @import("./shared").string;
const Thread = @import("./engine.zig").Thread;
const Frame = @import("./engine.zig").Frame;
const Class = @import("./type.zig").Class;
const Method = @import("./type.zig").Method;
const NULL = @import("./value.zig").NULL;
const int = @import("./value.zig").int;
const long = @import("./value.zig").long;
const float = @import("./value.zig").float;
const double = @import("./value.zig").double;
const Reference = @import("./value.zig").Reference;
const ArrayRef = @import("./value.zig").ArrayRef;
const Int = @import("./type.zig").Int;
const Long = @import("./type.zig").Long;
const Float = @import("./type.zig").Float;
const Double = @import("./type.zig").Double;
const Byte = @import("./type.zig").Byte;
const Boolean = @import("./type.zig").Boolean;

const Context = struct {
    t: *Thread,
    f: *Frame,
    c: *Class,
    m: *Method,
};

pub const Instruction = struct {
    mnemonic: string,
    length: u32,
    interpret: *const fn (context: Context) void,

    pub const registery = [_]Instruction{
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
};

fn nop(ctx: Context) void {
    _ = ctx;
}

fn aconst_null(ctx: Context) void {
    ctx.f.push(.{ .ref = NULL });
}

fn iconst_m1(ctx: Context) void {
    ctx.f.push(.{ .int = -1 });
}

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

fn lconst_0(ctx: Context) void {
    ctx.f.push(.{ .long = 0 });
}

fn lconst_1(ctx: Context) void {
    ctx.f.push(.{ .long = 1 });
}

fn fconst_0(ctx: Context) void {
    ctx.f.push(.{ .float = 0.0 });
}

fn fconst_1(ctx: Context) void {
    ctx.f.push(.{ .float = 1.0 });
}

fn fconst_2(ctx: Context) void {
    ctx.f.push(.{ .float = 2.0 });
}

fn dconst_0(ctx: Context) void {
    ctx.f.push(.{ .double = 0.0 });
}

fn dconst_1(ctx: Context) void {
    ctx.f.push(.{ .double = 1.0 });
}

fn bipush(ctx: Context) void {
    ctx.f.push(.{ .int = ctx.f.immidiate(i8) });
}

fn sipush(ctx: Context) void {
    ctx.f.push(.{ .int = ctx.f.immidiate(i16) });
}

fn ldc(ctx: Context) void {
    const index = ctx.f.immidiate(u8);
    const constant = ctx.c.constantPool[index];
    switch (constant) {
        .Integer => |c| ctx.f.push(.{ .int = c.value }),
        .Float => |c| ctx.f.push(.{ .float = c.value }),
        // TODO
        // .String => |c| ctx.f.push(.{ .double = c.value }),
    }
}

fn ldc_w(ctx: Context) void {
    const index = ctx.f.immidiate(u16);
    const constant = ctx.c.constantPool[index];
    switch (constant) {
        .Integer => |c| ctx.f.push(.{ .int = c.value }),
        .Float => |c| ctx.f.push(.{ .float = c.value }),
        // TODO
        // .String => |c| ctx.f.push(.{ .double = c.value }),
    }
}

fn ldc2_w(ctx: Context) void {
    const index = ctx.f.immidiate(u16);
    const constant = ctx.c.constantPool[index];
    switch (constant) {
        .Long => |c| ctx.f.push(.{ .long = c.value }),
        .Double => |c| ctx.f.push(.{ .double = c.value }),
        else => unreachable,
    }
}

fn iload(ctx: Context) void {
    const index = ctx.f.immidiate(u8);
    ctx.f.push(.{ .int = ctx.f.loadVar(index).as(int) });
}

fn lload(ctx: Context) void {
    const index = ctx.f.immidiate(u8);
    ctx.f.push(.{ .long = ctx.f.loadVar(index).as(long) });
}

fn fload(ctx: Context) void {
    const index = ctx.f.immidiate(u8);
    ctx.f.push(.{ .float = ctx.f.loadVar(index).as(float) });
}

fn dload(ctx: Context) void {
    const index = ctx.f.immidiate(u8);
    ctx.f.push(.{ .double = ctx.f.loadVar(index).as(double) });
}

fn aload(ctx: Context) void {
    const index = ctx.f.immidiate(u8);
    ctx.f.push(.{ .ref = ctx.f.loadVar(index).as(Reference) });
}

fn iload_0(ctx: Context) void {
    ctx.f.push(.{ .int = ctx.f.loadVar(0).as(int) });
}

fn iload_1(ctx: Context) void {
    ctx.f.push(.{ .int = ctx.f.loadVar(1).as(int) });
}

fn iload_2(ctx: Context) void {
    ctx.f.push(.{ .int = ctx.f.loadVar(2).as(int) });
}

fn iload_3(ctx: Context) void {
    ctx.f.push(.{ .int = ctx.f.loadVar(3).as(int) });
}

fn lload_0(ctx: Context) void {
    ctx.f.push(.{ .long = ctx.f.loadVar(0).as(long) });
}

fn lload_1(ctx: Context) void {
    ctx.f.push(.{ .long = ctx.f.loadVar(1).as(long) });
}

fn lload_2(ctx: Context) void {
    ctx.f.push(.{ .long = ctx.f.loadVar(2).as(long) });
}

fn lload_3(ctx: Context) void {
    ctx.f.push(.{ .long = ctx.f.loadVar(3).as(long) });
}

fn fload_0(ctx: Context) void {
    ctx.f.push(.{ .float = ctx.f.loadVar(0).as(float) });
}

fn fload_1(ctx: Context) void {
    ctx.f.push(.{ .float = ctx.f.loadVar(1).as(float) });
}

fn fload_2(ctx: Context) void {
    ctx.f.push(.{ .float = ctx.f.loadVar(2).as(float) });
}

fn fload_3(ctx: Context) void {
    ctx.f.push(.{ .float = ctx.f.loadVar(3).as(float) });
}

fn dload_0(ctx: Context) void {
    ctx.f.push(.{ .double = ctx.f.loadVar(0).as(double) });
}

fn dload_1(ctx: Context) void {
    ctx.f.push(.{ .double = ctx.f.loadVar(1).as(double) });
}

fn dload_2(ctx: Context) void {
    ctx.f.push(.{ .double = ctx.f.loadVar(2).as(double) });
}

fn dload_3(ctx: Context) void {
    ctx.f.push(.{ .double = ctx.f.loadVar(3).as(double) });
}

fn aload_0(ctx: Context) void {
    ctx.f.push(.{ .ref = ctx.f.loadVar(0).as(Reference) });
}

fn aload_1(ctx: Context) void {
    ctx.f.push(.{ .ref = ctx.f.loadVar(1).as(Reference) });
}

fn aload_2(ctx: Context) void {
    ctx.f.push(.{ .ref = ctx.f.loadVar(2).as(Reference) });
}

fn aload_3(ctx: Context) void {
    ctx.f.push(.{ .ref = ctx.f.loadVar(3).as(Reference) });
}

fn iaload(ctx: Context) void {
    const index = ctx.f.pop().as(int);
    const arrayref = ctx.f.pop().as(ArrayRef);
    if (arrayref.isNull()) {
        ctx.t.throw("java/lang/NullPointerException", "");
    }
    if (!arrayref.class().isArray()) {
        unreachable;
    }
    if (!arrayref.class().componentType.is(Int)) {
        unreachable;
    }
    if (index < 0 or index >= arrayref.len()) {
        unreachable;
    }

    ctx.f.push(.{ .int = arrayref.get(index).as(int) });
}

fn laload(ctx: Context) void {
    const index = ctx.f.pop().as(int);
    const arrayref = ctx.f.pop().as(ArrayRef);
    if (arrayref.isNull()) {
        ctx.t.throw("java/lang/NullPointerException", "");
    }
    if (!arrayref.class().isArray()) {
        unreachable;
    }
    if (!arrayref.class().componentType.is(Long)) {
        unreachable;
    }
    if (index < 0 or index >= arrayref.len()) {
        unreachable;
    }

    ctx.f.push(.{ .long = arrayref.get(index).as(long) });
}

fn faload(ctx: Context) void {
    const index = ctx.f.pop().as(int);
    const arrayref = ctx.f.pop().as(ArrayRef);
    if (arrayref.isNull()) {
        ctx.t.throw("java/lang/NullPointerException", "");
    }
    if (!arrayref.class().isArray()) {
        unreachable;
    }
    if (!arrayref.class().componentType.is(Float)) {
        unreachable;
    }
    if (index < 0 or index >= arrayref.len()) {
        unreachable;
    }

    ctx.f.push(.{ .float = arrayref.get(index).as(float) });
}

fn daload(ctx: Context) void {
    const index = ctx.f.pop().as(int);
    const arrayref = ctx.f.pop().as(ArrayRef);
    if (arrayref.isNull()) {
        ctx.t.throw("java/lang/NullPointerException", "");
    }
    if (!arrayref.class().isArray()) {
        unreachable;
    }
    if (!arrayref.class().componentType.is(Double)) {
        unreachable;
    }
    if (index < 0 or index >= arrayref.len()) {
        unreachable;
    }

    ctx.f.push(.{ .double = arrayref.get(index).as(double) });
}

fn aaload(ctx: Context) void {
    const index = ctx.f.pop().as(int);
    const arrayref = ctx.f.pop().as(ArrayRef);
    if (arrayref.isNull()) {
        ctx.t.throw("java/lang/NullPointerException", "");
    }
    if (!arrayref.class().isArray()) {
        unreachable;
    }
    if (!arrayref.class().componentType.is(Class)) {
        unreachable;
    }
    if (index < 0 or index >= arrayref.len()) {
        unreachable;
    }

    ctx.f.push(.{ .ref = arrayref.get(index).as(Reference) });
}

fn baload(ctx: Context) void {
    const index = ctx.f.pop().as(int);
    const arrayref = ctx.f.pop().as(ArrayRef);
    if (arrayref.isNull()) {
        ctx.t.throw("java/lang/NullPointerException", "");
    }
    if (!arrayref.class().isArray()) {
        unreachable;
    }
    if (index < 0 or index >= arrayref.len()) {
        unreachable;
    }
    if (!arrayref.class().componentType.is(Byte) and !arrayref.class().componentType.is(Boolean)) {
        unreachable;
    }
    ctx.f.push(.{ .int = arrayref.get(index).as(Int) });
}

fn caload(ctx: Context) void {
    _ = ctx;
}

fn saload(ctx: Context) void {
    _ = ctx;
}

fn istore(ctx: Context) void {
    _ = ctx;
}

fn lstore(ctx: Context) void {
    _ = ctx;
}

fn fstore(ctx: Context) void {
    _ = ctx;
}

fn dstore(ctx: Context) void {
    _ = ctx;
}

fn astore(ctx: Context) void {
    _ = ctx;
}

fn istore_0(ctx: Context) void {
    _ = ctx;
}

fn istore_1(ctx: Context) void {
    _ = ctx;
}

fn istore_2(ctx: Context) void {
    _ = ctx;
}

fn istore_3(ctx: Context) void {
    _ = ctx;
}

fn lstore_0(ctx: Context) void {
    _ = ctx;
}

fn lstore_1(ctx: Context) void {
    _ = ctx;
}

fn lstore_2(ctx: Context) void {
    _ = ctx;
}

fn lstore_3(ctx: Context) void {
    _ = ctx;
}

fn fstore_0(ctx: Context) void {
    _ = ctx;
}

fn fstore_1(ctx: Context) void {
    _ = ctx;
}

fn fstore_2(ctx: Context) void {
    _ = ctx;
}

fn fstore_3(ctx: Context) void {
    _ = ctx;
}

fn dstore_0(ctx: Context) void {
    _ = ctx;
}

fn dstore_1(ctx: Context) void {
    _ = ctx;
}

fn dstore_2(ctx: Context) void {
    _ = ctx;
}

fn dstore_3(ctx: Context) void {
    _ = ctx;
}

fn astore_0(ctx: Context) void {
    _ = ctx;
}

fn astore_1(ctx: Context) void {
    _ = ctx;
}

fn astore_2(ctx: Context) void {
    _ = ctx;
}

fn astore_3(ctx: Context) void {
    _ = ctx;
}

fn iastore(ctx: Context) void {
    _ = ctx;
}

fn lastore(ctx: Context) void {
    _ = ctx;
}

fn fastore(ctx: Context) void {
    _ = ctx;
}

fn dastore(ctx: Context) void {
    _ = ctx;
}

fn aastore(ctx: Context) void {
    _ = ctx;
}

fn bastore(ctx: Context) void {
    _ = ctx;
}

fn castore(ctx: Context) void {
    _ = ctx;
}

fn sastore(ctx: Context) void {
    _ = ctx;
}

fn pop(ctx: Context) void {
    _ = ctx;
}

fn pop2(ctx: Context) void {
    _ = ctx;
}

fn dup(ctx: Context) void {
    _ = ctx;
}

fn dup_x1(ctx: Context) void {
    _ = ctx;
}

fn dup_x2(ctx: Context) void {
    _ = ctx;
}

fn dup2(ctx: Context) void {
    _ = ctx;
}

fn dup2_x1(ctx: Context) void {
    _ = ctx;
}

fn dup2_x2(ctx: Context) void {
    _ = ctx;
}

fn swap(ctx: Context) void {
    _ = ctx;
}

fn iadd(ctx: Context) void {
    _ = ctx;
}

fn ladd(ctx: Context) void {
    _ = ctx;
}

fn fadd(ctx: Context) void {
    _ = ctx;
}

fn dadd(ctx: Context) void {
    _ = ctx;
}

fn isub(ctx: Context) void {
    _ = ctx;
}

fn lsub(ctx: Context) void {
    _ = ctx;
}

fn fsub(ctx: Context) void {
    _ = ctx;
}

fn dsub(ctx: Context) void {
    _ = ctx;
}

fn imul(ctx: Context) void {
    _ = ctx;
}

fn lmul(ctx: Context) void {
    _ = ctx;
}

fn fmul(ctx: Context) void {
    _ = ctx;
}

fn dmul(ctx: Context) void {
    _ = ctx;
}

fn idiv(ctx: Context) void {
    _ = ctx;
}

fn ldiv(ctx: Context) void {
    _ = ctx;
}

fn fdiv(ctx: Context) void {
    _ = ctx;
}

fn ddiv(ctx: Context) void {
    _ = ctx;
}

fn irem(ctx: Context) void {
    _ = ctx;
}

fn lrem(ctx: Context) void {
    _ = ctx;
}

fn frem(ctx: Context) void {
    _ = ctx;
}

fn drem(ctx: Context) void {
    _ = ctx;
}

fn ineg(ctx: Context) void {
    _ = ctx;
}

fn lneg(ctx: Context) void {
    _ = ctx;
}

fn fneg(ctx: Context) void {
    _ = ctx;
}

fn dneg(ctx: Context) void {
    _ = ctx;
}

fn ishl(ctx: Context) void {
    _ = ctx;
}

fn lshl(ctx: Context) void {
    _ = ctx;
}

fn ishr(ctx: Context) void {
    _ = ctx;
}

fn lshr(ctx: Context) void {
    _ = ctx;
}

fn iushr(ctx: Context) void {
    _ = ctx;
}

fn lushr(ctx: Context) void {
    _ = ctx;
}

fn iand(ctx: Context) void {
    _ = ctx;
}

fn land(ctx: Context) void {
    _ = ctx;
}

fn ior(ctx: Context) void {
    _ = ctx;
}

fn lor(ctx: Context) void {
    _ = ctx;
}

fn ixor(ctx: Context) void {
    _ = ctx;
}

fn lxor(ctx: Context) void {
    _ = ctx;
}

fn iinc(ctx: Context) void {
    _ = ctx;
}

fn i2l(ctx: Context) void {
    _ = ctx;
}

fn i2f(ctx: Context) void {
    _ = ctx;
}

fn i2d(ctx: Context) void {
    _ = ctx;
}

fn l2i(ctx: Context) void {
    _ = ctx;
}

fn l2f(ctx: Context) void {
    _ = ctx;
}

fn l2d(ctx: Context) void {
    _ = ctx;
}

fn f2i(ctx: Context) void {
    _ = ctx;
}

fn f2l(ctx: Context) void {
    _ = ctx;
}

fn f2d(ctx: Context) void {
    _ = ctx;
}

fn d2i(ctx: Context) void {
    _ = ctx;
}

fn d2l(ctx: Context) void {
    _ = ctx;
}

fn d2f(ctx: Context) void {
    _ = ctx;
}

fn i2b(ctx: Context) void {
    _ = ctx;
}

fn i2c(ctx: Context) void {
    _ = ctx;
}

fn i2s(ctx: Context) void {
    _ = ctx;
}

fn lcmp(ctx: Context) void {
    _ = ctx;
}

fn fcmpl(ctx: Context) void {
    _ = ctx;
}

fn fcmpg(ctx: Context) void {
    _ = ctx;
}

fn dcmpl(ctx: Context) void {
    _ = ctx;
}

fn dcmpg(ctx: Context) void {
    _ = ctx;
}

fn ifeq(ctx: Context) void {
    _ = ctx;
}

fn ifne(ctx: Context) void {
    _ = ctx;
}

fn iflt(ctx: Context) void {
    _ = ctx;
}

fn ifge(ctx: Context) void {
    _ = ctx;
}

fn ifgt(ctx: Context) void {
    _ = ctx;
}

fn ifle(ctx: Context) void {
    _ = ctx;
}

fn if_icmpeq(ctx: Context) void {
    _ = ctx;
}

fn if_icmpne(ctx: Context) void {
    _ = ctx;
}

fn if_icmplt(ctx: Context) void {
    _ = ctx;
}

fn if_icmpge(ctx: Context) void {
    _ = ctx;
}

fn if_icmpgt(ctx: Context) void {
    _ = ctx;
}

fn if_icmple(ctx: Context) void {
    _ = ctx;
}

fn if_acmpeq(ctx: Context) void {
    _ = ctx;
}

fn if_acmpne(ctx: Context) void {
    _ = ctx;
}

fn goto(ctx: Context) void {
    _ = ctx;
}

fn jsr(ctx: Context) void {
    _ = ctx;
}

fn ret(ctx: Context) void {
    _ = ctx;
}

fn tableswitch(ctx: Context) void {
    _ = ctx;
}

fn lookupswitch(ctx: Context) void {
    _ = ctx;
}

fn ireturn(ctx: Context) void {
    _ = ctx;
}

fn lreturn(ctx: Context) void {
    _ = ctx;
}

fn freturn(ctx: Context) void {
    _ = ctx;
}

fn dreturn(ctx: Context) void {
    _ = ctx;
}

fn areturn(ctx: Context) void {
    _ = ctx;
}

fn return_(ctx: Context) void {
    _ = ctx;
}

fn getstatic(ctx: Context) void {
    _ = ctx;
}

fn putstatic(ctx: Context) void {
    _ = ctx;
}

fn getfield(ctx: Context) void {
    _ = ctx;
}

fn putfield(ctx: Context) void {
    _ = ctx;
}

fn invokevirtual(ctx: Context) void {
    _ = ctx;
}

fn invokespecial(ctx: Context) void {
    _ = ctx;
}

fn invokestatic(ctx: Context) void {
    _ = ctx;
}

fn invokeinterface(ctx: Context) void {
    _ = ctx;
}

fn invokedynamic(ctx: Context) void {
    _ = ctx;
}

fn new(ctx: Context) void {
    _ = ctx;
}

fn newarray(ctx: Context) void {
    _ = ctx;
}

fn anewarray(ctx: Context) void {
    _ = ctx;
}

fn arraylength(ctx: Context) void {
    _ = ctx;
}

fn athrow(ctx: Context) void {
    _ = ctx;
}

fn checkcast(ctx: Context) void {
    _ = ctx;
}

fn instanceof(ctx: Context) void {
    _ = ctx;
}

fn monitorenter(ctx: Context) void {
    _ = ctx;
}

fn monitorexit(ctx: Context) void {
    _ = ctx;
}

fn wide(ctx: Context) void {
    _ = ctx;
}

fn multianewarray(ctx: Context) void {
    _ = ctx;
}

fn ifnull(ctx: Context) void {
    _ = ctx;
}

fn ifnonnull(ctx: Context) void {
    _ = ctx;
}

fn goto_w(ctx: Context) void {
    _ = ctx;
}

fn jsr_w(ctx: Context) void {
    _ = ctx;
}

fn breakpoint(ctx: Context) void {
    _ = ctx;
}
