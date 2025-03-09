# MOS6510 CPU Emulator

A simple MOS6510 (Commodore 64) CPU emulator in zig. Easily extendable. 


The test program `main.zig` writes a small routine into the memory, which executes a simple loop:
```
0800: A9 0A                       LDA #$0A        ; 2 
0802: AA                          TAX             ; 2 
0803: E8                          INX             ; 2 loop
0804: E0 14                       CPX #$14        ; 2 
0806: D0 FB                       BNE $0803       ; 2/3 
0808: 60                          RTS             ; 6 
```

Test Output:
```
Initializing CPU
PC: 0800 | A: 00 | X: 00 | Y: 00 | Last Opcode: 00 | Last Cycl: 0 | Cycl-TT: 0
Writing Program ...
PC: 0800 | A: 00 | X: 00 | Y: 00 | Last Opcode: 00 | Last Cycl: 0 | Cycl-TT: 9
Executing Program ...
PC: 0802 | A: 0A | X: 00 | Y: 00 | Last Opcode: A9 | Last Cycl: 2 | Cycl-TT: 11
PC: 0803 | A: 0A | X: 0A | Y: 00 | Last Opcode: AA | Last Cycl: 2 | Cycl-TT: 13
PC: 0804 | A: 0A | X: 0B | Y: 00 | Last Opcode: E8 | Last Cycl: 2 | Cycl-TT: 15
PC: 0806 | A: 0A | X: 0B | Y: 00 | Last Opcode: E0 | Last Cycl: 2 | Cycl-TT: 17
PC: 0803 | A: 0A | X: 0B | Y: 00 | Last Opcode: D0 | Last Cycl: 3 | Cycl-TT: 20
PC: 0804 | A: 0A | X: 0C | Y: 00 | Last Opcode: E8 | Last Cycl: 2 | Cycl-TT: 22
PC: 0806 | A: 0A | X: 0C | Y: 00 | Last Opcode: E0 | Last Cycl: 2 | Cycl-TT: 24
PC: 0803 | A: 0A | X: 0C | Y: 00 | Last Opcode: D0 | Last Cycl: 3 | Cycl-TT: 27
PC: 0804 | A: 0A | X: 0D | Y: 00 | Last Opcode: E8 | Last Cycl: 2 | Cycl-TT: 29
PC: 0806 | A: 0A | X: 0D | Y: 00 | Last Opcode: E0 | Last Cycl: 2 | Cycl-TT: 31
PC: 0803 | A: 0A | X: 0D | Y: 00 | Last Opcode: D0 | Last Cycl: 3 | Cycl-TT: 34
PC: 0804 | A: 0A | X: 0E | Y: 00 | Last Opcode: E8 | Last Cycl: 2 | Cycl-TT: 36
PC: 0806 | A: 0A | X: 0E | Y: 00 | Last Opcode: E0 | Last Cycl: 2 | Cycl-TT: 38
PC: 0803 | A: 0A | X: 0E | Y: 00 | Last Opcode: D0 | Last Cycl: 3 | Cycl-TT: 41
PC: 0804 | A: 0A | X: 0F | Y: 00 | Last Opcode: E8 | Last Cycl: 2 | Cycl-TT: 43
PC: 0806 | A: 0A | X: 0F | Y: 00 | Last Opcode: E0 | Last Cycl: 2 | Cycl-TT: 45
PC: 0803 | A: 0A | X: 0F | Y: 00 | Last Opcode: D0 | Last Cycl: 3 | Cycl-TT: 48
PC: 0804 | A: 0A | X: 10 | Y: 00 | Last Opcode: E8 | Last Cycl: 2 | Cycl-TT: 50
PC: 0806 | A: 0A | X: 10 | Y: 00 | Last Opcode: E0 | Last Cycl: 2 | Cycl-TT: 52
PC: 0803 | A: 0A | X: 10 | Y: 00 | Last Opcode: D0 | Last Cycl: 3 | Cycl-TT: 55
PC: 0804 | A: 0A | X: 11 | Y: 00 | Last Opcode: E8 | Last Cycl: 2 | Cycl-TT: 57
PC: 0806 | A: 0A | X: 11 | Y: 00 | Last Opcode: E0 | Last Cycl: 2 | Cycl-TT: 59
PC: 0803 | A: 0A | X: 11 | Y: 00 | Last Opcode: D0 | Last Cycl: 3 | Cycl-TT: 62
PC: 0804 | A: 0A | X: 12 | Y: 00 | Last Opcode: E8 | Last Cycl: 2 | Cycl-TT: 64
PC: 0806 | A: 0A | X: 12 | Y: 00 | Last Opcode: E0 | Last Cycl: 2 | Cycl-TT: 66
PC: 0803 | A: 0A | X: 12 | Y: 00 | Last Opcode: D0 | Last Cycl: 3 | Cycl-TT: 69
PC: 0804 | A: 0A | X: 13 | Y: 00 | Last Opcode: E8 | Last Cycl: 2 | Cycl-TT: 71
PC: 0806 | A: 0A | X: 13 | Y: 00 | Last Opcode: E0 | Last Cycl: 2 | Cycl-TT: 73
PC: 0803 | A: 0A | X: 13 | Y: 00 | Last Opcode: D0 | Last Cycl: 3 | Cycl-TT: 76
PC: 0804 | A: 0A | X: 14 | Y: 00 | Last Opcode: E8 | Last Cycl: 2 | Cycl-TT: 78
PC: 0806 | A: 0A | X: 14 | Y: 00 | Last Opcode: E0 | Last Cycl: 2 | Cycl-TT: 80
PC: 0808 | A: 0A | X: 14 | Y: 00 | Last Opcode: D0 | Last Cycl: 2 | Cycl-TT: 82
PC: 0001 | A: 0A | X: 14 | Y: 00 | Last Opcode: 60 | Last Cycl: 6 | Cycl-TT: 88
```
