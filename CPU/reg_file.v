// E/22/004
// E/22/159

// REGISTER FILE MODULE

//  8 registers (Register 0 to Register 7)
//  Each register stores 8 bits of data
//  Two asynchronous read ports
//  One synchronous write port
//  Synchronous reset
// Delays required by the lab Read delay  = #2 Write delay = #1 Reset delay = #1

`timescale 1ns/100ps
module reg_file (
    // INPUT DATA POR WRITEDATA contains the value that will be written into the register selected by WRITEREG.

    input [7:0] WRITEDATA,

    // OUTPUT DATA PORTS
    // REGOUT1 returns the value stored in the register selected by READREG1.
    // REGOUT2 returns the value stored in the register selected by READREG2.

    output [7:0] REGOUT1,
    output [7:0] REGOUT2,

    // WRITEREG : Register address for write operation
    // READREG1 : Register address for first read port
    // READREG2 : Register address for second read port

    input [2:0] WRITEREG,
    input [2:0] READREG1,
    input [2:0] READREG2,

    // CONTROL SIGNALS

    // WRITEENABLE : Enables writing to the register file
    // CLK         : System clock
    // RESET       : Synchronous reset signal

    input WRITEENABLE,
    input CLK,
    input RESET
);

    // 8x8 Register array (8 registers, each 8 bits wide)
    reg [7:0] registers [0:7];
    integer i;

    // 1. Asynchronous Read with a delay of #2
    // These continuously assign the output based on the read address.
    // If the address changes, OR if the internal register data changes, 
    // the output updates 2 time units later.
    assign #2 REGOUT1 = registers[READREG1];
    assign #2 REGOUT2 = registers[READREG2];

    // 2. Synchronous Write and Reset on the positive edge of CLOCK
always @(posedge CLK) begin
        if (RESET) begin
            // Reset registers with a delay
            #1;
            for (i = 0; i < 8; i = i + 1)
                registers[i] <= 8'b0;
        end 
        else if (WRITEENABLE) begin
            // Perform write with delay
            #1 registers[WRITEREG] <= WRITEDATA;
        end
    end

endmodule
