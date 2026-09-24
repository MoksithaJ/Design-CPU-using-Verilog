// E/22/159 , E/22/004
//shift_unit.v
`timescale 1ns/100ps

// THE SHARED SHIFT UNIT
module shift_unit(
    input  [7:0] data1,   // The register to shift
    input  [7:0] data2,   // The change  immediate for shift operation
    output reg [7:0] out
);
    // Extract the shift type and the shift amount from the single wire
    wire [1:0] shift_type = data2[7:6]; 
    wire [2:0] shamt      = data2[2:0];

    always @(*) begin
        #1
        case(shift_type)
            2'b00: begin // SLL (Shift Left Logical)
                case(shamt)
                    3'd0: out = data1;
                    3'd1: out = {data1[6:0], 1'b0};
                    3'd2: out = {data1[5:0], 2'b00};
                    3'd3: out = {data1[4:0], 3'b000};
                    3'd4: out = {data1[3:0], 4'b0000};
                    3'd5: out = {data1[2:0], 5'b00000};
                    3'd6: out = {data1[1:0], 6'b000000};
                    3'd7: out = {data1[0], 7'b0000000};
                endcase
                
            end
            
            2'b01: begin // SRL (Shift Right Logical)
                case(shamt)
                    3'd0: out = data1;
                    3'd1: out = {1'b0, data1[7:1]};
                    3'd2: out = {2'b00, data1[7:2]};
                    3'd3: out = {3'b000, data1[7:3]};
                    3'd4: out = {4'b0000, data1[7:4]};
                    3'd5: out = {5'b00000, data1[7:5]};
                    3'd6: out = {6'b000000, data1[7:6]};
                    3'd7: out = {7'b0000000, data1[7]};
                    
                endcase
            end

            2'b10: begin // SRA (Shift Right Arithmetic - Copy Sign Bit)
                case(shamt)
                    3'd0: out = data1;
                    3'd1: out = {data1[7], data1[7:1]};
                    3'd2: out = {{2{data1[7]}}, data1[7:2]};
                    3'd3: out = {{3{data1[7]}}, data1[7:3]};
                    3'd4: out = {{4{data1[7]}}, data1[7:4]};
                    3'd5: out = {{5{data1[7]}}, data1[7:5]};
                    3'd6: out = {{6{data1[7]}}, data1[7:6]};
                    3'd7: out = {{7{data1[7]}}, data1[7]};
                endcase
            end

            2'b11: begin // ROR (Rotate Right - Loop bits around)
                case(shamt)
                    3'd0: out = data1;
                    3'd1: out = {data1[0], data1[7:1]};
                    3'd2: out = {data1[1:0], data1[7:2]};
                    3'd3: out = {data1[2:0], data1[7:3]};
                    3'd4: out = {data1[3:0], data1[7:4]};
                    3'd5: out = {data1[4:0], data1[7:5]};
                    3'd6: out = {data1[5:0], data1[7:6]};
                    3'd7: out = {data1[6:0], data1[7]};
                endcase
            end
        endcase
    end
endmodule