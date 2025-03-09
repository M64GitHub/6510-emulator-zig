# 6510 Emulator in Zig

A **MOS 6510 (Commodore 64) CPU emulator** written in **Zig**, designed for accuracy, efficiency, and integration with SID-based applications. This emulator features **video synchronization** for **PAL and NTSC**, enabling smooth execution of CPU cycles in sync with real C64 refresh rates. Additionally, it includes **SID register monitoring**, making it ideal for **audio-driven applications** and real-time SID playback analysis.

Enjoy bringing the **C64 CPU to life in Zig!** 🕹🔥

<br>

## 🚀 Features
- 🎮 **Fully Functional 6510 CPU Emulator** – Implements all 6502/6510 instructions and addressing modes.
- 🎞 **Video Synchronization** – Execute CPU cycles in sync with PAL (19,656 cycles/frame) or NTSC (17,734 cycles/frame).
- 🎵 **SID Register Modification Detection** – Detects when SID registers (`0xD400-0xD418`) are written to, perfect for tracking SID interaction.
- 📝 **Memory Read/Write Functions** – Flexible access to C64 memory space.
- 💾 **Program Loading Support** – Load PRG files and execute C64 programs.
- 🛠 **CPU Debugging Tools** – Functions for inspecting CPU registers, memory, and SID states.

<br>

## Installation
### Requirements:
- **Zig** (Latest stable version)

### Building the Emulator:
```sh
zig build
```

### Running the Emulator:
```sh
zig build run
```


## API Reference

To integrate the emulator into a Zig project, simply import it and initialize:
```zig
const CPU = @import("6510.zig").CPU;
var cpu = CPU.Init(0x0800);
// write something into memory via WriteByte() calls, or use LoadProgram()
cpu.RunPALFrames(1); // Execute one PAL frame worth of cycles
```

The following **public functions** provide full control over the CPU:

### 🖥 **CPU Control**
```zig
pub fn Init(PC_init: u16) CPU // Initialize CPU with a start PC
pub fn Reset(cpu: *CPU) void // Reset CPU registers and PC (0xFFFC)
pub fn Run_Step(cpu: *CPU) u8 // Execute a single instruction
```

### 🎞 **Frame-Based Execution** (PAL & NTSC Timing)
```zig
pub fn RunPALFrames(cpu: *CPU, frame_count: u32) bool // Execute CPU cycles for given PAL frames
pub fn RunNTSCFrames(cpu: *CPU, frame_count: u32) bool // Execute CPU cycles for given NTSC frames
```

### 📝 **Memory Read/Write**
```zig
pub fn ReadByte(cpu: *CPU, Address: u16) u8  // Read a byte from memory
pub fn ReadWord(cpu: *CPU, Address: u16) u16  // Read a word (16-bit) from memory
pub fn WriteByte(cpu: *CPU, Value: u8, Address: u16) void // Write a byte to memory
pub fn WriteWord(cpu: *CPU, Value: u16, Address: u16) void // Write a word to memory
pub fn LoadPrg(cpu: *CPU, Program: []const u8, NumBytes: u32) u16 // Load a PRG program into memory
```

### 🎶 **SID Register Monitoring**
```zig
pub fn SIDRegWritten(cpu: *CPU) bool // Check if SID registers were modified
pub fn GetSIDRegisters(cpu: *CPU) [25]u8 // Retrieve the current SID register values
pub fn PrintSIDRegisters(cpu: *CPU) void // Print SID register values
```

### 🔍 **Debugging Tools**
```zig
pub fn PrintStatus(cpu: *CPU) void // Print CPU state (PC, Registers, Last Opcode, etc.)
```

## Test Run
The test program `main.zig` writes a small routine into the memory, which executes a simple loop:
```
0800: A9 0A                       LDA #$0A        ; 2
0802: AA                          TAX             ; 2
0803: 69 1E                       ADC #$1E        ; 2  loop start
0805: 9D 00 D4                    STA $D400,X     ; 5  write sid register X
0808: E8                          INX             ; 2
0809: E0 19                       CPX #$19        ; 2
080B: D0 F6                       BNE $0804       ; 2/3 loop
080D: 60                          RTS             ; 6
```

