`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:52:58 08/19/2019 
// Design Name: 
// Module Name:    FIFO_Channel 
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
module FIFO_Channel #(parameter word_width = 32,stk_ptr_width = 3)
				( output [word_width - 1 : 0] Data_out,
				  output                      ready,
				  input  [word_width - 1 : 0] Data_in,
				  input                       En,
				  input                       read,
				  input                       clk_write,clk_read,
				  input                       rst_n
					);
					
	wire [word_width - 1 : 0]  Data_out_Ser_Par;
	wire                       Data_in_Ser_Par;
	wire                       stk_full,stk_almost_full,stk_half_full,stk_empty,stk_almost_empty;
	wire                       write;
	
	FIFO_Dual_Port_A M0 ( .Data_out(Data_out),
						  .stk_full(stk_full),
						  .stk_almost_full(stk_almost_full),
						  .stk_half_full(stk_half_full),
						  .stk_empty(stk_empty),
						  .stk_almost_empty(stk_almost_empty),
						  .Data_in(Data_in),
						  .write(write),
						  .read(read),
						  .clk_read(clk_read),
						  .clk_write(clk_write),
						  .rst_n(rst_n)
						  );
						
	Ser_Par_Conv_32 M1( .Data_out(Data_out_Ser_Par),
					    .ready(ready),
						.write(write),
					    .Data_in(Data_in_Ser_Par),
					    .En(En),
					    .full(stk_full),
					    .clk(clk_write),
					    .rst_n(rst_n)
						 );

endmodule

//--------------------------------------------------------------------------------------------------------------------------------------//
//FIFO_Dual_Port_A

module FIFO_Dual_Port_A #(parameter word_width = 32,stk_ptr_width = 3)
					( output [word_width - 1 : 0] Data_out,
					  output                      stk_full,stk_empty,stk_almost_full,stk_half_full,stk_almost_empty,
					  input  [word_width - 1 : 0] Data_in,
					  input                       write,read,
					  input                       clk_read,clk_write,
					  input                       rst_n
						);
	
	wire [stk_ptr_width - 1 : 0] read_ptr,write_ptr;
	
	FIFO_Control_Unit M0_Controller ( .write_to_stk(write_to_stk),
									  .read_fr_stk (read_fr_stk),
									  .write(write),
									  .read(read),
									  .stk_full(stk_full),
									  .stk_empty(stk_empty)
										);
	
	FIFO_Datapath_Unit M1_Datapath ( .Data_out(Data_out),
									 .Data_in(Data_in),
									 .write_ptr(write_ptr),
									 .read_ptr(read_ptr),
									 .write_to_stk(write_to_stk),
									 .read_fr_stk (read_fr_stk),
									 .clk_read(clk_read),
									 .clk_write(clk_write),
									 .rst_n(rst_n)
										);
										
	FIFO_Status_Unit    M2_Status ( .write_ptr(write_ptr),
									.read_ptr(read_ptr),
									.stk_full(stk_full),
									.stk_half_full(stk_half_full),
									.stk_almost_full(stk_almost_full),
									.stk_almost_empty(stk_almost_empty),
									.stk_empty(stk_empty),
									.write_to_stk(write_to_stk),
									.read_fr_stk(read_fr_stk),
									.clk_read(clk_read),
									.clk_write(clk_write),
									.rst_n(rst_n)
										);
endmodule


//FIFO_Control_Unit
module FIFO_Control_Unit ( output write_to_stk,read_fr_stk,
						   input write,read,stk_full,stk_empty
						   );
	
	assign write_to_stk = write && (!stk_full);
	assign read_fr_stk  = read  && (!stk_empty);

endmodule

//FIFO_Datapath_Unit
module FIFO_Datapath_Unit #(parameter word_width = 32,stk_ptr_width = 3,stk_height = 8)
						( output [word_width - 1    : 0] Data_out,
						  input  [word_width - 1    : 0] Data_in,
						  input  [stk_ptr_width - 1 : 0] write_ptr,read_ptr,
						  input                          write_to_stk,read_fr_stk,
						  input                          clk_read,clk_write,
						  input                          rst_n
							);
							
	reg [word_width - 1 : 0] stk[0 : stk_height - 1]; //stack
	reg [word_width - 1 : 0] Data_out_reg;
	
	assign Data_out = Data_out_reg;
	
	always @(posedge clk_write) 
		if(write_to_stk)
			stk[write_ptr] <= Data_in;
	
	always @(posedge clk_read)
		if(read_fr_stk)
			Data_out_reg <= stk[read_ptr];
			
endmodule

//FIFO_Status_Unit
module FIFO_Status_Unit #(parameter stk_ptr_width = 3,stk_height = 8, HF_level = (stk_height) >> 1,AF_level = stk_height - (HF_level >> 1),									   AE_level = (HF_level) >> 1)
						( output [stk_ptr_width - 1 : 0] write_ptr,read_ptr,
						  output                         stk_full,stk_half_full,stk_almost_full,stk_empty,stk_almost_empty,
						  input                          write_to_stk,read_fr_stk,
						  input                          clk_read,clk_write,
						  input                   		 rst_n
							);
							
	wire  [stk_ptr_width : 0] wr_cntr,next_wr_cntr;
	wire  [stk_ptr_width : 0] wr_cntr_G;           //gray_code
	wire  [stk_ptr_width : 0] rd_cntr,next_rd_cntr;
	wire  [stk_ptr_width : 0] rd_cntr_G;
	wire  [stk_ptr_width : 0] wr_cntr_G_sync,rd_cntr_G_sync;  //gray sync
	wire  [stk_ptr_width : 0] wr_cntr_B_sync,rd_cntr_B_sync; // binary sync
	
	assign stk_full         = ((wr_cntr - rd_cntr_B_sync) == stk_height) || (!rst_n);
	assign stk_half_full    = ((wr_cntr - rd_cntr_B_sync) == HF_level)   || (!rst_n);
	assign stk_almost_full  = ((wr_cntr - rd_cntr_B_sync) == AF_level)   || (!rst_n);
	assign stk_empty        = ((rd_cntr - wr_cntr_B_sync) == rd_cntr)    || (!rst_n);
	assign stk_almost_empty = ((rd_cntr - wr_cntr_B_sync) == AE_level)   || (!rst_n);
	
	wr_cntr_Unit M0 ( .next_wr_cntr(next_wr_cntr),
					  .wr_cntr(wr_cntr),
					  .write_ptr(write_ptr),
					  .write_to_stk(write_to_stk),
					  .clk_write(clk_write),
					  .rst_n(rst_n)
						);
			
	rd_cntr_Unit M1 ( .next_rd_cntr(next_rd_cntr),
					  .rd_cntr(rd_cntr),
					  .read_ptr(read_ptr),
					  .read_fr_stk(read_fr_stk),
					  .clk_read(clk_read),
					  .rst_n(rst_n)
						);
						
	B2G_Reg     M2  ( .gray_out(wr_cntr_G),
					  .binary_in(next_wr_cntr),
					  .wr_rd(write_to_stk),
					  .limit(stk_full),
					  .clk(clk_write),
					  .rst_n(rst_n)
						);
						
	G2B_Conv    M3  ( .binary(wr_cntr_B_sync),
					  .gray(wr_cntr_G_sync)
						);
						
	B2G_Reg     M4  ( .gray_out(rd_cntr_G),
					  .binary_in(next_rd_cntr),
					  .wr_rd(read_to_stk),
					  .limit(stk_full),
					  .clk(clk_read),
					  .rst_n(rst_n)
						);
						
	G2B_Conv    M5  ( .binary(rd_cntr_B_sync),
					  .gray(rd_cntr_G_sync)
						);

						
	generate
		genvar k;
		for(k = 0;k <= stk_ptr_width;k = k + 1) begin : write_read
			Synchro_Long_Asynch_in_to_Short_Period_Clock M1 ( .Synch_out(wr_cntr_G_sync[k]),
															  .Asynch_in(wr_cntr_G_sync[k]),
															  .clk(clk_read),
															  .rst_n(rst_n)
																);
		end
		
		for(k = 0;k <= stk_ptr_width;k = k + 1) begin  : read_write
			Synchro_Short_Asynch_in_to_Long_Period_Clock M2 ( .Synch_out(rd_cntr_G_sync[k]),
															  .Asynch_in(rd_cntr_G_sync[k]),
															  .clk(clk_write),
															  .rst_n(rst_n)
																);
		end
	endgenerate
endmodule

module wr_cntr_Unit #(parameter stk_ptr_width = 3)
					( output [stk_ptr_width     : 0] next_wr_cntr,
					  output [stk_ptr_width     : 0] wr_cntr,
					  output [stk_ptr_width - 1 : 0] write_ptr,
					  input                          write_to_stk,
					  input 					     clk_write,rst_n
						);
						
	reg [stk_ptr_width : 0] wr_cntr_reg;
	reg [stk_ptr_width : 0] next_wr_cntr_reg;
	
	assign write_ptr    = wr_cntr_reg[stk_ptr_width - 1 : 0];
	assign wr_cntr      = wr_cntr_reg;
	assign next_wr_cntr = next_wr_cntr_reg;
	
	always @(posedge clk_write) begin
		if(!rst_n)
			wr_cntr_reg <= 0;
		else if(write_to_stk)
			wr_cntr_reg <= next_wr_cntr_reg;
	end
	
	always @(wr_cntr_reg)
		next_wr_cntr_reg <= wr_cntr_reg + 1;
	
endmodule

module rd_cntr_Unit #(parameter stk_ptr_width = 3)
					( output [stk_ptr_width     : 0] next_rd_cntr,
					  output [stk_ptr_width     : 0] rd_cntr,
					  output [stk_ptr_width - 1 : 0] read_ptr,
					  input                      read_fr_stk,
					  input 					 clk_read,rst_n
						);
						
	reg [stk_ptr_width : 0] rd_cntr_reg;
	reg [stk_ptr_width : 0] next_rd_cntr_reg;
	
	assign read_ptr     = rd_cntr_reg[stk_ptr_width - 1 : 0];
	assign rd_cntr      = rd_cntr_reg;
	assign next_rd_cntr = next_rd_cntr_reg;
	
	always @(posedge clk_read) begin
		if(!rst_n)
			rd_cntr_reg <= 0;
		else if(read_fr_stk)
			rd_cntr_reg <= next_rd_cntr_reg;
	end
	
	always @(rd_cntr_reg)
		next_rd_cntr_reg <= rd_cntr_reg + 1;
	
endmodule
	
module B2G_Reg #(parameter stk_ptr_width = 3)
			( output [stk_ptr_width : 0] gray_out,
			  input  [stk_ptr_width : 0] binary_in,
			  input                      wr_rd,
			  input                      limit,
			  input                      clk,rst_n
				);
				
	reg [stk_ptr_width : 0] gray_out_reg;
	assign gray_out = gray_out_reg;
	
	wire [stk_ptr_width : 0] next_gray_out;
	
	always @(posedge clk,negedge rst_n) begin
		if(!rst_n)
			gray_out_reg <= 0;
		else if(wr_rd && (!limit))
			gray_out_reg <= next_gray_out;
		else 
			gray_out_reg <= gray_out_reg;
	end
	
	B2G_Conv M0 ( .gray(next_gray_out),
				  .binary(binary_in)
					);
endmodule			

module B2G_Conv #(parameter stk_ptr_width = 3)
				( output [stk_ptr_width : 0] gray,
				  input  [stk_ptr_width : 0] binary
					);
	assign gray = (binary >> 1) ^ binary;

endmodule

module G2B_Conv #(parameter stk_ptr_width = 3)
				( output [stk_ptr_width : 0] binary,
				  input  [stk_ptr_width : 0] gray
					);
	
	reg [stk_ptr_width : 0] binary_reg;
	assign binary = binary_reg;
	
	integer k;
	always @(gray) begin
		binary_reg[stk_ptr_width] = gray[stk_ptr_width];
		for(k = 0;k <= stk_ptr_width - 1;k = k + 1 )
			binary_reg[k] = binary_reg[k + 1] ^ gray[k];
	end
	
endmodule

module Synchro_Long_Asynch_in_to_Short_Period_Clock ( output Synch_out,
													  input  Asynch_in,
													  input  clk,rst_n
                                                       );
	reg Synch_meta;
	reg Synch_out_reg;
	assign Synch_out = Synch_out_reg;
	
	always @(posedge clk,negedge rst_n) begin
		if(!rst_n) begin
			Synch_meta    <= 0;
			Synch_out_reg <= 0;
		end
		else
			{Synch_out_reg,Synch_meta} <= {Synch_meta,Asynch_in};
	end
endmodule


module Synchro_Short_Asynch_in_to_Long_Period_Clock ( output Synch_out, //快时钟同步到慢时钟域
													  input  Asynch_in,
													  input  clk,rst_n
                                                       );
													   
	reg q1,q2;
	reg Synch_out_reg;
	assign Synch_out = Synch_out_reg;
	
	supply1 Vcc;
	
	wire Clr_q1_q2;
	
	assign Clr_q1_q2 = (!rst_n) || ((!Asynch_in) && Synch_out);
	
	always @(posedge clk,negedge rst_n) begin
		if(!rst_n)
			Synch_out_reg <= 0;
		else 
			Synch_out_reg <= q2;
	end

	always @(posedge clk ,posedge Clr_q1_q2) begin
		if (Clr_q1_q2) q2 <= 0;
		else q2 <= q1;
	end


	always @ (posedge clk ,posedge Clr_q1_q2)
		if (Clr_q1_q2) q1 <= 0;
		else q1 <= Vcc;


endmodule		
//-----------------------------------------------------------------------------------------------------------------------------------------//
//Ser_Par_Conv_32
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
		
							