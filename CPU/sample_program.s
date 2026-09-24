
// 1. Test loadi
loadi 1 0x0C    // PC=0:  Load 12 into Reg 1 (Binary: 00001100)
loadi 2 0x05    // PC=4:  Load 5 into Reg 2  (Binary: 00000101)

// 2. Test mov
mov 3 1         // PC=8:  Copy Reg 1 into Reg 3 (Reg 3 should become 12)

// 3. Test add
add 4 1 2       // PC=12: Reg 4 = 12 + 5 (Result should be 17)

// 4. Test sub
sub 5 1 2       // PC=16: Reg 5 = 12 - 5 (Result should be 7)

// 5. Test and
and 6 1 2       // PC=20: Reg 6 = 12 & 5 (Result should be 4)

// 6. Test or 
or 7 1 2        // PC=24: Reg 7 = 12 | 5 (Result should be 13)



// PART 2: SHARED SHIFT UNIT


// 1. Setup Data for Shifting
loadi 1 0x8C    // PC=28: Load 10001100 into Reg 1 (-116 Signed)

// 2. Test the Shift Hardware 
sll 2 1 0x02    // PC=32: Reg 2 = 00110000 (Shift left 2, zeros fill the right)
srl 3 1 0x02    // PC=36: Reg 3 = 00100011 (Shift right 2, zeros fill the left)
sra 4 1 0x02    // PC=40: Reg 4 = 11100011 (Arith shift 2, SIGN BITS fill the left!)
ror 5 1 0x02    // PC=44: Reg 5 = 00100011 (Rotate 2, the '00' on the right wraps)


// PART 3: BNE LOOP (BRANCH IF NOT EQUAL)


// 1. Setup Data for Loop
loadi 6 0x03    // PC=48: Reg 6 = 3 (Our loop counter)
loadi 7 0x00    // PC=52: Reg 7 = 0 (Our target to reach)
loadi 0 0x01    // PC=56: Reg 0 = 1 (Decrement value)

// --- LOOP START ---
sub 6 6 0       // PC=60: Subtract 1 from counter (Reg 6 = Reg 6 - 1)

bne 0xFE 6 7    // PC=64: If Reg 6 != Reg 7, jump BACKWARD 2 instructions!
                //        (Offset 0xFE is -2. PC+4 = 68. Target = 68 - 8 = 60).



// PART 4: BEQ TEST (BRANCH IF EQUAL)


// Because the loop above just finished, we KNOW Reg 6 and Reg 7 both equal 0!
beq 0x02 6 7    // PC=68: If Reg 6 == Reg 7, jump FORWARD 2 instructions!
                //        (Offset 0x02 is +2. PC+4 = 72. Target = 72 + 8 = 80).

// BEQ TRAPS (If your BEQ fails, these will overwrite your registers!)
loadi 6 0xFF    // PC=72:  (Should be skipped)
loadi 7 0xFF    // PC=76:  (Should be skipped)



// PART 6: BONUS MULTIPLIER TEST

loadi 1 0x05    // Load 5 into Reg 1
loadi 2 0x06    // Load 6 into Reg 2
mult 4 1 2      // Reg 4 = 5 * 6 (Result should be 30, which is 0x1E in Hex!)



// PART 5: UNCONDITIONAL JUMP TEST (J)

j 0x02          // PC=80: Unconditional jump FORWARD 2 instructions
                //        (Offset 0x02 is +2. PC+4 = 84. Target = 84 + 8 = 92).

// JUMP TRAPS
loadi 2 0xEE    // PC=84:  (Should be skipped)
loadi 3 0xEE    // PC=88:  (Should be skipped)

// The Jump should safely land the CPU exactly here.
mov 0 0         // PC=92: Dummy instruction to catch the CPU