Test Output:
```
[MAIN] Initializing CPU
[CPU ] PC: 0800 | A: 00 | X: 00 | Y: 00 | Last Opc: 00 | Last Cycl: 0 | Cycl-TT: 0 | F: 00100100
[MAIN] Writing program ...
[CPU ] PC: 0800 | A: 00 | X: 00 | Y: 00 | Last Opc: 00 | Last Cycl: 0 | Cycl-TT: 14 | F: 00100100
[MAIN] Executing program ...
[CPU ] PC: 0802 | A: 0A | X: 00 | Y: 00 | Last Opc: A9 | Last Cycl: 2 | Cycl-TT: 16 | F: 00100100
[CPU ] PC: 0803 | A: 0A | X: 0A | Y: 00 | Last Opc: AA | Last Cycl: 2 | Cycl-TT: 18 | F: 00100100
[CPU ] PC: 0805 | A: 28 | X: 0A | Y: 00 | Last Opc: 69 | Last Cycl: 2 | Cycl-TT: 20 | F: 00100100
[CPU ] PC: 0808 | A: 28 | X: 0A | Y: 00 | Last Opc: 9D | Last Cycl: 5 | Cycl-TT: 25 | F: 00100100
[MAIN] SID register written!
[CPU ] SID Registers: 00 00 00 00 00 00 00 00 00 00 28 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
[CPU ] PC: 0809 | A: 28 | X: 0B | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 27 | F: 00100100
[CPU ] PC: 080B | A: 28 | X: 0B | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 29 | F: 00100100
[CPU ] PC: 0803 | A: 28 | X: 0B | Y: 00 | Last Opc: D0 | Last Cycl: 3 | Cycl-TT: 32 | F: 00100100
[CPU ] PC: 0805 | A: 46 | X: 0B | Y: 00 | Last Opc: 69 | Last Cycl: 2 | Cycl-TT: 34 | F: 00100100
[CPU ] PC: 0808 | A: 46 | X: 0B | Y: 00 | Last Opc: 9D | Last Cycl: 5 | Cycl-TT: 39 | F: 00100100
[MAIN] SID register written!
[CPU ] SID Registers: 00 00 00 00 00 00 00 00 00 00 28 46 00 00 00 00 00 00 00 00 00 00 00 00 00 
...
...
[CPU ] PC: 0809 | A: AE | X: 18 | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 209 | F: 00100100
[CPU ] PC: 080B | A: AE | X: 18 | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 211 | F: 00100100
[CPU ] PC: 0803 | A: AE | X: 18 | Y: 00 | Last Opc: D0 | Last Cycl: 3 | Cycl-TT: 214 | F: 00100100
[CPU ] PC: 0805 | A: CC | X: 18 | Y: 00 | Last Opc: 69 | Last Cycl: 2 | Cycl-TT: 216 | F: 00100100
[CPU ] PC: 0808 | A: CC | X: 18 | Y: 00 | Last Opc: 9D | Last Cycl: 5 | Cycl-TT: 221 | F: 00100100
[MAIN] SID register written!
[CPU ] SID Registers: 00 00 00 00 00 00 00 00 00 00 28 46 64 82 A0 BE DC FA 18 36 54 72 90 AE CC 
[MAIN] SID volume changed: CC
[CPU ] PC: 0809 | A: CC | X: 19 | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 223 | F: 00100100
[CPU ] PC: 080B | A: CC | X: 19 | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 225 | F: 00100100
[CPU ] PC: 080D | A: CC | X: 19 | Y: 00 | Last Opc: D0 | Last Cycl: 2 | Cycl-TT: 227 | F: 00100100
[CPU ] PC: 0001 | A: CC | X: 19 | Y: 00 | Last Opc: 60 | Last Cycl: 6 | Cycl-TT: 233 | F: 00100100
```

## License
This emulator is released under the **MIT License**, allowing free modification and distribution.

## Credits
Developed with ❤️ by **M64**. Structured and based on the works of @davepoo 💖🚀🔥

## 🚀 Get Started Now!
Clone the repository and start experimenting:
```sh
git clone https://github.com/M64GitHub/6510-emulator-zig.git
cd 6510-emulator-zig
zig build
```
Enjoy bringing the **C64 CPU to life in Zig!** 🕹🔥






