// ../../6510-emulator-c/6510.h:6:19: warning: struct demoted to opaque type - has bitfield
pub const struct_S_CPUFlags = opaque {};
pub const CPUFlags_t = struct_S_CPUFlags;
pub const struct_S_Mem64k = extern struct {
    Data: [65536]u8 = @import("std").mem.zeroes([65536]u8),
};
pub const MEM64K_t = struct_S_Mem64k;
pub export fn MEM_Init(arg_mem: [*c]MEM64K_t) void {
    var mem = arg_mem;
    _ = &mem;
    {
        var i: c_int = 0;
        _ = &i;
        while (i < @as(c_int, 65536)) : (i += 1) {
            mem.*.Data[@as(c_uint, @intCast(i))] = 0;
        }
    }
}
const union_unnamed_1 = extern union {
    PS: u8,
    Flags: CPUFlags_t,
};

pub const struct_S_CPU = extern struct {
    PC: c_ushort = @import("std").mem.zeroes(c_ushort),
    SP: u8 = @import("std").mem.zeroes(u8),
    A: u8 = @import("std").mem.zeroes(u8),
    X: u8 = @import("std").mem.zeroes(u8),
    Y: u8 = @import("std").mem.zeroes(u8),
    unnamed_0: union_unnamed_1 = @import("std").mem.zeroes(union_unnamed_1),
    memdata: MEM64K_t = @import("std").mem.zeroes(MEM64K_t),
    mem: [*c]MEM64K_t = @import("std").mem.zeroes([*c]MEM64K_t),
    cycles_executed: c_uint = @import("std").mem.zeroes(c_uint),
    cycles_last_step: c_uint = @import("std").mem.zeroes(c_uint),
    opcode_last: u8 = @import("std").mem.zeroes(u8),
};

pub const CPU = struct_S_CPU;

pub export fn CPU_Reset(arg_cpu: ?*CPU) void {
    var cpu = arg_cpu;
    _ = &cpu;
    CPU_Init(cpu, @as(c_ushort, @bitCast(@as(c_short, @truncate(@as(c_int, 65532))))));
}

