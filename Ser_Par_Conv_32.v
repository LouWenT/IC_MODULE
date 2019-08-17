`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:04:18 08/17/2019 
// Design Name: 
// Module Name:    Ser_Par_Conv_32 
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
module Ser_Par_Conv_32 #(parameter word_width = 32)
					( output [word_width - 1 : 0] Data_out,
					  output                      ready,
					  output                      write,
					  input                       Data_in,
					  input                       En,full,
					  input                       clk,rst_n
						);
						
	wire pause_full,pause_En_b,shift_incr,cntr_limit;
	
	Control_Unit M0_Controller ( .ready(ready),
						    .write(write),
							.shift_incr(shift_incr),
							.cntr_limit(cntr_limit),
							.pause_full(pause_full),
							.pause_En_b(pause_En_b),
							.En(En),
							.full(full),
							.clk(clk),
							.rst_n(rst_n)
							);
							
	Datapath_Unit M1_Datapath ( .Data_out(Data_out),
						   .cntr_limit(cntr_limit),
						   .Data_in(Data_in),
						   .pause_full(pause_full),
						   .pause_En_b(pause_En_b),
						   .shift_incr(shift_incr),
						   .clk(clk),
						   .rst_n(rst_n)
							);


endmodule

module Control_Unit ( output     ready,write,
					  output     pause_En_b,pause_full,shift_incr,
					  input      En,full,clk,rst_n,cntr_limit
						);
				 
	parameter S_IDLE = 0,
			  S_1    = 1,
			  S_2    = 2;
			  
	reg [1:0] state,next_state;
	reg pause_En_b_reg,pause_full_reg,shift_incr_reg;
	assign pause_En_b = pause_En_b_reg;
	assign pause_full = pause_full_reg;
	assign shift_incr = shift_incr_reg;
	
	assign ready = (state == S_IDLE);
	assign write = (state == S_2);
	
	always @(posedge clk,negedge rst_n) begin
		if(!rst_n)
			state <= S_IDLE;
		else
			state <= next_state;
	end
	
	always @(state,En,full,cntr_limit) begin
		
		pause_En_b_reg = 0;
		pause_full_reg = 0;
		shift_incr_reg = 0;
		next_state     = S_IDLE;
		
		case(state)
			
			S_IDLE : begin
				if(En &&(!full)) begin
					next_state     = S_1;
					shift_incr_reg = 1;
				end
				else
					next_state = S_IDLE;
			end
			
			S_1 : begin
				if(full) begin
					next_state     = S_IDLE;
					pause_full_reg = 1;
				end
				else begin
					shift_incr_reg = 1;
					if(cntr_limit)
						next_state = S_2;
					else
						next_state = S_1;
				end
			end
				
			S_2 : begin
				if(En) begin
					shift_incr_reg = 1;
					next_state     = S_1;
				end
				else begin	
					pause_En_b_reg = 1;
					next_state     = S_IDLE;
				end
			end
			
			default : next_state = S_IDLE;
		endcase
		
	end
	
endmodule


module Datapath_Unit #(parameter word_width = 32,cntr_width = 5)
					( output [word_width - 1 : 0] Data_out,
					  output                      cntr_limit,
					  input                       Data_in,
					  input                       pause_En_b,pause_full,shift_incr,
					  input                       clk,rst_n
						);
						
	reg [word_width - 1 : 0] Data_out_reg;
	assign Data_out = Data_out_reg;
	
	reg [cntr_width : 0] cntr;
	
	always @(posedge clk,negedge rst_n) begin
		if(!rst_n)
			cntr <= 0;
		else if(pause_full || pause_En_b)
			cntr <= 0;
		else if(shift_incr)
			cntr <= cntr + 1;
	end
	
	always @(posedge clk,negedge rst_n) begin
		if(!rst_n)
			Data_out_reg <= 0;
		else if(pause_En_b || pause_full)
			Data_out_reg <= 0;
		else if(shift_incr)
			Data_out_reg <= {Data_in,Data_out_reg[word_width - 1 : 1]};
	end
	
	assign cntr_limit = (cntr == word_width - 1);
	
endmodule
		
