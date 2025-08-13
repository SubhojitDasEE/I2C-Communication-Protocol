`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.08.2025 08:32:13
// Design Name: 
// Module Name: i2c_slave
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


module i2c_slave(input clk,
				input reset,
				inout sda,
				output reg sda_out,
				input scl,
				input [6:0]slave_addr,
				input [7:0]data_in,
				output reg [7:0]data_out,
				output reg data_ready
    );
	

	parameter clk_count=250;
	//..........state.......
	parameter idle=0, address=1, write=2, ackw=4, ack_wr=7, ack_rd=6, read=5;
	reg [3:0]state;
	reg scl_prev,sda_oe,sda_prev;	
	reg scl_posedge, sda_posedge;
	
	
	//.......process parameters........
	reg [3:0]count;
	reg [7:0]stop_count;
	reg [7:0]addr_reg, data_reg, read_st;
	wire sda_in;

	
	
	assign sda = (sda_oe) ? sda_out : 1'bz;
	assign sda_in = sda;
	
	always@(posedge clk or negedge reset)begin
		if(~reset)begin
			count<=0;
			state<=idle;
			data_ready<=0;
			data_out<=0;
			read_st<=0;
			data_reg<=0;
			scl_prev<=1;
			sda_oe<=0;
			stop_count<=0;
		end
		else begin
			scl_prev<=scl;
			sda_prev<=sda;
			scl_posedge <= (scl == 1) && (scl_prev == 0);
			sda_posedge <= (sda == 1) && (sda_prev == 0);
			data_reg<=data_in;
			data_ready<=0;
			case(state)
			
				idle:begin
					sda_oe<=0;
					count<=0;
					data_ready<=0;
					data_out<=0;
					read_st<=0;
					data_reg<=0;
					scl_prev<=1;
					state<=(~sda_in&scl)?address:idle;					
				end
				
				address:begin
					addr_reg[7-count]<=sda_in;
					if(scl_posedge)begin
						
						if(count==7)begin
							state<=(addr_reg[7:1]==slave_addr)?ackw:idle;
							count<=0;
						end
						else
							count<=count+1;
					end
				end
				
				ackw:begin
					sda_oe<=1;
					sda_out<=0;
					if(scl_posedge)begin					
						state<=(addr_reg[0]==1)?write:read;
						data_reg<=data_in;
					end
				end
				
				write:begin
					sda_oe<=1;
					sda_out<=data_reg[7-count];
					if(scl_posedge)begin
						
						if(count==7)begin
							count<=0;
							state<=ack_wr;
							data_ready<=1;
						end
						else
							count<=count+1;
					end
				end
				
				ack_wr:begin
					sda_oe<=0;
					if(scl_posedge)begin
						if(~sda_in)begin
							state<=write;						
						end
						else
							state<=idle;						
					end
				end
				
				read:begin
					sda_oe<=0;
					read_st[7-count]<=sda_in;
					if(scl_posedge)begin
					    stop_count<=0;						
					    if(count==7)begin
                            data_out<=read_st;
                            //data_ready<=1'b1;
                            count<=0;
                            state<=ack_rd;
                            sda_oe<=1;
                        end
                        else begin
                            count<=count+1;
                        end										
					end
					else begin
					   if(stop_count==clk_count-1)begin
					       if(sda&scl)
					           state<=idle;
					       else
					           stop_count<=0;
					    end
					    else 
					       stop_count<=stop_count+1;
					end
					
				end
				
				ack_rd:begin
						sda_out<=0;
						if (scl_posedge) begin
							state <= read;
							sda_oe <= 0; // release SDA after ACK
						end
					
				end
			
			endcase
		end
	end
	
	
endmodule
