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
PC: 0800 | A: 00 | X: 00 | Y: 00 | Last Opc: 00 | Last Cycl: 0 | Cycl-TT: 0 | F: 00100100
Writing Program ...
PC: 0800 | A: 00 | X: 00 | Y: 00 | Last Opc: 00 | Last Cycl: 0 | Cycl-TT: 9 | F: 00100100
Executing Program ...
PC: 0802 | A: 0A | X: 00 | Y: 00 | Last Opc: A9 | Last Cycl: 2 | Cycl-TT: 11 | F: 00100100
PC: 0803 | A: 0A | X: 0A | Y: 00 | Last Opc: AA | Last Cycl: 2 | Cycl-TT: 13 | F: 00100100
PC: 0804 | A: 0A | X: 0B | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 15 | F: 00100100
PC: 0806 | A: 0A | X: 0B | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 17 | F: 00100100
PC: 0803 | A: 0A | X: 0B | Y: 00 | Last Opc: D0 | Last Cycl: 3 | Cycl-TT: 20 | F: 00100100
PC: 0804 | A: 0A | X: 0C | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 22 | F: 00100100
PC: 0806 | A: 0A | X: 0C | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 24 | F: 00100100
PC: 0803 | A: 0A | X: 0C | Y: 00 | Last Opc: D0 | Last Cycl: 3 | Cycl-TT: 27 | F: 00100100
PC: 0804 | A: 0A | X: 0D | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 29 | F: 00100100
PC: 0806 | A: 0A | X: 0D | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 31 | F: 00100100
PC: 0803 | A: 0A | X: 0D | Y: 00 | Last Opc: D0 | Last Cycl: 3 | Cycl-TT: 34 | F: 00100100
PC: 0804 | A: 0A | X: 0E | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 36 | F: 00100100
PC: 0806 | A: 0A | X: 0E | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 38 | F: 00100100
PC: 0803 | A: 0A | X: 0E | Y: 00 | Last Opc: D0 | Last Cycl: 3 | Cycl-TT: 41 | F: 00100100
PC: 0804 | A: 0A | X: 0F | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 43 | F: 00100100
PC: 0806 | A: 0A | X: 0F | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 45 | F: 00100100
PC: 0803 | A: 0A | X: 0F | Y: 00 | Last Opc: D0 | Last Cycl: 3 | Cycl-TT: 48 | F: 00100100
PC: 0804 | A: 0A | X: 10 | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 50 | F: 00100100
PC: 0806 | A: 0A | X: 10 | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 52 | F: 00100100
PC: 0803 | A: 0A | X: 10 | Y: 00 | Last Opc: D0 | Last Cycl: 3 | Cycl-TT: 55 | F: 00100100
PC: 0804 | A: 0A | X: 11 | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 57 | F: 00100100
PC: 0806 | A: 0A | X: 11 | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 59 | F: 00100100
PC: 0803 | A: 0A | X: 11 | Y: 00 | Last Opc: D0 | Last Cycl: 3 | Cycl-TT: 62 | F: 00100100
PC: 0804 | A: 0A | X: 12 | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 64 | F: 00100100
PC: 0806 | A: 0A | X: 12 | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 66 | F: 00100100
PC: 0803 | A: 0A | X: 12 | Y: 00 | Last Opc: D0 | Last Cycl: 3 | Cycl-TT: 69 | F: 00100100
PC: 0804 | A: 0A | X: 13 | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 71 | F: 00100100
PC: 0806 | A: 0A | X: 13 | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 73 | F: 00100100
PC: 0803 | A: 0A | X: 13 | Y: 00 | Last Opc: D0 | Last Cycl: 3 | Cycl-TT: 76 | F: 00100100
PC: 0804 | A: 0A | X: 14 | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 78 | F: 00100100
PC: 0806 | A: 0A | X: 14 | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 80 | F: 00100100
PC: 0808 | A: 0A | X: 14 | Y: 00 | Last Opc: D0 | Last Cycl: 2 | Cycl-TT: 82 | F: 00100100
PC: 0001 | A: 0A | X: 14 | Y: 00 | Last Opc: 60 | Last Cycl: 6 | Cycl-TT: 88 | F: 00100100
```
