`timescale 1ns/100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Depatment of Computer Engineering
// Engineer: E/22/159 , E/22/004
// Create Date: 05/31/2026 05:36:37 PM
// Design Name: Building a Simple Processor Integration & Control
// Module Name: cpu
// Project Name: LAB 03
///////////////////////////////////////////////////////////////////////////////////

//cpu.v
//  PC,Current instruction from instruction memory,Clock signal,Reset signal
// This is the main CPU core module. It acts as the structural top-level datapath 
// that integrates our register file, ALU, control logic, and program counter.
module cpu(
output reg [31:0] PC, input [31:0] INSTRUCTION ,input CLK,input RESET,input BUSYWAIT,

    output reg MEMORY_READ,
    output reg MEMORY_WRITE,
    output [7:0] MEMORY_ADDRESS,
    output [7:0] MEMORY_WRITEDATA,
    input  [7:0] MEMORY_READDATA
    );

// PC 32-bit Program Counter tracking the current instruction addre
// INSTRUCTION 32-bit - instruction word fetched from Instruction Memory (IMEM)
// CLK - Main system clock signal driving sequential state updates
// RESET - Master reset signal to force the CPU into a known initial state

// Control Signals    

    // Instruction Fields Extracted cleanly via combinational wire assignments
    wire [7:0] OPCODE;         // 8-bit operational code determines what type of hardware instruction to run
    wire [7:0] IMMEDIATE;      // 8-bit constant immediate value encoded directly inside the instruction
    wire [2:0] WRITEREG;       // 3-bit address pointing to the Destination Register to be written into
    wire [2:0] READREG1;       // 3-bit address pointing to Source Register 1 (Rs) for reading Operand A
    wire [2:0] READREG2;       // 3-bit address pointing to Source Register 2 (Rt) for reading Operand B
    
    // Datapath Interconnect Busses

    wire [7:0] REGOUT1;        // 8-bit data bus carrying the contents of Register[Rs] out of Port 1
    wire [7:0] REGOUT2;        // 8-bit data bus carrying the contents of Register[Rt] out of Port 2
    wire [7:0] ALURESULT;      // 8-bit data bus routing the final arithmetic/logical output back to the write port
   
    // Control Signals Declared as reg because they are targets of procedural assignments inside an always block

    reg WRITEENABLE;           // Control flag Activates synchronous write-back to the register file
    reg [2:0] ALUOP;           // 3-bit execution vector: Instructs the ALU which mathematical primitive to trigger
    reg is_sub;                // MUX select line Forces execution of a twos complement step on Operand B
    reg use_immediate;         // MUX select line Determines if ALU Input B reads a register value or a constant
    reg is_memory_read;
    // Control-Flow (Branching/Jumping) Control Network Flags

    reg is_branch;             // High when processing a BEQ Branch if Equal instruction
    reg is_jump;               // High when processing an absolute unconditional jump J instruction
    reg is_bne;                // High when processing a BNE Branch if Not Equal instruction
    wire [31:0] next_pc;       // 32-bit target pointer fed directly into the D input of the PC register
    wire ZERO;                 // Dynamic evaluation flag output by the ALU high if ALU result is exactly 0



   

    // Instruction Decoding
  
    // Extract opcode from instruction

    // The Opcode occupies the upper byte of the instruction [Bits 31 down to 24]
    assign OPCODE = INSTRUCTION[31:24];

    // Destination register index lives inside bits [23:16]. We slice only the lowest 3 bits 
    // of this byte because our custom architectural register file only contains 8 registers R0 through R7.
    assign WRITEREG = INSTRUCTION[18:16];  // Bottom 3 bits of the [23:16] field

    // Source register 1 index lives inside bits [15:8]. We slice the lowest 3 bits to read Port 1.
    assign READREG1 = INSTRUCTION[10:8];   // Bottom 3 bits of the [15:8] field Source Register 1 (Rs) index mapping

    // Source register 2 index lives inside bits [7:0]. We slice the lowest 3 bits to read Port 2.
    assign READREG2 = INSTRUCTION[2:0];    // Bottom 3 bits of the [7:0] field Source Register 2 (Rt) index mapping

    // Immediate byte field spans bits [7 down to 0], providing immediate numbers or shift magnitudes.
    assign IMMEDIATE = INSTRUCTION[7:0];

    
    
    // Program Counter Logic
    // PC increments by 4 after every instruction

    
always @(posedge CLK) begin
        //RESET logic
        if(RESET == 1'b1) begin
            #1 PC = 32'd0;
        end else if (!BUSYWAIT) begin
            // Only fetch the next instruction if memory is NOT busy
            #1 PC <= next_pc;
        end 
    end
    
    // Two's Complement Generator that is used for sub instruct

    // Used for subtraction A - B = A + (-B)

    wire [7:0] twos_comp_out;
    assign #1 twos_comp_out = ~REGOUT2 + 8'd1;

    wire [7:0] change_immediate;
    assign change_immediate = (OPCODE == 8'b00001101) ? {2'b00, IMMEDIATE[5:0]} : // SLL
                              (OPCODE == 8'b00001110) ? {2'b01, IMMEDIATE[5:0]} : // SRL
                              (OPCODE == 8'b00001111) ? {2'b10, IMMEDIATE[5:0]} : // SRA
                              (OPCODE == 8'b00010000) ? {2'b11, IMMEDIATE[5:0]} : // ROR
                               IMMEDIATE;
      


  

         
     // selecting OPCODE Control UNIT

     // Small delay added to simulate control unit delay Control unit checks the opcode and generates required control signals for each instruction
    always @(*) begin
        // Simulated internal gate propagation delay of the decoding control matrix.
        #1
        WRITEENABLE = 1'b0;
        ALUOP = 3'b000;
        use_immediate = 1'b0;
        is_sub = 1'b0;
        is_branch = 1'b0;
        is_jump = 1'b0;
        is_bne = 1'b0;
       
        MEMORY_READ =1'b0;
        MEMORY_WRITE = 1'b0;
        is_memory_read = 1'b0;

        case(OPCODE)

            // ADD Instruction: Reg[Rd] = Reg[Rs] + Reg[Rt]
            8'b00000010: begin
                WRITEENABLE = 1'b1;  // Allow write-back to register file on next clock cycle
                ALUOP = 3'b001;      // Point the ALU operational selection matrix to ADD
                use_immediate = 1'b0; // Route Register File Output 2 to the ALU, not the constant
                is_sub = 1'b0;       // Ensure normal non-inverted register contents are used
             end

            // SUB Instruction: Reg[Rd] = Reg[Rs] - Reg[Rt]
             8'b00000011: begin
                WRITEENABLE = 1'b1;  // Allow writeback
                ALUOP = 3'b001;      // Keep ALU in ADD mode because subtraction is done via 2's complement hardware
                use_immediate = 1'b0; // Reading from register source
                is_sub = 1'b1;       // Flip MUX select line to route inverted 2's complement value into ALU Input B
             end

             // MOV / FORWARD Instruction: Reg[Rd] = Reg[Rs]
             8'b00000001: begin
                WRITEENABLE = 1'b1;  // Allow destination update
                ALUOP = 3'b000;      // Put ALU into bypass mode (Pass Input A directly to output)
                use_immediate = 1'b0; 
                is_sub = 1'b0;
             end

            // Bitwise AND Instruction: Reg[Rd] = Reg[Rs] & Reg[Rt]
             8'b00000100: begin
                WRITEENABLE = 1'b1;
                ALUOP = 3'b010;      // Point ALU execution map to the bitwise AND hardware block
                use_immediate = 1'b0;
                is_sub = 1'b0;
             end

            // Bitwise OR Instruction: Reg[Rd] = Reg[Rs] | Reg[Rt]
             8'b00000101: begin
                WRITEENABLE = 1'b1;
                ALUOP = 3'b011;      // Point ALU execution map to the bitwise OR hardware block
                use_immediate = 1'b0;
                is_sub = 1'b0;
             end

             // LOADI Instruction: Reg[Rd] = 8-bit Immediate Constant
             8'b00000000: begin
                WRITEENABLE = 1'b1;  // Allow register file save
                ALUOP = 3'b000;      // Run ALU bypass so the incoming immediate constant passes straight through
                use_immediate = 1'b1; // Switch MUX to completely isolate Reg File Port 2 and pick up immediate instead
                is_sub = 1'b0;
             end
             
            // BEQ (Branch if Equal) Instruction: if(Reg[Rs] == Reg[Rt]) branch to target offset
            8'b00000111: begin
                WRITEENABLE = 1'b0; // NEVER let write-enable assert during a branch to protect register memory states
                ALUOP = 3'b001;     // Forces an addition inside the ALU core
                use_immediate = 1'b0; 
                is_sub = 1'b1;      // Routes 2's complement of register 2. A-B=0 sets the ALU ZERO flag high.
                is_branch = 1'b1;   // Armed branch check line
             end

            // BNE (Branch if Not Equal) Instruction: if(Reg[Rs] != Reg[Rt]) branch to target offset
            8'b00001100: begin
                WRITEENABLE = 1'b0; // Absolute protection against accidental writes during branching
                ALUOP = 3'b001;     // Run subtraction using adder hardware
                use_immediate = 1'b0;
                is_sub = 1'b1;      // Route 2's complement into ALU B input
                is_branch = 1'b0;   
                is_bne = 1'b1;      // Armed alternative branch check line
             end

            // J (Absolute direct jump): Jump immediately to program location
            8'b00000110: begin
                WRITEENABLE = 1'b0; // Direct bypass of register file writeback
                ALUOP = 3'b000;     // ALU results do not matter here
                use_immediate = 1'b0; 
                is_sub = 1'b0;
                is_branch = 1'b0;
                is_jump = 1'b1;     // Overrides the standard PC processing track to force a jump execution
            end

            // Shifter Core Instructions (SLL, SRL, SRA, ROR)
            // All four opcodes share ALUOP 3'b100 because they all call the same internal Shifter Unit.
            
            // SLL (Shift Left Logical)
            8'b00001101: begin
                WRITEENABLE = 1'b1;
                ALUOP = 3'b100;
                use_immediate = 1'b1; // Requires the conditioned shift constant input from change_immediate
             end

            // SRL (Shift Right Logical)
            8'b00001110: begin
                WRITEENABLE = 1'b1;
                ALUOP = 3'b100;
                use_immediate = 1'b1;
             end

            // SRA (Shift Right Arithmetic)
            8'b00001111: begin
                WRITEENABLE = 1'b1;
                ALUOP = 3'b100;
                use_immediate = 1'b1;
             end

            // ROR (Rotate Right)
            8'b00010000: begin
                WRITEENABLE = 1'b1;
                ALUOP = 3'b100;
                use_immediate = 1'b1;
             end

            // Reserved opcode slot for future lab manual custom instruction specifications
            8'b00010001: begin
                WRITEENABLE = 1'b1;   
                ALUOP = 3'b101;      
                use_immediate = 1'b0; 
                is_sub = 1'b0;
                is_branch = 1'b0;
                is_jump = 1'b0;
                is_bne = 1'b0;
             end
             //lwd
            8'b00001000: begin   
                ALUOP = 3'b000;      
                WRITEENABLE = 1'b1;
                MEMORY_READ = 1'b1;
                is_memory_read = 1'b1;

            end
            //swd
            8'b00001010: begin   
                ALUOP = 3'b000;      
                
                MEMORY_WRITE = 1'b1;

            end
            //lwi
            8'b00001001: begin   
                ALUOP = 3'b000;      
                use_immediate = 1'b1;
                MEMORY_READ= 1'b1;
                WRITEENABLE = 1'b1;
                is_memory_read = 1'b1;

            end
            //swi
            8'b00001011: begin   
                ALUOP = 3'b000;  
                use_immediate = 1'b1;
                
                MEMORY_WRITE = 1'b1;

            end

             // System Safety Catch: If a corrupted or illegal opcode is detected, lock out the 
             // register write-enable lines to guarantee system data safety.
             default: begin 
                WRITEENABLE = 1'b0;
                ALUOP = 3'b000;
                use_immediate = 1'b0;
                is_sub = 1'b0;
            end
        endcase
       
    end
    
    // Multiplexer Section
    wire [7:0] mux1_out;
    wire [7:0] alu_mux_out;

    // MUX 1: Choose Two's Complement if is_sub is true else choose normal REGOUT2
    assign mux1_out = is_sub ? twos_comp_out : REGOUT2;

    // MUX 2: Choose IMMEDIATE if use_immediate is true else choose mux1_out
    assign alu_mux_out = use_immediate ? change_immediate : mux1_out;
     // The MUX
    wire [7:0] data_memory_mux;
    assign data_memory_mux = is_memory_read ? MEMORY_READDATA : ALURESULT;
    wire safe_write_enable = WRITEENABLE & ~BUSYWAIT;
    reg_file register_file (
        .WRITEDATA(data_memory_mux),   // The answer from the ALU loop
        .REGOUT1(REGOUT1),       // Output wire 1
        .REGOUT2(REGOUT2),       // Output wire 2
        .WRITEREG(WRITEREG),     // The RD address from the instruction
        .READREG1(READREG1),     // The RT address from the instruction
        .READREG2(READREG2),     // The RS address from the instruction
        .WRITEENABLE(safe_write_enable), // From your Control Unit
        .CLK(CLK),               // The main system clock
        .RESET(RESET)            // The main system reset
    );

    // ALU Instance
    alu ALU (
        // First ALU input
        .DATA1(REGOUT1),         // Directly from the Register File output 1
        // Second ALU input
        .DATA2(alu_mux_out),     // From your final MUX (either Reg2, Immed, or Two's Comp)
        // ALU output
        .RESULT(ALURESULT),      // This wire shoots the answer back to WRITEDATA!
        // ALU operation select
        .SELECT(ALUOP)    ,       // From your Control Unit
    
        .ZERO(ZERO)
    );
    

    // The target branching offset byte lives securely within instruction bits [23:16]
    wire [7:0] OFFSET = INSTRUCTION[23:16];
    
    // Combinational evaluation gate logic to establish branch verification:
    // Takes the branch path if: (Instruction is BEQ AND operands matched) OR (Instruction is BNE AND operands mismatched)
    wire branch_taken;
    assign branch_taken = (is_branch & ZERO) || (is_bne & ~ZERO);
    
    // Master routing flag: We divert execution flow away from normal sequential order if a branch resolves true OR a jump is loaded
    wire take_jump_path = branch_taken || is_jump;

    // Sign Extension Logic Block: Scaler expansion from 8 bits to a full 32-bit machine word.
    // We replicate the original sign bit (MSB index 7 of the offset) exactly 24 times to fill 
    // out the higher positions, preserving signed value continuity across operations.
    wire [31:0] sign_extended_offset = {{24{OFFSET[7]}}, OFFSET};
    
    // Bit Alignment: Arithmetic barrel-shifting left by 2 positions. This scales the index word 
    // offset up into full byte-address spaces since every instruction occupies 4 distinct bytes in memory.
    wire [31:0] shifted_offset = sign_extended_offset << 2;

    // Dedicated Adders to prevent stalling the main execution engine or using the primary ALU for program index calculations
    wire [31:0] pc_plus_4;
    wire [31:0] target_address;

    // Next sequential instruction memory lookup boundary. Increments by 4 bytes (Latency #1 matches simulation specification)
    assign #1 pc_plus_4 = PC + 32'd4;

    // PC-Relative Branch Target calculation: Evaluates target by adding the shifted offset to the NEXT instruction index ($PC + 4$).
    // Latency is set to #2 to wait for the sequential increment value ($PC + 4$) to finish resolving first.
    assign #2 target_address = pc_plus_4 + shifted_offset;

    // Final Program Counter Destination Multiplexer: Diverts execution flow into the calculated branch/jump target index 
    // if the control flag network resolves high; otherwise, lets the system advance to the next instruction in memory ($PC + 4$).
    assign next_pc = take_jump_path ? target_address : pc_plus_4;




// Route the ALU result to the Data Memory address port
    assign MEMORY_ADDRESS = ALURESULT;
    
    // Route the data from Source Register 1 (RT) to the Data Memory write port
    assign MEMORY_WRITEDATA = REGOUT1;

   
endmodule