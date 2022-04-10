
`timescale 1ns / 1ps

/*
 * File: hazard.v
 * --------------
 * This file exports a hazard detecting unit, which is basically composed of
 * forwarding unit, stall unit and control hazard handling.
 * This is a combiantional circuit since there is no clock input.
 */


`include "newDefine.h"


module hazard_unit(
	input wire[4:0] rs,					// number of rs regsiter to be fetched by DE stage
	input wire[4:0] rt,					// number of rs regsiter to be fetched by DE stage
	input wire[4:0] rsNum_D,			// number of rs regsiter fetched by EXE stage 
	input wire[4:0] rtNum_D,			// number of rt regsiter fetched by EXE stage 
	input wire[4:0] rdNum_E,			// number of register to be written by MEM stage instruction
	input wire[4:0] rdNum_M,			// number of register to be written by WB stage instruction
	input wire[0:0] RegWriteE,			// even if named E, it stands for whether MEM stage needs to write back
	input wire[0:0] RegWriteM,			// even if named M, it stands for whether WB stage needs to write back
	input wire[0:0] MemtoRegE,			// only be 1 for LW instruciton
	input wire[0:0] branchE,
	input wire[0:0] zero,
	input wire[4:0] rsNum_E,
	input wire[4:0] rtNum_E,
	input wire[0:0] stall,


	output reg[1:0] forward_A,
	output reg[1:0] forward_B,
	output reg[0:0] stallF,
	output reg[0:0] stallD,
	output reg[0:0] flash
	);


initial begin
	forward_A = `_ori;
	forward_B = `_ori;
	stallF = 1'b0;
	stallD = 1'b0;
	flash = 1'b0;

end


//// Forwarding Control ////									// make sure that each control is fully discussed, meaning do not forget the reset the control to 0 when special condition is not met

always @(rsNum_D, rtNum_D, rdNum_E, rdNum_M, RegWriteE, RegWriteM) begin 	// need to use the ending flip flops of last stage 

	if (RegWriteE) begin 										// if MEM stage needs to be written back
		// consider register rs
		if 	(rsNum_D == rdNum_E) 		forward_A = `_fM;		// if rs is the register to be written by MEM stage, forward MEM then. no need to check whether WB will write the same register
		else if (RegWriteM) begin 								// if rs is not, check if WB stage needs to write back to rs
			if 	(rsNum_D == rdNum_M) 	forward_A = `_fW;		// if WB stage needs to write rs, forward control will select forwarded data to be written back
			else begin
				forward_A = `_ori;		// if none of MEM and WB stages are going to write back, select original register value
			end 						
		end

		// consider register rt
		if 	(rtNum_D == rdNum_E)		forward_B = `_fM;		// if rt is the register to be written by MEM stage, forward MEM then. no need to check whether WB will write the same register
		else if (RegWriteM) begin 								// if rt is not and WB stage needs to be written back
			if 	(rtNum_D == rdNum_M)	forward_B = `_fW;		// see if rt is the same register as the one WB is going to write, if yes forward control will forward WB
			else begin
				forward_B = `_ori;		// if rt stands alone, no forwarding happens. therefore forwarding control <code>forward_B</code> is assigned to be <code>`_ori</code>
			end			

		end
	end


	else if (RegWriteM) begin 									// if MEM stage need not to be written back, no forward is needed for MEM stage
																// however, WB stage is still in need of checking
		// check forward condition of rs														
		if 		(rsNum_D == rdNum_M)	forward_A = `_fW;
		else 							forward_A = `_ori;

		// check forward condition of rt
		if (rtNum_D == rdNum_M)			forward_B = `_fW;
		else 							forward_B = `_ori;	
		
	end

	else begin
										forward_A = `_ori;		// if none of MEM and WB stage is going to write register file
										forward_B = `_ori;		// no forward will happen
	end

end



//// Stalling Control ////

always @(rs, rt, rsNum_D, rtNum_D, MemtoRegE, stall) begin
	if (MemtoRegE) begin 										// if EX stage is holding an lw instruction
		
		if (rs == rtNum_D || rt == rtNum_D) begin 				// if either rs or rt of DE stage needs to use the loaded value
		
			stallF = 1'b1;										// used to stall pc
			stallD = 1'b1;										// used to stall IF/DE

		end														// after set stall control to 1, the IF and DE will be stalled for the next clock cycle
		else begin 

			stallF = 1'b0;										// also remember to reset the stall control when there is a LW instruction 
			stallD = 1'b0;										// but no stalling is going to happen

		end

	end
	
	else begin
			stallF = 1'b0;
			stallD = 1'b0;

	end

	if (stall) begin

		stallD = 1'b0;
		stallF = 1'b0;
		
	end
end



//// Control Hazard ////

always @(branchE, zero) begin

	if (branchE && zero) 	flash = 1'b1;
	else 					flash = 1'b0;

end




endmodule

