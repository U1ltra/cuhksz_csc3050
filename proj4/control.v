
`timescale 1ns / 1ps

/* 
 * File: control.v
 * ---------------
 * This file siumulates the control unit of CPU.
 * It is basically a combinational circuit in the second pipeline stage (DE).
 * The module takes in parts of instuctions and outputs all control signal needed.
 */


 `include "newDefine.h"


module control(op, func, shamt, imm, gr1, gr2, flashB, jumpAddr,
				reg_a, reg_b, RegWriteD, MemtoRegD, MemWriteD, BranchD, ALUCon, RegDstD, jumpD, imm_ext, jAddr);

input wire CLK;
input wire[5:0] op;
input wire[5:0] func;
input wire[4:0] shamt;
input wire[15:0] imm;
input wire[31:0] gr1;
input wire[31:0] gr2;
input wire[0:0] flashB;
input wire[25:0] jumpAddr;

output signed[31:0] imm_ext;
output signed[3:0] ALUControlD;		// in single cycle, the is no registers between ALU control and ALU. So wire type output
output signed[31:0] reg_a, reg_b;	// the data to be perform operations. already passed the multiplexer and extender
output reg[0:0] RegWriteD;
output reg[0:0] MemtoRegD;
output reg[0:0] MemWriteD;
output reg[0:0] BranchD;
output reg[3:0] ALUCon;				
output reg[0:0] RegDstD;
output reg[0:0] jumpD;
output reg[31:0] jAddr;

reg[31:0] reg_A;					// data to be passed into and operate by ALU module
reg[31:0] reg_B;					// data to be passed into and operate by ALU module



wire[0:0] sign = (op==`ANDI || op==`ORI || op==`XORI || op==`SLTIU) ? `_unsign : `_sign;


			// extended values //
reg[31:0] imm_ext;
// reg[31:0] imm_ext = sign ? {{16{imm[15]}}, imm} : {{16{1'b0}}, imm};					




// generate RegWriteD
always @(op, func, shamt, imm) begin
	
	// instructions other than BEQ, BNE, J, JAL, JR should have RegWriteD being true
	case(op)
		`R_type:
			case(func)
				`JR:			RegWriteD = 1'b0;
				default:		RegWriteD = 1'b1;
			endcase

		`BEQ,
		`BNE,
		`J,
		`JAL:					RegWriteD = 1'b0;
		default:				RegWriteD = 1'b1;
	endcase
end



// generate MemtoRegD
always @(op, func, shamt, imm) begin
	
	// only load instructions will cause MemtoRegD to be true
	// in this project we only have lw
	case(op)
		`LW: 					MemtoRegD = 1'b1;
		default:				MemtoRegD = 1'b0;	
	endcase
end



// generate MemWriteD
always @(op, func, shamt, imm) begin

	// only store instructions will have MemWriteD equal to one
	// in this project we only consider sw
	case(op)
		`SW: 					MemWriteD = 1'b1;
		default:				MemWriteD = 1'b0;
	endcase
	// $display("here", MemWriteD);
end



// generate BranchD
always @(op, func, shamt, imm) begin
	
	// together with zero flag
	// decide whether a brach occurs
	case(op)
		`BEQ,
		`BNE:					BranchD = 1'b1;
		default:				BranchD = 1'b0;
	endcase

end



// generate the ALUCon
always @(op, func, shamt, imm) 
begin
	
	case(op)
		`R_type:			/*/// R type instructions ///*/
		begin

			case(func)	// control to the ALU operation to be performed
					`ADD:		ALUCon = `_ADD;
					`ADDU:		ALUCon = `_ADD;
					`SUB:		ALUCon = `_ADD;
					`SUBU: 		ALUCon = `_ADD;
					`AND: 		ALUCon = `_AND;
					`OR:		ALUCon = `_OR;
					`NOR:		ALUCon = `_NOR;
					`XOR:		ALUCon = `_XOR;
					`SLT:		ALUCon = `_SLT;
					`SLTU:		ALUCon = `_SLT;
					`SLL:		ALUCon = `_SLL;
					`SLLV:		ALUCon = `_SLL;				// combined into one, just needs some sign extension
					`SRL:		ALUCon = `_SRL;
					`SRLV:		ALUCon = `_SRL;
					`SRA:		ALUCon = `_SRA;
					`SRAV:		ALUCon = `_SRA;
					`MULT:		ALUCon = `_MULT;
					`MULTU:		ALUCon = `_MULT;
					`DIV:		ALUCon = `_DIV;
					`DIVU:		ALUCon = `_DIV;
					`JR:		ALUCon = `_SLL;				// to support flashing
					default:	ALUCon = 4'b0000;			// set default to avoid deadlock
			endcase 										// end of func

		end 												// end of case R_type

						/*///  I type operations  ///*/

		`ADDI:					ALUCon = `_ADD;				// control to the ALU operation to be performed
		`ADDIU:					ALUCon = `_ADD;
		`ANDI:					ALUCon = `_AND;
		`ORI:					ALUCon = `_OR;
		`XORI:					ALUCon = `_XOR;
		`SLTI:					ALUCon = `_SLT;
		`SLTIU:					ALUCon = `_SLT;
		`LW:					ALUCon = `_ADD;
		`SW:					ALUCon = `_ADD;
		`BEQ:					ALUCon = `_ADD;
		`BNE:					ALUCon = `_ADD;
		`J,
		`JAL:					ALUCon = `_SLL;				// to support flashing
		default:				ALUCon = 4'b0000;			// to avoid deadlock

		
	endcase	// end of op 
