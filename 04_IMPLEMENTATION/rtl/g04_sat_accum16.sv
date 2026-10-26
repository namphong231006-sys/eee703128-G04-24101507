module g04_sat_accum16 (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        valid_in,
    input  logic [15:0] inc_in,
    output logic        valid_out,
    output logic [7:0]  acc_out_hi,
    output logic        sat
);

    logic [15:0] acc_q;
    logic [16:0] total_ext;
    logic [15:0] acc_next;
    logic        sat_next;

    assign total_ext = {1'b0, acc_q} + {1'b0, inc_in};

    always_comb begin
        sat_next = total_ext[16];
        acc_next = total_ext[16] ? 16'hFFFF : total_ext[15:0];
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            acc_q      <= 16'h0000;
            valid_out  <= 1'b0;
            acc_out_hi <= 8'h00;
            sat        <= 1'b0;
        end else begin
            valid_out <= 1'b0;

            if (valid_in) begin
                acc_q      <= acc_next;
                acc_out_hi <= acc_next[15:8];
                sat        <= sat_next;
                valid_out  <= 1'b1;
            end
        end
    end

endmodule
