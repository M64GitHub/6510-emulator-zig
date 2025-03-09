pub const CPU = struct {
    PC: u16,
    SP: u8,
    A: u8,
    X: u8,
    Y: u8,
    Status: u8,
    Flags: CPUFlags,
    mem: MEM64K,
    cycles_executed: u32,
    cycles_last_step: u32,
    opcode_last: u8,

    pub const MEM64K = struct {
        Data: [65536]u8,
    };

    const CPUFlags = struct {
        C: u8,
        Z: u8,
        I: u8,
        D: u8,
        B: u8,
        Unused: u8,
        V: u8,
        N: u8,
    };

    const FB_Negative = 0b10000000;
    const FB_Overflow = 0b01000000;
    const FB_Unused = 0b000100000;
    const FB_Break = 0b000010000;
    const FB_Decimal = 0b000001000;
    const FB_InterruptDisable = 0b000000100;
    const FB_Zero = 0b000000010;
    const FB_Carry = 0b000000001;

    pub fn Init(PC_init: u16) CPU {
        return CPU{
            .PC = PC_init,
            .SP = 0xFD,
            .A = 0,
            .X = 0,
            .Y = 0,
            .Status = 0x24, // Default status flags (Interrupt disable set)
            .Flags = CPUFlags{
                .C = 0,
                .Z = 0,
                .I = 1, // Interrupt Disable set on boot
                .D = 0,
                .B = 0,
                .Unused = 1, // Always 1 in 6502
                .V = 0,
                .N = 0,
            },
            .mem = MEM64K{ .Data = [_]u8{0} ** 65536 }, // Clear memory
            .cycles_executed = 0,
            .cycles_last_step = 0,
            .opcode_last = 0x00, // No opcode executed yet
        };
    }

    pub fn Reset(cpu: *CPU) void {
        // leaves memory unchanged
        cpu.A = 0;
        cpu.X = 0;
        cpu.Y = 0;
        cpu.SP = 0xFD;
        cpu.Status = 0x24;
        cpu.PC = 0xFFFC;
        cpu.Flags = CPUFlags{
            .C = 0,
            .Z = 0,
            .I = 1,
            .D = 0,
            .B = 0,
            .Unused = 1,
            .V = 0,
            .N = 0,
        };

        cpu.cycles_executed = 0;
        cpu.cycles_last_step = 0;
        cpu.opcode_last = 0x00;
    }

    fn CPU_FlagsToPS(cpu: *CPU) void {
        var ps: u8 = 0;
        if (cpu.Flags.Unused != 0) {
            ps |= FB_Unused;
        }
        if (cpu.Flags.C != 0) {
            ps |= FB_Carry;
        }
        if (cpu.Flags.Z != 0) {
            ps |= FB_Zero;
        }
        if (cpu.Flags.I != 0) {
            ps |= FB_InterruptDisable;
        }
        if (cpu.Flags.D != 0) {
            ps |= FB_Decimal;
        }
        if (cpu.Flags.B != 0) {
            ps |= FB_Break;
        }
        if (cpu.Flags.V != 0) {
            ps |= FB_Overflow;
        }
        if (cpu.Flags.N != 0) {
            ps |= FB_Negative;
        }
        cpu.Status = ps;
    }

    fn CPU_PSToFlags(cpu: *CPU) void {
        cpu.Flags.Unused = (cpu.Status & FB_Unused) != 0;
        cpu.Flags.C = (cpu.Status & FB_Carry) != 0;
        cpu.Flags.Z = (cpu.Status & FB_Zero) != 0;
        cpu.Flags.I = (cpu.Status & FB_InterruptDisable) != 0;
        cpu.Flags.D = (cpu.Status & FB_Decimal) != 0;
        cpu.Flags.B = (cpu.Status & FB_Break) != 0;
        cpu.Flags.V = (cpu.Status & FB_Overflow) != 0;
        cpu.Flags.N = (cpu.Status & FB_Negative) != 0;
    }

    fn CPU_FetchByte(cpu: *CPU) i8 {
        return @as(i8, @bitCast(CPU_FetchUByte(cpu)));
    }

    fn CPU_FetchUByte(cpu: *CPU) u8 {
        const Data: u8 = cpu.mem.Data[cpu.PC];
        cpu.PC +%= 1;
        cpu.cycles_executed +%= 1;
        return Data;
    }

    fn CPU_FetchWord(cpu: *CPU) u16 {
        var Data: u16 = cpu.mem.Data[cpu.PC];
        cpu.PC +%= 1;
        Data |= @as(u16, cpu.mem.Data[cpu.PC]) << 8;
        cpu.PC +%= 1;
        cpu.cycles_executed +%= 2;
        return Data;
    }

    fn CPU_ReadByte(cpu: *CPU, Address: u16) u8 {
        cpu.cycles_executed +%= 1;
        return cpu.mem.Data[Address];
    }

    fn CPU_ReadWord(cpu: *CPU, Address: u16) u16 {
        const LoByte: u8 = CPU_ReadByte(cpu, Address);
        const HiByte: u8 = CPU_ReadByte(cpu, Address + 1);
        cpu.cycles_executed +%= 2;
        return @as(u16, LoByte) | (@as(u16, HiByte) << 8);
    }

    fn CPU_WriteByte(cpu: *CPU, Value: u8, Address: u16) void {
        cpu.mem.Data[Address] = Value;
        cpu.cycles_executed +%= 1;
    }

    fn CPU_WriteWord(cpu: *CPU, Value: u16, Address: u16) void {
        cpu.mem.Data[Address] = @truncate(Value & 0xFF);
        cpu.mem.Data[Address + 1] = @truncate(Value >> 8);
        cpu.cycles_executed +%= 2;
    }

    fn CPU_SPToAddress(cpu: *CPU) u16 {
        return @as(u16, cpu.SP) | 0x100;
    }

    fn CPU_PushWordToStack(cpu: *CPU, Value: u16) void {
        CPU_WriteByte(cpu, @truncate(Value >> 8), CPU_SPToAddress(cpu));
        cpu.SP -%= 1;
        CPU_WriteByte(cpu, @truncate(Value & 0xff), CPU_SPToAddress(cpu));
        cpu.SP -%= 1;
    }

    fn CPU_PushPCToStack(cpu: *CPU) void {
        CPU_PushWordToStack(cpu, cpu.PC);
    }

    fn CPU_PushByteOntoStack(cpu: *CPU, Value: u8) void {
        const SPWord: u16 = CPU_SPToAddress(cpu);
        cpu.mem.Data[SPWord] = Value;
        cpu.cycles_executed +%= 1;
        cpu.SP -%= 1;
        cpu.cycles_executed +%= 1;
    }

    fn CPU_PopByteFromStack(cpu: *CPU) u8 {
        cpu.SP +%= 1;
        cpu.cycles_executed +%= 1;
        const SPWord: u16 = CPU_SPToAddress(cpu);
        const Value: u8 = cpu.mem.Data[SPWord];
        cpu.cycles_executed +%= 1;
        return Value;
    }

    fn CPU_PopWordFromStack(cpu: *CPU) u16 {
        const ValueFromStack: u16 = CPU_ReadWord(cpu, CPU_SPToAddress(cpu) + 1);
        cpu.SP +%= 2;
        cpu.cycles_executed +%= 1;
        return ValueFromStack;
    }

    fn CPU_UpdateFlags(cpu: *CPU, Register: u8) void {
        cpu.Flags.Z = (Register == 0);
        cpu.Flags.N = ((Register & FB_Negative) != 0);
    }

    fn CPU_LoadPrg(cpu: *CPU, Program: []const u8, NumBytes: u32) u16 {
        var LoadAddress: u16 = 0;
        if ((Program.len != 0) and (NumBytes > 2)) {
            var offs: u32 = 0;
            const Lo: u16 = Program[offs];
            offs += 1;
            const Hi: u16 = @as(u16, Program[offs]) << 8;
            offs += 1;
            LoadAddress = @as(u16, Lo) | @as(u16, Hi);

            var i: u16 = LoadAddress;
            while (i < (LoadAddress +% NumBytes -% 2)) : (i +%= 1) {
                cpu.mem.Data[i] = Program[offs];
                offs += 1;
            }
        }
        return LoadAddress;
    }

    // pub export fn CPU_LoadRegister(cpu: *CPU, Address: u16, Register: [*c]u8) void {
    //     var cpu = arg_cpu;
    //     _ = &cpu;
    //     var Address = Address;
    //     _ = &Address;
    //     var Register = Register;
    //     _ = &Register;
    //     Register = CPU_ReadByte(cpu, Address);
    //     CPU_UpdateFlags(cpu, Register);
    // }
    //
    // pub export fn CPU_And(cpu: *CPU, Address: u16) void {
    //     var cpu = arg_cpu;
    //     _ = &cpu;
    //     var Address = Address;
    //     _ = &Address;
    //     cpu.A &= @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(u32, CPU_ReadByte(cpu, Address))))))));
    //     CPU_UpdateFlags(cpu, cpu.A);
    // }
    //
    // pub export fn CPU_Ora(cpu: *CPU, Address: u16) void {
    //     var cpu = arg_cpu;
    //     _ = &cpu;
    //     var Address = Address;
    //     _ = &Address;
    //     cpu.A |= @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(u32, CPU_ReadByte(cpu, Address))))))));
    //     CPU_UpdateFlags(cpu, cpu.A);
    // }
    //
    // pub export fn CPU_Xor(cpu: *CPU, Address: u16) void {
    //     var cpu = arg_cpu;
    //     _ = &cpu;
    //     var Address = Address;
    //     _ = &Address;
    //     cpu.A ^= @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(u32, CPU_ReadByte(cpu, Address))))))));
    //     CPU_UpdateFlags(cpu, cpu.A);
    // }
    //
    // pub export fn CPU_Branch(cpu: *CPU, arg_Test: u8, arg_Expected: u8) void {
    //     var cpu = arg_cpu;
    //     _ = &cpu;
    //     var Test = arg_Test;
    //     _ = &Test;
    //     var Expected = arg_Expected;
    //     _ = &Expected;
    //     var Offset: u8 = CPU_FetchByte(cpu);
    //     _ = &Offset;
    //     if (@as(c_int, @bitCast(@as(u32, Test))) == @as(c_int, @bitCast(@as(u32, Expected)))) {
    //         const PCOld: u16 = cpu.PC;
    //         _ = &PCOld;
    //         cpu.PC +%= @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(u32, Offset)))))));
    //         cpu.cycles_executed +%= 1;
    //         var PageChanged: u8 = @as(u8, @intFromBool((@as(c_int, @bitCast(@as(u32, cpu.PC))) >> @intCast(8)) != (@as(c_int, @bitCast(@as(u32, PCOld))) >> @intCast(8))));
    //         _ = &PageChanged;
    //         if (PageChanged != 0) {
    //             cpu.cycles_executed +%= 1;
    //         }
    //     }
    // }
    //
    // pub export fn CPU_ADC(cpu: *CPU, arg_Operand: u8) void {
    //     var cpu = arg_cpu;
    //     _ = &cpu;
    //     var Operand = arg_Operand;
    //     _ = &Operand;
    //     var AreSignBitsTheSame: u8 = @as(u8, @intFromBool(!(((@as(c_int, @bitCast(@as(u32, cpu.A))) ^ @as(c_int, @bitCast(@as(u32, Operand)))) & @as(c_int, @bitCast(@as(u32, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 128))))))))) != 0)));
    //     _ = &AreSignBitsTheSame;
    //     var Sum: u16 = @as(u16, @bitCast(@as(u16, cpu.A)));
    //     _ = &Sum;
    //     Sum +%= @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(u32, Operand)))))));
    //     Sum +%= @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(u32, cpu.Flags.C)))))));
    //     cpu.A = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(u32, Sum))) & @as(c_int, 255)))));
    //     CPU_UpdateFlags(cpu, cpu.A);
    //     cpu.Flags.C = @as(u8, @intFromBool(@as(c_int, @bitCast(@as(u32, Sum))) > @as(c_int, 255)));
    //     cpu.Flags.V = @as(u8, @intFromBool((@as(c_int, @bitCast(@as(u32, AreSignBitsTheSame))) != 0) and (((@as(c_int, @bitCast(@as(u32, cpu.A))) ^ @as(c_int, @bitCast(@as(u32, Operand)))) & @as(c_int, @bitCast(@as(u32, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 128))))))))) != 0)));
    // }
    //
    // pub export fn CPU_SBC(cpu: *CPU, arg_Operand: u8) void {
    //     var cpu = arg_cpu;
    //     _ = &cpu;
    //     var Operand = arg_Operand;
    //     _ = &Operand;
    //     CPU_ADC(cpu, @as(u8, @bitCast(@as(i8, @truncate(~@as(c_int, @bitCast(@as(u32, Operand))))))));
    // }
    //
    // pub export fn CPU_ASL(cpu: *CPU, arg_Operand: u8) u8 {
    //     var cpu = arg_cpu;
    //     _ = &cpu;
    //     var Operand = arg_Operand;
    //     _ = &Operand;
    //     cpu.Flags.C = @as(u8, @intFromBool((@as(c_int, @bitCast(@as(u32, Operand))) & @as(c_int, @bitCast(@as(u32, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 128))))))))) > @as(c_int, 0)));
    //     var Result: u8 = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(u32, Operand))) << @intCast(1)))));
    //     _ = &Result;
    //     CPU_UpdateFlags(cpu, @as(u8, @bitCast(Result)));
    //     cpu.cycles_executed +%= 1;
    //     return Result;
    // }
    //
    // pub export fn CPU_LSR(cpu: *CPU, arg_Operand: u8) u8 {
    //     var cpu = arg_cpu;
    //     _ = &cpu;
    //     var Operand = arg_Operand;
    //     _ = &Operand;
    //     cpu.Flags.C = @as(u8, @intFromBool((@as(c_int, @bitCast(@as(u32, Operand))) & @as(c_int, @bitCast(@as(u32, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 2))))))))) > @as(c_int, 0)));
    //     var Result: u8 = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(u32, Operand))) >> @intCast(1)))));
    //     _ = &Result;
    //     CPU_UpdateFlags(cpu, @as(u8, @bitCast(Result)));
    //     cpu.cycles_executed +%= 1;
    //     return Result;
    // }
    //
    // pub export fn CPU_ROL(cpu: *CPU, arg_Operand: u8) u8 {
    //     var cpu = arg_cpu;
    //     _ = &cpu;
    //     var Operand = arg_Operand;
    //     _ = &Operand;
    //     var NewBit0: u8 = @as(u8, @bitCast(@as(i8, @truncate(if (@as(c_int, @bitCast(@as(u32, cpu.Flags.C))) != 0) @as(c_int, @bitCast(@as(u32, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 2)))))))) else @as(c_int, 0)))));
    //     _ = &NewBit0;
    //     cpu.Flags.C = @as(u8, @intFromBool((@as(c_int, @bitCast(@as(u32, Operand))) & @as(c_int, @bitCast(@as(u32, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 128))))))))) > @as(c_int, 0)));
    //     Operand = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(u32, Operand))) << @intCast(1)))));
    //     Operand |= @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(u32, NewBit0)))))));
    //     CPU_UpdateFlags(cpu, @as(u8, @bitCast(Operand)));
    //     cpu.cycles_executed +%= 1;
    //     return Operand;
    // }
    //
    // pub export fn CPU_ROR(cpu: *CPU, arg_Operand: u8) u8 {
    //     var cpu = arg_cpu;
    //     _ = &cpu;
    //     var Operand = arg_Operand;
    //     _ = &Operand;
    //     var OldBit0: u8 = @as(u8, @intFromBool((@as(c_int, @bitCast(@as(u32, Operand))) & @as(c_int, @bitCast(@as(u32, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 2))))))))) > @as(c_int, 0)));
    //     _ = &OldBit0;
    //     Operand = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(u32, Operand))) >> @intCast(1)))));
    //     if (cpu.Flags.C != 0) {
    //         Operand |= @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(u32, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 128))))))))))));
    //     }
    //     cpu.cycles_executed +%= 1;
    //     cpu.Flags.C = @as(u8, @bitCast(OldBit0));
    //     CPU_UpdateFlags(cpu, @as(u8, @bitCast(Operand)));
    //     return Operand;
    // }
    //
    // pub export fn CPU_PushPSToStack(cpu: *CPU) void {
    //     var cpu = arg_cpu;
    //     _ = &cpu;
    //     CPU_FlagsToPS(cpu);
    //     var PSStack: u8 = @as(u8, @bitCast(@as(i8, @truncate((@as(c_int, @bitCast(@as(u32, cpu.Status))) | @as(c_int, @bitCast(@as(u32, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 16))))))))) | @as(c_int, @bitCast(@as(u32, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 32))))))))))));
    //     _ = &PSStack;
    //     CPU_PushByteOntoStack(cpu, @as(u8, @bitCast(PSStack)));
    // }
    //
    // pub export fn CPU_PopPSFromStack(cpu: *CPU) void {
    //     var cpu = arg_cpu;
    //     _ = &cpu;
    //     cpu.Status = @as(u8, @bitCast(CPU_PopByteFromStack(cpu)));
    //     CPU_PSToFlags(cpu);
    //     cpu.Flags.B = 0;
    //     cpu.Flags.Unused = 0;
    // }
    //
    // pub export fn CPU_Run_Step(cpu: *CPU) u8 {
    //     var cpu = arg_cpu;
    //     _ = &cpu;
    //     var cycles_now: u32 = cpu.cycles_executed;
    //     _ = &cycles_now;
    //     var opcode: u8 = CPU_FetchUByte(cpu);
    //     _ = &opcode;
    //     cpu.opcode_last = opcode;
    //     while (true) {
    //         switch (@as(c_int, @bitCast(@as(u32, opcode)))) {
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 41)))) => {
    //                 cpu.A &= @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(u32, CPU_FetchUByte(cpu))))))));
    //                 CPU_UpdateFlags(cpu, cpu.A);
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 9)))) => {
    //                 cpu.A |= @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(u32, CPU_FetchUByte(cpu))))))));
    //                 CPU_UpdateFlags(cpu, cpu.A);
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 73)))) => {
    //                 cpu.A ^= @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(u32, CPU_FetchUByte(cpu))))))));
    //                 CPU_UpdateFlags(cpu, cpu.A);
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 37)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPage(cpu);
    //                     _ = &Address;
    //                     CPU_And(cpu, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 5)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPage(cpu);
    //                     _ = &Address;
    //                     CPU_Ora(cpu, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 69)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPage(cpu);
    //                     _ = &Address;
    //                     CPU_Xor(cpu, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 53)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPageX(cpu);
    //                     _ = &Address;
    //                     CPU_And(cpu, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 21)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPageX(cpu);
    //                     _ = &Address;
    //                     CPU_Ora(cpu, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 85)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPageX(cpu);
    //                     _ = &Address;
    //                     CPU_Xor(cpu, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 45)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsolute(cpu);
    //                     _ = &Address;
    //                     CPU_And(cpu, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 13)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsolute(cpu);
    //                     _ = &Address;
    //                     CPU_Ora(cpu, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 77)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsolute(cpu);
    //                     _ = &Address;
    //                     CPU_Xor(cpu, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 61)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsoluteX(cpu);
    //                     _ = &Address;
    //                     CPU_And(cpu, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 29)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsoluteX(cpu);
    //                     _ = &Address;
    //                     CPU_Ora(cpu, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 93)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsoluteX(cpu);
    //                     _ = &Address;
    //                     CPU_Xor(cpu, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 57)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsoluteY(cpu);
    //                     _ = &Address;
    //                     CPU_And(cpu, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 25)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsoluteY(cpu);
    //                     _ = &Address;
    //                     CPU_Ora(cpu, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 89)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsoluteY(cpu);
    //                     _ = &Address;
    //                     CPU_Xor(cpu, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 33)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrIndirectX(cpu);
    //                     _ = &Address;
    //                     CPU_And(cpu, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 1)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrIndirectX(cpu);
    //                     _ = &Address;
    //                     CPU_Ora(cpu, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 65)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrIndirectX(cpu);
    //                     _ = &Address;
    //                     CPU_Xor(cpu, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 49)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrIndirectY(cpu);
    //                     _ = &Address;
    //                     CPU_And(cpu, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 17)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrIndirectY(cpu);
    //                     _ = &Address;
    //                     CPU_Ora(cpu, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 81)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrIndirectY(cpu);
    //                     _ = &Address;
    //                     CPU_Xor(cpu, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 36)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPage(cpu);
    //                     _ = &Address;
    //                     var Value: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Value;
    //                     cpu.Flags.Z = @as(u8, @intFromBool(!((@as(c_int, @bitCast(@as(u32, cpu.A))) & @as(c_int, @bitCast(@as(u32, Value)))) != 0)));
    //                     cpu.Flags.N = @as(u8, @intFromBool((@as(c_int, @bitCast(@as(u32, Value))) & @as(c_int, @bitCast(@as(u32, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 128))))))))) != @as(c_int, 0)));
    //                     cpu.Flags.V = @as(u8, @intFromBool((@as(c_int, @bitCast(@as(u32, Value))) & @as(c_int, @bitCast(@as(u32, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 64))))))))) != @as(c_int, 0)));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 44)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsolute(cpu);
    //                     _ = &Address;
    //                     var Value: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Value;
    //                     cpu.Flags.Z = @as(u8, @intFromBool(!((@as(c_int, @bitCast(@as(u32, cpu.A))) & @as(c_int, @bitCast(@as(u32, Value)))) != 0)));
    //                     cpu.Flags.N = @as(u8, @intFromBool((@as(c_int, @bitCast(@as(u32, Value))) & @as(c_int, @bitCast(@as(u32, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 128))))))))) != @as(c_int, 0)));
    //                     cpu.Flags.V = @as(u8, @intFromBool((@as(c_int, @bitCast(@as(u32, Value))) & @as(c_int, @bitCast(@as(u32, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 64))))))))) != @as(c_int, 0)));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 169)))) => {
    //                 {
    //                     cpu.A = CPU_FetchUByte(cpu);
    //                     CPU_UpdateFlags(cpu, cpu.A);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 162)))) => {
    //                 {
    //                     cpu.X = CPU_FetchUByte(cpu);
    //                     CPU_UpdateFlags(cpu, cpu.X);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 160)))) => {
    //                 {
    //                     cpu.Y = CPU_FetchUByte(cpu);
    //                     CPU_UpdateFlags(cpu, cpu.Y);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 165)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPage(cpu);
    //                     _ = &Address;
    //                     CPU_LoadRegister(cpu, Address, &cpu.A);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 166)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPage(cpu);
    //                     _ = &Address;
    //                     CPU_LoadRegister(cpu, Address, &cpu.X);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 182)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPageY(cpu);
    //                     _ = &Address;
    //                     CPU_LoadRegister(cpu, Address, &cpu.X);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 164)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPage(cpu);
    //                     _ = &Address;
    //                     CPU_LoadRegister(cpu, Address, &cpu.Y);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 181)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPageX(cpu);
    //                     _ = &Address;
    //                     CPU_LoadRegister(cpu, Address, &cpu.A);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 180)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPageX(cpu);
    //                     _ = &Address;
    //                     CPU_LoadRegister(cpu, Address, &cpu.Y);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 173)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsolute(cpu);
    //                     _ = &Address;
    //                     CPU_LoadRegister(cpu, Address, &cpu.A);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 174)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsolute(cpu);
    //                     _ = &Address;
    //                     CPU_LoadRegister(cpu, Address, &cpu.X);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 172)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsolute(cpu);
    //                     _ = &Address;
    //                     CPU_LoadRegister(cpu, Address, &cpu.Y);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 189)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsoluteX(cpu);
    //                     _ = &Address;
    //                     CPU_LoadRegister(cpu, Address, &cpu.A);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 188)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsoluteX(cpu);
    //                     _ = &Address;
    //                     CPU_LoadRegister(cpu, Address, &cpu.Y);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 185)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsoluteY(cpu);
    //                     _ = &Address;
    //                     CPU_LoadRegister(cpu, Address, &cpu.A);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 190)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsoluteY(cpu);
    //                     _ = &Address;
    //                     CPU_LoadRegister(cpu, Address, &cpu.X);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 161)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrIndirectX(cpu);
    //                     _ = &Address;
    //                     CPU_LoadRegister(cpu, Address, &cpu.A);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 129)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrIndirectX(cpu);
    //                     _ = &Address;
    //                     CPU_WriteByte(cpu, cpu.A, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 177)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrIndirectY(cpu);
    //                     _ = &Address;
    //                     CPU_LoadRegister(cpu, Address, &cpu.A);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 145)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrIndirectY_6(cpu);
    //                     _ = &Address;
    //                     CPU_WriteByte(cpu, cpu.A, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 133)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPage(cpu);
    //                     _ = &Address;
    //                     CPU_WriteByte(cpu, cpu.A, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 134)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPage(cpu);
    //                     _ = &Address;
    //                     CPU_WriteByte(cpu, cpu.X, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 150)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPageY(cpu);
    //                     _ = &Address;
    //                     CPU_WriteByte(cpu, cpu.X, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 132)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPage(cpu);
    //                     _ = &Address;
    //                     CPU_WriteByte(cpu, cpu.Y, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 141)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsolute(cpu);
    //                     _ = &Address;
    //                     CPU_WriteByte(cpu, cpu.A, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 142)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsolute(cpu);
    //                     _ = &Address;
    //                     CPU_WriteByte(cpu, cpu.X, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 140)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsolute(cpu);
    //                     _ = &Address;
    //                     CPU_WriteByte(cpu, cpu.Y, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 149)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPageX(cpu);
    //                     _ = &Address;
    //                     CPU_WriteByte(cpu, cpu.A, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 148)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPageX(cpu);
    //                     _ = &Address;
    //                     CPU_WriteByte(cpu, cpu.Y, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 157)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsoluteX_5(cpu);
    //                     _ = &Address;
    //                     CPU_WriteByte(cpu, cpu.A, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 153)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsoluteY_5(cpu);
    //                     _ = &Address;
    //                     CPU_WriteByte(cpu, cpu.A, Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 32)))) => {
    //                 {
    //                     var SubAddr: u16 = CPU_FetchWord(cpu);
    //                     _ = &SubAddr;
    //                     CPU_PushWordToStack(cpu, @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(u32, cpu.PC))) - @as(c_int, 1))))));
    //                     cpu.PC = SubAddr;
    //                     cpu.cycles_executed +%= 1;
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 96)))) => {
    //                 {
    //                     var ReturnAddress: u16 = CPU_PopWordFromStack(cpu);
    //                     _ = &ReturnAddress;
    //                     cpu.PC = @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(u32, ReturnAddress))) + @as(c_int, 1)))));
    //                     cpu.cycles_executed +%= @as(u32, @bitCast(@as(c_int, 2)));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 76)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsolute(cpu);
    //                     _ = &Address;
    //                     cpu.PC = Address;
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 108)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsolute(cpu);
    //                     _ = &Address;
    //                     Address = CPU_ReadWord(cpu, Address);
    //                     cpu.PC = Address;
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 186)))) => {
    //                 {
    //                     cpu.X = cpu.SP;
    //                     cpu.cycles_executed +%= 1;
    //                     CPU_UpdateFlags(cpu, cpu.X);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 154)))) => {
    //                 {
    //                     cpu.SP = cpu.X;
    //                     cpu.cycles_executed +%= 1;
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 72)))) => {
    //                 {
    //                     CPU_PushByteOntoStack(cpu, cpu.A);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 104)))) => {
    //                 {
    //                     cpu.A = CPU_PopByteFromStack(cpu);
    //                     CPU_UpdateFlags(cpu, cpu.A);
    //                     cpu.cycles_executed +%= 1;
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 8)))) => {
    //                 {
    //                     CPU_PushPSToStack(cpu);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 40)))) => {
    //                 {
    //                     CPU_PopPSFromStack(cpu);
    //                     cpu.cycles_executed +%= 1;
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 170)))) => {
    //                 {
    //                     cpu.X = cpu.A;
    //                     cpu.cycles_executed +%= 1;
    //                     CPU_UpdateFlags(cpu, cpu.X);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 168)))) => {
    //                 {
    //                     cpu.Y = cpu.A;
    //                     cpu.cycles_executed +%= 1;
    //                     CPU_UpdateFlags(cpu, cpu.Y);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 138)))) => {
    //                 {
    //                     cpu.A = cpu.X;
    //                     cpu.cycles_executed +%= 1;
    //                     CPU_UpdateFlags(cpu, cpu.A);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 152)))) => {
    //                 {
    //                     cpu.A = cpu.Y;
    //                     cpu.cycles_executed +%= 1;
    //                     CPU_UpdateFlags(cpu, cpu.A);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 232)))) => {
    //                 {
    //                     cpu.X +%= 1;
    //                     cpu.cycles_executed +%= 1;
    //                     CPU_UpdateFlags(cpu, cpu.X);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 200)))) => {
    //                 {
    //                     cpu.Y +%= 1;
    //                     cpu.cycles_executed +%= 1;
    //                     CPU_UpdateFlags(cpu, cpu.Y);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 202)))) => {
    //                 {
    //                     cpu.X -%= 1;
    //                     cpu.cycles_executed +%= 1;
    //                     CPU_UpdateFlags(cpu, cpu.X);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 136)))) => {
    //                 {
    //                     cpu.Y -%= 1;
    //                     cpu.cycles_executed +%= 1;
    //                     CPU_UpdateFlags(cpu, cpu.Y);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 198)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPage(cpu);
    //                     _ = &Address;
    //                     var Value: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Value;
    //                     Value -%= 1;
    //                     cpu.cycles_executed +%= 1;
    //                     CPU_WriteByte(cpu, @as(u8, @bitCast(Value)), Address);
    //                     CPU_UpdateFlags(cpu, @as(u8, @bitCast(Value)));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 214)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPageX(cpu);
    //                     _ = &Address;
    //                     var Value: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Value;
    //                     Value -%= 1;
    //                     cpu.cycles_executed +%= 1;
    //                     CPU_WriteByte(cpu, @as(u8, @bitCast(Value)), Address);
    //                     CPU_UpdateFlags(cpu, @as(u8, @bitCast(Value)));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 206)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsolute(cpu);
    //                     _ = &Address;
    //                     var Value: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Value;
    //                     Value -%= 1;
    //                     cpu.cycles_executed +%= 1;
    //                     CPU_WriteByte(cpu, @as(u8, @bitCast(Value)), Address);
    //                     CPU_UpdateFlags(cpu, @as(u8, @bitCast(Value)));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 222)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsoluteX_5(cpu);
    //                     _ = &Address;
    //                     var Value: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Value;
    //                     Value -%= 1;
    //                     cpu.cycles_executed +%= 1;
    //                     CPU_WriteByte(cpu, @as(u8, @bitCast(Value)), Address);
    //                     CPU_UpdateFlags(cpu, @as(u8, @bitCast(Value)));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 230)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPage(cpu);
    //                     _ = &Address;
    //                     var Value: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Value;
    //                     Value +%= 1;
    //                     cpu.cycles_executed +%= 1;
    //                     CPU_WriteByte(cpu, @as(u8, @bitCast(Value)), Address);
    //                     CPU_UpdateFlags(cpu, @as(u8, @bitCast(Value)));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 246)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPageX(cpu);
    //                     _ = &Address;
    //                     var Value: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Value;
    //                     Value +%= 1;
    //                     cpu.cycles_executed +%= 1;
    //                     CPU_WriteByte(cpu, @as(u8, @bitCast(Value)), Address);
    //                     CPU_UpdateFlags(cpu, @as(u8, @bitCast(Value)));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 238)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsolute(cpu);
    //                     _ = &Address;
    //                     var Value: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Value;
    //                     Value +%= 1;
    //                     cpu.cycles_executed +%= 1;
    //                     CPU_WriteByte(cpu, @as(u8, @bitCast(Value)), Address);
    //                     CPU_UpdateFlags(cpu, @as(u8, @bitCast(Value)));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 254)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsoluteX_5(cpu);
    //                     _ = &Address;
    //                     var Value: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Value;
    //                     Value +%= 1;
    //                     cpu.cycles_executed +%= 1;
    //                     CPU_WriteByte(cpu, @as(u8, @bitCast(Value)), Address);
    //                     CPU_UpdateFlags(cpu, @as(u8, @bitCast(Value)));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 240)))) => {
    //                 {
    //                     CPU_Branch(cpu, @as(u8, @bitCast(cpu.Flags.Z)), @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 1))))));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 208)))) => {
    //                 {
    //                     CPU_Branch(cpu, @as(u8, @bitCast(cpu.Flags.Z)), @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 176)))) => {
    //                 {
    //                     CPU_Branch(cpu, @as(u8, @bitCast(cpu.Flags.C)), @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 1))))));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 144)))) => {
    //                 {
    //                     CPU_Branch(cpu, @as(u8, @bitCast(cpu.Flags.C)), @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 48)))) => {
    //                 {
    //                     CPU_Branch(cpu, @as(u8, @bitCast(cpu.Flags.N)), @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 1))))));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 16)))) => {
    //                 {
    //                     CPU_Branch(cpu, @as(u8, @bitCast(cpu.Flags.N)), @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 80)))) => {
    //                 {
    //                     CPU_Branch(cpu, @as(u8, @bitCast(cpu.Flags.V)), @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 0))))));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 112)))) => {
    //                 {
    //                     CPU_Branch(cpu, @as(u8, @bitCast(cpu.Flags.V)), @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 1))))));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 24)))) => {
    //                 {
    //                     cpu.Flags.C = 0;
    //                     cpu.cycles_executed +%= 1;
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 56)))) => {
    //                 {
    //                     cpu.Flags.C = 1;
    //                     cpu.cycles_executed +%= 1;
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 216)))) => {
    //                 {
    //                     cpu.Flags.D = 0;
    //                     cpu.cycles_executed +%= 1;
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 248)))) => {
    //                 {
    //                     cpu.Flags.D = 1;
    //                     cpu.cycles_executed +%= 1;
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 88)))) => {
    //                 {
    //                     cpu.Flags.I = 0;
    //                     cpu.cycles_executed +%= 1;
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 120)))) => {
    //                 {
    //                     cpu.Flags.I = 1;
    //                     cpu.cycles_executed +%= 1;
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 184)))) => {
    //                 {
    //                     cpu.Flags.V = 0;
    //                     cpu.cycles_executed +%= 1;
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 234)))) => {
    //                 {
    //                     cpu.cycles_executed +%= 1;
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 109)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsolute(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     CPU_ADC(cpu, Operand);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 125)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsoluteX(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     CPU_ADC(cpu, Operand);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 121)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsoluteY(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     CPU_ADC(cpu, Operand);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 101)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPage(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     CPU_ADC(cpu, Operand);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 117)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPageX(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     CPU_ADC(cpu, Operand);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 97)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrIndirectX(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     CPU_ADC(cpu, Operand);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 113)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrIndirectY(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     CPU_ADC(cpu, Operand);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 105)))) => {
    //                 {
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_FetchUByte(cpu)));
    //                     _ = &Operand;
    //                     CPU_ADC(cpu, Operand);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 233)))) => {
    //                 {
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_FetchUByte(cpu)));
    //                     _ = &Operand;
    //                     CPU_SBC(cpu, Operand);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 237)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsolute(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     CPU_SBC(cpu, Operand);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 229)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPage(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     CPU_SBC(cpu, Operand);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 245)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPageX(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     CPU_SBC(cpu, Operand);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 253)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsoluteX(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     CPU_SBC(cpu, Operand);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 249)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsoluteY(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     CPU_SBC(cpu, Operand);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 225)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrIndirectX(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     CPU_SBC(cpu, Operand);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 241)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrIndirectY(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     CPU_SBC(cpu, Operand);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 224)))) => {
    //                 {
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_FetchUByte(cpu)));
    //                     _ = &Operand;
    //                     CPU_RegisterCompare(cpu, Operand, @as(u8, @bitCast(cpu.X)));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 192)))) => {
    //                 {
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_FetchUByte(cpu)));
    //                     _ = &Operand;
    //                     CPU_RegisterCompare(cpu, Operand, @as(u8, @bitCast(cpu.Y)));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 228)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPage(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     CPU_RegisterCompare(cpu, Operand, @as(u8, @bitCast(cpu.X)));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 196)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPage(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     CPU_RegisterCompare(cpu, Operand, @as(u8, @bitCast(cpu.Y)));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 236)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsolute(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     CPU_RegisterCompare(cpu, Operand, @as(u8, @bitCast(cpu.X)));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 204)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsolute(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     CPU_RegisterCompare(cpu, Operand, @as(u8, @bitCast(cpu.Y)));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 201)))) => {
    //                 {
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_FetchUByte(cpu)));
    //                     _ = &Operand;
    //                     CPU_RegisterCompare(cpu, Operand, @as(u8, @bitCast(cpu.A)));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 197)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPage(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     CPU_RegisterCompare(cpu, Operand, @as(u8, @bitCast(cpu.A)));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 213)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPageX(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     CPU_RegisterCompare(cpu, Operand, @as(u8, @bitCast(cpu.A)));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 205)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsolute(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     CPU_RegisterCompare(cpu, Operand, @as(u8, @bitCast(cpu.A)));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 221)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsoluteX(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     CPU_RegisterCompare(cpu, Operand, @as(u8, @bitCast(cpu.A)));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 217)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsoluteY(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     CPU_RegisterCompare(cpu, Operand, @as(u8, @bitCast(cpu.A)));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 193)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrIndirectX(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     CPU_RegisterCompare(cpu, Operand, @as(u8, @bitCast(cpu.A)));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 209)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrIndirectY(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     CPU_RegisterCompare(cpu, Operand, @as(u8, @bitCast(cpu.A)));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 10)))) => {
    //                 {
    //                     cpu.A = @as(u8, @bitCast(CPU_ASL(cpu, @as(u8, @bitCast(cpu.A)))));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 6)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPage(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     var Result: u8 = CPU_ASL(cpu, Operand);
    //                     _ = &Result;
    //                     CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 22)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPageX(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     var Result: u8 = CPU_ASL(cpu, Operand);
    //                     _ = &Result;
    //                     CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 14)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsolute(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     var Result: u8 = CPU_ASL(cpu, Operand);
    //                     _ = &Result;
    //                     CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 30)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsoluteX_5(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     var Result: u8 = CPU_ASL(cpu, Operand);
    //                     _ = &Result;
    //                     CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 74)))) => {
    //                 {
    //                     cpu.A = @as(u8, @bitCast(CPU_LSR(cpu, @as(u8, @bitCast(cpu.A)))));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 70)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPage(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     var Result: u8 = CPU_LSR(cpu, Operand);
    //                     _ = &Result;
    //                     CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 86)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPageX(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     var Result: u8 = CPU_LSR(cpu, Operand);
    //                     _ = &Result;
    //                     CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 78)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsolute(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     var Result: u8 = CPU_LSR(cpu, Operand);
    //                     _ = &Result;
    //                     CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 94)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsoluteX_5(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     var Result: u8 = CPU_LSR(cpu, Operand);
    //                     _ = &Result;
    //                     CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 42)))) => {
    //                 {
    //                     cpu.A = @as(u8, @bitCast(CPU_ROL(cpu, @as(u8, @bitCast(cpu.A)))));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 38)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPage(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     var Result: u8 = CPU_ROL(cpu, Operand);
    //                     _ = &Result;
    //                     CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 54)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPageX(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     var Result: u8 = CPU_ROL(cpu, Operand);
    //                     _ = &Result;
    //                     CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 46)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsolute(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     var Result: u8 = CPU_ROL(cpu, Operand);
    //                     _ = &Result;
    //                     CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 62)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsoluteX_5(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     var Result: u8 = CPU_ROL(cpu, Operand);
    //                     _ = &Result;
    //                     CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 106)))) => {
    //                 {
    //                     cpu.A = @as(u8, @bitCast(CPU_ROR(cpu, @as(u8, @bitCast(cpu.A)))));
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 102)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPage(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     var Result: u8 = CPU_ROR(cpu, Operand);
    //                     _ = &Result;
    //                     CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 118)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrZeroPageX(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     var Result: u8 = CPU_ROR(cpu, Operand);
    //                     _ = &Result;
    //                     CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 110)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsolute(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     var Result: u8 = CPU_ROR(cpu, Operand);
    //                     _ = &Result;
    //                     CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 126)))) => {
    //                 {
    //                     var Address: u16 = CPU_AddrAbsoluteX_5(cpu);
    //                     _ = &Address;
    //                     var Operand: u8 = @as(u8, @bitCast(CPU_ReadByte(cpu, Address)));
    //                     _ = &Operand;
    //                     var Result: u8 = CPU_ROR(cpu, Operand);
    //                     _ = &Result;
    //                     CPU_WriteByte(cpu, @as(u8, @bitCast(Result)), Address);
    //                 }
    //                 break;
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 0)))) => {
    //                 {
    //                     CPU_PushWordToStack(cpu, @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(u32, cpu.PC))) + @as(c_int, 1))))));
    //                     CPU_PushPSToStack(cpu);
    //                     cpu.PC = CPU_ReadWord(cpu, @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, 65534))))));
    //                     cpu.Flags.B = 1;
    //                     cpu.Flags.I = 1;
    //                     return 0;
    //                 }
    //             },
    //             @as(c_int, @bitCast(@as(u32, @as(u8, 64)))) => {
    //                 {
    //                     CPU_PopPSFromStack(cpu);
    //                     cpu.PC = CPU_PopWordFromStack(cpu);
    //                 }
    //                 break;
    //             },
    //             else => return 0,
    //         }
    //         break;
    //     }
    //     cpu.cycles_last_step = cpu.cycles_executed -% cycles_now;
    //     return @as(u8, @bitCast(@as(u8, @truncate(cpu.cycles_last_step))));
    // }
    //
    // pub export fn CPU_AddrZeroPage(cpu: *CPU) u16 {
    //     var cpu = arg_cpu;
    //     _ = &cpu;
    //     var ZeroPageAddr: u8 = @as(u8, @bitCast(CPU_FetchUByte(cpu)));
    //     _ = &ZeroPageAddr;
    //     return @as(u16, @bitCast(@as(u16, ZeroPageAddr)));
    // }
    //
    // pub export fn CPU_AddrZeroPageX(cpu: *CPU) u16 {
    //     var cpu = arg_cpu;
    //     _ = &cpu;
    //     var ZeroPageAddr: u8 = @as(u8, @bitCast(CPU_FetchUByte(cpu)));
    //     _ = &ZeroPageAddr;
    //     ZeroPageAddr +%= @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(u32, cpu.X)))))));
    //     cpu.cycles_executed +%= 1;
    //     return @as(u16, @bitCast(@as(u16, ZeroPageAddr)));
    // }
    //
    // pub export fn CPU_AddrZeroPageY(cpu: *CPU) u16 {
    //     var cpu = arg_cpu;
    //     _ = &cpu;
    //     var ZeroPageAddr: u8 = @as(u8, @bitCast(CPU_FetchUByte(cpu)));
    //     _ = &ZeroPageAddr;
    //     ZeroPageAddr +%= @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(u32, cpu.Y)))))));
    //     cpu.cycles_executed +%= 1;
    //     return @as(u16, @bitCast(@as(u16, ZeroPageAddr)));
    // }
    //
    // pub export fn CPU_AddrAbsolute(cpu: *CPU) u16 {
    //     var cpu = arg_cpu;
    //     _ = &cpu;
    //     var AbsAddress: u16 = CPU_FetchWord(cpu);
    //     _ = &AbsAddress;
    //     return AbsAddress;
    // }
    //
    // pub export fn CPU_AddrAbsoluteX(cpu: *CPU) u16 {
    //     var cpu = arg_cpu;
    //     _ = &cpu;
    //     var AbsAddress: u16 = CPU_FetchWord(cpu);
    //     _ = &AbsAddress;
    //     var AbsAddressX: u16 = @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(u32, AbsAddress))) + @as(c_int, @bitCast(@as(u32, cpu.X)))))));
    //     _ = &AbsAddressX;
    //     var CrossedPageBoundary: u8 = @as(u8, @bitCast(@as(i8, @truncate((@as(c_int, @bitCast(@as(u32, AbsAddress))) ^ @as(c_int, @bitCast(@as(u32, AbsAddressX)))) >> @intCast(8)))));
    //     _ = &CrossedPageBoundary;
    //     if (CrossedPageBoundary != 0) {
    //         cpu.cycles_executed +%= 1;
    //     }
    //     return AbsAddressX;
    // }
    //
    // pub export fn CPU_AddrAbsoluteX_5(cpu: *CPU) u16 {
    //     var cpu = arg_cpu;
    //     _ = &cpu;
    //     var AbsAddress: u16 = CPU_FetchWord(cpu);
    //     _ = &AbsAddress;
    //     var AbsAddressX: u16 = @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(u32, AbsAddress))) + @as(c_int, @bitCast(@as(u32, cpu.X)))))));
    //     _ = &AbsAddressX;
    //     cpu.cycles_executed +%= 1;
    //     return AbsAddressX;
    // }
    //
    // pub export fn CPU_AddrAbsoluteY(cpu: *CPU) u16 {
    //     var cpu = arg_cpu;
    //     _ = &cpu;
    //     var AbsAddress: u16 = CPU_FetchWord(cpu);
    //     _ = &AbsAddress;
    //     var AbsAddressY: u16 = @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(u32, AbsAddress))) + @as(c_int, @bitCast(@as(u32, cpu.Y)))))));
    //     _ = &AbsAddressY;
    //     var CrossedPageBoundary: u8 = @as(u8, @bitCast(@as(i8, @truncate((@as(c_int, @bitCast(@as(u32, AbsAddress))) ^ @as(c_int, @bitCast(@as(u32, AbsAddressY)))) >> @intCast(8)))));
    //     _ = &CrossedPageBoundary;
    //     if (CrossedPageBoundary != 0) {
    //         cpu.cycles_executed +%= 1;
    //     }
    //     return AbsAddressY;
    // }
    //
    // pub export fn CPU_AddrAbsoluteY_5(cpu: *CPU) u16 {
    //     var cpu = arg_cpu;
    //     _ = &cpu;
    //     var AbsAddress: u16 = CPU_FetchWord(cpu);
    //     _ = &AbsAddress;
    //     var AbsAddressY: u16 = @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(u32, AbsAddress))) + @as(c_int, @bitCast(@as(u32, cpu.Y)))))));
    //     _ = &AbsAddressY;
    //     cpu.cycles_executed +%= 1;
    //     return AbsAddressY;
    // }
    //
    // pub export fn CPU_AddrIndirectX(cpu: *CPU) u16 {
    //     var cpu = arg_cpu;
    //     _ = &cpu;
    //     var ZPAddress: u8 = @as(u8, @bitCast(CPU_FetchUByte(cpu)));
    //     _ = &ZPAddress;
    //     ZPAddress +%= @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(u32, cpu.X)))))));
    //     cpu.cycles_executed +%= 1;
    //     var EffectiveAddr: u16 = CPU_ReadWord(cpu, @as(u16, @bitCast(@as(u16, ZPAddress))));
    //     _ = &EffectiveAddr;
    //     return EffectiveAddr;
    // }
    //
    // pub export fn CPU_AddrIndirectY(cpu: *CPU) u16 {
    //     var cpu = arg_cpu;
    //     _ = &cpu;
    //     var ZPAddress: u8 = @as(u8, @bitCast(CPU_FetchUByte(cpu)));
    //     _ = &ZPAddress;
    //     var EffectiveAddr: u16 = CPU_ReadWord(cpu, @as(u16, @bitCast(@as(u16, ZPAddress))));
    //     _ = &EffectiveAddr;
    //     var EffectiveAddrY: u16 = @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(u32, EffectiveAddr))) + @as(c_int, @bitCast(@as(u32, cpu.Y)))))));
    //     _ = &EffectiveAddrY;
    //     var CrossedPageBoundary: u8 = @as(u8, @bitCast(@as(i8, @truncate((@as(c_int, @bitCast(@as(u32, EffectiveAddr))) ^ @as(c_int, @bitCast(@as(u32, EffectiveAddrY)))) >> @intCast(8)))));
    //     _ = &CrossedPageBoundary;
    //     if (CrossedPageBoundary != 0) {
    //         cpu.cycles_executed +%= 1;
    //     }
    //     return EffectiveAddrY;
    // }
    //
    // pub export fn CPU_AddrIndirectY_6(cpu: *CPU) u16 {
    //     var cpu = arg_cpu;
    //     _ = &cpu;
    //     var ZPAddress: u8 = @as(u8, @bitCast(CPU_FetchUByte(cpu)));
    //     _ = &ZPAddress;
    //     var EffectiveAddr: u16 = CPU_ReadWord(cpu, @as(u16, @bitCast(@as(u16, ZPAddress))));
    //     _ = &EffectiveAddr;
    //     var EffectiveAddrY: u16 = @as(u16, @bitCast(@as(c_short, @truncate(@as(c_int, @bitCast(@as(u32, EffectiveAddr))) + @as(c_int, @bitCast(@as(u32, cpu.Y)))))));
    //     _ = &EffectiveAddrY;
    //     cpu.cycles_executed +%= 1;
    //     return EffectiveAddrY;
    // }
    //
    // pub export fn CPU_RegisterCompare(cpu: *CPU, arg_Operand: u8, RegisterValue: u8) void {
    //     var cpu = arg_cpu;
    //     _ = &cpu;
    //     var Operand = arg_Operand;
    //     _ = &Operand;
    //     var RegisterValue = RegisterValue;
    //     _ = &RegisterValue;
    //     var Temp: u8 = @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, @bitCast(@as(u32, RegisterValue))) - @as(c_int, @bitCast(@as(u32, Operand)))))));
    //     _ = &Temp;
    //     cpu.Flags.N = @as(u8, @intFromBool((@as(c_int, @bitCast(@as(u32, Temp))) & @as(c_int, @bitCast(@as(u32, @as(u8, @bitCast(@as(i8, @truncate(@as(c_int, 128))))))))) > @as(c_int, 0)));
    //     cpu.Flags.Z = @as(u8, @intFromBool(@as(c_int, @bitCast(@as(u32, RegisterValue))) == @as(c_int, @bitCast(@as(u32, Operand)))));
    //     cpu.Flags.C = @as(u8, @intFromBool(@as(c_int, @bitCast(@as(u32, RegisterValue))) >= @as(c_int, @bitCast(@as(u32, Operand)))));
    // }
};
