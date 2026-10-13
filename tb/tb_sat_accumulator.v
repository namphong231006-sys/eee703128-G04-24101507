`timescale 1ns/1ps

module tb_sat_accumulator;

    reg        clk;
    reg        rst_n;
    reg  [7:0] ui_in;
    reg  [7:0] uio_in;
    wire [7:0] uo_out;
    wire [7:0] uio_out;

    integer errors = 0;

    sat_accumulator dut (
        .clk(clk),
        .rst_n(rst_n),
        .ui_in(ui_in),
        .uio_in(uio_in),
        .uo_out(uo_out),
        .uio_out(uio_out)
    );

    always #5 clk = ~clk;

    task check_output;
        input [15:0] expected_acc;
        input        expected_sat;
        input [100*8:1] test_name;
        begin
            if (uio_out[0] !== expected_sat) begin
                $display("[FAIL] %0s: Saturation flag mismatch! Expected: %b, Got: %b", test_name, expected_sat, uio_out[0]);
                errors = errors + 1;
            end else begin
                $display("[PASS] %0s: Saturation flag = %b", test_name, uio_out[0]);
            end
        end
    endtask

    initial begin
        $dumpfile("sim/tb_sat_accumulator.vcd");
        $dumpvars(0, tb_sat_accumulator);

        clk    = 0;
        rst_n  = 0;
        ui_in  = 8'h00;
        uio_in = 8'h00;

        $display("--------------------------------------------------");
        $display("STARTING FUNCTIONAL VERIFICATION");
        $display("--------------------------------------------------");

        #15;
        rst_n = 1;
        #10;
        check_output(16'h0000, 1'b0, "Test 1: Reset state");

        uio_in[0] = 1;
        ui_in     = 8'd100;
        #10;
        ui_in     = 8'd50;
        #10;
        uio_in[0] = 0;
        #10;
        check_output(16'd150, 1'b0, "Test 2: Normal Addition");

        uio_in[1] = 1;
        #10;
        uio_in[1] = 0;
        #10;
        check_output(16'h0000, 1'b0, "Test 3: Clear Accumulator");

        uio_in[0] = 1;
        ui_in     = 8'hFF;
        
        repeat (258) begin
            #10;
        end
        
        check_output(16'hFFFF, 1'b1, "Test 4: Saturation Limit Reached");

        ui_in = 8'd50;
        #10;
        check_output(16'hFFFF, 1'b1, "Test 5: Hold Saturation Value");

        $display("--------------------------------------------------");
        if (errors == 0) begin
            $display("ALL TESTS PASSED SUCCESSFULLY!");
        end else begin
            $display("VERIFICATION FAILED WITH %0d ERRORS.", errors);
        end
        $display("--------------------------------------------------");

        $finish;
    end

endmodule