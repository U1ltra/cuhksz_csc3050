module control(i_dataIn, gr1, gr2, ALUCr, reg_a, reg_b, of_det);


input signed[31:0] i_dataIn, gr1, gr2;

output signed[3:0] ALUCr;			// in single cycle, the is no registers between ALU control and ALU. So wire type output
output signed[0:0] of_det;
output [31:0] reg_a, reg_b;			// the data to be perform operations. already passed the multiplexer and extender

reg[31:0] reg_A;					// data to be passed into and operate by ALU module
reg[31:0] reg_B;					// data to be passed into and operate by ALU module
reg[3:0] ALUCon;					// ALU control code generated with operation code and function code of the given instruction



wire[5:0] op = i_dataIn[31:26];
wire[5:0] func = i_dataIn[5:0];		// for recognizing R type instructions		
wire[15:0] imm = i_dataIn[15:0];	// for I type instructions
wire[4:0] shamt = i_dataIn[10:6];	// for shifting
wire[0:0] sign = (op==ANDI || op==ORI || op==XORI || op==SLTIU) ? _unsign : _sign;
wire[0:0] of_det = (func==ADD || func==SUB || func == ADDI) ? 1 : 0;


			// extended values //
wire[31:0] shamt_ext = {27'b0, i_dataIn[10:6]};
wire[31:0] imm_ext = sign ? {{16{i_dataIn[15]}}, i_dataIn[15:0]} : {{16{1'b0}}, i_dataIn[15:0]};					



parameter	// signed or unsigned //
			_sign = 1'b1,
			_unsign = 1'b0;



parameter	// R type - func code //
			R_type = 6'b000000,
			ADD = 6'b100000,
			ADDU = 6'b100001,
			SUB = 6'b100010,
			SUBU = 6'b100011,
			MULT = 6'b011000,
			MULTU = 6'b011001,
			DIV = 6'b011010,
			DIVU = 6'b011011,
			AND = 6'b100100,
			OR = 6'b100101,
			NOR = 6'b100111,
			XOR = 6'b100110,
			SLT = 6'b101010,
			SLTU = 6'b101011,
			SLL = 6'b000000,
			SLLV = 6'b000100,
			SRL = 6'b000010,
			SRLV = 6'b000110,
			SRA = 6'b000011,
			SRAV = 6'b000111;


parameter	// I type - op code //
			ADDI = 6'b001000,
			ADDIU = 6'b001001,
			ANDI = 6'b001100,
			ORI = 6'b001101,
			XORI = 6'b001110,
			SLTI = 6'b001010,
			SLTIU = 6'b001011,
			LW = 6'b100011,
			SW = 6'b101011,
			BEQ = 6'b000100,
			BNE = 6'b000101;

parameter	// ALU control //
			_ADD = 4'b0010,
			_AND = 4'b0100,
			_OR = 4'b0101,
			_XOR = 4'b0110,
			_NOR = 4'b0111,
			_SLT = 4'b1011,
			_SRA = 4'b1100,
			_SLL = 4'b1110,
			_SRL = 4'b1101,
			_MULT = 4'b0001,
			_DIV = 4'b1010;





always @(i_dataIn, gr1, gr2) 
begin
	
	case(op)
		R_type:			/*/// R type instructions ///*/
		begin

			case(func)	// control to the ALU operation to be performed
					ADD:	ALUCon = _ADD;
					ADDU:	ALUCon = _ADD;
					SUB:	ALUCon = _ADD;
					SUBU: 	ALUCon = _ADD;
					AND: 	ALUCon = _AND;
					OR:		ALUCon = _OR;
					NOR:	ALUCon = _NOR;
					XOR:	ALUCon = _XOR;
					SLT:	ALUCon = _SLT;
					SLTU:	ALUCon = _SLT;
					SLL:	ALUCon = _SLL;
					SLLV:	ALUCon = _SLL;					// combined into one, just needs some sign extension
					SRL:	ALUCon = _SRL;
					SRLV:	ALUCon = _SRL;
					SRA:	ALUCon = _SRA;
					SRAV:	ALUCon = _SRA;
					MULT:	ALUCon = _MULT;
					MULTU:	ALUCon = _MULT;
					DIV:	ALUCon = _DIV;
					DIVU:	ALUCon = _DIV;
					default:	ALUCon = 4'b0000;			// set default to avoid deadlock
			endcase 										// end of func

			if (func == SLL || func == SRL || func == SRA)	// data processing between the instruction fetched and ALU
			begin 					// sll, srl, sra (shifts according to the number of shift amount)
				reg_A = gr2;		// value of gr2 is taken since for shift instructions, rt is used to specify the register and the place of rs is kept zero
				reg_B = shamt_ext;	// amount to be shift
			end

			else if (func == SUB || func == SUBU)			// to reuse the add basic function of ALU module
			begin 											// we just need to calculate the 2's complement code of data in rt

				reg_A = gr1;								// in sub cases
				reg_B = (~gr2)+1 ;

			end

			else 					// for other R type instructions, they will just take the value in
			begin 					// gr1 and gr2
				reg_A = gr1;	
				reg_B = gr2;	
			end

		end 					// end of case R_type


						/*///  I type operations  ///*/

		ADDI:	ALUCon = _ADD;	// control to the ALU operation to be performed
		ADDIU:	ALUCon = _ADD;
		ANDI:	ALUCon = _AND;
		ORI:	ALUCon = _OR;
		XORI:	ALUCon = _XOR;
		SLTI:	ALUCon = _SLT;
		SLTIU:	ALUCon = _SLT;
		LW:		ALUCon = _ADD;
		SW:		ALUCon = _ADD;
		BEQ:	ALUCon = _ADD;
		BNE:	ALUCon = _ADD;
		default:	ALUCon = 4'b0000;		// to avoid deadlock

	endcase	// end of op 


	if (op == BEQ || op == BNE) 			// to reuse add operation of ALU
	begin 									// needs to change the sign of the value in reg_B
		reg_A = gr1;
		reg_B = (~gr2) + 1;
	end
	else if (op == SW || op == LW) begin 	// for lw and sw case the imm number has to be multiplied by 4 to gain the corresponding address
		reg_A = gr1;
		reg_B = (sign ? {{16{i_dataIn[15]}}, i_dataIn[15:0]} : {{16{1'b0}}, i_dataIn[15:0]}) * 4;
	end
	else if (op != R_type) begin 			// any other i type instructoins will simply take the extended imm
		reg_A = gr1;
		reg_B = sign ? {{16{i_dataIn[15]}}, i_dataIn[15:0]} : {{16{1'b0}}, i_dataIn[15:0]};	// this expression extends imm to 32 bits
	end 																					// considering the need of signed or unsigned extension

end // end of always


assign ALUCr = ALUCon;
assign reg_a = reg_A;
assign reg_b = reg_B;

endmodule







