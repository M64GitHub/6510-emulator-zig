const std = @import("std");
const CPU = @import("6510.zig").CPU;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("Initializing CPU\n", .{});
    var cpu = CPU.Init(0x800);
    cpu.CPU_PrintStatus();

    try stdout.print("Writing Program ...\n", .{});
    cpu.CPU_WriteByte(0xa9, 0x0800); //         LDA
    cpu.CPU_WriteByte(0x0a, 0x0801); //             #0A     ; 10
    cpu.CPU_WriteByte(0xaa, 0x0802); //         TAX
    cpu.CPU_WriteByte(0xe8, 0x0803); // LOOP:   INX
    cpu.CPU_WriteByte(0xe0, 0x0804); //         CPX
    cpu.CPU_WriteByte(0x14, 0x0805); //             #$14    ; 20
    cpu.CPU_WriteByte(0xd0, 0x0806); //         BNE
    cpu.CPU_WriteByte(0xfb, 0x0807); //             LOOP
    cpu.CPU_WriteByte(0x60, 0x0808); //         RTS
    cpu.CPU_PrintStatus();

    try stdout.print("Executing Program ...\n", .{});
    while (cpu.CPU_Run_Step() != 0) {
        cpu.CPU_PrintStatus();
    }
}
