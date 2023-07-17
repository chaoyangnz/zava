const string = @import("./shared").string;
const Thread = @import("./engine.zig").Thread;
const Frame = @import("./engine.zig").Frame;
const Class = @import("./type.zig").Class;
const Method = @import("./type.zig").Method;

pub const Instruction = struct {
    mnemonic: string,
    length: u32,
    interpret: *const fn (t: *Thread, f: *Frame, c: *Class, m: *Method) void,

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
        .{ .mnemonic = "return", .length = 1, .interpret = return },

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

fn nop(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn aconst_null(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn iconst_m1(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn iconst_0(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn iconst_1(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn iconst_2(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn iconst_3(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn iconst_4(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn iconst_5(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn lconst_0(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn lconst_1(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn fconst_0(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn fconst_1(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn fconst_2(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn dconst_0(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn dconst_1(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn bipush(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn sipush(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn ldc(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn ldc_w(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn ldc2_w(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn iload(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn lload(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn fload(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn dload(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn aload(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn iload_0(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn iload_1(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn iload_2(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn iload_3(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn lload_0(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn lload_1(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn lload_2(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn lload_3(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn fload_0(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn fload_1(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn fload_2(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn fload_3(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn dload_0(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn dload_1(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn dload_2(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn dload_3(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn aload_0(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn aload_1(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn aload_2(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn aload_3(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn iaload(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn laload(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn faload(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn daload(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn aaload(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn baload(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn caload(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn saload(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn istore(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn lstore(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn fstore(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn dstore(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn astore(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn istore_0(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn istore_1(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn istore_2(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn istore_3(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn lstore_0(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn lstore_1(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn lstore_2(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn lstore_3(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn fstore_0(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn fstore_1(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn fstore_2(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn fstore_3(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn dstore_0(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn dstore_1(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn dstore_2(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn dstore_3(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn astore_0(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn astore_1(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn astore_2(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn astore_3(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn iastore(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn lastore(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn fastore(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn dastore(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn aastore(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn bastore(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn castore(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn sastore(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn pop(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn pop2(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn dup(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn dup_x1(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn dup_x2(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn dup2(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn dup2_x1(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn dup2_x2(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn swap(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn iadd(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn ladd(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn fadd(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn dadd(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn isub(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn lsub(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn fsub(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn dsub(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn imul(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn lmul(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn fmul(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn dmul(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn idiv(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn ldiv(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn fdiv(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn ddiv(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn irem(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn lrem(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn frem(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn drem(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn ineg(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn lneg(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn fneg(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn dneg(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn ishl(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn lshl(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn ishr(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn lshr(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn iushr(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn lushr(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn iand(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn land(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn ior(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn lor(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn ixor(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn lxor(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn iinc(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn i2l(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn i2f(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn i2d(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn l2i(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn l2f(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn l2d(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn f2i(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn f2l(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn f2d(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn d2i(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn d2l(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn d2f(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn i2b(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn i2c(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn i2s(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn lcmp(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn fcmpl(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn fcmpg(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn dcmpl(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn dcmpg(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn ifeq(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn ifne(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn iflt(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn ifge(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn ifgt(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn ifle(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn if_icmpeq(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn if_icmpne(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn if_icmplt(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn if_icmpge(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn if_icmpgt(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn if_icmple(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn if_acmpeq(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn if_acmpne(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn goto(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn jsr(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn ret(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn tableswitch(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn lookupswitch(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn ireturn(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn lreturn(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn freturn(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn dreturn(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn areturn(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn return(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn getstatic(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn putstatic(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn getfield(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn putfield(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn invokevirtual(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn invokespecial(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn invokestatic(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn invokeinterface(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn invokedynamic(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn new(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn newarray(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn anewarray(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn arraylength(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn athrow(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn checkcast(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn instanceof(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn monitorenter(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn monitorexit(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn wide(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn multianewarray(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn ifnull(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn ifnonnull(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn goto_w(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn jsr_w(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}

fn breakpoint(t: *Thread, f: *Frame, c: *Class, m: *Method) void {
    _ = m;
    _ = c;
    _ = f;
    _ = t;
}
