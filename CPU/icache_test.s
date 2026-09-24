// icache_test.s - Instruction Cache Stress Test
// Strictly formatted for CO2070Assembler (one instruction per line, 4 bytes each)
// Word addresses are shown in the comments (word*4 = byte address)

// ---- Block 0 (byte 0-15, index 0, tag 0) : words 0-3 ----
loadi 1 0x01    // word 0  (byte 0)   - COMPULSORY MISS on block 0 (fetches block 0)
loadi 2 0x02    // word 1  (byte 4)   - HIT (block 0 already cached)
loadi 3 0x03    // word 2  (byte 8)   - HIT
loadi 4 0x04    // word 3  (byte 12)  - HIT

// ---- Block 1 (byte 16-31, index 1, tag 0) : words 4-7 ----
loadi 5 0x05    // word 4  (byte 16)  - COMPULSORY MISS on block 1
loadi 6 0x06    // word 5  (byte 20)  - HIT
loadi 7 0x07    // word 6  (byte 24)  - HIT
mov   0 0       // word 7  (byte 28)  - HIT

// ---- Block 2 (byte 32-47, index 2, tag 0) : word 8 ----
j 0x17          // word 8  (byte 32)  - MISS on block 2, then jumps forward
                //   offset 0x17=23 -> target = (PC+4) + 23*4 = 36 + 92 = 128 = word 32

// ---- Filler words 9-31 (never executed, just padding so the .machine file
//      keeps every word address aligned) ----
mov 0 0         // word 9
mov 0 0         // word 10
mov 0 0         // word 11
mov 0 0         // word 12
mov 0 0         // word 13
mov 0 0         // word 14
mov 0 0         // word 15
mov 0 0         // word 16
mov 0 0         // word 17
mov 0 0         // word 18
mov 0 0         // word 19
mov 0 0         // word 20
mov 0 0         // word 21
mov 0 0         // word 22
mov 0 0         // word 23
mov 0 0         // word 24
mov 0 0         // word 25
mov 0 0         // word 26
mov 0 0         // word 27
mov 0 0         // word 28
mov 0 0         // word 29
mov 0 0         // word 30
mov 0 0         // word 31

// ---- Block 8 (byte 128-143, index 0, tag 1) : words 32-34 ----
// Block 8 maps to the SAME index (0) as block 0 -> this access EVICTS block 0
loadi 1 0x63    // word 32 (byte 128) - CONFLICT MISS (evicts block 0 from index 0)
loadi 2 0x62    // word 33 (byte 132) - HIT
loadi 3 0x61    // word 34 (byte 136) - HIT

// word 35: jump back to word 0. Block 0 was evicted, so this recreates the
// classic direct-mapped "thrashing" pattern between block 0 and block 8.
j 0xDC          // word 35 (byte 140) - offset 0xDC = -36 (two's complement)
                //   target = (PC+4) + (-36*4) = 144 - 144 = 0 = word 0
                //   (Word 0's block is now a MISS again, since it was evicted)
