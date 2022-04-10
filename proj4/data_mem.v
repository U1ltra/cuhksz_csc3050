
`timescale 1ns / 1ps

/* 
 * File: data_mem.v
 * ----------------
 * This file exports data_mem module which simulates the data memory of real machine.
 * A separated text file is used to store the memory data. Assuming th first line of 
 * the text file is memory address 0x0000_0000.
 * Please modify the path when the environment is changed.
 */


 module dataMem(
 	input wire[31:0] addr,
 	input wire[0:0] CLK,
 	input wire[31:0] storeW,
 	input wire[0:0] store,

 	output wire[31:0] out
 	);

 	reg[31:0] data[31:0];				// assuming that there are less than 32 lines of data
 	reg[31:0] A;



 	initial
 	begin
 		$readmemb("/path_to/dataMem.txt", data);
 		A <= 1'bx;
 	end


 	always @(addr) begin

 		if (addr < 32'h0000_0080)				
 			begin
 				A <= (addr>>2);			// since 4 bytes forms a line of data
 			end
 		else 
	 		begin
	 			A <= 1'bx;						
	 		end
 		
 	end



 	always @(posedge CLK) begin
 		if (store) begin
 			
 			data[addr>>2] = storeW;

 		end

 	end





	assign out = data[A];


endmodule