end // end of always



// generate RegDstD
always @(op, func, shamt, imm) begin
	case(op)

		// instructions that use rd as the destination register
		`R_type:
			case(func)
				`ADD,
				`SUB,
				`ADDU,
				`SUBU,
				`AND,
				`OR,
				`NOR,
				`XOR,
				`SLL,
				`SRA,
				`SRL,
				`SLLV,
				`SRAV,
				`SRLV,
				`SLT:			RegDstD = 1'b1;
				default: 		RegDstD = 1'b0;						// avoid deadlock

		// instructions that use rt as the destination register
		`LW,
		`SW,
		`ADDI,
		`ADDIU,
		`ANDI,
		`ORI:					RegDstD = 1'b0;
		default:				RegDstD = 1'b0;						// note that beq, bne, j, jr, jal does not write one of rt or rd

			endcase
	endcase
end



// generate jumpD
always @(op, func, shamt, imm) begin

	// jumpD is true when come across a jump instruciton
	case(op)
		`R_type:
			case(func)
				`JR: begin
								jAddr = gr1;
								jumpD = 1'b1;
				end		
				default: 		jumpD = 1'b0;
			endcase

		`J,
		`JAL: begin
								jAddr = {6'b000000, jumpAddr};
								jumpD = 1'b1;
		end					
		
		default:				jumpD = 1'b0;
	endcase
end




// extension, selection and modification on the data to be perform ALU operations
always @(op, func, shamt, imm, gr1, gr2) begin

	if (op == `R_type) 
	begin
			if (func == `SLL || func == `SRL || func == `SRA)	// data processing between the instruction fetched and ALU
			begin 												// sll, srl, sra (shifts according to the number of shift amount)
				reg_A = gr2;									// value of gr2 is taken since for shift instructions, rt is used to specify the register and the place of rs is kept zero
				reg_B = {27'b0, shamt};						// amount to be shift
			end

			else if (func == `SUB || func == `SUBU)			// to reuse the add basic function of ALU module
			begin 											// we just need to calculate the 2's complement code of data in rt

				reg_A = gr1;								// in sub cases
				reg_B = (~gr2)+1 ;

			end

			else if (func == `JR) begin 					// flashing ~
				reg_A = 32'b0;			
				reg_B = 32'b0;
			end

			else 					// for other R type instructions, they will just take the value in
			begin 					// gr1 and gr2
				reg_A = gr1;	
				reg_B = gr2;	
			end
	end

	else if (op == `BEQ) begin 		// needs to change the sign of the value in reg_B
		reg_A = gr1;
		reg_B = (~gr2) + 1;
	end

	else if (op == `BNE) begin 		// change data of bne to reuse beq logic
		if (gr1 == gr2)	begin
			reg_A = gr1;
			reg_B = (~gr2);			
		end
		else begin
			reg_A = gr1;
			reg_B = (~gr1) + 1;
		end
	end

	else if (op == `SW || op == `LW) begin 					// for lw and sw case the imm number has to be multiplied by 4 to gain the corresponding address
		reg_A = gr1;
		reg_B = (sign ? {{16{imm[15]}}, imm[15:0]} : {{16{1'b0}}, imm[15:0]}) * 4;
	end

	else if (op == `J || op == `JAL) begin 					// flashing ~
		reg_A = 32'b0;
		reg_B = 32'b0;
	end

	else if (op != `R_type) begin 							// any other i type instructoins will simply take the extended imm
		reg_A = gr1;
		reg_B = sign ? {{16{imm[15]}}, imm[15:0]} : {{16{1'b0}}, imm[15:0]};	// this expression extends imm to 32 bits
	end

	imm_ext = sign ? {{16{imm[15]}}, imm} : {{16{1'b0}}, imm};

end



always @(flashB) begin
	if (flashB) begin
		imm_ext = 32'b0;
		reg_A = 32'b0; 
		reg_B = 32'b0;	
		RegWriteD = 1'b0;
		MemtoRegD = 1'b0;
		MemWriteD = 1'b0;
		BranchD = 1'b0;
		ALUCon = `_SLL;				
		RegDstD = 1'b0;
		jumpD = 1'b0;
		jAddr = 32'b0;
	end
end


// assign ALUCr = ALUCon;
assign reg_a = reg_A;
assign reg_b = reg_B;

endmodule







