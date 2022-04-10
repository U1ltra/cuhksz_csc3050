
`timescale 1ns / 1ps

/* 
 * File: my_CPU.v
 * --------------
 * This file simulates a pipelined 32 bit CPU.
 * Two main componets are datapath and control unit.
 */


`include "newDefine.h"


module my_CPU(

	input wire CLK,
	input wire start,

	input wire[31:0] i_datain,			// instruction memory data in
	input wire[31:0] d_datain,			// data memory data in

	output wire[31:0] d_dataout,		// data output (to data memory or register file) ???
	output wire[31:0] d_addr,
	output wire[31:0] i_addr,
	output wire[0:0] store

	);

	
	////** Control **////

	// control signal for DE part of pipelined processor //

	wire[0:0] RegWriteD;
	wire[0:0] MemtoRegD;
	wire[0:0] MemWriteD;
	wire[0:0] BranchD;
	wire[3:0] ALUControlD;
	wire[0:0] RegDstD;
	wire[0:0] jumpD;

	// control signal for EX part of pipelined processor //

	reg[0:0] RegWriteE;
	reg[0:0] MemtoRegE;
	reg[0:0] MemWriteE;
	reg[0:0] BranchE;
	reg[3:0] ALUControlE;
	reg[0:0] RegDstE;
	reg[4:0] WriteRegE;



	// control signal for MEM part of pipelined processor //

	reg[0:0] RegWriteM;
	reg[0:0] MemtoRegM;
	reg[0:0] BranchM;
	reg[0:0] PCSrcM;
	

	// control signal for WB part of pipelined processor //

	reg[0:0] RegWriteW;
	reg[0:0] MemtoRegW;



	////** Datapath **////

	// IF stage //

	reg[31:0] pc = 32'h0000_0000;
	reg[31:0] instrIF;

	// DE stage //

	reg[4:0] rs_num;
	reg[4:0] rt_num;				// both could be the destination register
	reg[4:0] rd_num;
	reg[5:0] op;
	reg[5:0] func;
	reg[4:0] shamt;
	reg[15:0] imm;
	reg[25:0] jumpAddr;
	reg[31:0] PCPlus4D;
	wire[31:0] imm_ext;
	wire[31:0] gr1;
	wire[31:0] gr2;
	wire[31:0] reg_a;
	wire[31:0] reg_b;
	wire[31:0] jAddr;

	// EX stage //

	wire[31:0] c;
	wire[0:0] zero;
	wire[0:0] overflow;
	wire[0:0] negative;
	// reg[31:0] reg_C;
	// reg[0:0] zf;
	// reg[0:0] of;
	// reg[0:0] nf;
	reg[31:0] reg_A;
	reg[31:0] reg_B;
	reg[31:0] PCBranch;
	reg[31:0] WriteDataE;

	// MEM stage //

	reg[31:0] ALUOutM;
	reg[4:0] WriteRegM;
	reg[31:0] WriteDataM;
	reg[31:0] ReadData;				// data read for lw insturction, to be written back to the register file in next stage

	// WB stage //

	reg[4:0] WriteRegW;
	reg[31:0] wb_data;


	// hazard unit // 

	wire[1:0] forward_A;
	wire[1:0] forward_B;
	wire[0:0] stallF;
	wire[0:0] stallD;
	wire[0:0] flashB;
	reg[4:0]  rs_numE;
	reg[4:0]  rt_numE;
	reg[0:0] 	stall;



	reg_file REGS(start, wb_data, pc, rs_num, rt_num, WriteRegW, RegWriteW, jumpD, gr1, gr2);

	control CON_DE(op, func, shamt, imm, gr1, gr2, flashB, jumpAddr,
					reg_a, reg_b, RegWriteD, MemtoRegD, MemWriteD, BranchD, ALUControlD, RegDstD, jumpD, imm_ext, jAddr);

	alu ALU_EX(reg_A, reg_B, ALUControlE, c, zero, overflow, negative);			// ALUControlD assign then input???is the same??? no i think this way make things faster but when ALUCon changes, reg_A and reg_B are still unknown so the result is xxxx

	hazard_unit hzd(instrIF[25:21], instrIF[20:16], rs_num, rt_num, WriteRegE, WriteRegM, RegWriteE, RegWriteM, MemtoRegD, BranchE, zero, rs_numE, rt_numE, stall,
				forward_A, forward_B, stallF, stallD, flashB);




/////////////////////////////////
///*/// Pipelined Stages  ///*///
/////////////////////////////////



//// PC updating ////

always @(posedge CLK) begin

	if (!stallF) 								// if stalling is needed, pc will be held the same for this cycle
	begin
		if (BranchE && zero) begin

			pc <= PCBranch;


		end

		else if (jumpD) begin

			pc <= jAddr;

		end

		else begin

			pc <= pc + 32'h0000_0004;			// update pc by 4 if no branch or jump required ?? maybe should set the base to -4?

		end
	end
