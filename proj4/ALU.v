
`timescale 1ns / 1ps

/*
 * File: ALU.v
 * -----------
 * This file exports the ALU module, which is based on combinational logic.
 */


`include "newDefine.h"

module alu(reg_a, reg_b, ALUCr, c, zero, overflow, negative);


output signed[31:0] c;			// in MIPS the result of ALU will be directly used, so c should be wire type
output signed[0:0] zero, overflow, negative;

input signed[3:0] ALUCr;
input signed[31:0] reg_a, reg_b;


reg[32:0] result;
reg[0:0] zf, nf, of;			// in real MIPS they are just registers

wire[3:0] ALUCr;




// combination logic //

always @(reg_a, reg_b, ALUCr)
begin

	case(ALUCr)										// ALU operations
		`_ADD:	result = reg_a + reg_b;
		`_AND:	result = reg_a & reg_b;
		`_OR:	result = reg_a | reg_b;
		`_XOR:	result = reg_a ^ reg_b;
		`_NOR:	result = ~ (reg_a | reg_b);
		`_SLL:	result = reg_a << reg_b;
		`_SRL:	result = $unsigned(reg_a) >> reg_b;
		`_SRA:	result = reg_a >>> reg_b;
		`_SLT:	result = (reg_a < reg_b) ? 1 : 0;	// no need to consider _USLT
	endcase
	

	zf = result ? 0 : 1;
	nf = result[31];
	of = (result[32] != result[31]) ? 1 : 0;		// when carry out of the most significant bit does not equal to 
													// the carry in to the most significant bit. overflow happens

end


	// parallel assigning syntax //

assign c = result[31:0];
assign zero = zf;								// flag will be set everytime
assign negative = nf;							// but whether they will be used depends on other part of the control
assign overflow = of;


endmodule



