/*
Module  : Instruction Cache
Group   : group04
Date    : 2026

Description:

Direct-mapped, read-only instruction cache for CO2070 Lab 7.

    - Cache size        : 128 Bytes
    - Block size         : 16 Bytes  -> 8 blocks/lines
    - Placement           : Direct-mapped
    - Word size            : 4 Bytes (32-bit instructions)
    - Instruction memory : 1024 Bytes (256 words), accessed by the cache
                            using a 6-bit block address (Tag++Index)

Address (10 bits, the two LSBs of a word address are always 0 since
instructions are word aligned):

    9        7 6      4 3        0
   +----------+---------+----------+
   |   TAG    |  INDEX  |  OFFSET  |
   +----------+---------+----------+
     (3 bits)   (3 bits)  (4 bits)

The OFFSET's top 2 bits ([3:2]) select which of the 4 words inside the
16-Byte block is being requested; the bottom 2 bits ([1:0]) are always 0
because the CPU only ever fetches whole, word-aligned instructions.

Since the CPU never writes to instruction memory, there is no dirty bit and
no write-back logic -- a cache line can simply be overwritten (discarded) on
a miss.

This module follows exactly the same FSM / timing style used in the data
cache (dcache.v) from Lab 6, just simplified for read-only access.
*/
`timescale 1ns/100ps
module icache (
    input clock,
    input reset,

    // CPU Interface
    input read,                    // CPU is always fetching, tie to 1'b1 in the testbench
    input [9:0] address,           // word address coming from the PC (address[1:0] == 00)
    output reg [31:0] readinst,    // instruction word returned to the CPU
    output busywait,               // stalls the CPU (BUSYWAIT) on a miss

    // Memory Interface
    output reg mem_read,
    output reg [5:0] mem_address,
    input [127:0] mem_readinst,
    input mem_busywait
);

    // Split the 10-bit address into Tag, Index and Offset
    wire [2:0] tag    = address[9:7];
    wire [2:0] index  = address[6:4];
    wire [3:0] offset = address[3:0];      // offset[3:2] = word-select inside the block

    // Cache Storage Arrays (8 blocks, each holding 128 bits / 16 Bytes)
    reg [127:0] cache_data [0:7];
    reg [2:0]   cache_tag  [0:7];
    reg         valid_bit  [0:7];

    // Extraction with artificial latency of #1
    wire valid;
    wire [2:0]   stored_tag;
    wire [127:0] stored_block;

    assign #1 valid       = valid_bit[index];
    assign #1 stored_tag  = cache_tag[index];
    assign #1 stored_block = cache_data[index];

    // Tag Comparison with artificial latency of #0.9
    wire tag_match;
    assign #0.9 tag_match = (tag == stored_tag);

    // Hit Detection
    wire hit;
    assign hit = valid ? tag_match : 1'b0;

    // CPU Busywait Logic: stall the CPU while we are fetching and haven't hit yet
    assign busywait = read ? !hit : 1'b0;

    // Asynchronous Read Hit Logic (Latency #1) -- selects the requested word
    // from the block; this runs in parallel to the tag comparison above.
    always @(*) begin
        #1;
        case(offset[3:2])
            2'b00: readinst = stored_block[31:0];
            2'b01: readinst = stored_block[63:32];
            2'b10: readinst = stored_block[95:64];
            2'b11: readinst = stored_block[127:96];
        endcase
    end

    /* Cache Controller FSM Start */

    parameter IDLE = 2'b00, MEM_READ = 2'b01, CACHE_UPDATE = 2'b10;
    reg [1:0] state, next_state;

    // combinational next state logic
    always @(*)
    begin
        case (state)
            IDLE:
                if (read && !hit)
                    next_state = MEM_READ;     // Miss detected, start fetching from instruction memory
                else
                    next_state = IDLE;

            MEM_READ:
                if (!mem_busywait)
                    next_state = CACHE_UPDATE; // Memory fetch done (after 80 cycles), update internal arrays
                else
                    next_state = MEM_READ;     // Keep waiting/holding signals stable

            CACHE_UPDATE:
                next_state = IDLE;             // Return to IDLE so the async hit logic re-evaluates

            default:
                next_state = IDLE;
        endcase
    end

    // combinational output logic
    always @(*)
    begin
        mem_read    = 1'b0;
        mem_address = 6'dx;
        case(state)
            IDLE: begin
                // nothing to do, waiting for a miss
            end

            MEM_READ: begin
                // Assert READ as soon as the miss is detected and keep the
                // block address stable until the memory de-asserts busywait
                mem_read    = 1'b1;
                mem_address = {tag, index};
            end

            CACHE_UPDATE: begin
                mem_read    = 1'b0;
                mem_address = 6'dx;
            end
        endcase
    end

    // sequential logic for state transitioning and cache-line update
    integer i;
    always @(posedge clock or posedge reset)
    begin
        if (reset) begin
            state <= IDLE;
            // Wipe the cache clean on reset
            for (i = 0; i < 8; i = i + 1) begin
                valid_bit[i] <= 1'b0;
                cache_tag[i] <= 3'd0;
                cache_data[i] <= 128'd0;
            end
        end
        else begin
            state <= next_state;

            // Cache Update Logic - on the clock edge the 80-cycle memory
            // fetch completes, latch the fetched 16-Byte block into the
            // indexed cache entry and update its tag/valid bit.
            if (state == MEM_READ && !mem_busywait) begin
                #1;                              // Artificial write latency
                cache_data[index] <= mem_readinst;
                cache_tag[index]  <= tag;
                valid_bit[index]  <= 1'b1;
            end
        end
    end
    /* Cache Controller FSM End */

endmodule
