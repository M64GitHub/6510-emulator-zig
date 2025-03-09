# MOS6510 CPU Emulator

A simple MOS6510 (Commodore 64) CPU emulator in zig. With enhancements for video synchronisation (PAL- and NTSC video frame support), and SID register modification detection. Ideal for use in SID audio applications.


The test program `main.zig` writes a small routine into the memory, which executes a simple loop:
```
0800: A9 0A                       LDA #$0A        ; 2
0802: AA                          TAX             ; 2
0803: 69 1E                       ADC #$1E        ; 2  loop
0805: 9D 00 D4                    STA $D400,X     ; 5  write sid register X
0808: E8                          INX             ; 2
0809: E0 19                       CPX #$19        ; 2
080B: D0 F6                       BNE $0804       ; 2/3
080D: 60                          RTS             ; 6

```

Test Output:
```
Initializing CPU
PC: 0800 | A: 00 | X: 00 | Y: 00 | Last Opc: 00 | Last Cycl: 0 | Cycl-TT: 0 | F: 00100100
Writing program ...
PC: 0800 | A: 00 | X: 00 | Y: 00 | Last Opc: 00 | Last Cycl: 0 | Cycl-TT: 14 | F: 00100100
Executing program ...
PC: 0802 | A: 0A | X: 00 | Y: 00 | Last Opc: A9 | Last Cycl: 2 | Cycl-TT: 16 | F: 00100100
PC: 0803 | A: 0A | X: 0A | Y: 00 | Last Opc: AA | Last Cycl: 2 | Cycl-TT: 18 | F: 00100100
PC: 0805 | A: 28 | X: 0A | Y: 00 | Last Opc: 69 | Last Cycl: 2 | Cycl-TT: 20 | F: 00100100
PC: 0808 | A: 28 | X: 0A | Y: 00 | Last Opc: 9D | Last Cycl: 5 | Cycl-TT: 25 | F: 00100100
SID register written!
SID Registers: 00 00 00 00 00 00 00 00 00 00 28 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
SID volume: 00
PC: 0809 | A: 28 | X: 0B | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 27 | F: 00100100
PC: 080B | A: 28 | X: 0B | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 29 | F: 00100100
PC: 0803 | A: 28 | X: 0B | Y: 00 | Last Opc: D0 | Last Cycl: 3 | Cycl-TT: 32 | F: 00100100
PC: 0805 | A: 46 | X: 0B | Y: 00 | Last Opc: 69 | Last Cycl: 2 | Cycl-TT: 34 | F: 00100100
PC: 0808 | A: 46 | X: 0B | Y: 00 | Last Opc: 9D | Last Cycl: 5 | Cycl-TT: 39 | F: 00100100
SID register written!
SID Registers: 00 00 00 00 00 00 00 00 00 00 28 46 00 00 00 00 00 00 00 00 00 00 00 00 00 
SID volume: 00
PC: 0809 | A: 46 | X: 0C | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 41 | F: 00100100
PC: 080B | A: 46 | X: 0C | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 43 | F: 00100100
PC: 0803 | A: 46 | X: 0C | Y: 00 | Last Opc: D0 | Last Cycl: 3 | Cycl-TT: 46 | F: 00100100
PC: 0805 | A: 64 | X: 0C | Y: 00 | Last Opc: 69 | Last Cycl: 2 | Cycl-TT: 48 | F: 00100100
PC: 0808 | A: 64 | X: 0C | Y: 00 | Last Opc: 9D | Last Cycl: 5 | Cycl-TT: 53 | F: 00100100
SID register written!
SID Registers: 00 00 00 00 00 00 00 00 00 00 28 46 64 00 00 00 00 00 00 00 00 00 00 00 00 
SID volume: 00
PC: 0809 | A: 64 | X: 0D | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 55 | F: 00100100
PC: 080B | A: 64 | X: 0D | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 57 | F: 00100100
PC: 0803 | A: 64 | X: 0D | Y: 00 | Last Opc: D0 | Last Cycl: 3 | Cycl-TT: 60 | F: 00100100
PC: 0805 | A: 82 | X: 0D | Y: 00 | Last Opc: 69 | Last Cycl: 2 | Cycl-TT: 62 | F: 00100100
PC: 0808 | A: 82 | X: 0D | Y: 00 | Last Opc: 9D | Last Cycl: 5 | Cycl-TT: 67 | F: 00100100
SID register written!
SID Registers: 00 00 00 00 00 00 00 00 00 00 28 46 64 82 00 00 00 00 00 00 00 00 00 00 00 
SID volume: 00
PC: 0809 | A: 82 | X: 0E | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 69 | F: 00100100
PC: 080B | A: 82 | X: 0E | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 71 | F: 00100100
PC: 0803 | A: 82 | X: 0E | Y: 00 | Last Opc: D0 | Last Cycl: 3 | Cycl-TT: 74 | F: 00100100
PC: 0805 | A: A0 | X: 0E | Y: 00 | Last Opc: 69 | Last Cycl: 2 | Cycl-TT: 76 | F: 00100100
PC: 0808 | A: A0 | X: 0E | Y: 00 | Last Opc: 9D | Last Cycl: 5 | Cycl-TT: 81 | F: 00100100
SID register written!
SID Registers: 00 00 00 00 00 00 00 00 00 00 28 46 64 82 A0 00 00 00 00 00 00 00 00 00 00 
SID volume: 00
PC: 0809 | A: A0 | X: 0F | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 83 | F: 00100100
PC: 080B | A: A0 | X: 0F | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 85 | F: 00100100
PC: 0803 | A: A0 | X: 0F | Y: 00 | Last Opc: D0 | Last Cycl: 3 | Cycl-TT: 88 | F: 00100100
PC: 0805 | A: BE | X: 0F | Y: 00 | Last Opc: 69 | Last Cycl: 2 | Cycl-TT: 90 | F: 00100100
PC: 0808 | A: BE | X: 0F | Y: 00 | Last Opc: 9D | Last Cycl: 5 | Cycl-TT: 95 | F: 00100100
SID register written!
SID Registers: 00 00 00 00 00 00 00 00 00 00 28 46 64 82 A0 BE 00 00 00 00 00 00 00 00 00 
SID volume: 00
PC: 0809 | A: BE | X: 10 | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 97 | F: 00100100
PC: 080B | A: BE | X: 10 | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 99 | F: 00100100
PC: 0803 | A: BE | X: 10 | Y: 00 | Last Opc: D0 | Last Cycl: 3 | Cycl-TT: 102 | F: 00100100
PC: 0805 | A: DC | X: 10 | Y: 00 | Last Opc: 69 | Last Cycl: 2 | Cycl-TT: 104 | F: 00100100
PC: 0808 | A: DC | X: 10 | Y: 00 | Last Opc: 9D | Last Cycl: 5 | Cycl-TT: 109 | F: 00100100
SID register written!
SID Registers: 00 00 00 00 00 00 00 00 00 00 28 46 64 82 A0 BE DC 00 00 00 00 00 00 00 00 
SID volume: 00
PC: 0809 | A: DC | X: 11 | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 111 | F: 00100100
PC: 080B | A: DC | X: 11 | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 113 | F: 00100100
PC: 0803 | A: DC | X: 11 | Y: 00 | Last Opc: D0 | Last Cycl: 3 | Cycl-TT: 116 | F: 00100100
PC: 0805 | A: FA | X: 11 | Y: 00 | Last Opc: 69 | Last Cycl: 2 | Cycl-TT: 118 | F: 00100100
PC: 0808 | A: FA | X: 11 | Y: 00 | Last Opc: 9D | Last Cycl: 5 | Cycl-TT: 123 | F: 00100100
SID register written!
SID Registers: 00 00 00 00 00 00 00 00 00 00 28 46 64 82 A0 BE DC FA 00 00 00 00 00 00 00 
SID volume: 00
PC: 0809 | A: FA | X: 12 | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 125 | F: 00100100
PC: 080B | A: FA | X: 12 | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 127 | F: 00100100
PC: 0803 | A: FA | X: 12 | Y: 00 | Last Opc: D0 | Last Cycl: 3 | Cycl-TT: 130 | F: 00100100
PC: 0805 | A: 18 | X: 12 | Y: 00 | Last Opc: 69 | Last Cycl: 2 | Cycl-TT: 132 | F: 00100100
PC: 0808 | A: 18 | X: 12 | Y: 00 | Last Opc: 9D | Last Cycl: 5 | Cycl-TT: 137 | F: 00100100
SID register written!
SID Registers: 00 00 00 00 00 00 00 00 00 00 28 46 64 82 A0 BE DC FA 18 00 00 00 00 00 00 
SID volume: 00
PC: 0809 | A: 18 | X: 13 | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 139 | F: 00100100
PC: 080B | A: 18 | X: 13 | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 141 | F: 00100100
PC: 0803 | A: 18 | X: 13 | Y: 00 | Last Opc: D0 | Last Cycl: 3 | Cycl-TT: 144 | F: 00100100
PC: 0805 | A: 36 | X: 13 | Y: 00 | Last Opc: 69 | Last Cycl: 2 | Cycl-TT: 146 | F: 00100100
PC: 0808 | A: 36 | X: 13 | Y: 00 | Last Opc: 9D | Last Cycl: 5 | Cycl-TT: 151 | F: 00100100
SID register written!
SID Registers: 00 00 00 00 00 00 00 00 00 00 28 46 64 82 A0 BE DC FA 18 36 00 00 00 00 00 
SID volume: 00
PC: 0809 | A: 36 | X: 14 | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 153 | F: 00100100
PC: 080B | A: 36 | X: 14 | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 155 | F: 00100100
PC: 0803 | A: 36 | X: 14 | Y: 00 | Last Opc: D0 | Last Cycl: 3 | Cycl-TT: 158 | F: 00100100
PC: 0805 | A: 54 | X: 14 | Y: 00 | Last Opc: 69 | Last Cycl: 2 | Cycl-TT: 160 | F: 00100100
PC: 0808 | A: 54 | X: 14 | Y: 00 | Last Opc: 9D | Last Cycl: 5 | Cycl-TT: 165 | F: 00100100
SID register written!
SID Registers: 00 00 00 00 00 00 00 00 00 00 28 46 64 82 A0 BE DC FA 18 36 54 00 00 00 00 
SID volume: 00
PC: 0809 | A: 54 | X: 15 | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 167 | F: 00100100
PC: 080B | A: 54 | X: 15 | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 169 | F: 00100100
PC: 0803 | A: 54 | X: 15 | Y: 00 | Last Opc: D0 | Last Cycl: 3 | Cycl-TT: 172 | F: 00100100
PC: 0805 | A: 72 | X: 15 | Y: 00 | Last Opc: 69 | Last Cycl: 2 | Cycl-TT: 174 | F: 00100100
PC: 0808 | A: 72 | X: 15 | Y: 00 | Last Opc: 9D | Last Cycl: 5 | Cycl-TT: 179 | F: 00100100
SID register written!
SID Registers: 00 00 00 00 00 00 00 00 00 00 28 46 64 82 A0 BE DC FA 18 36 54 72 00 00 00 
SID volume: 00
PC: 0809 | A: 72 | X: 16 | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 181 | F: 00100100
PC: 080B | A: 72 | X: 16 | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 183 | F: 00100100
PC: 0803 | A: 72 | X: 16 | Y: 00 | Last Opc: D0 | Last Cycl: 3 | Cycl-TT: 186 | F: 00100100
PC: 0805 | A: 90 | X: 16 | Y: 00 | Last Opc: 69 | Last Cycl: 2 | Cycl-TT: 188 | F: 00100100
PC: 0808 | A: 90 | X: 16 | Y: 00 | Last Opc: 9D | Last Cycl: 5 | Cycl-TT: 193 | F: 00100100
SID register written!
SID Registers: 00 00 00 00 00 00 00 00 00 00 28 46 64 82 A0 BE DC FA 18 36 54 72 90 00 00 
SID volume: 00
PC: 0809 | A: 90 | X: 17 | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 195 | F: 00100100
PC: 080B | A: 90 | X: 17 | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 197 | F: 00100100
PC: 0803 | A: 90 | X: 17 | Y: 00 | Last Opc: D0 | Last Cycl: 3 | Cycl-TT: 200 | F: 00100100
PC: 0805 | A: AE | X: 17 | Y: 00 | Last Opc: 69 | Last Cycl: 2 | Cycl-TT: 202 | F: 00100100
PC: 0808 | A: AE | X: 17 | Y: 00 | Last Opc: 9D | Last Cycl: 5 | Cycl-TT: 207 | F: 00100100
SID register written!
SID Registers: 00 00 00 00 00 00 00 00 00 00 28 46 64 82 A0 BE DC FA 18 36 54 72 90 AE 00 
SID volume: 00
PC: 0809 | A: AE | X: 18 | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 209 | F: 00100100
PC: 080B | A: AE | X: 18 | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 211 | F: 00100100
PC: 0803 | A: AE | X: 18 | Y: 00 | Last Opc: D0 | Last Cycl: 3 | Cycl-TT: 214 | F: 00100100
PC: 0805 | A: CC | X: 18 | Y: 00 | Last Opc: 69 | Last Cycl: 2 | Cycl-TT: 216 | F: 00100100
PC: 0808 | A: CC | X: 18 | Y: 00 | Last Opc: 9D | Last Cycl: 5 | Cycl-TT: 221 | F: 00100100
SID register written!
SID Registers: 00 00 00 00 00 00 00 00 00 00 28 46 64 82 A0 BE DC FA 18 36 54 72 90 AE CC 
SID volume: CC
PC: 0809 | A: CC | X: 19 | Y: 00 | Last Opc: E8 | Last Cycl: 2 | Cycl-TT: 223 | F: 00100100
PC: 080B | A: CC | X: 19 | Y: 00 | Last Opc: E0 | Last Cycl: 2 | Cycl-TT: 225 | F: 00100100
PC: 080D | A: CC | X: 19 | Y: 00 | Last Opc: D0 | Last Cycl: 2 | Cycl-TT: 227 | F: 00100100
PC: 0001 | A: CC | X: 19 | Y: 00 | Last Opc: 60 | Last Cycl: 6 | Cycl-TT: 233 | F: 00100100
```
