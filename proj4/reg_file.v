
`timescale 1ns / 1ps

/*
 * File: reg_file.v
 * ----------------
 * This file simulates the 32 general register file of MIPS CPU.
 */


`include "newDefine.h"

module reg_file(

	input wire start,
	input wire[31:0] wb_data,			// data to be write into the destination register
	input wire[31:0] pc,				// for jal return address recording
	input wire[4:0] rs_num,
	input wire[4:0] rt_num,
	input wire[4:0] WriteRegW,
	input wire[0:0] RegWriteW,			// write back enable - which triggers the write back
	input wire[0:0] jumpD,				// for jal return address recording

	output reg[31:0] rs,
	output reg[31:0] rt

	);


	reg[31:0] gr[31:0];					// 32 general registers




////*** main module ***////

// set the value of gr0 to zero when the module start to function

always @(start) 
	begin
		gr[`gr0] = 32'h0000_0000;
		gr[`gr8] = 32'h0000_0008;
		gr[`gr9] = 32'h0000_0009;
		gr[`gr10] = 32'h0000_000a;
		gr[`gr11] = 32'h0000_000b;
		gr[`gr12] = 32'h0000_000c;
		gr[`gr13] = 32'h0000_000d;
		gr[`gr14] = 32'h0000_000e;
		gr[`gr15] = 32'h0000_000f;
		gr[`gr16] = 32'h0000_0010;
		gr[`gr17] = 32'h0000_0011;
		gr[`gr18] = 32'h0000_0012;
		gr[`gr19] = 32'h0000_0013;
		gr[`gr20] = 32'h0000_0014;
		gr[`gr21] = 32'h0000_0015;
		gr[`gr22] = 32'h0000_0016;
		gr[`gr23] = 32'h0000_0017;
		gr[`gr24] = 32'h0000_0018;
		gr[`gr25] = 32'h0000_0019;
	end


// when positive edge of clock arrives, if write back enable is true, write the data into the 
// note that only under write operation will the CLK signal input come into effect

always @(wb_data) 						
	begin
		if (RegWriteW) 
			begin
				gr[WriteRegW] = wb_data;			// if write back needed, write the data into the given number of destination register
			end 								
	end


// during read operation, the register file perform as combinational circuit

always @(rs_num, rt_num) begin

	rs = gr[rs_num];
	rt = gr[rt_num];

end


always @(jumpD) begin

	if (jumpD)	gr[`gr31] = pc;

end



endmodule
