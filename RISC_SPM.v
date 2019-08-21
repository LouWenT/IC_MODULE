`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:16:31 12/17/2018 
// Design Name: 
// Module Name:    RISC_SPM 
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
//RSIC_SPM

/*顶层模块*/

module RISC_SPM #(parameter word_size = 8,Sel1_size = 3,Sel2_size = 2)
					(input clk,
					 input rst,
					 output [word_size-1:0] Mem_word);
					 
	
	//Data Nets 
	wire [Sel1_size-1:0] Sel_Bus_1_Mux;
	wire [Sel2_size-1:0] Sel_Bus_2_Mux; //总线选择信号
	wire                 zero;
	wire [word_size-1:0] instruction,address,Bus_1,mem_word;
	assign Mem_word = mem_word;
	
	//Control Nets
	wire Load_R0,Load_R1,Load_R2,Load_R3,Load_PC,Inc_PC,
	     Load_IR,Load_ADD_R,Load_Reg_Y,Load_Reg_Z,write;
		 
	// instance module
	
	/*处理器模块*/
	Processing_Unit M0_Processor( .instruction(instruction),
								  .address(address),
								  .Bus_1(Bus_1),
								  .Zflag(zero),
								  .mem_word(mem_word),
								  .Load_R0(Load_R0),
								  .Load_R1(Load_R1),
								  .Load_R2(Load_R2),
								  .Load_R3(Load_R3),
								  .Load_PC(Load_PC),
								  .Inc_PC(Inc_PC),
								  .Sel_Bus_1_Mux(Sel_Bus_1_Mux),
								  .Sel_Bus_2_Mux(Sel_Bus_2_Mux),
								  .Load_IR(Load_IR),
								  .Load_ADD_R(Load_ADD_R),
								  .Load_Reg_Y(Load_Reg_Y),
								  .Load_Reg_Z(Load_Reg_Z),
								  .clk(clk),
								  .rst(rst)
									);
									
	/*控制器模块*/
	Control_Unit M1_Controller( .Sel_Bus_1_Mux(Sel_Bus_1_Mux),
								.Sel_Bus_2_Mux(Sel_Bus_2_Mux),
								.Load_R0(Load_R0),
								.Load_R1(Load_R1),
								.Load_R2(Load_R2),
								.Load_R3(Load_R3),
							   .Load_PC(Load_PC),
								.Inc_PC(Inc_PC),
								.Load_IR(Load_IR),
								.Load_Add_R(Load_ADD_R),
								.Load_Reg_Y(Load_Reg_Y),
								.Load_Reg_Z(Load_Reg_Z),
								.write(write),
								.instruction(instruction),
								.zero(zero),
								.clk(clk),
								.rst(rst)
								);
								
	/*存储器模块*/
	Memory_Unit M2_MEM( .data_out(mem_word),
						.data_in(Bus_1),
						.address(address),
						.clk(clk),
						.write(write)
						);
	
endmodule


/*处理器顶层模块*/

module Processing_Unit #(parameter word_size = 8,op_size = 4,Sel1_size = 3,Sel2_size = 2)
				( output [word_size-1:0] instruction,
				  output [word_size-1:0] address,
				  output [word_size-1:0] Bus_1,
				  output                 Zflag,
				  input  [word_size-1:0] mem_word,
				  input                  Load_R0,Load_R1,Load_R2,Load_R3,
				  input 				       Load_PC,Inc_PC,
				  input  [Sel1_size-1:0] Sel_Bus_1_Mux,
				  input  [Sel2_size-1:0] Sel_Bus_2_Mux,
				  input                  Load_IR,Load_ADD_R,
				  input                  Load_Reg_Y,Load_Reg_Z,
				  input                  clk,rst
				 );
				 
	wire [word_size-1:0] Bus_2;
	wire [word_size-1:0] R0_out,R1_out,R2_out,R3_out;
	wire [word_size-1:0] PC_count,alu_out,Y_value;
	wire 				      alu_zreo_flag;
	wire [op_size-1:0]   opcode = instruction[word_size-1:word_size-op_size];
	
	/*通用寄存器R0-R3*/
	Register_Unit     R0 ( .data_out(R0_out),
						   .data_in(Bus_2),
						   .load(Load_R0),
						   .clk(clk),
						   .rst(rst)
							);
							
	Register_Unit     R1 ( .data_out(R1_out),
						   .data_in(Bus_2),
						   .load(Load_R1),
						   .clk(clk),
						   .rst(rst)
							);
							
	Register_Unit     R2 ( .data_out(R2_out),
						   .data_in(Bus_2),
						   .load(Load_R2),
						   .clk(clk),
						   .rst(rst)
							);
							
	Register_Unit     R3 ( .data_out(R3_out),
						   .data_in(Bus_2),
						   .load(Load_R3),
						   .clk(clk),
						   .rst(rst)
							);
							
	/*操作数寄存器Reg_Y*/
	Register_Unit     Reg_Y ( .data_out(Y_value),
							  .data_in(Bus_2),
							  .load(Load_Reg_Y),
						      .clk(clk),
						      .rst(rst)
							 );
	/*专用寄存器Reg_Z*/
	D_flop            Reg_Z ( .data_out(Zflag),
							  .data_in(alu_zreo_flag),
							  .load(Load_Reg_Z),
						      .clk(clk),
						      .rst(rst)
							 );
	/*地址寄存器Add_R*/
	Address_Register  Add_R ( .data_out(address),
							  .data_in(Bus_2),
							  .load(Load_ADD_R),
						      .clk(clk),
						      .rst(rst)
							 );
	/*指令寄存器Add_R*/
	Instruction_Register IR ( .data_out(instruction),
							  .data_in(Bus_2),
							  .load(Load_IR),
						      .clk(clk),
						      .rst(rst)
							 );
	/*程序计数器PC*/
	Program_Counter PC      ( .count(PC_count),
							        .data_in(Bus_2),
							        .Load_PC(Load_PC),
							        .Inc_PC(Inc_PC),
						           .clk(clk),
						          .rst(rst)
							     );
	/*总线1-5选择器*/
	Multiplexer_5ch   Mux_1 ( .mux_out(Bus_1),
							  .data_a(R0_out),
							  .data_b(R1_out),
							  .data_c(R2_out),
							  .data_d(R3_out),
							  .data_e(PC_count),
							  .sel(Sel_Bus_1_Mux)
	                         );
							 
	/*总线2-3路选择器*/
	Multiplexer_3ch   Mux_2 ( .mux_out(Bus_2),
							  .data_a(alu_out),
							  .data_b(Bus_1),
							  .data_c(mem_word),
							  .sel(Sel_Bus_2_Mux)
							 ); 
	/*算术运算器ALU*/
	Alu_RISC          ALU  ( .alu_out(alu_out),
							 .alu_zero_flag(alu_zreo_flag),
							 .data_1(Y_value),
							 .data_2(Bus_1),
							 .sel(opcode)
	                        );
endmodule


/*控制单元的设计，设计的核心部分*/

module Control_Unit #(parameter word_size = 8,op_size = 4,state_size = 4,src_size = 2,
								dest_size = 2,Sel1_size = 3,Sel2_size = 2)
			( output [Sel1_size-1:0] Sel_Bus_1_Mux,
			  output [Sel2_size-1:0] Sel_Bus_2_Mux,
			  output reg             Load_R0,Load_R1,Load_R2,Load_R3,
			  output reg		       Load_PC,Inc_PC,
			  output reg			    Load_IR,Load_Add_R,
			  output reg 			    Load_Reg_Y,Load_Reg_Z,
			  output reg 			    write,
			  input  [word_size-1:0] instruction,
			  input                  zero,
			  input                  clk,rst
			);
			
    /*state codes
	parameter S_idle = 4'b0000 ,S_fet1 = 4'b0001,S_fet2 = 4'b0010,S_dec = 4'b0011,
			    S_ex1  = 4'b0100 ,S_rd1  = 4'b0101,S_rd2  = 4'b0110,
			    S_wr1  = 4'b0111, S_wr2  = 4'b1000,
			    S_br1  = 4'b1001, S_br2  = 4'b1010,
			    S_halt = 4'b1011;
    
	*opcodes*
	parameter NOP = 4'b0000, ADD = 4'b0001, SUB = 4'b0010,
	          AND = 4'b0011, NOT = 4'b0100, RD  = 4'b0101,WR = 4'b0110,
			    BR  = 4'b0111, BRZ = 4'b1000;
			  
	source and destinction codes*
	parameter R0 = 2'b00,R1 = 2'b01,R2 = 2'b10,R3 = 2'b11;*/
	
	
	/*state codes*/
	parameter S_idle = 0 ,S_fet1 = 1,S_fet2 = 2,S_dec = 3,
			  S_ex1  = 4 ,S_rd1  = 5,S_rd2  = 6,
			  S_wr1  = 7 , S_wr2  = 8,
			  S_br1  = 9 ,S_br2   = 10,
			  S_halt = 11;
    
	/*opcodes*/
	parameter NOP = 0, ADD = 1, SUB = 2,
	          AND = 3, NOT = 4, RD  = 5,WR = 6,
			  BR  = 7, BRZ = 8;
			  
	/*source and destinction codes*/
	parameter R0 = 0,R1 = 1,R2 = 2,R3 = 3;
	
	
	
	reg [state_size-1:0] state,next_state;
	reg  Sel_ALU,Sel_Bus_1,Sel_Mem;
	reg  Sel_R0,Sel_R1,Sel_R2,Sel_R3,Sel_PC;
	reg  err_flag;
	
	wire [op_size-1  :0] opcode = instruction[word_size-1:word_size-op_size];
	wire [src_size-1 :0] src    = instruction[src_size + dest_size-1:dest_size];
	wire [dest_size-1:0] dest   = instruction[dest_size-1:0];
	
	/*Mux selectors
	assign Sel_Bus_1_Mux [Sel1_size-1:0] = Sel_R0 ? 3'b000 :
										            Sel_R1 ? 3'b001 :
														Sel_R2 ? 3'b010 :
														Sel_R3 ? 3'b011 :
														Sel_PC ? 3'b100 : 3'bx;
										   
	assign Sel_Bus_2_Mux [Sel2_size-1:0] = Sel_ALU   ? 2'b00 :
										            Sel_Bus_1 ? 2'b01 :
										            Sel_Mem   ? 2'b10 :2'bx;*/
														
	/*Mux selectors*/
	assign Sel_Bus_1_Mux [Sel1_size-1:0] = Sel_R0 ? 0 :
										   Sel_R1 ? 1 :
										   Sel_R2 ? 2 :
										   Sel_R3 ? 3 :
										   Sel_PC ? 4 : 3'bx;
										   
	assign Sel_Bus_2_Mux [Sel2_size-1:0] = Sel_ALU   ? 0 :
										   Sel_Bus_1 ? 1 :
										   Sel_Mem   ? 2 : 2'bx;
	
	
	/*状态转移*/
	always @ (posedge clk,negedge rst)
		begin
			if(rst == 1'b0)
				state <= S_idle;
			else
				state <=next_state;
		end
		
	/*状态转移组合逻辑*/
	always @(state,opcode,src,dest,zero) begin : Output_and_nextstate
		Sel_R0 = 0;Sel_R1 = 0;Sel_R2 = 0;Sel_R3 = 0;Sel_PC = 0;
		Load_R0 = 0;Load_R1 = 0;Load_R2 = 0;Load_R3 = 0;Load_PC = 0;
		Load_IR = 0;Load_Add_R = 0;Load_Reg_Y = 0;Load_Reg_Z = 0;
		Inc_PC = 0;
		Sel_Bus_1 = 0;
		Sel_ALU = 0;
		Sel_Mem = 0;
		write = 0;
		err_flag = 0;//仅适用于仿真，不会综合出具体端口
		next_state = state;
		case(state)
			S_idle : next_state = S_fet1;
			
			S_fet1 : begin
				next_state = S_fet2;
				Sel_PC     = 1;
				Sel_Bus_1  = 1;
				Load_Add_R = 1;
			end
			
			S_fet2 : begin
				next_state = S_dec;
				Sel_Mem    = 1;
				Load_IR    = 1;
				Inc_PC     = 1;
			end
			
			S_dec  :
				case(opcode)
					NOP : next_state = S_fet1;
					
					ADD,SUB,AND:begin
						next_state = S_ex1;
						Sel_Bus_1  = 1;
						Load_Reg_Y = 1;
						case(src)
							R0      : Sel_R0   = 1;
							R1      : Sel_R1   = 1;
							R2      : Sel_R2   = 1;
							R3      : Sel_R3   = 1;
							default : err_flag = 1;
						endcase
					end/*ADD,SUB,AND*/
					
					NOT         : begin
						next_state = S_fet1;
						Load_Reg_Z = 1;
						Sel_ALU    = 1;
						case(src)
							R0      : Sel_R0   = 1;
							R1      : Sel_R1   = 1;
							R2      : Sel_R2   = 1;
							R3      : Sel_R3   = 1;
							default : err_flag = 1;
						endcase
						case(dest)
							R0      : Sel_R0   = 1;
							R1      : Sel_R1   = 1;
							R2      : Sel_R2   = 1;
							R3      : Sel_R3   = 1;
							default : err_flag = 1;
						endcase
					end//NOT
					
					RD          :begin
						next_state = S_rd1;
						Sel_PC     = 1;
						Sel_Bus_1  = 1;
						Load_Add_R = 1;
					end//RD
					
					WR          :begin
						next_state = S_wr1;
						Sel_PC     = 1;
						Sel_Bus_1  = 1;
						Load_Add_R = 1;
					end//WR
					
					BR          :begin
						next_state = S_br1;
						Sel_PC     = 1;
						Sel_Bus_1  = 1;
						Load_Add_R = 1;
					end//BR
					
					BRZ         :if(zero == 1) begin
						next_state = S_br1;
						Sel_PC     = 1;
						Sel_Bus_1  = 1;
						Load_Add_R = 1;
					end//BRZ
					else begin
						next_state = S_fet1;
						Inc_PC     = 1;
					end
					
					default : next_state = S_halt;
					
				endcase//opcode
				
			S_ex1  : begin
				next_state = S_fet1;
				Load_Reg_Z = 1;
				case(dest)
					R0 : begin Sel_R0 = 1; Load_R0 = 1; end
					R1 : begin Sel_R1 = 1; Load_R1 = 1; end
					R2 : begin Sel_R2 = 1; Load_R2 = 1; end
					R3 : begin Sel_R3 = 1; Load_R3 = 1; end
					default : err_flag = 1;
				endcase
			end
			
			S_rd1  : begin
				next_state = S_rd2;
				Sel_Mem    = 1;
				Load_Add_R = 1;
				Inc_PC     = 1;
			end
			
			S_wr1  : begin
				next_state = S_wr2;
				Sel_Mem    = 1;
				Load_Add_R = 1;
				Inc_PC     = 1;
			end
			
			S_rd2  : begin
				next_state = S_fet1;
				Sel_Mem    = 1;
				case(dest)
							R0      : Load_R0   = 1;
							R1      : Load_R1   = 1;
							R2      : Load_R2   = 1;
							R3      : Load_R3   = 1;
							default : err_flag = 1;
				endcase	
			end
			
			S_wr2  : begin
				next_state = S_fet1;
				write     = 1;
				case(src)
							R0      : Sel_R0   = 1;
							R1      : Sel_R1   = 1;
							R2      : Sel_R2   = 1;
							R3      : Sel_R3   = 1;
							default : err_flag = 1;
				endcase
			end
			
			S_br1  : begin
				next_state = S_br2;
				Sel_Mem    = 1;
				Load_Add_R = 1;
			end
			
			
			S_br2  : begin
				next_state = S_fet1;
				Sel_Mem    = 1;
				Load_PC    = 1;
			end	
			
			S_halt  : begin
				next_state = S_halt;
			end
			
			default : next_state = S_idle;
			
		endcase
	end
	
endmodule
			

/*存储器建模*/
module Memory_Unit #(parameter word_size = 8,memory_size = 256)
			( output [word_size-1:0] data_out,
			  input  [word_size-1:0] data_in,
			  input  [word_size-1:0] address,
			  input                  clk,write
			);
			
    reg [word_size-1:0] memory [memory_size-1:0];
	
	assign data_out = memory[address];
	always @ (posedge clk)
		if(write)
			memory[address] <= data_in;
endmodule


/*通用寄存器*/
module Register_Unit #(parameter word_size = 8)
			( output reg [word_size-1:0] data_out,
			  input      [word_size-1:0] data_in,
			  input                      load,
			  input                      clk,rst
			);
			
	always @(posedge clk,negedge rst)
		begin
		    if(rst == 1'b0)
				data_out <= 0;
			else if(load == 1'b1)
				data_out <= data_in;
		end
	
endmodule
	
/*D触发器*/
module D_flop  ( output reg data_out,
		         input      data_in,
				 input      load,
				 input      clk,rst
	           );
	always @(posedge clk,negedge rst)
		begin
		    if(rst == 1'b0)
				data_out <= 0;
			else if(load == 1'b1)
				data_out <= data_in;
		end
	
endmodule

/*地址寄存器Address*/
module Address_Register #(parameter word_size = 8)
			( output reg [word_size-1:0] data_out,
			  input      [word_size-1:0] data_in,
			  input                      load,
			  input                      clk,rst
			);
	always @(posedge clk,negedge rst)
		begin
		    if(rst == 1'b0)
				data_out <= 0;
			else if(load == 1'b1)
				data_out <= data_in;
		end
	
endmodule

/*指令寄存器IR*/
module Instruction_Register  #(parameter word_size = 8)
			( output reg [word_size-1:0] data_out,
			  input      [word_size-1:0] data_in,
			  input                      load,
			  input                      clk,rst
			);
	always @(posedge clk,negedge rst)
		begin
		    if(rst == 1'b0)
				data_out <= 0;
			else if(load == 1'b1)
				data_out <= data_in;
		end
endmodule

/*程序指令计数器PC*/
module Program_Counter  #(parameter word_size = 8)
			( output reg [word_size-1:0] count,
			  input      [word_size-1:0] data_in,
			  input                      Load_PC,Inc_PC,
			  input                      clk,rst
			);
	always @ (posedge clk,negedge rst)
		begin
			if(rst == 1'b0)
				count <= 0;
			else if(Load_PC == 1'b1)
				count <= data_in;
			else if(Inc_PC == 1'b1)
				count <= count + 1;
	   end
endmodule

/*总线1-5路选择器*/
module Multiplexer_5ch  #(parameter word_size = 8)
			( output     [word_size-1:0] mux_out,
			  input      [word_size-1:0] data_a,data_b,data_c,data_d,data_e,
			  input      [2:0]           sel
			 
			);
	assign mux_out = (sel == 0)  ? data_a : (sel == 1)
							     ? data_b : (sel == 2)
								 ? data_c : (sel == 3)
								 ? data_d : (sel == 4)
								 ? data_e : 8'bx;
endmodule

/*总线2-3路选择器*/
module Multiplexer_3ch  #(parameter word_size = 8)
			( output     [word_size-1:0] mux_out,
			  input      [word_size-1:0] data_a,data_b,data_c,
			  input      [1:0]           sel
			 
			);
	assign mux_out = (sel == 0)  ? data_a : (sel == 1)
							     ? data_b : (sel == 2)
								 ? data_c :  8'bx;
endmodule

/*ALU算术运算单元*/
module Alu_RISC #(parameter word_size = 8,op_size = 4,
					/*opcodes*/
					NOP = 4'b0000,
					ADD = 4'b0001,
					SUB = 4'b0010,
					AND = 4'b0011,
					NOT = 4'b0100,
					RD  = 4'b0101,
					WR  = 4'b0110,
					BR  = 4'b0111,
					BRZ = 4'b1000)
		( output reg [word_size-1:0] alu_out,
		  output                     alu_zero_flag,
		  input      [word_size-1:0] data_1,data_2,
		  input      [op_size-1  :0] sel
		);
	
	assign alu_zero_flag = ~|alu_out;
	always @ (sel,data_1,data_2)
		case (sel)
			NOP : alu_out = 0;
			ADD : alu_out = data_1 + data_2;
			SUB : alu_out = data_1 - data_2;
			AND : alu_out = data_1 & data_2;
			NOT : alu_out = ~data_2;
			default : alu_out = 0;
		endcase
endmodule
	
			
			
			
					
					
					
			
										  
										   
	
			  
