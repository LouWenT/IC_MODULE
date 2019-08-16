`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:14:28 08/16/2019 
// Design Name: 
// Module Name:    differentiator 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module differentiator #(parameter word_size = 8)
						( output [word_size - 1 : 0] data_out,
						  input  [word_size - 1 : 0] data_in,
						  input                      hold,
						  input                      clk,rst_n
							);
	
	reg [word_size - 1 : 0] buffer;
	assign data_out = data_in - buffer;
	
	always @ (posedge clk) begin
		if(!rst_n)
			buffer <= 0;
		else if(hold)
			buffer <= buffer;
		else
			buffer <= data_in;
	end
		


endmodule
