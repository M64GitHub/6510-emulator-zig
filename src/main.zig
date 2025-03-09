const std = @import("std");
const CPU = @import("6510.zig").CPU;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var cpu = CPU.Init(0x800);

    cpu.Reset();

    try stdout.print("Hackeeeee!!!\n", .{});
}
