# 6510 Emulator in Zig

A **MOS 6510 (Commodore 64) CPU emulator** written in **Zig**, designed for accuracy, efficiency, and integration with SID-based applications. This emulator features **video synchronization** for **PAL and NTSC**, enabling smooth execution of CPU cycles in sync with real C64 refresh rates. Additionally, it includes **SID register monitoring**, making it ideal for **audio-driven applications** and real-time SID playback and -analysis.

Enjoy bringing the **C64 CPU to life in Zig!** 🕹🔥

<br>

## 🚀 Features
- 🎮 **Fully Functional 6510 CPU Emulator** – Implements all legal 6502/6510 instructions and addressing modes.
- 🎞 **Video Synchronization** – Execute CPU cycles in sync with PAL (19,656 cycles/frame) or NTSC (17,734 cycles/frame).
- 🎵 **SID Register Modification Detection** – Detects when SID registers (`0xD400-0xD418`) are written to, perfect for tracking SID interaction.
- 📝 **Memory Read/Write Functions** – Flexible access to C64 memory space.
- 💾 **Program Loading Support** – Load PRG files and execute C64 programs.
- 🛠 **CPU Debugging Tools** – Functions for inspecting CPU registers, flags, memory, and SID states.

<br>

## Building the Project
#### Requirements:
- ⚡ **Zig** (Latest stable version)

#### Building the Test Executable:
```sh
zig build
```

#### Running the Test Executable:
```sh
zig build run
```
<br>

## API Reference
### 💡 Quick Start
**To integrate the emulator into a Zig project, simply import it and initialize:**
```zig
const CPU = @import("6510.zig").CPU;
var cpu = CPU.Init(std.heap.page_allocator, 0x0800); // initialize the PC with address 0x0800
```
**Load a program `.prg` file:**
```zig
// The second parameter (true) tells LoadPrg() to set the PC to the load address,
// effectively jupming to program start. LoadPrg() is currently the only function
// utilizing the allocator we set above.

const file_name = "data/test1.prg";
const load_address = try cpu.LoadPrg(file_name, true);
```
**Run the CPU until program end:**  
```zig
cpu.Call(load_address); // returns on RTS
```
Or have more control and execute instruction by instruction:
`RunStep()` returns the number of cycles executed
```zig
while (cpu.RunStep() != 0) {
    cpu.PrintStatus();
}
```
**Or run the CPU a specific amount of virtual video frames:**  
`RunPALFrames()` returns the number of frames executed.
```zig
cpu.dbg_enabled = true; // will call PrintStatus() after each step
var frames_executed = cpu.RunPALFrames(1);
```

<br>

### 📜 Emulator API

The following **public functions** provide full control over the CPU:

#### 🖥 **CPU Control**
```zig
pub fn Init(allocator: std.mem.Allocator, PC_init: u16) CPU // Initialize CPU with a start PC
pub fn Reset(cpu: *CPU) void // Reset CPU registers and PC (0xFFFC)
pub fn HardReset(cpu: *CPU) void // Reset and clear memory
```

#### ⚡ ***Execution**
```zig
pub fn RunStep(cpu: *CPU) u8 // Execute a single instruction, return number of used cycles
pub fn Call(cpu: *CPU, Address: u16) void // Call a subroutine at Address, return on RTS
```

#### 🎞 **Frame-Based Execution** (PAL & NTSC Timing)
```zig
// The following functions execute until a number of PAL or NTSC frames is reached
// They return the number of frames executed

pub fn RunPALFrames(cpu: *CPU, frame_count: u32) u32
pub fn RunNTSCFrames(cpu: *CPU, frame_count: u32) u32
```

#### 📝 **Memory Read/Write**
```zig
pub fn ReadByte(cpu: *CPU, Address: u16) u8  // Read a byte from memory
pub fn ReadWord(cpu: *CPU, Address: u16) u16  // Read a word (16-bit) from memory
pub fn WriteByte(cpu: *CPU, Value: u8, Address: u16) void // Write a byte to memory
pub fn WriteWord(cpu: *CPU, Value: u16, Address: u16) void // Write a word to memory

// LoadPrg() - Load a .prg file into memory. Returns the load address.
// When setPC is true, the CPU.PC is set to the load address.
// This function utilizes the allocator set at CPU initialization
pub fn LoadPrg(cpu: *CPU, Filename: []const u8, setPC: bool) !u16

// Write a buffer containing a .prg to memory. Returns the load address of the .prg.
pub fn SetPrg(cpu: *CPU, Program: []const u8, setPC: bool) u16

// Write a raw buffer to memory Address
pub fn WriteMem(cpu: *CPU, data: []const u8, Address: u16) void
```

#### 🎶 **SID Register Monitoring**
```zig
pub fn SIDRegWritten(cpu: *CPU) bool // Check if SID registers were modified
pub fn GetSIDRegisters(cpu: *CPU) [25]u8 // Retrieve the current SID register values
pub fn PrintSIDRegisters(cpu: *CPU) void // Print SID register values
```

#### 🔍 **Debugging Tools**
```zig
pub fn PrintStatus(cpu: *CPU) void // Print CPU state (PC, Registers, Last Opcode, etc.)
CPU.dbg_enabled: bool // set for calling PrintStatus() after each execution step
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

<br>

## License
This emulator is released under the **MIT License**, allowing free modification and distribution.

<br>

## Credits
Developed with ❤️ by **M64**. Based on a lot of online research, and the works of @davepoo 💖🚀🔥

<br>

## 🚀 Get Started Now!
Clone the repository and start experimenting:
```sh
git clone https://github.com/M64GitHub/6510-emulator-zig.git
cd 6510-emulator-zig
zig build
```
Enjoy bringing the **C64 CPU to life in Zig!** 🕹🔥






