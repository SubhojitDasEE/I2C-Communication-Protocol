`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.08.2025 08:30:41
// Design Name: 
// Module Name: i2c_master
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module i2c_master(input clk,
					input reset,
					input start,
					input [7:0]byte_no,
					input [7:0]data_in,
					input [6:0]slave_addr,
					input rd_wr,
					inout sda,
					output reg ack_wstrobe,
					output reg sda_out,
					output reg sda_oe,
					output reg scl,
					output busy,
					output reg done,
					output reg[7:0]data_out

    );
	
	
	//..........SCL parameters.........
	// clk_freq=50_000_000;
	// i2c_freq=100_000;
	parameter clk_count=250;
	reg [15:0]scl_count;
	reg scl_posedge,scl_prev;
	
	//..........state.......
	parameter idle=0, START=1, address=2, write=3, ackw=4, ack_wr=6, ack_rd=7, read=5, stop=8;
	reg [4:0]state;
	
	
	//.......process parameters........
	reg [3:0]count;
	reg [7:0]stop_count;
	reg [7:0]addr_reg, data_reg, read_st;
	wire sda_in;
	reg [7:0] byte_count;
	
	
	
	
	//.............SCL clock generation...............
	
	always@(posedge clk or negedge reset)begin
		if(~reset)begin
			scl_count<=0;
			scl<=1;
			scl_posedge<=0;
			scl_prev<=1;
		end
		else begin
			if(~(state==idle | state==START | state==stop))begin
				if(scl_count==clk_count-1)begin
					scl<=~scl;
					scl_count<=0;
				end
				else begin
					scl_count<=scl_count+1;
					scl_posedge<=0;
				end				
				scl_posedge<=(~scl_prev)&scl;
				scl_prev<=scl;
			end
			else
				scl<=1;
		end
	end
	
	
	//..........state transition FSM............
	
	
	always@(posedge clk or negedge reset)begin
		if(!reset)begin
			state     <= idle;
            sda_out   <= 1;
			read_st<=0;
			count     <= 0;
			stop_count<=0;
			addr_reg  <= 0;
			data_reg  <= 0;
			sda_oe<=1;			
			done<=0;
		end
		else begin
		    data_reg<=data_in;
			ack_wstrobe<=1'b0;
			case(state)
			
				idle: begin
					count<=0;
					byte_count<=0;
					stop_count<=0;
					sda_out <= 1;
					addr_reg  <= 0;
					data_reg  <= 0;
					sda_oe<=1;
					scl<=1;
					scl_prev<=1;
					done<=0;
                    if (start) 
                        state <= START;
				end
				
				START:begin
					sda_out<=0;
					addr_reg<=(rd_wr)?{slave_addr,1'b1}:{slave_addr,1'b0};
					state<=address;
				end
				
				address:begin
				    sda_out<=addr_reg[7-count];
					if(scl_posedge)begin
						if(count==7)begin
							count<=0;
							state<=ackw;
						end
						else
							count<=count+1;
					end
				end
				
				ackw:begin
					data_reg<=data_in;
					sda_oe<=0;
					if(scl_posedge)begin
						state<=(sda)?stop:((rd_wr)?read:write);
					end
				end
				
				
				write:begin
					sda_oe<=1;
					sda_out<=data_reg[7-count];
					if(scl_posedge)begin						
						if(count==7)begin
							count<=0;
							state<=ack_wr;
						end
						else
							count<=count+1;
					end
				end
								
				ack_wr:begin
				    sda_oe<=0;
					if(scl_posedge)begin
						if(byte_count==byte_no-1)begin
							state<=stop;
							ack_wstrobe<=1'b1;
							done<=(~sda_in);
						end
						else begin
							if(~sda_in)begin
								byte_count<=byte_count+1;
								state<=write;
								ack_wstrobe<=1'b1;
							end
							else begin
								state<=stop;
							end
						end
					end
				end
								
				read:begin
					sda_oe<=0;
					read_st[7-count]<=sda_in;
					if(scl_posedge)begin
						
						if(count==7)begin
							count<=0;
							state<=ack_rd;
							data_out<=read_st;
							sda_oe<=1;
						end
						else
							count<=count+1;
					end
				end
				
				ack_rd:begin
					sda_out <= (byte_count == byte_no - 1) ? 1'b1 : 1'b0;
					if(scl_posedge)begin
						if(byte_count==byte_no-1)begin
							state<=stop;
							done<=1'b1;
						end
						else begin
							byte_count<=byte_count+1;
							state<=read;
						end
					end
				end
				
				
				stop:begin
					scl<=1;
					scl_prev<=1;
					sda_oe<=1;
					sda_out<=1;
					if(stop_count==(clk_count-1))begin
						state<=idle;
						stop_count<=0;
					end
					else
						stop_count<=stop_count+1;
					
				end
				
				default:state<=idle;
				
			endcase
		end
	end
	
	
	
	assign sda = (sda_oe) ? sda_out : 1'bz;
	assign sda_in = sda;

	assign busy = (state==write | state==read | state==address);
	
	
	
	
	
endmodule