end



//// fetch instruction ////

always @(posedge CLK) begin
	// get the instruction from the test banch
	if (!stallF) begin

			instrIF <= i_datain[31:0];			// here instrIF always stands for the next instruction fetched which pc is currently pointing to

		if (BranchE && zero) begin

			instrIF <= 32'b0;

		end

		if (jumpD) begin

			instrIF <= 32'b0;
			
		end
			
	end
	

end


//// instruction decoding ////

always @(posedge CLK) begin

	if (!stallD) begin 							// when stalling is needed, hold decoding procedure for one clock cycle

		rs_num <= instrIF[25:21];				// meaning inside the register file i should make it combinational logic
		rt_num <= instrIF[20:16];
		rd_num <= instrIF[15:11];
		op <= instrIF[31:26];
		func <= instrIF[5:0];
		shamt <= instrIF[10:6];
		imm <= instrIF[15:0];
		jumpAddr <= instrIF[25:0];
		PCPlus4D <= pc;

	end

	else 		stall <= stallD;
end


//// excecution stage ////

always @(posedge CLK) begin
	
	rs_numE <= rs_num;							// rs, rt number in EX stage for hazard detection
	rt_numE <= rt_num;

		// forwarding multiplexer on rs // 
		if 		(forward_A == `_ori)	reg_A <= reg_a;
		else if (forward_A == `_fM)		reg_A <= c;			// i have to forward from c but not ALUOutM, since c is the flip flop EX/MEM
		else if (forward_A == `_fW)	
		begin
			if 	(MemtoRegM) 			reg_A <= d_datain;	// need to know which one of ALUOut and d_datain are going to be forwarded
			else 						reg_A <= ALUOutM;	// since have not enter WB stage yet, MemtoRegE stands for the signal for choosing
		end	
		else 							reg_A <= reg_a;		// when there is no value in MEM & WB stage yet

		// forwarding multiplexer on rt //
		if 		(forward_B == `_ori)	reg_B <= reg_b;		// note that in both selection, <code>`_fM</code> comes in front of <code>`_fW</code>
		else if (forward_B == `_fM)		reg_B <= c;			// since when both MEM and WB stage is in need of forwarding 
		else if (forward_B == `_fW)							// we only need to forward MEM stage
		begin
			if 	(MemtoRegM) 			reg_B <= d_datain;	// check which one of the two result is going to be written back
			else 						reg_B <= ALUOutM;
		end
		else 							reg_B <= reg_b;

		ALUControlE <= ALUControlD;							// set ALUControlE to control the ALU operation of EX stage


		RegWriteE <= RegWriteD;
		MemtoRegE <= MemtoRegD;
		MemWriteE <= MemWriteD;
		BranchE <= BranchD;
		WriteDataE <= gr2;							// gr2 just the same as reg_C. both r determined at last stage

		PCBranch <= PCPlus4D + (imm_ext << 2);		// used if branch condition is true

		if (RegDstD) WriteRegE <= rd_num;			// select destination register
		else 		 WriteRegE <= rt_num;	
	end



//// memory stage ////

always @(posedge CLK) begin
	
	RegWriteM <= RegWriteE;
	MemtoRegM <= MemtoRegE;						// not necessary ******
	WriteRegM <= WriteRegE;

	ALUOutM <= c;								// ALUOutM is the address of data memory to be written or to be read

	// for sw instruction				
	if (MemWriteE) begin
		WriteDataM <= WriteDataE;				// if store, write the data in (last moment) /// is this right?
	end
	// for lw instruction
	ReadData <= d_datain;


end


//// write back stage ////

always @(posedge CLK) begin

	// sequentially assign the control and data and trigger the combinational writing circuit inside reg_file.v to write data back
	// note that the reg_file is the kind that does not take clock input into consideration
	RegWriteW <= RegWriteM;
	WriteRegW <= WriteRegM;

	if (MemtoRegM)	wb_data <= ReadData;	
	else 			wb_data <= ALUOutM;
	
end


//// flashing ////

always @(flashB) begin
	if (flashB && !stall) begin 				// if EXE stage find that branch happens, immediately do the following operations

		instrIF = 32'b0;						
		rs_num = 5'b0;
		rt_num = 5'b0;
		rd_num = 5'b0;
		op = 6'b0;
		func <= 6'b0;
		imm <= 16'b0;
		PCPlus4D = 32'b0;
	end
end



always @(jumpD, jAddr) begin

	if (jumpD && !stallF) begin
		
		instrIF = 32'b0;
	end
end



assign d_addr = c;
assign i_addr = pc;
assign store = MemWriteE;
assign d_dataout = WriteDataE;

endmodule


