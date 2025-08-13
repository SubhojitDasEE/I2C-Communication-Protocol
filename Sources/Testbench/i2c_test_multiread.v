`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: 
// Create Date: 11.08.2025 
// Design Name: 
// Module Name: i2c_test_multiread
//////////////////////////////////////////////////////////////////////////////////

module i2c_test_multiread();

    reg clk = 0;
    reg reset = 0;
    reg start = 0;
    reg [6:0] slave_addr = 7'h42;
    reg rd_wr = 1;  // Read from master point of view
    reg [7:0] data_in;  // Slave will put this on the bus
    wire ack_wstrobe, sda_out_master, sda_oe_master, scl, busy, done;
    wire [7:0] data_out_master;
    wire [7:0] slave_data_out;
    wire slave_data_ready;
    wire sda_out_slave;
    wire sda;

    // Tristate SDA
    wire sda_wire;
    assign sda = sda_wire;
    assign sda_wire = (sda_oe_master) ? sda_out_master :
                      (slave_inst.sda_oe) ? sda_out_slave : 1'bz;

    // Instantiate master
    i2c_master master_inst (
        .clk(clk), .reset(reset), .start(start),
        .byte_no(3),  // Read 3 bytes
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
        .data_in(data_in),  // Slave will drive this
        .data_out(slave_data_out), .data_ready(slave_data_ready)
    );

    // Clock
    always #10 clk = ~clk;  // 50 MHz

    reg [7:0] read_values [0:2];  // Expected to be read by master
    integer i = 0;

    initial begin
        // Set the data slave will send
        read_values[0] = 8'hDE;
        read_values[1] = 8'hAD;
        read_values[2] = 8'hBE;

        reset = 0;
        #50;
        reset = 1;
        #50;

        start = 1;
        #20;
        start = 0;

        for (i = 0; i < 3; i = i + 1) begin
            data_in = read_values[i];  // Slave drives this to master
            #50;
            wait(slave_data_ready);   // Wait for slave to latch it out
            #50;  // Give time for master to capture
            $display("Master received byte %0d: %h at time %0t", i, data_out_master, $time);
        end

        wait(done);
        $display("Multi-byte read test completed at time %0t", $time);
        $finish;
    end

    // Debug Monitor
    initial begin
        $monitor("Time=%0t | Master State=%0d | Slave State=%0d | Master Data Out=%h | Slave Ready=%b",
                  $time, master_inst.state, slave_inst.state, data_out_master, slave_data_ready);
    end

endmodule
