`timescale 1ns / 1ps

// Testbench for the robust synchronous FIFO
module tb_robust_sync_fifo;

    // Testbench input signals
    reg clk = 0;       // Clock signal, initially LOW
    reg rst = 1;       // Active-high reset, initially asserted
    reg wr_en = 0;     // Write enable
    reg rd_en = 0;     // Read enable

    // 8-bit data input to the FIFO
    reg [7:0] data_in = 0;

    // Testbench output signals from the FIFO
    wire [7:0] data_out;
    wire full;         // Indicates FIFO is full
    wire empty;        // Indicates FIFO is empty

    // Indicates whether read/write operations are actually accepted
    wire wr_accept;
    wire rd_accept;

    // FIFO occupancy counter (0 to 4 for a depth-4 FIFO)
    wire [2:0] count;


    // Instantiate the Device Under Test (DUT)
    // Connect testbench signals to the FIFO module ports
    robust_sync_fifo dut (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .data_in(data_in),
        .rd_en(rd_en),
        .data_out(data_out),
        .full(full),
        .empty(empty),
        .count(count),
        .wr_accept(wr_accept),
        .rd_accept(rd_accept)
    );


    // Generate a clock with a 10 ns period
    // Clock changes state every 5 ns:
    // 5 ns HIGH + 5 ns LOW = 10 ns period
    always #5 clk = ~clk;


    // Main test sequence
    initial begin

        // Apply reset initially
        // Reset is released after 12 ns
        #12 rst = 0;


        // ------------------------------------------------
        // TEST 1: Write first data word into FIFO
        // ------------------------------------------------

        // Wait for the next falling edge of the clock
        // This avoids changing inputs near the active rising edge
        @(negedge clk);

        wr_en = 1;              // Enable FIFO write
        data_in = 8'h10;        // Write hexadecimal 10


        // ------------------------------------------------
        // TEST 2: Write second data word into FIFO
        // ------------------------------------------------

        @(negedge clk);

        wr_en = 1;              // Keep write enabled
        data_in = 8'h20;        // Write hexadecimal 20


        // ------------------------------------------------
        // TEST 3: Read first data word from FIFO
        // ------------------------------------------------

        @(negedge clk);

        wr_en = 0;              // Disable writing
        rd_en = 1;              // Enable reading

        // FIFO should return the oldest stored data first


        // Check the read data at the next falling edge
        @(negedge clk);

        // Verify that the first data word read is 8'h10
        // !== also detects unknown (X) values
        if (data_out !== 8'h10)
            $fatal(1, "Read ordering failed");


        // ------------------------------------------------
        // TEST 4: Simultaneous read and write operation
        // ------------------------------------------------

        // At this point, FIFO contains 8'h20
        // Enable both read and write operations
        wr_en = 1;
        data_in = 8'h30;        // New data to be written
        rd_en = 1;              // Read existing data

        // Both operations should be accepted because
        // FIFO is neither full nor empty


        @(negedge clk);

        // One word was read and one word was written.
        // Therefore, FIFO occupancy should remain unchanged.
        if (count != 1)
            $fatal(1, "Simultaneous operation changed occupancy");


        // ------------------------------------------------
        // TEST 5: Read remaining FIFO data
        // ------------------------------------------------

        wr_en = 0;              // Disable writing
        rd_en = 1;              // Continue reading

        @(negedge clk);

        // The remaining data has now been read.
        // Disable read enable.
        rd_en = 0;


        // ------------------------------------------------
        // TEST 6: Verify FIFO empty condition
        // ------------------------------------------------

        // Check whether FIFO reports an empty condition
        if (!empty)
            $fatal(1, "Expected empty");


        // ------------------------------------------------
        // TEST COMPLETE
        // ------------------------------------------------

        $display("LEVEL 4 PASS");
        $finish;                // End simulation

    end

endmodule