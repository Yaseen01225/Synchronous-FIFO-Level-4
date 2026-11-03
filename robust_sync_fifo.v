`timescale 1ns / 1ps

//==============================================================
// Module: robust_sync_fifo
// Description:
// A synchronous FIFO (First-In First-Out) memory buffer.
// Data is written and read using the same clock.
//
// Level 4: Explicit acceptance policy for simultaneous
// read and write operations.
//
// Acceptance policy:
// 1. Write is accepted only when FIFO is NOT full.
// 2. Read is accepted only when FIFO is NOT empty.
// 3. At full condition, a simultaneous read does NOT allow
//    a write on the same clock edge.
// 4. At empty condition, a simultaneous write does NOT allow
//    a read on the same clock edge.
//==============================================================

module robust_sync_fifo #(

    // Width of each data word stored in FIFO
    parameter DATA_WIDTH = 8,

    // Total number of storage locations in FIFO
    parameter DEPTH = 4,

    // Width of read and write address pointers
    parameter ADDR_WIDTH = 2,

    // Width of FIFO occupancy counter
    parameter COUNT_WIDTH = 3

)(

    // Clock and reset signals
    input wire clk,
    input wire rst,

    // Write interface
    input wire wr_en,                     // Write enable
    input wire [DATA_WIDTH-1:0] data_in, // Input data

    // Read interface
    input wire rd_en,                     // Read enable
    output reg [DATA_WIDTH-1:0] data_out,// Output data

    // FIFO status signals
    output wire full,                     // FIFO is full
    output wire empty,                    // FIFO is empty

    // Number of occupied FIFO locations
    output reg [COUNT_WIDTH-1:0] count,

    // Indicates whether read/write requests are accepted
    output wire wr_accept,
    output wire rd_accept
);

    //==========================================================
    // 1. FIFO MEMORY
    //==========================================================

    // Memory array containing DEPTH locations.
    // Each location stores DATA_WIDTH bits.
    reg [DATA_WIDTH-1:0] memory [0:DEPTH-1];


    //==========================================================
    // 2. READ AND WRITE POINTERS
    //==========================================================

    // wr_ptr points to the next memory location for writing.
    reg [ADDR_WIDTH-1:0] wr_ptr;

    // rd_ptr points to the next memory location for reading.
    reg [ADDR_WIDTH-1:0] rd_ptr;


    //==========================================================
    // 3. FIFO STATUS GENERATION
    //==========================================================

    // FIFO becomes FULL when occupied locations equal DEPTH.
    assign full = (count == DEPTH);

    // FIFO becomes EMPTY when no data is stored.
    assign empty = (count == 0);


    //==========================================================
    // 4. READ/WRITE ACCEPTANCE LOGIC
    //==========================================================

    // Write request is accepted only if FIFO is not full.
    assign wr_accept = wr_en && !full;

    // Read request is accepted only if FIFO is not empty.
    assign rd_accept = rd_en && !empty;


    //==========================================================
    // 5. WRITE POINTER AND MEMORY CONTROL
    //==========================================================

    always @(posedge clk) begin

        // Reset write pointer to first memory location.
        if (rst)
            wr_ptr <= 0;

        // Perform write only when write request is accepted.
        else if (wr_accept) begin

            // Store input data at the current write address.
            memory[wr_ptr] <= data_in;

            // Wrap pointer to zero after reaching last location.
            if (wr_ptr == DEPTH-1)
                wr_ptr <= 0;

            // Otherwise increment write pointer.
            else
                wr_ptr <= wr_ptr + 1'b1;

        end
    end


    //==========================================================
    // 6. READ POINTER AND OUTPUT DATA CONTROL
    //==========================================================

    always @(posedge clk) begin

        if (rst) begin

            // Reset read pointer.
            rd_ptr <= 0;

            // Clear output register.
            data_out <= 0;

        end

        // Read data only when read request is accepted.
        else if (rd_accept) begin

            // Transfer FIFO memory data to output register.
            data_out <= memory[rd_ptr];

            // Wrap read pointer after last memory location.
            if (rd_ptr == DEPTH-1)
                rd_ptr <= 0;

            // Otherwise increment read pointer.
            else
                rd_ptr <= rd_ptr + 1'b1;

        end
    end


    //==========================================================
    // 7. FIFO OCCUPANCY COUNTER
    //==========================================================

    always @(posedge clk) begin

        // Reset occupancy counter.
        if (rst)
            count <= 0;

        else begin

            // Check accepted read and write operations.
            case ({wr_accept, rd_accept})

                // Case 1: Write accepted, read not accepted.
                // FIFO occupancy increases by one.
                2'b10:
                    count <= count + 1'b1;

                // Case 2: Read accepted, write not accepted.
                // FIFO occupancy decreases by one.
                2'b01:
                    count <= count - 1'b1;

                // Case 3: Both read and write accepted.
                // One item enters and one item leaves.
                // Therefore, occupancy remains unchanged.
                2'b11:
                    count <= count;

                // Case 4: Neither operation accepted.
                // FIFO occupancy remains unchanged.
                2'b00:
                    count <= count;

            endcase
        end
    end

endmodule

//==============================================================
// End of robust_sync_fifo module
//==============================================================