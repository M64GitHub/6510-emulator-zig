const std = @import("std");
const CPU = @import("6510.zig").CPU;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("Initializing CPU\n", .{});
    var cpu = CPU.Init(0x800);
    cpu.PrintStatus();

    try stdout.print("Writing program ...\n", .{});
    cpu.WriteByte(0xa9, 0x0800); //         LDA
    cpu.WriteByte(0x0a, 0x0801); //             #0A     ; 10
    cpu.WriteByte(0xaa, 0x0802); //         TAX
    cpu.WriteByte(0xe8, 0x0803); // LOOP:   INX
    cpu.WriteByte(0xe0, 0x0804); //         CPX
    cpu.WriteByte(0x14, 0x0805); //             #$14    ; 20
    cpu.WriteByte(0xd0, 0x0806); //         BNE
    cpu.WriteByte(0xfb, 0x0807); //             LOOP
    cpu.WriteByte(0x60, 0x0808); //         RTS
    cpu.PrintStatus();

    try stdout.print("Executing program ...\n", .{});
    while (cpu.Run_Step() != 0) {
        cpu.PrintStatus();
        if (cpu.SIDRegWritten()) {
            try stdout.print("SID register written!\n", .{});
        }
    }
}
