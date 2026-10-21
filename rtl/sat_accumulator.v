// Module: g04_sat_accum16
// Description: 16-bit Saturated Accumulator (2's complement)

module g04_sat_accum16 (
    input  logic        clk,
    input  logic        rst_n,      // Asynchronous active-low reset
    input  logic        clear,      // Synchronous clear
    input  logic        enable,     // Accumulate enable
    input  logic [15:0] in_data,    // 16-bit signed input
    output logic [15:0] out_data,   // 16-bit signed output
    output logic        saturated   // High when saturation occurs
);

    // Constants for 16-bit signed limits
    localparam logic [15:0] MAX_POS = 16'sh7FFF; // +32767
    localparam logic [15:0] MAX_NEG = 16'sh8000; // -32768

    logic signed [16:0] acc_ext; // Extended 17-bit accumulator for overflow detection
    logic signed [16:0] sum_ext;

    // Calculate extended sum
    assign sum_ext = $signed({acc_ext[15], acc_ext[15:0]}) + $signed({in_data[15], in_data});

    // Saturation Logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_ext   <= '0;
            saturated <= 1'b0;
        end else if (clear) begin
            acc_ext   <= '0;
            saturated <= 1'b0;
        end else if (enable) begin
            // Check for positive overflow (> +32767)
            if (sum_ext > $signed({1'b0, MAX_POS})) begin
                acc_ext   <= $signed({1'b0, MAX_POS});
                saturated <= 1'b1;
            end
            // Check for negative overflow (< -32768)
            else if (sum_ext < $signed({1'b1, MAX_NEG})) begin
                acc_ext   <= $signed({1'b1, MAX_NEG});
                saturated <= 1'b1;
            end
            // Normal accumulation
            else begin
                acc_ext   <= sum_ext;
                saturated <= 1'b0;
            end
        end
    end

    assign out_data = acc_ext[15:0];

endmodule
