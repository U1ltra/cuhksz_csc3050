
`timescale 1ns / 1ps

/* 
 * File: instruction_mem.v
 * -----------------------
 * This file exports instruction_mem module which simulates the instruction memory of real machine.
 * Instructions are given in a separated text file. The instrMem module will read the instructions
 * from the file according to the current pc, assuming the first line of the text file is address
 * 0x0000_0000.
 * Note that please remember to modify the path to the file when environment is changed.
 */


 module instrMem(
 	input wire[31:0] 	addr,
 	input wire[0:0]		CLK,

 	output wire[31:0]	out
 	);


 	reg[31:0] instructions[31:0];		// assume that there are less than 32 lines of instructions
 	reg[31:0] A;


 	initial
 	begin
 		$readmemb("/path_to/instructionMem.txt", instructions);
 	end


 	assign out = instructions[addr>>2];

endmodule



