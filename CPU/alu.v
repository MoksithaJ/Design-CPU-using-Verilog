// E/22/004
// E/22/159
//alu.v

`timescale 1ns/100ps

// AND FUNCTIONAL UNIT this performs bitwise AND between DATA1 and DATA2 and Artificial delay = #1 time unit

module and_unit(
    input  [7:0] data1,  // 8-bit input bus
    input  [7:0] data2,  // 8-bit input bus
    output [7:0] out     // 8-bit output bus
);
    assign #1 out = data1 & data2; // add 1ns delay and do data1 & data2

endmodule

// ADD FUNCTIONAL UNIT this function adds DATA1 and DATA2 and Artificial delay = #2 time units

module add_unit(
    input  [7:0] data1,  // 8-bit input bus
    input  [7:0] data2,  // 8-bit input bus
    output [7:0] out     // 8-bit output bus
);
    assign #2 out = data1 + data2; // add 1ns delay and do data1 + data2

endmodule

// OR FUNCTIONAL UNIT this function performs bitwise OR between DATA1 and DATA2 and Artificial delay = #1 time unit

module or_unit(
    input  [7:0] data1,  // 8-bit input bus
    input  [7:0] data2,  // 8-bit input bus
    output [7:0] out     // 8-bit output bus
);
    assign #1 out = data1 | data2; // add 1ns delay and do data1 | data2

endmodule

// FORWARD FUNCTIONAL UNIT this function forwards DATA2 directly to output and Used by MOV and LOADI instructions uses artificial delay = #1 time unit

module Forward_unit(
    input  [7:0] data1,  // 8-bit input bus
    input  [7:0] data2,  // 8-bit input bus
    output [7:0] out     // 8-bit output bus
);
    assign #1 out = data2; // add 1ns delay and assign data2 to output

endmodule

// ALU MODULE
//
// SELECT = 000 means FORWARD
// SELECT = 001 means ADD
// SELECT = 010 means AND
// SELECT = 011 means OR
// SELECT = 1XX means RESERVED
//
// The ALU instantiates all functional units and uses a multiplexer which implemented using a case statement which to choose the required output.
module mult_unit(
    input  [7:0] data1,  // 8-bit input bus
    input  [7:0] data2,  // 8-bit input bus
    output [7:0] out     // 8-bit output bus
);
    // Generate 8 partial products
    // If the bit in data1 is 1, keep data2 shifted by the bit's position.
    // If the bit in data1 is 0, the partial product is just 0.
    wire [7:0] pp0 = data1[0]?data2       : 8'd0;
    wire [7:0] pp1 = data1[1]?data2 <<1  : 8'd0;
    wire [7:0] pp2 = data1[2]?data2 << 2  : 8'd0;
    wire [7:0] pp3 = data1[3]? data2 << 3  : 8'd0;
    wire [7:0] pp4 = data1[4] ?data2 << 4  : 8'd0;
    wire [7:0] pp5 = data1[5] ? data2 <<5  : 8'd0;
    wire [7:0] pp6 = data1[6] ?data2 << 6  : 8'd0;
    wire [7:0] pp7 = data1[7] ? data2 << 7  : 8'd0;
    // Sum all partial products together with the proper artificial delay
    assign #2 out = pp0 + pp1 + pp2 + pp3 + pp4 +pp5 +pp6 + pp7;

endmodule


module alu(DATA1, DATA2, RESULT, SELECT,ZERO);

    // INPUT and OUTPUT PORT DECLARATIONS
    input [7:0] DATA1,DATA2;
    input [2:0] SELECT;
    output reg [7:0] RESULT;
    output reg ZERO;

    // Internal wires to hold outputs from functional units
    wire [7:0] fwd_res, add_res, and_res, or_res,su_res, mult_res;

    // Instantiate functional units Each unit continuously computes its result.
    Forward_unit  fu (.data2(DATA2), .out(fwd_res));
    add_unit      au (.data1(DATA1), .data2(DATA2), .out(add_res));
    and_unit      andu (.data1(DATA1), .data2(DATA2), .out(and_res));
    or_unit       ou (.data1(DATA1), .data2(DATA2), .out(or_res));
    shift_unit  su (.data1(DATA1), .data2(DATA2), .out(su_res));
    mult_unit   mu (.data1(DATA1), .data2(DATA2), .out(mult_res));
    // MUX Logic to select the correct functional unit output
    always @(*) begin
        case (SELECT)
            3'b000: RESULT = fwd_res; // FORWARD
            3'b001: RESULT = add_res; // ADD
            3'b010: RESULT = and_res; // AND
            3'b011: RESULT = or_res;  // OR
            3'b100: RESULT = su_res; //shift
            3'b101: RESULT = mult_res;
            default: RESULT = 8'b00000000; // Handle reserved/unused bit combinations
        endcase
        // This updates instantly whenever the RESULT changes.
        if (RESULT == 8'b00000000) begin
            ZERO = 1'b1;
        end 
        else begin
            ZERO = 1'b0;
        end
    end

    



endmodule