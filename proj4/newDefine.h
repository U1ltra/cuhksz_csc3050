

/* File: newDefine.h
 * -----------------
 * This file defines constants frequently used in process notation of MIPS processor.
 */


// general register
`define gr0  		5'b00000
`define gr1  		5'b00001
`define gr2  		5'b00010
`define gr3 		5'b00011
`define gr4  		5'b00100
`define gr5  		5'b00101
`define gr6  		5'b00110
`define gr7  		5'b00111
`define gr8     	5'b01000
`define gr9     	5'b01001
`define gr10     	5'b01010
`define gr11     	5'b01011
`define gr12     	5'b01100
`define gr13  		5'b01101
`define gr14 		5'b01110
`define gr15  		5'b01111
`define gr16 		5'b10000
`define gr17  		5'b10001
`define gr18  		5'b10010
`define gr19 		5'b10011
`define gr20  		5'b10100
`define gr21     	5'b10101
`define gr22     	5'b10110
`define gr23     	5'b10111
`define gr24     	5'b11000
`define gr25     	5'b11001
`define gr26  		5'b11010
`define gr27  		5'b11011
`define gr28  		5'b11100
`define gr29 		5'b11101
`define gr30  		5'b11110
`define gr31  		5'b11111



// signed or unsigned //
`define _sign 		1'b1
`define _unsign 	1'b0



// R type - func code //
`define	R_type 	 	6'b000000
`define	ADD  		6'b100000
`define	ADDU  		6'b100001
`define	SUB 		6'b100010
`define	SUBU 		6'b100011
`define	MULT 		6'b011000
`define	MULTU 		6'b011001
`define	DIV 		6'b011010
`define	DIVU 	 	6'b011011
`define	AND 		6'b100100
`define	OR 			6'b100101
`define	NOR 		6'b100111
`define	XOR 		6'b100110
`define	SLT 		6'b101010
`define	SLTU 		6'b101011
`define	SLL 		6'b000000
`define	SLLV 		6'b000100
`define	SRL 		6'b000010
`define	SRLV 		6'b000110
`define	SRA 		6'b000011
`define	SRAV 		6'b000111



// I type - op code //
`define	ADDI 		6'b001000
`define	ADDIU 		6'b001001
`define	ANDI 		6'b001100
`define	ORI  		6'b001101
`define	XORI 		6'b001110
`define	SLTI 		6'b001010
`define	SLTIU 		6'b001011
`define	LW 			6'b100011
`define	SW 			6'b101011
`define	BEQ 		6'b000100
`define	BNE 		6'b000101



// J type //
`define	J 			6'b000010					// op
`define	JR 			6'b001000					// func	
`define	JAL 		6'b000011					// op	



// ALU control //
`define	_ADD 		4'b0010
`define	_AND 		4'b0100
`define	_OR 		4'b0101
`define	_XOR 		4'b0110
`define	_NOR 		4'b0111
`define	_SLT 		4'b1011
`define	_SRA 		4'b1100
`define	_SLL 		4'b1110
`define	_SRL 		4'b1101
`define	_MULT 		4'b0001
`define	_DIV 		4'b1010



// forwarding control //
`define _ori		2'b00 						// no forwarding occurred
`define _fM			2'b01 						// forward from EX/MEM
`define _fW			2'b10 						// forward from MEM/WB