pub export fn CPU_Init(arg_cpu: ?*CPU, arg_PC_init: c_ushort) void {
    var cpu = arg_cpu;
    _ = &cpu;
    var PC_init = arg_PC_init;
    _ = &PC_init;
    cpu.*.PC = PC_init;
    cpu.*.SP = 255;
    cpu.*.unnamed_0.Flags.C = blk: {
        const tmp = blk_1: {
            const tmp_2 = blk_2: {
                const tmp_3 = blk_3: {
                    const tmp_4 = blk_4: {
                        const tmp_5 = blk_5: {
                            const tmp_6 = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0)))));
                            cpu.*.unnamed_0.Flags.N = tmp_6;
                            break :blk_5 tmp_6;
                        };
                        cpu.*.unnamed_0.Flags.V = tmp_5;
                        break :blk_4 tmp_5;
                    };
                    cpu.*.unnamed_0.Flags.B = tmp_4;
                    break :blk_3 tmp_4;
                };
                cpu.*.unnamed_0.Flags.D = tmp_3;
                break :blk_2 tmp_3;
            };
            cpu.*.unnamed_0.Flags.I = tmp_2;
            break :blk_1 tmp_2;
        };
        cpu.*.unnamed_0.Flags.Z = tmp;
        break :blk tmp;
    };
    cpu.*.A = blk: {
        const tmp = blk_1: {
            const tmp_2 = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0)))));
            cpu.*.Y = tmp_2;
            break :blk_1 tmp_2;
        };
        cpu.*.X = tmp;
        break :blk tmp;
    };
    cpu.*.cycles_executed = 0;
    cpu.*.cycles_last_step = 0;
    cpu.*.opcode_last = 0;
    cpu.*.mem = &cpu.*.memdata;
    MEM_Init(cpu.*.mem);
}
pub extern fn FetchByte(cpu: ?*CPU) u8;
pub export fn CPU_FetchSByte(arg_cpu: ?*CPU) u8 {
    var cpu = arg_cpu;
    _ = &cpu;
    return @as(u8, @bitCast(CPU_FetchByte(cpu)));
}
pub export fn CPU_FetchWord(arg_cpu: ?*CPU) c_ushort {
    var cpu = arg_cpu;
    _ = &cpu;
    var Data: c_ushort = @as(c_ushort, @bitCast(@as(c_ushort, cpu.*.mem.*.Data[cpu.*.PC])));
    _ = &Data;
    cpu.*.PC +%= 1;
    Data |= @as(c_ushort, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(c_uint, cpu.*.mem.*.Data[cpu.*.PC]))) << @intCast(8)))));
    cpu.*.PC +%= 1;
    cpu.*.cycles_executed +%= @as(c_uint, @bitCast(@as(c_int, 2)));
    return Data;
}
pub export fn CPU_ReadByte(arg_cpu: ?*CPU, arg_Address: c_ushort) u8 {
    var cpu = arg_cpu;
    _ = &cpu;
    var Address = arg_Address;
    _ = &Address;
    var Data: u8 = cpu.*.mem.*.Data[Address];
    _ = &Data;
    cpu.*.cycles_executed +%= 1;
    return Data;
}
pub export fn CPU_ReadWord(arg_cpu: ?*CPU, arg_Address: c_ushort) c_ushort {
    var cpu = arg_cpu;
    _ = &cpu;
    var Address = arg_Address;
    _ = &Address;
    var LoByte: u8 = CPU_ReadByte(cpu, Address);
    _ = &LoByte;
    var HiByte: u8 = CPU_ReadByte(cpu, @as(c_ushort, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(c_uint, Address))) + @as(c_int, 1))))));
    _ = &HiByte;
    return @as(c_ushort, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(c_uint, LoByte))) | (@as(c_int, @bitCast(@as(c_uint, HiByte))) << @intCast(8))))));
}
pub export fn CPU_WriteByte(arg_cpu: ?*CPU, arg_Value: u8, arg_Address: c_ushort) void {
    var cpu = arg_cpu;
    _ = &cpu;
    var Value = arg_Value;
    _ = &Value;
    var Address = arg_Address;
    _ = &Address;
    cpu.*.mem.*.Data[Address] = Value;
    cpu.*.cycles_executed +%= 1;
}
pub export fn CPU_WriteWord(arg_cpu: ?*CPU, arg_Value: c_ushort, arg_Address: c_ushort) void {
    var cpu = arg_cpu;
    _ = &cpu;
    var Value = arg_Value;
    _ = &Value;
    var Address = arg_Address;
    _ = &Address;
    cpu.*.mem.*.Data[Address] = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(c_uint, Value))) & @as(c_int, 255)))));
    cpu.*.mem.*.Data[@as(c_uint, @intCast(@as(c_int, @bitCast(@as(c_uint, Address))) + @as(c_int, 1)))] = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(c_uint, Value))) >> @intCast(8)))));
    cpu.*.cycles_executed +%= @as(c_uint, @bitCast(@as(c_int, 2)));
}
pub export fn CPU_SPToAddress(arg_cpu: ?*CPU) c_ushort {
    var cpu = arg_cpu;
    _ = &cpu;
    return @as(c_ushort, @bitCast(@as(c_short, @truncate(@as(c_int, 256) | @as(c_int, @bitCast(@as(c_uint, cpu.*.SP)))))));
}
pub export fn CPU_PushWordToStack(arg_cpu: ?*CPU, arg_Value: c_ushort) void {
    var cpu = arg_cpu;
    _ = &cpu;
    var Value = arg_Value;
    _ = &Value;
    CPU_WriteByte(cpu, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(c_uint, Value))) >> @intCast(8))))), CPU_SPToAddress(cpu));
    cpu.*.SP -%= 1;
    CPU_WriteByte(cpu, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(c_uint, Value))) & @as(c_int, 255))))), CPU_SPToAddress(cpu));
    cpu.*.SP -%= 1;
}
pub export fn CPU_PushPCMinusOneToStack(arg_cpu: ?*CPU) void {
    var cpu = arg_cpu;
    _ = &cpu;
    CPU_PushWordToStack(cpu, @as(c_ushort, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(c_uint, cpu.*.PC))) - @as(c_int, 1))))));
}
pub export fn CPU_PushPCPlusOneToStack(arg_cpu: ?*CPU) void {
    var cpu = arg_cpu;
    _ = &cpu;
    CPU_PushWordToStack(cpu, @as(c_ushort, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(c_uint, cpu.*.PC))) + @as(c_int, 1))))));
}
pub export fn CPU_PushPCToStack(arg_cpu: ?*CPU) void {
    var cpu = arg_cpu;
    _ = &cpu;
    CPU_PushWordToStack(cpu, cpu.*.PC);
}
pub export fn CPU_PushByteOntoStack(arg_cpu: ?*CPU, arg_Value: u8) void {
    var cpu = arg_cpu;
    _ = &cpu;
    var Value = arg_Value;
    _ = &Value;
    const SPWord: c_ushort = CPU_SPToAddress(cpu);
    _ = &SPWord;
    cpu.*.mem.*.Data[SPWord] = Value;
    cpu.*.cycles_executed +%= 1;
    cpu.*.SP -%= 1;
    cpu.*.cycles_executed +%= 1;
}
pub export fn CPU_PopByteFromStack(arg_cpu: ?*CPU) u8 {
    var cpu = arg_cpu;
    _ = &cpu;
    cpu.*.SP +%= 1;
    cpu.*.cycles_executed +%= 1;
    const SPWord: c_ushort = CPU_SPToAddress(cpu);
    _ = &SPWord;
    var Value: u8 = cpu.*.mem.*.Data[SPWord];
    _ = &Value;
    cpu.*.cycles_executed +%= 1;
    return Value;
}
pub export fn CPU_PopWordFromStack(arg_cpu: ?*CPU) c_ushort {
    var cpu = arg_cpu;
    _ = &cpu;
    var ValueFromStack: c_ushort = CPU_ReadWord(cpu, @as(c_ushort, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(c_uint, CPU_SPToAddress(cpu)))) + @as(c_int, 1))))));
    _ = &ValueFromStack;
    cpu.*.SP +%= @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 2)))));
    cpu.*.cycles_executed +%= 1;
    return ValueFromStack;
}
pub export fn CPU_SetZeroAndNegativeFlags(arg_cpu: ?*CPU, arg_Register: u8) void {
    var cpu = arg_cpu;
    _ = &cpu;
    var Register = arg_Register;
    _ = &Register;
    cpu.*.unnamed_0.Flags.Z = @as(u8, @intFromBool(@as(c_int, @bitCast(@as(c_uint, Register))) == @as(c_int, 0)));
    cpu.*.unnamed_0.Flags.N = @as(u8, @intFromBool((@as(c_int, @bitCast(@as(c_uint, Register))) & @as(c_int, @bitCast(@as(c_uint, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 128))))))))) > @as(c_int, 0)));
}
pub export fn CPU_LoadPrg(arg_cpu: ?*CPU, arg_Program: [*c]const u8, arg_NumBytes: c_uint) c_ushort {
    var cpu = arg_cpu;
    _ = &cpu;
    var Program = arg_Program;
    _ = &Program;
    var NumBytes = arg_NumBytes;
    _ = &NumBytes;
    var LoadAddress: c_ushort = 0;
    _ = &LoadAddress;
    if ((Program != null) and (NumBytes > @as(c_uint, @bitCast(@as(c_int, 2))))) {
        var At: c_uint = 0;
        _ = &At;
        const Lo: c_ushort = @as(c_ushort, @bitCast(@as(c_ushort, Program[
            blk: {
                const ref = &At;
                const tmp = ref.*;
                ref.* +%= 1;
                break :blk tmp;
            }
        ])));
        _ = &Lo;
        const Hi: c_ushort = @as(c_ushort, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(c_uint, Program[
            blk: {
                const ref = &At;
                const tmp = ref.*;
                ref.* +%= 1;
                break :blk tmp;
            }
        ]))) << @intCast(8)))));
        _ = &Hi;
        LoadAddress = @as(c_ushort, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(c_uint, Lo))) | @as(c_int, @bitCast(@as(c_uint, Hi)))))));
        {
            var i: c_ushort = LoadAddress;
            _ = &i;
            while (@as(c_uint, @bitCast(@as(c_uint, i))) < ((@as(c_uint, @bitCast(@as(c_uint, LoadAddress))) +% NumBytes) -% @as(c_uint, @bitCast(@as(c_int, 2))))) : (i +%= 1) {
                cpu.*.mem.*.Data[i] = @as(u8, @bitCast(Program[
                    blk: {
                        const ref = &At;
                        const tmp = ref.*;
                        ref.* +%= 1;
                        break :blk tmp;
                    }
                ]));
            }
        }
    }
    return LoadAddress;
}
pub export fn CPU_LoadRegister(arg_cpu: ?*CPU, arg_Address: c_ushort, arg_Register: [*c]u8) void {
    var cpu = arg_cpu;
    _ = &cpu;
    var Address = arg_Address;
    _ = &Address;
    var Register = arg_Register;
    _ = &Register;
    Register.* = CPU_ReadByte(cpu, Address);
    CPU_SetZeroAndNegativeFlags(cpu, Register.*);
}
pub export fn CPU_And(arg_cpu: ?*CPU, arg_Address: c_ushort) void {
    var cpu = arg_cpu;
    _ = &cpu;
    var Address = arg_Address;
    _ = &Address;
    cpu.*.A &= @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(c_uint, CPU_ReadByte(cpu, Address))))))));
    CPU_SetZeroAndNegativeFlags(cpu, cpu.*.A);
}
pub export fn CPU_Ora(arg_cpu: ?*CPU, arg_Address: c_ushort) void {
    var cpu = arg_cpu;
    _ = &cpu;
    var Address = arg_Address;
    _ = &Address;
    cpu.*.A |= @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(c_uint, CPU_ReadByte(cpu, Address))))))));
    CPU_SetZeroAndNegativeFlags(cpu, cpu.*.A);
}
pub export fn CPU_Xor(arg_cpu: ?*CPU, arg_Address: c_ushort) void {
    var cpu = arg_cpu;
    _ = &cpu;
    var Address = arg_Address;
    _ = &Address;
    cpu.*.A ^= @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(c_uint, CPU_ReadByte(cpu, Address))))))));
    CPU_SetZeroAndNegativeFlags(cpu, cpu.*.A);
}
pub export fn CPU_BranchIf(arg_cpu: ?*CPU, arg_Test: u8, arg_Expected: u8) void {
    var cpu = arg_cpu;
    _ = &cpu;
    var Test = arg_Test;
    _ = &Test;
    var Expected = arg_Expected;
    _ = &Expected;
    var Offset: u8 = CPU_FetchSByte(cpu);
    _ = &Offset;
    if (@as(c_int, @bitCast(@as(c_uint, Test))) == @as(c_int, @bitCast(@as(c_uint, Expected)))) {
        const PCOld: c_ushort = cpu.*.PC;
        _ = &PCOld;
        cpu.*.PC +%= @as(c_ushort, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(c_uint, Offset)))))));
        cpu.*.cycles_executed +%= 1;
        var PageChanged: u8 = @as(u8, @intFromBool((@as(c_int, @bitCast(@as(c_uint, cpu.*.PC))) >> @intCast(8)) != (@as(c_int, @bitCast(@as(c_uint, PCOld))) >> @intCast(8))));
        _ = &PageChanged;
        if (PageChanged != 0) {
            cpu.*.cycles_executed +%= 1;
        }
    }
}
pub export fn CPU_ADC(arg_cpu: ?*CPU, arg_Operand: u8) void {
    var cpu = arg_cpu;
    _ = &cpu;
    var Operand = arg_Operand;
    _ = &Operand;
    var AreSignBitsTheSame: u8 = @as(u8, @intFromBool(!(((@as(c_int, @bitCast(@as(c_uint, cpu.*.A))) ^ @as(c_int, @bitCast(@as(c_uint, Operand)))) & @as(c_int, @bitCast(@as(c_uint, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 128))))))))) != 0)));
    _ = &AreSignBitsTheSame;
    var Sum: c_ushort = @as(c_ushort, @bitCast(@as(c_ushort, cpu.*.A)));
    _ = &Sum;
    Sum +%= @as(c_ushort, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(c_uint, Operand)))))));
    Sum +%= @as(c_ushort, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(c_uint, cpu.*.unnamed_0.Flags.C)))))));
    cpu.*.A = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(c_uint, Sum))) & @as(c_int, 255)))));
    CPU_SetZeroAndNegativeFlags(cpu, cpu.*.A);
    cpu.*.unnamed_0.Flags.C = @as(u8, @intFromBool(@as(c_int, @bitCast(@as(c_uint, Sum))) > @as(c_int, 255)));
    cpu.*.unnamed_0.Flags.V = @as(u8, @intFromBool((@as(c_int, @bitCast(@as(c_uint, AreSignBitsTheSame))) != 0) and (((@as(c_int, @bitCast(@as(c_uint, cpu.*.A))) ^ @as(c_int, @bitCast(@as(c_uint, Operand)))) & @as(c_int, @bitCast(@as(c_uint, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 128))))))))) != 0)));
}
pub export fn CPU_SBC(arg_cpu: ?*CPU, arg_Operand: u8) void {
    var cpu = arg_cpu;
    _ = &cpu;
    var Operand = arg_Operand;
    _ = &Operand;
    CPU_ADC(cpu, @as(u8, @bitCast(@as(i8, @truncate(~@as(c_int, @bitCast(@as(c_uint, Operand))))))));
}
pub export fn CPU_ASL(arg_cpu: ?*CPU, arg_Operand: u8) u8 {
    var cpu = arg_cpu;
    _ = &cpu;
    var Operand = arg_Operand;
    _ = &Operand;
    cpu.*.unnamed_0.Flags.C = @as(u8, @intFromBool((@as(c_int, @bitCast(@as(c_uint, Operand))) & @as(c_int, @bitCast(@as(c_uint, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 128))))))))) > @as(c_int, 0)));
    var Result: u8 = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(c_uint, Operand))) << @intCast(1)))));
    _ = &Result;
    CPU_SetZeroAndNegativeFlags(cpu, @as(u8, @bitCast(Result)));
    cpu.*.cycles_executed +%= 1;
    return Result;
}
pub export fn CPU_LSR(arg_cpu: ?*CPU, arg_Operand: u8) u8 {
    var cpu = arg_cpu;
    _ = &cpu;
    var Operand = arg_Operand;
    _ = &Operand;
    cpu.*.unnamed_0.Flags.C = @as(u8, @intFromBool((@as(c_int, @bitCast(@as(c_uint, Operand))) & @as(c_int, @bitCast(@as(c_uint, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 1))))))))) > @as(c_int, 0)));
    var Result: u8 = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(c_uint, Operand))) >> @intCast(1)))));
    _ = &Result;
    CPU_SetZeroAndNegativeFlags(cpu, @as(u8, @bitCast(Result)));
    cpu.*.cycles_executed +%= 1;
    return Result;
}
pub export fn CPU_ROL(arg_cpu: ?*CPU, arg_Operand: u8) u8 {
    var cpu = arg_cpu;
    _ = &cpu;
    var Operand = arg_Operand;
    _ = &Operand;
    var NewBit0: u8 = @as(u8, @bitCast(@as(i8, @truncate(if (@as(c_int, @bitCast(@as(c_uint, cpu.*.unnamed_0.Flags.C))) != 0) @as(c_int, @bitCast(@as(c_uint, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 1)))))))) else @as(c_int, 0)))));
    _ = &NewBit0;
    cpu.*.unnamed_0.Flags.C = @as(u8, @intFromBool((@as(c_int, @bitCast(@as(c_uint, Operand))) & @as(c_int, @bitCast(@as(c_uint, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 128))))))))) > @as(c_int, 0)));
    Operand = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(c_uint, Operand))) << @intCast(1)))));
    Operand |= @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(c_uint, NewBit0)))))));
    CPU_SetZeroAndNegativeFlags(cpu, @as(u8, @bitCast(Operand)));
    cpu.*.cycles_executed +%= 1;
    return Operand;
}
pub export fn CPU_ROR(arg_cpu: ?*CPU, arg_Operand: u8) u8 {
    var cpu = arg_cpu;
    _ = &cpu;
    var Operand = arg_Operand;
    _ = &Operand;
    var OldBit0: u8 = @as(u8, @intFromBool((@as(c_int, @bitCast(@as(c_uint, Operand))) & @as(c_int, @bitCast(@as(c_uint, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 1))))))))) > @as(c_int, 0)));
    _ = &OldBit0;
    Operand = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(c_uint, Operand))) >> @intCast(1)))));
    if (cpu.*.unnamed_0.Flags.C != 0) {
        Operand |= @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(c_uint, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 128))))))))))));
    }
    cpu.*.cycles_executed +%= 1;
    cpu.*.unnamed_0.Flags.C = @as(u8, @bitCast(OldBit0));
    CPU_SetZeroAndNegativeFlags(cpu, @as(u8, @bitCast(Operand)));
    return Operand;
}
pub export fn CPU_PushPSToStack(arg_cpu: ?*CPU) void {
    var cpu = arg_cpu;
    _ = &cpu;
    var PSStack: u8 = @as(u8, @bitCast(@as(i8, @truncate((@as(c_int, @bitCast(@as(c_uint, cpu.*.unnamed_0.PS))) | @as(c_int, @bitCast(@as(c_uint, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 16))))))))) | @as(c_int, @bitCast(@as(c_uint, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 32))))))))))));
    _ = &PSStack;
    CPU_PushByteOntoStack(cpu, @as(u8, @bitCast(PSStack)));
}
pub export fn CPU_PopPSFromStack(arg_cpu: ?*CPU) void {
    var cpu = arg_cpu;
    _ = &cpu;
    cpu.*.unnamed_0.PS = @as(u8, @bitCast(CPU_PopByteFromStack(cpu)));
    cpu.*.unnamed_0.Flags.B = 0;
    cpu.*.unnamed_0.Flags.Unused = 0;
}
pub export fn CPU_Run_Step(arg_cpu: ?*CPU) u8 {
    var cpu = arg_cpu;
    _ = &cpu;
    var cycles_now: c_uint = cpu.*.cycles_executed;
    _ = &cycles_now;
    var opcode: u8 = CPU_FetchByte(cpu);
    _ = &opcode;
    cpu.*.opcode_last = opcode;
    while (true) {
        switch (@as(c_int, @bitCast(@as(c_uint, opcode)))) {
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 41)))) => {
                cpu.*.A &= @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(c_uint, CPU_FetchByte(cpu))))))));
                CPU_SetZeroAndNegativeFlags(cpu, cpu.*.A);
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 9)))) => {
                cpu.*.A |= @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(c_uint, CPU_FetchByte(cpu))))))));
                CPU_SetZeroAndNegativeFlags(cpu, cpu.*.A);
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 73)))) => {
                cpu.*.A ^= @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(c_uint, CPU_FetchByte(cpu))))))));
                CPU_SetZeroAndNegativeFlags(cpu, cpu.*.A);
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 37)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPage(cpu);
                    _ = &Address;
                    CPU_And(cpu, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 5)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPage(cpu);
                    _ = &Address;
                    CPU_Ora(cpu, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 69)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPage(cpu);
                    _ = &Address;
                    CPU_Xor(cpu, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 53)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPageX(cpu);
                    _ = &Address;
                    CPU_And(cpu, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 21)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPageX(cpu);
                    _ = &Address;
                    CPU_Ora(cpu, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 85)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPageX(cpu);
                    _ = &Address;
                    CPU_Xor(cpu, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 45)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsolute(cpu);
                    _ = &Address;
                    CPU_And(cpu, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 13)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsolute(cpu);
                    _ = &Address;
                    CPU_Ora(cpu, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 77)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsolute(cpu);
                    _ = &Address;
                    CPU_Xor(cpu, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 61)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsoluteX(cpu);
                    _ = &Address;
                    CPU_And(cpu, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 29)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsoluteX(cpu);
                    _ = &Address;
                    CPU_Ora(cpu, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 93)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsoluteX(cpu);
                    _ = &Address;
                    CPU_Xor(cpu, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 57)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsoluteY(cpu);
                    _ = &Address;
                    CPU_And(cpu, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 25)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsoluteY(cpu);
                    _ = &Address;
                    CPU_Ora(cpu, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 89)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsoluteY(cpu);
                    _ = &Address;
                    CPU_Xor(cpu, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 33)))) => {
                {
                    var Address: c_ushort = CPU_AddrIndirectX(cpu);
                    _ = &Address;
                    CPU_And(cpu, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 1)))) => {
                {
                    var Address: c_ushort = CPU_AddrIndirectX(cpu);
                    _ = &Address;
                    CPU_Ora(cpu, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 65)))) => {
                {
                    var Address: c_ushort = CPU_AddrIndirectX(cpu);
                    _ = &Address;
                    CPU_Xor(cpu, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 49)))) => {
                {
                    var Address: c_ushort = CPU_AddrIndirectY(cpu);
                    _ = &Address;
                    CPU_And(cpu, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 17)))) => {
                {
                    var Address: c_ushort = CPU_AddrIndirectY(cpu);
                    _ = &Address;
                    CPU_Ora(cpu, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 81)))) => {
                {
                    var Address: c_ushort = CPU_AddrIndirectY(cpu);
                    _ = &Address;
                    CPU_Xor(cpu, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 36)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPage(cpu);
                    _ = &Address;
                    var Value: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Value;
                    cpu.*.unnamed_0.Flags.Z = @as(u8, @intFromBool(!((@as(c_int, @bitCast(@as(c_uint, cpu.*.A))) & @as(c_int, @bitCast(@as(c_uint, Value)))) != 0)));
                    cpu.*.unnamed_0.Flags.N = @as(u8, @intFromBool((@as(c_int, @bitCast(@as(c_uint, Value))) & @as(c_int, @bitCast(@as(c_uint, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 128))))))))) != @as(c_int, 0)));
                    cpu.*.unnamed_0.Flags.V = @as(u8, @intFromBool((@as(c_int, @bitCast(@as(c_uint, Value))) & @as(c_int, @bitCast(@as(c_uint, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 64))))))))) != @as(c_int, 0)));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 44)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsolute(cpu);
                    _ = &Address;
                    var Value: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Value;
                    cpu.*.unnamed_0.Flags.Z = @as(u8, @intFromBool(!((@as(c_int, @bitCast(@as(c_uint, cpu.*.A))) & @as(c_int, @bitCast(@as(c_uint, Value)))) != 0)));
                    cpu.*.unnamed_0.Flags.N = @as(u8, @intFromBool((@as(c_int, @bitCast(@as(c_uint, Value))) & @as(c_int, @bitCast(@as(c_uint, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 128))))))))) != @as(c_int, 0)));
                    cpu.*.unnamed_0.Flags.V = @as(u8, @intFromBool((@as(c_int, @bitCast(@as(c_uint, Value))) & @as(c_int, @bitCast(@as(c_uint, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 64))))))))) != @as(c_int, 0)));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 169)))) => {
                {
                    cpu.*.A = CPU_FetchByte(cpu);
                    CPU_SetZeroAndNegativeFlags(cpu, cpu.*.A);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 162)))) => {
                {
                    cpu.*.X = CPU_FetchByte(cpu);
                    CPU_SetZeroAndNegativeFlags(cpu, cpu.*.X);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 160)))) => {
                {
                    cpu.*.Y = CPU_FetchByte(cpu);
                    CPU_SetZeroAndNegativeFlags(cpu, cpu.*.Y);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 165)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPage(cpu);
                    _ = &Address;
                    CPU_LoadRegister(cpu, Address, &cpu.*.A);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 166)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPage(cpu);
                    _ = &Address;
                    CPU_LoadRegister(cpu, Address, &cpu.*.X);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 182)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPageY(cpu);
                    _ = &Address;
                    CPU_LoadRegister(cpu, Address, &cpu.*.X);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 164)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPage(cpu);
                    _ = &Address;
                    CPU_LoadRegister(cpu, Address, &cpu.*.Y);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 181)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPageX(cpu);
                    _ = &Address;
                    CPU_LoadRegister(cpu, Address, &cpu.*.A);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 180)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPageX(cpu);
                    _ = &Address;
                    CPU_LoadRegister(cpu, Address, &cpu.*.Y);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 173)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsolute(cpu);
                    _ = &Address;
                    CPU_LoadRegister(cpu, Address, &cpu.*.A);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 174)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsolute(cpu);
                    _ = &Address;
                    CPU_LoadRegister(cpu, Address, &cpu.*.X);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 172)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsolute(cpu);
                    _ = &Address;
                    CPU_LoadRegister(cpu, Address, &cpu.*.Y);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 189)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsoluteX(cpu);
                    _ = &Address;
                    CPU_LoadRegister(cpu, Address, &cpu.*.A);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 188)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsoluteX(cpu);
                    _ = &Address;
                    CPU_LoadRegister(cpu, Address, &cpu.*.Y);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 185)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsoluteY(cpu);
                    _ = &Address;
                    CPU_LoadRegister(cpu, Address, &cpu.*.A);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 190)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsoluteY(cpu);
                    _ = &Address;
                    CPU_LoadRegister(cpu, Address, &cpu.*.X);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 161)))) => {
                {
                    var Address: c_ushort = CPU_AddrIndirectX(cpu);
                    _ = &Address;
                    CPU_LoadRegister(cpu, Address, &cpu.*.A);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 129)))) => {
                {
                    var Address: c_ushort = CPU_AddrIndirectX(cpu);
                    _ = &Address;
                    CPU_WriteByte(cpu, cpu.*.A, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 177)))) => {
                {
                    var Address: c_ushort = CPU_AddrIndirectY(cpu);
                    _ = &Address;
                    CPU_LoadRegister(cpu, Address, &cpu.*.A);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 145)))) => {
                {
                    var Address: c_ushort = CPU_AddrIndirectY_6(cpu);
                    _ = &Address;
                    CPU_WriteByte(cpu, cpu.*.A, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 133)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPage(cpu);
                    _ = &Address;
                    CPU_WriteByte(cpu, cpu.*.A, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 134)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPage(cpu);
                    _ = &Address;
                    CPU_WriteByte(cpu, cpu.*.X, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 150)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPageY(cpu);
                    _ = &Address;
                    CPU_WriteByte(cpu, cpu.*.X, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 132)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPage(cpu);
                    _ = &Address;
                    CPU_WriteByte(cpu, cpu.*.Y, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 141)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsolute(cpu);
                    _ = &Address;
                    CPU_WriteByte(cpu, cpu.*.A, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 142)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsolute(cpu);
                    _ = &Address;
                    CPU_WriteByte(cpu, cpu.*.X, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 140)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsolute(cpu);
                    _ = &Address;
                    CPU_WriteByte(cpu, cpu.*.Y, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 149)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPageX(cpu);
                    _ = &Address;
                    CPU_WriteByte(cpu, cpu.*.A, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 148)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPageX(cpu);
                    _ = &Address;
                    CPU_WriteByte(cpu, cpu.*.Y, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 157)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsoluteX_5(cpu);
                    _ = &Address;
                    CPU_WriteByte(cpu, cpu.*.A, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 153)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsoluteY_5(cpu);
                    _ = &Address;
                    CPU_WriteByte(cpu, cpu.*.A, Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 32)))) => {
                {
                    var SubAddr: c_ushort = CPU_FetchWord(cpu);
                    _ = &SubAddr;
                    CPU_PushPCMinusOneToStack(cpu);
                    cpu.*.PC = SubAddr;
                    cpu.*.cycles_executed +%= 1;
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 96)))) => {
                {
                    var ReturnAddress: c_ushort = CPU_PopWordFromStack(cpu);
                    _ = &ReturnAddress;
                    cpu.*.PC = @as(c_ushort, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(c_uint, ReturnAddress))) + @as(c_int, 1)))));
                    cpu.*.cycles_executed +%= @as(c_uint, @bitCast(@as(c_int, 2)));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 76)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsolute(cpu);
                    _ = &Address;
                    cpu.*.PC = Address;
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 108)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsolute(cpu);
                    _ = &Address;
                    Address = CPU_ReadWord(cpu, Address);
                    cpu.*.PC = Address;
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 186)))) => {
                {
                    cpu.*.X = cpu.*.SP;
                    cpu.*.cycles_executed +%= 1;
                    CPU_SetZeroAndNegativeFlags(cpu, cpu.*.X);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 154)))) => {
                {
                    cpu.*.SP = cpu.*.X;
                    cpu.*.cycles_executed +%= 1;
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 72)))) => {
                {
                    CPU_PushByteOntoStack(cpu, cpu.*.A);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 104)))) => {
                {
                    cpu.*.A = CPU_PopByteFromStack(cpu);
                    CPU_SetZeroAndNegativeFlags(cpu, cpu.*.A);
                    cpu.*.cycles_executed +%= 1;
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 8)))) => {
                {
                    CPU_PushPSToStack(cpu);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 40)))) => {
                {
                    CPU_PopPSFromStack(cpu);
                    cpu.*.cycles_executed +%= 1;
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 170)))) => {
                {
                    cpu.*.X = cpu.*.A;
                    cpu.*.cycles_executed +%= 1;
                    CPU_SetZeroAndNegativeFlags(cpu, cpu.*.X);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 168)))) => {
                {
                    cpu.*.Y = cpu.*.A;
                    cpu.*.cycles_executed +%= 1;
                    CPU_SetZeroAndNegativeFlags(cpu, cpu.*.Y);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 138)))) => {
                {
                    cpu.*.A = cpu.*.X;
                    cpu.*.cycles_executed +%= 1;
                    CPU_SetZeroAndNegativeFlags(cpu, cpu.*.A);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 152)))) => {
                {
                    cpu.*.A = cpu.*.Y;
                    cpu.*.cycles_executed +%= 1;
                    CPU_SetZeroAndNegativeFlags(cpu, cpu.*.A);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 232)))) => {
                {
                    cpu.*.X +%= 1;
                    cpu.*.cycles_executed +%= 1;
                    CPU_SetZeroAndNegativeFlags(cpu, cpu.*.X);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 200)))) => {
                {
                    cpu.*.Y +%= 1;
                    cpu.*.cycles_executed +%= 1;
                    CPU_SetZeroAndNegativeFlags(cpu, cpu.*.Y);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 202)))) => {
                {
                    cpu.*.X -%= 1;
                    cpu.*.cycles_executed +%= 1;
                    CPU_SetZeroAndNegativeFlags(cpu, cpu.*.X);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 136)))) => {
                {
                    cpu.*.Y -%= 1;
                    cpu.*.cycles_executed +%= 1;
                    CPU_SetZeroAndNegativeFlags(cpu, cpu.*.Y);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 198)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPage(cpu);
                    _ = &Address;
                    var Value: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Value;
                    Value -%= 1;
                    cpu.*.cycles_executed +%= 1;
                    CPU_WriteByte(cpu, @as(u8, @bitCast(Value)), Address);
                    CPU_SetZeroAndNegativeFlags(cpu, @as(u8, @bitCast(Value)));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 214)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPageX(cpu);
                    _ = &Address;
                    var Value: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Value;
                    Value -%= 1;
                    cpu.*.cycles_executed +%= 1;
                    CPU_WriteByte(cpu, @as(u8, @bitCast(Value)), Address);
                    CPU_SetZeroAndNegativeFlags(cpu, @as(u8, @bitCast(Value)));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 206)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsolute(cpu);
                    _ = &Address;
                    var Value: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Value;
                    Value -%= 1;
                    cpu.*.cycles_executed +%= 1;
                    CPU_WriteByte(cpu, @as(u8, @bitCast(Value)), Address);
                    CPU_SetZeroAndNegativeFlags(cpu, @as(u8, @bitCast(Value)));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 222)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsoluteX_5(cpu);
                    _ = &Address;
                    var Value: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Value;
                    Value -%= 1;
                    cpu.*.cycles_executed +%= 1;
                    CPU_WriteByte(cpu, @as(u8, @bitCast(Value)), Address);
                    CPU_SetZeroAndNegativeFlags(cpu, @as(u8, @bitCast(Value)));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 230)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPage(cpu);
                    _ = &Address;
                    var Value: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Value;
                    Value +%= 1;
                    cpu.*.cycles_executed +%= 1;
                    CPU_WriteByte(cpu, @as(u8, @bitCast(Value)), Address);
                    CPU_SetZeroAndNegativeFlags(cpu, @as(u8, @bitCast(Value)));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 246)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPageX(cpu);
                    _ = &Address;
                    var Value: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Value;
                    Value +%= 1;
                    cpu.*.cycles_executed +%= 1;
                    CPU_WriteByte(cpu, @as(u8, @bitCast(Value)), Address);
                    CPU_SetZeroAndNegativeFlags(cpu, @as(u8, @bitCast(Value)));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 238)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsolute(cpu);
                    _ = &Address;
                    var Value: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Value;
                    Value +%= 1;
                    cpu.*.cycles_executed +%= 1;
                    CPU_WriteByte(cpu, @as(u8, @bitCast(Value)), Address);
                    CPU_SetZeroAndNegativeFlags(cpu, @as(u8, @bitCast(Value)));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 254)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsoluteX_5(cpu);
                    _ = &Address;
                    var Value: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Value;
                    Value +%= 1;
                    cpu.*.cycles_executed +%= 1;
                    CPU_WriteByte(cpu, @as(u8, @bitCast(Value)), Address);
                    CPU_SetZeroAndNegativeFlags(cpu, @as(u8, @bitCast(Value)));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 240)))) => {
                {
                    CPU_BranchIf(cpu, @as(u8, @bitCast(cpu.*.unnamed_0.Flags.Z)), @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 1))))));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 208)))) => {
                {
                    CPU_BranchIf(cpu, @as(u8, @bitCast(cpu.*.unnamed_0.Flags.Z)), @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 176)))) => {
                {
                    CPU_BranchIf(cpu, @as(u8, @bitCast(cpu.*.unnamed_0.Flags.C)), @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 1))))));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 144)))) => {
                {
                    CPU_BranchIf(cpu, @as(u8, @bitCast(cpu.*.unnamed_0.Flags.C)), @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 48)))) => {
                {
                    CPU_BranchIf(cpu, @as(u8, @bitCast(cpu.*.unnamed_0.Flags.N)), @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 1))))));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 16)))) => {
                {
                    CPU_BranchIf(cpu, @as(u8, @bitCast(cpu.*.unnamed_0.Flags.N)), @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 80)))) => {
                {
                    CPU_BranchIf(cpu, @as(u8, @bitCast(cpu.*.unnamed_0.Flags.V)), @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 112)))) => {
                {
                    CPU_BranchIf(cpu, @as(u8, @bitCast(cpu.*.unnamed_0.Flags.V)), @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 1))))));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 24)))) => {
                {
                    cpu.*.unnamed_0.Flags.C = 0;
                    cpu.*.cycles_executed +%= 1;
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 56)))) => {
                {
                    cpu.*.unnamed_0.Flags.C = 1;
                    cpu.*.cycles_executed +%= 1;
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 216)))) => {
                {
                    cpu.*.unnamed_0.Flags.D = 0;
                    cpu.*.cycles_executed +%= 1;
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 248)))) => {
                {
                    cpu.*.unnamed_0.Flags.D = 1;
                    cpu.*.cycles_executed +%= 1;
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 88)))) => {
                {
                    cpu.*.unnamed_0.Flags.I = 0;
                    cpu.*.cycles_executed +%= 1;
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 120)))) => {
                {
                    cpu.*.unnamed_0.Flags.I = 1;
                    cpu.*.cycles_executed +%= 1;
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 184)))) => {
                {
                    cpu.*.unnamed_0.Flags.V = 0;
                    cpu.*.cycles_executed +%= 1;
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 234)))) => {
                {
                    cpu.*.cycles_executed +%= 1;
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 109)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsolute(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    CPU_ADC(cpu, Operand);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 125)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsoluteX(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    CPU_ADC(cpu, Operand);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 121)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsoluteY(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    CPU_ADC(cpu, Operand);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 101)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPage(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    CPU_ADC(cpu, Operand);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 117)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPageX(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    CPU_ADC(cpu, Operand);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 97)))) => {
                {
                    var Address: c_ushort = CPU_AddrIndirectX(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    CPU_ADC(cpu, Operand);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 113)))) => {
                {
                    var Address: c_ushort = CPU_AddrIndirectY(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    CPU_ADC(cpu, Operand);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 105)))) => {
                {
                    var Operand: u8 = @as(u8, @bitCast(CPU_FetchByte(cpu)));
                    _ = &Operand;
                    CPU_ADC(cpu, Operand);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 233)))) => {
                {
                    var Operand: u8 = @as(u8, @bitCast(CPU_FetchByte(cpu)));
                    _ = &Operand;
                    CPU_SBC(cpu, Operand);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 237)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsolute(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    CPU_SBC(cpu, Operand);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 229)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPage(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    CPU_SBC(cpu, Operand);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 245)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPageX(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    CPU_SBC(cpu, Operand);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 253)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsoluteX(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    CPU_SBC(cpu, Operand);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 249)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsoluteY(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    CPU_SBC(cpu, Operand);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 225)))) => {
                {
                    var Address: c_ushort = CPU_AddrIndirectX(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    CPU_SBC(cpu, Operand);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 241)))) => {
                {
                    var Address: c_ushort = CPU_AddrIndirectY(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    CPU_SBC(cpu, Operand);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 224)))) => {
                {
                    var Operand: u8 = @as(u8, @bitCast(CPU_FetchByte(cpu)));
                    _ = &Operand;
                    CPU_RegisterCompare(cpu, Operand, @as(u8, @bitCast(cpu.*.X)));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 192)))) => {
                {
                    var Operand: u8 = @as(u8, @bitCast(CPU_FetchByte(cpu)));
                    _ = &Operand;
                    CPU_RegisterCompare(cpu, Operand, @as(u8, @bitCast(cpu.*.Y)));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 228)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPage(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    CPU_RegisterCompare(cpu, Operand, @as(u8, @bitCast(cpu.*.X)));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 196)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPage(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    CPU_RegisterCompare(cpu, Operand, @as(u8, @bitCast(cpu.*.Y)));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 236)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsolute(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    CPU_RegisterCompare(cpu, Operand, @as(u8, @bitCast(cpu.*.X)));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 204)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsolute(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    CPU_RegisterCompare(cpu, Operand, @as(u8, @bitCast(cpu.*.Y)));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 201)))) => {
                {
                    var Operand: u8 = @as(u8, @bitCast(CPU_FetchByte(cpu)));
                    _ = &Operand;
                    CPU_RegisterCompare(cpu, Operand, @as(u8, @bitCast(cpu.*.A)));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 197)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPage(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    CPU_RegisterCompare(cpu, Operand, @as(u8, @bitCast(cpu.*.A)));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 213)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPageX(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    CPU_RegisterCompare(cpu, Operand, @as(u8, @bitCast(cpu.*.A)));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 205)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsolute(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    CPU_RegisterCompare(cpu, Operand, @as(u8, @bitCast(cpu.*.A)));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 221)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsoluteX(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    CPU_RegisterCompare(cpu, Operand, @as(u8, @bitCast(cpu.*.A)));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 217)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsoluteY(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    CPU_RegisterCompare(cpu, Operand, @as(u8, @bitCast(cpu.*.A)));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 193)))) => {
                {
                    var Address: c_ushort = CPU_AddrIndirectX(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    CPU_RegisterCompare(cpu, Operand, @as(u8, @bitCast(cpu.*.A)));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 209)))) => {
                {
                    var Address: c_ushort = CPU_AddrIndirectY(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    CPU_RegisterCompare(cpu, Operand, @as(u8, @bitCast(cpu.*.A)));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 10)))) => {
                {
                    cpu.*.A = @as(u8, @bitCast(CPU_ASL(cpu, @as(u8, @bitCast(cpu.*.A)))));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 6)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPage(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    var Result: u8 = CPU_ASL(cpu, Operand);
                    _ = &Result;
                    CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 22)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPageX(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    var Result: u8 = CPU_ASL(cpu, Operand);
                    _ = &Result;
                    CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 14)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsolute(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    var Result: u8 = CPU_ASL(cpu, Operand);
                    _ = &Result;
                    CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 30)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsoluteX_5(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    var Result: u8 = CPU_ASL(cpu, Operand);
                    _ = &Result;
                    CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 74)))) => {
                {
                    cpu.*.A = @as(u8, @bitCast(CPU_LSR(cpu, @as(u8, @bitCast(cpu.*.A)))));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 70)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPage(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    var Result: u8 = CPU_LSR(cpu, Operand);
                    _ = &Result;
                    CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 86)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPageX(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    var Result: u8 = CPU_LSR(cpu, Operand);
                    _ = &Result;
                    CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 78)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsolute(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    var Result: u8 = CPU_LSR(cpu, Operand);
                    _ = &Result;
                    CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 94)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsoluteX_5(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    var Result: u8 = CPU_LSR(cpu, Operand);
                    _ = &Result;
                    CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 42)))) => {
                {
                    cpu.*.A = @as(u8, @bitCast(CPU_ROL(cpu, @as(u8, @bitCast(cpu.*.A)))));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 38)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPage(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    var Result: u8 = CPU_ROL(cpu, Operand);
                    _ = &Result;
                    CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 54)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPageX(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    var Result: u8 = CPU_ROL(cpu, Operand);
                    _ = &Result;
                    CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 46)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsolute(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    var Result: u8 = CPU_ROL(cpu, Operand);
                    _ = &Result;
                    CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 62)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsoluteX_5(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    var Result: u8 = CPU_ROL(cpu, Operand);
                    _ = &Result;
                    CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 106)))) => {
                {
                    cpu.*.A = @as(u8, @bitCast(CPU_ROR(cpu, @as(u8, @bitCast(cpu.*.A)))));
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 102)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPage(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    var Result: u8 = CPU_ROR(cpu, Operand);
                    _ = &Result;
                    CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 118)))) => {
                {
                    var Address: c_ushort = CPU_AddrZeroPageX(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    var Result: u8 = CPU_ROR(cpu, Operand);
                    _ = &Result;
                    CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 110)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsolute(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    var Result: u8 = CPU_ROR(cpu, Operand);
                    _ = &Result;
                    CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 126)))) => {
                {
                    var Address: c_ushort = CPU_AddrAbsoluteX_5(cpu);
                    _ = &Address;
                    var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
                    _ = &Operand;
                    var Result: u8 = CPU_ROR(cpu, Operand);
                    _ = &Result;
                    CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
                }
                break;
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 0)))) => {
                {
                    CPU_PushPCPlusOneToStack(cpu);
                    CPU_PushPSToStack(cpu);
                    cpu.*.PC = CPU_ReadWord(cpu, @as(c_ushort, @bitCast(@as(c_short, @truncate(@as(c_int, 65534))))));
                    cpu.*.unnamed_0.Flags.B = 1;
                    cpu.*.unnamed_0.Flags.I = 1;
                    return 0;
                }
            },
            @as(c_int, @bitCast(@as(c_uint, @as(u8, 64)))) => {
                {
                    CPU_PopPSFromStack(cpu);
                    cpu.*.PC = CPU_PopWordFromStack(cpu);
                }
                break;
            },
            else => return 0,
        }
        break;
    }
    cpu.*.cycles_last_step = cpu.*.cycles_executed -% cycles_now;
    return @as(u8, @bitCast(@as(u8, @truncate(cpu.*.cycles_last_step))));
}
pub extern fn CPU_Execute(cpu: ?*CPU) c_int;
pub export fn CPU_AddrZeroPage(arg_cpu: ?*CPU) c_ushort {
    var cpu = arg_cpu;
    _ = &cpu;
    var ZeroPageAddr: u8 = @as(u8, @bitCast(CPU_FetchByte(cpu)));
    _ = &ZeroPageAddr;
    return @as(c_ushort, @bitCast(@as(c_ushort, ZeroPageAddr)));
}
pub export fn CPU_AddrZeroPageX(arg_cpu: ?*CPU) c_ushort {
    var cpu = arg_cpu;
    _ = &cpu;
    var ZeroPageAddr: u8 = @as(u8, @bitCast(CPU_FetchByte(cpu)));
    _ = &ZeroPageAddr;
    ZeroPageAddr +%= @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(c_uint, cpu.*.X)))))));
    cpu.*.cycles_executed +%= 1;
    return @as(c_ushort, @bitCast(@as(c_ushort, ZeroPageAddr)));
}
pub export fn CPU_AddrZeroPageY(arg_cpu: ?*CPU) c_ushort {
    var cpu = arg_cpu;
    _ = &cpu;
    var ZeroPageAddr: u8 = @as(u8, @bitCast(CPU_FetchByte(cpu)));
    _ = &ZeroPageAddr;
    ZeroPageAddr +%= @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(c_uint, cpu.*.Y)))))));
    cpu.*.cycles_executed +%= 1;
    return @as(c_ushort, @bitCast(@as(c_ushort, ZeroPageAddr)));
}
pub export fn CPU_AddrAbsolute(arg_cpu: ?*CPU) c_ushort {
    var cpu = arg_cpu;
    _ = &cpu;
    var AbsAddress: c_ushort = CPU_FetchWord(cpu);
    _ = &AbsAddress;
    return AbsAddress;
}
pub export fn CPU_AddrAbsoluteX(arg_cpu: ?*CPU) c_ushort {
    var cpu = arg_cpu;
    _ = &cpu;
    var AbsAddress: c_ushort = CPU_FetchWord(cpu);
    _ = &AbsAddress;
    var AbsAddressX: c_ushort = @as(c_ushort, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(c_uint, AbsAddress))) + @as(c_int, @bitCast(@as(c_uint, cpu.*.X)))))));
    _ = &AbsAddressX;
    var CrossedPageBoundary: u8 = @as(u8, @bitCast(@as(i8, @truncate((@as(c_int, @bitCast(@as(c_uint, AbsAddress))) ^ @as(c_int, @bitCast(@as(c_uint, AbsAddressX)))) >> @intCast(8)))));
    _ = &CrossedPageBoundary;
    if (CrossedPageBoundary != 0) {
        cpu.*.cycles_executed +%= 1;
    }
    return AbsAddressX;
}
pub export fn CPU_AddrAbsoluteX_5(arg_cpu: ?*CPU) c_ushort {
    var cpu = arg_cpu;
    _ = &cpu;
    var AbsAddress: c_ushort = CPU_FetchWord(cpu);
    _ = &AbsAddress;
    var AbsAddressX: c_ushort = @as(c_ushort, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(c_uint, AbsAddress))) + @as(c_int, @bitCast(@as(c_uint, cpu.*.X)))))));
    _ = &AbsAddressX;
    cpu.*.cycles_executed +%= 1;
    return AbsAddressX;
}
pub export fn CPU_AddrAbsoluteY(arg_cpu: ?*CPU) c_ushort {
    var cpu = arg_cpu;
    _ = &cpu;
    var AbsAddress: c_ushort = CPU_FetchWord(cpu);
    _ = &AbsAddress;
    var AbsAddressY: c_ushort = @as(c_ushort, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(c_uint, AbsAddress))) + @as(c_int, @bitCast(@as(c_uint, cpu.*.Y)))))));
    _ = &AbsAddressY;
    var CrossedPageBoundary: u8 = @as(u8, @bitCast(@as(i8, @truncate((@as(c_int, @bitCast(@as(c_uint, AbsAddress))) ^ @as(c_int, @bitCast(@as(c_uint, AbsAddressY)))) >> @intCast(8)))));
    _ = &CrossedPageBoundary;
    if (CrossedPageBoundary != 0) {
        cpu.*.cycles_executed +%= 1;
    }
    return AbsAddressY;
}
pub export fn CPU_AddrAbsoluteY_5(arg_cpu: ?*CPU) c_ushort {
    var cpu = arg_cpu;
    _ = &cpu;
    var AbsAddress: c_ushort = CPU_FetchWord(cpu);
    _ = &AbsAddress;
    var AbsAddressY: c_ushort = @as(c_ushort, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(c_uint, AbsAddress))) + @as(c_int, @bitCast(@as(c_uint, cpu.*.Y)))))));
    _ = &AbsAddressY;
    cpu.*.cycles_executed +%= 1;
    return AbsAddressY;
}
pub export fn CPU_AddrIndirectX(arg_cpu: ?*CPU) c_ushort {
    var cpu = arg_cpu;
    _ = &cpu;
    var ZPAddress: u8 = @as(u8, @bitCast(CPU_FetchByte(cpu)));
    _ = &ZPAddress;
    ZPAddress +%= @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(c_uint, cpu.*.X)))))));
    cpu.*.cycles_executed +%= 1;
    var EffectiveAddr: c_ushort = CPU_ReadWord(cpu, @as(c_ushort, @bitCast(@as(c_ushort, ZPAddress))));
    _ = &EffectiveAddr;
    return EffectiveAddr;
}
pub export fn CPU_AddrIndirectY(arg_cpu: ?*CPU) c_ushort {
    var cpu = arg_cpu;
    _ = &cpu;
    var ZPAddress: u8 = @as(u8, @bitCast(CPU_FetchByte(cpu)));
    _ = &ZPAddress;
    var EffectiveAddr: c_ushort = CPU_ReadWord(cpu, @as(c_ushort, @bitCast(@as(c_ushort, ZPAddress))));
    _ = &EffectiveAddr;
    var EffectiveAddrY: c_ushort = @as(c_ushort, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(c_uint, EffectiveAddr))) + @as(c_int, @bitCast(@as(c_uint, cpu.*.Y)))))));
    _ = &EffectiveAddrY;
    var CrossedPageBoundary: u8 = @as(u8, @bitCast(@as(i8, @truncate((@as(c_int, @bitCast(@as(c_uint, EffectiveAddr))) ^ @as(c_int, @bitCast(@as(c_uint, EffectiveAddrY)))) >> @intCast(8)))));
    _ = &CrossedPageBoundary;
    if (CrossedPageBoundary != 0) {
        cpu.*.cycles_executed +%= 1;
    }
    return EffectiveAddrY;
}
pub export fn CPU_AddrIndirectY_6(arg_cpu: ?*CPU) c_ushort {
    var cpu = arg_cpu;
    _ = &cpu;
    var ZPAddress: u8 = @as(u8, @bitCast(CPU_FetchByte(cpu)));
    _ = &ZPAddress;
    var EffectiveAddr: c_ushort = CPU_ReadWord(cpu, @as(c_ushort, @bitCast(@as(c_ushort, ZPAddress))));
    _ = &EffectiveAddr;
    var EffectiveAddrY: c_ushort = @as(c_ushort, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(c_uint, EffectiveAddr))) + @as(c_int, @bitCast(@as(c_uint, cpu.*.Y)))))));
    _ = &EffectiveAddrY;
    cpu.*.cycles_executed +%= 1;
    return EffectiveAddrY;
}
pub export fn CPU_FetchByte(arg_cpu: ?*CPU) u8 {
    var cpu = arg_cpu;
    _ = &cpu;
    var Data: u8 = cpu.*.mem.*.Data[cpu.*.PC];
    _ = &Data;
    cpu.*.PC +%= 1;
    cpu.*.cycles_executed +%= 1;
    return Data;
}
pub export fn CPU_RegisterCompare(arg_cpu: ?*CPU, arg_Operand: u8, arg_RegisterValue: u8) void {
    var cpu = arg_cpu;
    _ = &cpu;
    var Operand = arg_Operand;
    _ = &Operand;
    var RegisterValue = arg_RegisterValue;
    _ = &RegisterValue;
    var Temp: u8 = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(c_uint, RegisterValue))) - @as(c_int, @bitCast(@as(c_uint, Operand)))))));
    _ = &Temp;
    cpu.*.unnamed_0.Flags.N = @as(u8, @intFromBool((@as(c_int, @bitCast(@as(c_uint, Temp))) & @as(c_int, @bitCast(@as(c_uint, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 128))))))))) > @as(c_int, 0)));
    cpu.*.unnamed_0.Flags.Z = @as(u8, @intFromBool(@as(c_int, @bitCast(@as(c_uint, RegisterValue))) == @as(c_int, @bitCast(@as(c_uint, Operand)))));
    cpu.*.unnamed_0.Flags.C = @as(u8, @intFromBool(@as(c_int, @bitCast(@as(c_uint, RegisterValue))) >= @as(c_int, @bitCast(@as(c_uint, Operand)))));
}
