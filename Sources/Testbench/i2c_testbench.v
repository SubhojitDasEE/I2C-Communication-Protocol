module i2c_test_write_then_read();

    reg clk = 0;
    reg reset = 0;
    reg start = 0;
    reg [6:0] slave_addr = 7'h42;
    reg rd_wr = 0;  // Start with Write
    reg [7:0] data_in;
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
        .byte_no(3), .data_in(data_in), .slave_addr(slave_addr),
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
        .data_in(data_in),  // For simplicity
        .data_out(slave_data_out), .data_ready(slave_data_ready)
    );

    // Clock
    always #10 clk = ~clk;  // 50 MHz

    // Write & Read Buffers
    reg [7:0] bytes_to_send [0:2];
    reg [7:0] bytes_to_read  [0:2];
    integer i;

    initial begin
        // Data to be written to slave
        bytes_to_send[0] = 8'hAA;
        bytes_to_send[1] = 8'hBB;
        bytes_to_send[2] = 8'hCC;

        // Data to be sent from slave during read
        bytes_to_read[0] = 8'hDE;
        bytes_to_read[1] = 8'hAD;
        bytes_to_read[2] = 8'hBE;

        // Reset system
        reset = 0;
        #50;
        reset = 1;
        #50;

        //-----------------------------------------
        // WRITE PROCESS
        //-----------------------------------------
        rd_wr = 0;  // Write
        start = 1;
        #20;
        start = 0;

        for (i = 0; i < 3; i = i + 1) begin
            data_in = bytes_to_send[i];
            #50;
            wait(ack_wstrobe);
            #50;
        end

        $display("Multi-byte write test completed at time %0t", $time);

        //-----------------------------------------
        // DELAY BETWEEN WRITE AND READ
        //-----------------------------------------
        #50000;

        //-----------------------------------------
        // READ PROCESS
        //-----------------------------------------
        rd_wr = 1;  // Read
        start = 1;
        #20;
        start = 0;

        for (i = 0; i < 3; i = i + 1) begin
            data_in = bytes_to_read[i];  // Slave sends this to master
            #50;
            wait(slave_data_ready);
            #50;
            $display("Master received byte %0d: %h at time %0t", i, data_out_master, $time);
        end

        wait(done);
        $display("Multi-byte read test completed at time %0t", $time);
        $finish;
    end

    // Debug Monitor
    initial begin
        $monitor("Time=%0t | Master State=%0d | Slave State=%0d | Data In=%h | Master Out=%h | Slave Out=%h | Ready=%b",
                 $time, master_inst.state, slave_inst.state, data_in, data_out_master, slave_data_out, slave_data_ready);
    end

endmodule

