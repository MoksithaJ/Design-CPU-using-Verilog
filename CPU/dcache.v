/*
Module  : Data Cache 
Author  : Isuru Nawinne, Kisaru Liyanage
Date    : 25/05/2020

Description	:

This file presents a skeleton implementation of the cache controller using a Finite State Machine model. Note that this code is not complete.
*/
`timescale 1ns/100ps
module dcache (
    input clock,
    input reset,
    
    // CPU Interface 
    input read,
    input write,
    input [7:0] address,
    input [7:0] writedata,
    output reg [7:0] readdata,
    output busywait,
    
    // Memory Interface 
    output reg mem_read,
    output reg mem_write,
    output reg [5:0] mem_address,
    output reg [31:0] mem_writedata,
    input [31:0] mem_readdata,
    input mem_busywait
);
    

    
// Split the 8-bit address into Tag, Index, and Offset
    wire [2:0] tag    = address[7:5];
    wire [2:0] index  = address[4:2];
    wire [1:0] offset = address[1:0];
// Cache Storage Arrays (8 blocks, each holding 32 bits / 4 Bytes)
    reg [31:0] cache_data [0:7];
    reg [2:0] cache_tag [0:7];
    reg valid_bit [0:7];
    reg dirty_bit [0:7];

    //  Extraction with artificial latency of #1
    wire valid, dirty;
    wire [2:0] stored_tag;
    wire [31:0] stored_block;

    assign #1 valid = valid_bit[index];
    assign #1 dirty = dirty_bit[index];
    assign #1 stored_tag = cache_tag[index];
    assign #1 stored_block = cache_data[index];

    //  Tag Comparison with artificial latency of #0.9
    wire tag_match;
    assign #0.9 tag_match = (tag == stored_tag);

    // Hit Detection
    wire hit;
    assign hit = valid ? tag_match : 1'b0;

    //CPU Busywait Logic: Stall the CPU if we are reading/writing but haven't hit the data
    assign busywait = (read || write) ? !hit : 0;

    //  Asynchronous Read Hit Logic (Latency #1)
    always @(*) begin
        #1;
        case(offset)
            2'b00: readdata = stored_block[7:0];
            2'b01: readdata = stored_block[15:8];
            2'b10: readdata = stored_block[23:16];
            2'b11: readdata = stored_block[31:24];
        endcase
    end

    /* Cache Controller FSM Start */

    parameter IDLE = 3'b000, MEM_READ = 3'b001, MEM_WRITE = 3'b010, CACHE_UPDATE = 3'b011;
    reg [2:0] state, next_state;

    // combinational next state logic
    always @(*)
    begin
        case (state)
            IDLE:
                if ((read || write) && !dirty && !hit)  
                    next_state = MEM_READ;
                else if ((read || write) && dirty && !hit)
                    next_state = MEM_WRITE; // Dirty miss: must save old data to memory first
                else
                    next_state = IDLE;
            
            MEM_READ:
                if (!mem_busywait)
                    next_state = CACHE_UPDATE; // Memory fetch done, now update internal arrays
                else    
                    next_state = MEM_READ;
            MEM_WRITE:
                if (!mem_busywait)
                    next_state = MEM_READ; // Write-back done, now fetch the new block
                else
                    next_state = MEM_WRITE;
            
            CACHE_UPDATE:
                next_state = IDLE; // Return to IDLE to let the fast brain evaluate the hit
                
        endcase
    end

    // combinational output logic
    always @(*)
    begin
        mem_read = 0;
        mem_write = 0;
        mem_address = 6'dx;
        mem_writedata = 32'dx;
        case(state)
            IDLE:
            begin
              
            end
         
            MEM_READ: 
            begin
                mem_read = 1;
                mem_write = 0;
                mem_address = {tag, index};
                mem_writedata = 32'dx;
                
            end
            MEM_WRITE:
            begin
                mem_write = 1;
                mem_address = {stored_tag, index}; // Write back using the OLD tag currently in the cache
                mem_writedata = stored_block;
            end
            CACHE_UPDATE:
            begin
                mem_read = 0;
                mem_write = 0;
                mem_address = 6'dx;
                mem_writedata = 32'dx;
            end
        endcase
    end

    // sequential logic for state transitioning 
    integer i;
    always @(posedge clock or posedge reset)
    begin
        if(reset)begin
            state <= IDLE;
            // Wipe the cache clean on reset
            for (i = 0; i < 8; i = i + 1) begin
                valid_bit[i] <= 0;
                dirty_bit[i] <= 0;
                cache_tag[i]  <= 3'd0;   
                cache_data[i] <= 32'd0;
            end
        end
        else begin
            state <= next_state;
            
            // Write-Hit Logic-Modify the specific byte inside the 32-bit block
            if (write && hit) begin
                #1; // Artificial latency[cite: 1]
                dirty_bit[index] <= 1; // Mark block as modified[cite: 1]
                case(offset)
                    2'b00: cache_data[index][7:0]   <= writedata;
                    2'b01: cache_data[index][15:8]  <= writedata;
                    2'b10: cache_data[index][23:16] <= writedata;
                    2'b11: cache_data[index][31:24] <= writedata;
                endcase
            end
            
            // Cache Update Logic= Save the 32-bit block fetched from memory
            if (state == CACHE_UPDATE) begin
                #1; // Artificial latency
                cache_data[index] <= mem_readdata; 
                cache_tag[index]  <= tag;          
                valid_bit[index]  <= 1;            
                dirty_bit[index]  <= 0; // Newly fetched block is clea
            end
        end
    end
    /* Cache Controller FSM End */

endmodule