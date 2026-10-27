
module g04_tb;
    logic clk, rst_n, valid_in;
    logic [15:0] inc_in;
    logic valid_out;
    logic [7:0] acc_out_hi;
    logic sat;

    g04_sat_accum16 dut(
        .clk(clk), .rst_n(rst_n), .valid_in(valid_in),
        .inc_in(inc_in), .valid_out(valid_out),
        .acc_out_hi(acc_out_hi), .sat(sat)
    );

    always #5 clk = ~clk;

    task automatic send(
        input logic [15:0] inc,
        input logic [7:0] exp_hi,
        input logic exp_sat,
        input logic [15:0] exp_acc
    );
        begin
            inc_in = inc;
            valid_in = 1'b1;
            @(posedge clk); #1;

            assert(valid_out)
                else $fatal(1, "valid_out missing");

            assert(acc_out_hi == exp_hi)
                else $fatal(1, "upper byte mismatch got=%h expected=%h",
                            acc_out_hi, exp_hi);

            assert(sat == exp_sat)
                else $fatal(1, "sat mismatch got=%b expected=%b",
                            sat, exp_sat);

            assert(dut.acc_q == exp_acc)
                else $fatal(1, "acc_q mismatch got=%h expected=%h",
                            dut.acc_q, exp_acc);

            valid_in = 1'b0;
        end
    endtask

    initial begin
        $dumpfile("/mnt/d/G04_Bo_tich_luy_co_bao_hoa_16bit/05_VERIFICATION/waveforms/g04_tb.vcd");
        $dumpvars(0, g04_tb);

        clk = 0;
        rst_n = 0;
        valid_in = 0;
        inc_in = 0;

        repeat(2) @(posedge clk);
        rst_n = 1;

        // ===== CAC KIEM THU GOC =====
        send(16'h0001, 8'h00, 0, 16'h0001);
        send(16'h00FF, 8'h01, 0, 16'h0100);
        send(16'hFE00, 8'hFF, 0, 16'hFF00);

        // CC-1: Dat dung nguong 0xFFFF, chua bao hoa
        send(16'h00FF, 8'hFF, 0, 16'hFFFF);

        // CC-2: Vuot nguong, bao hoa
        send(16'h0001, 8'hFF, 1, 16'hFFFF);

        // Sau bao hoa, tiep tuc cong so duong
        send(16'h0001, 8'hFF, 1, 16'hFFFF);

        // CC-4: Cong 0 khi dang bao hoa
        send(16'h0000, 8'hFF, 0, 16'hFFFF);

        // Kiem tra valid gap
        valid_in = 0;
        inc_in = 16'hFFFF;
        @(posedge clk); #1;
        assert(!valid_out)
            else $fatal(1, "gap generated valid_out");

        // ===== 3 CA KIEM THU MOI =====

        // CA 1: Reset bo tich luy ve 0
        @(negedge clk);
        rst_n = 0;
        repeat(2) @(posedge clk);
        @(negedge clk);
        rst_n = 1;

        // CA 1: Cong 0 khi bo tich luy bang 0
        send(16'h0000, 8'h00, 0, 16'h0000);

        // CA 2: Cong so nho sau reset
        send(16'h0002, 8'h00, 0, 16'h0002);

        // Reset lai de chuan bi CA 3
        @(negedge clk);
        rst_n = 0;
        repeat(2) @(posedge clk);
        @(negedge clk);
        rst_n = 1;

        // CA 3: Dat 0xFFFF nhung chua bao hoa
        send(16'hFFFE, 8'hFF, 0, 16'hFFFE);
        send(16'h0001, 8'hFF, 0, 16'hFFFF);

        $display("G04 TB completed");
        $finish;
    end
endmodule
