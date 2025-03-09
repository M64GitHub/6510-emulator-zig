# MOS6510 CPU Emulator

A simple MOS6510 (Commodore 64) CPU emulator in zig. With enhancements for video synchronisation (PAL- and NTSC video frame support), and SID register modification detection. Ideal for use in SID audio applications.


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
...
[CPU ] PC: 0809 | A: AE | X: 18 | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 209 | F: 00100100
[CPU ] PC: 080B | A: AE | X: 18 | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 211 | F: 00100100
[CPU ] PC: 0803 | A: AE | X: 18 | Y: 00 | Last Opc: D0 | Last Cycl: 3 | Cycl-TT: 214 | F: 00100100
[CPU ] PC: 0805 | A: CC | X: 18 | Y: 00 | Last Opc: 69 | Last Cycl: 2 | Cycl-TT: 216 | F: 00100100
[CPU ] PC: 0808 | A: CC | X: 18 | Y: 00 | Last Opc: 9D | Last Cycl: 5 | Cycl-TT: 221 | F: 00100100
[MAIN] SID register written!
[CPU ] SID Registers: 00 00 00 00 00 00 00 00 00 00 28 46 64 82 A0 BE DC FA 18 36 54 72 90 AE CC 
**[MAIN] SID volume changed: CC**
[CPU ] PC: 0809 | A: CC | X: 19 | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 223 | F: 00100100
[CPU ] PC: 080B | A: CC | X: 19 | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 225 | F: 00100100
[CPU ] PC: 080D | A: CC | X: 19 | Y: 00 | Last Opc: D0 | Last Cycl: 2 | Cycl-TT: 227 | F: 00100100
[CPU ] PC: 0001 | A: CC | X: 19 | Y: 00 | Last Opc: 60 | Last Cycl: 6 | Cycl-TT: 233 | F: 00100100
```
