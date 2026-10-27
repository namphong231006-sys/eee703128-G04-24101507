module g04_tb;
    logic clk,rst_n,valid_in;
    logic [15:0] inc_in;
    logic valid_out;
    logic [7:0] acc_out_hi;
    logic sat;

    g04_sat_accum16 dut(
        .clk(clk), .rst_n(rst_n), .valid_in(valid_in),
        .inc_in(inc_in), .valid_out(valid_out),
        .acc_out_hi(acc_out_hi), .sat(sat)
    );

    always #5 clk=~clk;

    task automatic send(
        input logic [15:0] inc,
        input logic [7:0] exp_hi,
        input logic exp_sat
    );
        begin
            inc_in=inc;
            valid_in=1'b1;
            @(posedge clk); #1;
            assert(valid_out)
                else $fatal(1,"valid_out missing");
            assert(acc_out_hi==exp_hi)
                else $fatal(1,"upper byte mismatch got=%h expected=%h",
                            acc_out_hi,exp_hi);
            assert(sat==exp_sat)
                else $fatal(1,"sat mismatch got=%b expected=%b",sat,exp_sat);
            valid_in=1'b0;
        end
    endtask

    initial begin
        clk=0; rst_n=0; valid_in=0; inc_in=0;
        repeat(2) @(posedge clk);
        rst_n=1;

        send(16'h0001,8'h00,0);
        send(16'h00FF,8'h01,0);
        send(16'hFE00,8'hFF,0);
        send(16'h0001,8'hFF,1);

        // Once saturated, further positive increments remain saturated.
        send(16'h0001,8'hFF,1);

        // valid gap must not create an update.
        valid_in=0; inc_in=16'hFFFF;
        @(posedge clk); #1;
        assert(!valid_out) else $fatal(1,"gap generated valid_out");

        $display("G04 TB completed");
        $finish;
    end
endmodule
