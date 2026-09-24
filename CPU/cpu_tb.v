// Computer Architecture (CO2070) - Lab 7
// Design: Testbench for CPU + Instruction Cache/Memory + Data Cache/Memory
// Group: group04
`timescale 1ns/100ps
module cpu_tb;

    reg CLK, RESET;
    wire [31:0] PC;
    wire [31:0] INSTRUCTION;

    // --- WIRES BETWEEN CPU AND INSTRUCTION CACHE ---
    wire ic_busywait;

    // --- WIRES BETWEEN INSTRUCTION CACHE AND INSTRUCTION MEMORY ---
    wire imem_read;
    wire [5:0] imem_address;
    wire [127:0] imem_readinst;
    wire imem_busywait;

    // --- WIRES BETWEEN CPU AND DATA CACHE ---
    wire cpu_read;
    wire cpu_write;
    wire [7:0] cpu_address;
    wire [7:0] cpu_writedata;
    wire [7:0] cpu_readdata;
    wire dc_busywait;

    // --- WIRES BETWEEN DATA CACHE AND MAIN DATA MEMORY ---
    wire mem_read;
    wire mem_write;
    wire [5:0] mem_address;
    wire [31:0] mem_writedata;
    wire [31:0] mem_readdata;
    wire mem_busywait;

    // The CPU is stalled if EITHER the instruction cache or the data cache
    // is busy servicing a miss.
    wire cpu_busywait = ic_busywait | dc_busywait;

    integer j;
    integer c;

    /*
    -----
     CPU
    -----
    */
    cpu mycpu(
        .PC(PC),
        .INSTRUCTION(INSTRUCTION),
        .CLK(CLK),
        .RESET(RESET),
        .BUSYWAIT(cpu_busywait),         // Listens to both caches
        .MEMORY_READ(cpu_read),          // Talks to Data Cache
        .MEMORY_WRITE(cpu_write),        // Talks to Data Cache
        .MEMORY_ADDRESS(cpu_address),    // Talks to Data Cache
        .MEMORY_WRITEDATA(cpu_writedata),// Talks to Data Cache
        .MEMORY_READDATA(cpu_readdata)   // Listens to Data Cache
    );

    /*
    -------------------
     INSTRUCTION CACHE
    -------------------
    */
    icache my_icache(
        .clock(CLK),
        .reset(RESET),

        // CPU Facing Ports -- the CPU is always trying to fetch the
        // instruction at the current PC, so read is tied high.
        .read(1'b1),
        .address(PC[9:0]),
        .readinst(INSTRUCTION),
        .busywait(ic_busywait),

        // Memory Facing Ports
        .mem_read(imem_read),
        .mem_address(imem_address),
        .mem_readinst(imem_readinst),
        .mem_busywait(imem_busywait)
    );

    /*
    --------------------
     INSTRUCTION MEMORY
    --------------------
    */
    instruction_memory my_imem(
        .clock(CLK),
        .read(imem_read),          // Listens to Instruction Cache
        .address(imem_address),    // Listens to Instruction Cache
        .readinst(imem_readinst),  // Talks to Instruction Cache
        .busywait(imem_busywait)   // Talks to Instruction Cache
    );

    /*
    ------------
     DATA CACHE
    ------------
    */
    dcache my_cache(
        .clock(CLK),
        .reset(RESET),

        // CPU Facing Ports
        .read(cpu_read),
        .write(cpu_write),
        .address(cpu_address),
        .writedata(cpu_writedata),
        .readdata(cpu_readdata),
        .busywait(dc_busywait),

        // Memory Facing Ports
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_address(mem_address),
        .mem_writedata(mem_writedata),
        .mem_readdata(mem_readdata),
        .mem_busywait(mem_busywait)
    );

    /*
    -----------------
     MAIN DATA MEMORY
    -----------------
    */
    data_memory my_data_mem (
        .clock(CLK),
        .reset(RESET),
        .read(mem_read),            // Listens to Data Cache
        .write(mem_write),          // Listens to Data Cache
        .address(mem_address),      // Listens to Data Cache
        .writedata(mem_writedata),  // Listens to Data Cache
        .readdata(mem_readdata),    // Talks to Data Cache
        .busywait(mem_busywait)     // Talks to Data Cache
    );

    initial
    begin

        // generate files needed to plot the waveform using GTKWave
        $dumpfile("cpu_wavedata.vcd");
        $dumpvars(0, cpu_tb);

        for (j = 0; j < 8; j = j + 1) begin
            $dumpvars(1, mycpu.register_file.registers[j]);
        end

        for (c = 0; c < 8; c = c + 1) begin
            $dumpvars(1, my_icache.cache_data[c]);
            $dumpvars(1, my_icache.cache_tag[c]);
            $dumpvars(1, my_icache.valid_bit[c]);
        end

        CLK = 1'b0;
        RESET = 1'b0;

        // Reset the CPU (pulse RESET) to start program execution
        RESET = 1'b1;
        #5;
        RESET = 1'b0;

        // finish simulation after some time
        #6000
        $display("\n====================================================");
        $display("             FINAL INSTRUCTION CACHE STATE          ");
        $display("====================================================");
        $display("Index | Valid | Tag | Data (Hex)");
        $display("----------------------------------------------------");
        for (j = 0; j < 8; j = j + 1) begin
            $display("  %d   |   %b   |  %d  | %h",
                     j,
                     my_icache.valid_bit[j],
                     my_icache.cache_tag[j],
                     my_icache.cache_data[j]);
        end
        $display("====================================================\n");

        $display("====================================================");
        $display("                 FINAL REGISTER FILE                ");
        $display("====================================================");
        for (j = 0; j < 8; j = j + 1) begin
            $display("  R%d = %d (0x%h)", j,
                      mycpu.register_file.registers[j],
                      mycpu.register_file.registers[j]);
        end
        $display("====================================================\n");

        $finish;

    end

    // clock signal generation (period = 8ns, matches the 5ns/byte * 16 = 80
    // cycle instruction memory fetch latency assumed by the lab handout)
    always
        #4 CLK = ~CLK;

endmodule
