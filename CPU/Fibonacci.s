// Fibonacci sequence generator (CO2070 custom ISA)
// Computes the first 10 terms F0..F9 and stores them to data memory
// addresses 0..9 (one byte each), then halts in a self-jump.
//
// R1 = F(i-2)  (running "older" term)
// R2 = F(i-1)  (running "newer" term)
// R3 = scratch (next term)
// R4 = memory pointer (address to store the current term)
// R5 = remaining terms to produce
// R7 = constant 1 (pointer increment / loop-counter decrement)

loadi 1 0x00     // word 0:  R1 = 0   (F0)
loadi 2 0x01     // word 1:  R2 = 1   (F1)
loadi 4 0x00     // word 2:  R4 = 0   (store pointer)
loadi 5 0x0C     // word 3:  R5 = 10  (how many terms to generate)
loadi 7 0x01     // word 4:  R7 = 1   (constant)

// ---- LOOP (word 5) ----
swd   1 4        // word 5:  mem[R4] = R1        (store current term)
add   4 4 7      // word 6:  R4 = R4 + 1         (advance pointer)
add   3 1 2      // word 7:  R3 = R1 + R2        (next term)
mov   1 2        // word 8:  R1 = R2
mov   2 3        // word 9:  R2 = R3
sub   5 5 7      // word 10: R5 = R5 - 1
bne   0xF9 5 0   // word 11: if R5 != R0(=0), jump back to word 5
                 //   offset 0xF9 = -7 -> target = (44+4) + (-7*4) = 48-28 = 20 = word 5

j     0xFF       // word 12: HALT (infinite self-jump; offset 0xFF = -1 -> target = 48 = itself)