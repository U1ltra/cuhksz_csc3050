module alu(i_dataIn, gr1, gr2, c, zero, overflow, negative);


output signed[31:0] c;			// in MIPS the result of ALU will be directly used, so c should be wire type
output signed[0:0] zero, overflow, negative;

input signed[3:0] ALUCr; 
input signed[31:0] i_dataIn;	// used to trigger the always process
input signed[31:0] gr1, gr2;


reg[32:0] result;
reg[63:0] reg_hilo;				// for multiplication and division
reg[0:0] zf, nf, of;			// in real MIPS they are just registers

wire[0:0] of_det;
wire[3:0] ALUCr;
wire[5:0] op = i_dataIn[31:26];
wire[5:0] func = i_dataIn[5:0];
wire signed[31:0] reg_a, reg_b;


parameter	R_type = 6'b000000,
			MULTU = 6'b011001,
			DIVU = 6'b011011,
			SLTU = 6'b101011;

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

control ALU_control(i_dataIn, gr1, gr2, ALUCr, reg_a, reg_b, of_det);


always @(i_dataIn, reg_a, reg_b)
begin

	zf = 1'bx;							// reset the flags 
	nf = 1'bx;
	of = 1'bx;


	case(ALUCr)							// ALU operations
		_ADD:	result = reg_a + reg_b;
		_AND:	result = reg_a & reg_b;
		_OR:	result = reg_a | reg_b;
		_XOR:	result = reg_a ^ reg_b;
		_NOR:	result = ~ (reg_a | reg_b);
		_SLL:	result = reg_a << reg_b;
		_SRL:	result = reg_a >> reg_b;
		_SRA:	result = reg_a >>> reg_b;
		_MULT:														// mult and div are specially discussed
		begin
			if (func == MULTU) begin
				reg_hilo = $unsigned(reg_a) * $unsigned(reg_b);
			end
			else begin
				reg_hilo = reg_a * reg_b;
			end
		end

		_DIV:	
		begin
			if (func == DIVU) begin
				reg_hilo[31:0] = $unsigned(reg_a) / $unsigned(reg_b);
				reg_hilo[63:32] = $unsigned(reg_a) % $unsigned(reg_b);
			end
			else begin
				reg_hilo[31:0] = reg_a / reg_b;
				reg_hilo[63:32] = reg_a % reg_b;
			end
		end

		_SLT:	
		begin
			if (func == SLTU) begin
				result = ($unsigned(reg_a) < $unsigned(reg_b)) ? 1 : 0;
			end
			else begin
				result = (reg_a < reg_b) ? 1 : 0;
			end
		end
		
	endcase
	
	zf = result ? 0 : 1;
	nf = result[31];
	of = (result[32] != result[31]) ? 1 : 0;	// when carry out of the most significant bit does not equal to 
												// the carry in to the most significant bit. overflow happens
end


	// parallel assigning syntax //

assign c = result[31:0];
assign zero = zf;								// flag will be set everytime
assign negative = nf;							// but whether they will be used depends on other part of the control
assign overflow = (of_det) ? of : 1'bx;


endmodule



