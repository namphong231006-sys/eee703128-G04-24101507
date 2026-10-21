`timescale 1ns/1ps

module tb_g04_sat_accum16;

    logic        clk;
    logic        rst_n;
    logic        clear;
    logic        enable;
    logic [15:0] in_data;
    logic [15:0] out_data;
    logic        saturated;

    // Instantiate Duty Under Test (DUT)
    g04_sat_accum16 dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .clear    (clear),
        .enable   (enable),
        .in_data  (in_data),
        .out_data (out_data),
        .saturated(saturated)
    );

    // Clock generation (100MHz)
    always #5 clk = ~clk;

    initial begin
        // Initialize Signals
        clk     = 0;
        rst_n   = 0;
        clear   = 0;
        enable  = 0;
        in_data = 0;

        // Reset
        #15 rst_n = 1;
        #10;

        // Test Case 1: Normal Accumulation
        $display("=== TC1: Normal Accumulation ===");
        enable  = 1;
        in_data = 16'h1000; #10; // +4096
        in_data = 16'h2000; #10; // +8192 -> total 12288
        
        // Test Case 2: Positive Saturation
        $display("=== TC2: Positive Saturation ===");
        in_data = 16'h6000; #10; // 12288 + 24576 = 36864 > 32767 -> Saturated 0x7FFF
        
        // Test Case 3: Clear
        $display("=== TC3: Clear ===");
        clear = 1; #10;
        clear = 0;

        // Test Case 4: Negative Saturation
        $display("=== TC4: Negative Saturation ===");
        in_data = -16'sd20000; #10;
        in_data = -16'sd20000; #10; // -40000 < -32768 -> Saturated 0x8000

        #20;
        $display("=== Simulation Finished ===");
        $finish;
    end

endmodule
