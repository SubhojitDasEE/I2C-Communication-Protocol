`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.08.2025 17:12:43
// Design Name: 
// Module Name: i2c_test_multiwrite
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


module i2c_test_multiwrite(

    );
	 reg clk = 0;
    reg reset = 0;
    reg start = 0;
    reg [6:0] slave_addr = 7'h42;
    reg rd_wr = 0;  // Write
    reg [7:0] data_in;
    wire ack_wstrobe, sda_out_master, sda_oe_master, scl, busy, done;
    wire [7:0] data_out_master;
    wire [7:0] slave_data_out;
    wire slave_data_ready;
    wire sda_out_slave;
    wire sda;

    // For SDA tristate
    wire sda_wire;
    assign sda = sda_wire;
    assign sda_wire = (sda_oe_master) ? sda_out_master :
                      (slave_inst.sda_oe) ? sda_out_slave : 1'bz;

    // Instantiate master
    i2c_master master_inst (
        .clk(clk), .reset(reset), .start(start),
        .byte_no(3),  // Sending 3 bytes
        .data_in(data_in), .slave_addr(slave_addr),
        .rd_wr(rd_wr), .sda(sda),
        .ack_wstrobe(ack_wstrobe), .sda_out(sda_out_master),
        .sda_oe(sda_oe_master), .scl(scl),
        .busy(busy), .done(done),
        .data_out(data_out_master)
    );

    // Instantiate slave
    i2c_slave slave_inst (
        .clk(clk), .reset(reset), .sda(sda),
        .sda_out(sda_out_slave), .scl(scl),
        .slave_addr(slave_addr),
        .data_in(data_in),  // For simplicity, provide same byte; real design may differ
        .data_out(slave_data_out), .data_ready(slave_data_ready)
    );

    // Clock gen
    always #10 clk = ~clk; // 50 MHz

    reg [1:0] byte_index = 0;
    reg [7:0] bytes_to_send [0:2];  // 3 bytes

    initial begin
        bytes_to_send[0] = 8'hAA;
        bytes_to_send[1] = 8'hBB;
        bytes_to_send[2] = 8'hCC;

        reset = 0;
        #50;
        reset = 1;

        #50;
        start = 1;
            #20;
            start = 0;

        for (byte_index = 0; byte_index < 3; byte_index = byte_index + 1) begin
            data_in = bytes_to_send[byte_index];
            #50
            wait(ack_wstrobe);
            #50;
        end

        $display("Multi-byte write test completed at time %0t", $time);
        
        $finish;
    end

    // Debug
    initial begin
        $monitor("Time=%0t | Master State=%0d | Slave State=%0d | Data Sent=%h | Slave Data Out=%h | Ready=%b",
                  $time, master_inst.state, slave_inst.state, data_in, slave_data_out, slave_data_ready);
    end


endmodule
