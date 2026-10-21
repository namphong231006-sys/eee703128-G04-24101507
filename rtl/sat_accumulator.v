/*
 * Module: sat_accumulator
 * Description: 16-bit Saturation Accumulator for Tiny Tapeout
 */

`default_nettype none

module sat_accumulator (
    input  wire       clk,        // Clock hệ thống
    input  wire       rst_n,      // Reset cứng (Active-low)
    input  wire [7:0] ui_in,      // Mẫu ngõ vào 8-bit
    input  wire [7:0] uio_in,     // uio_in[0] = Add, uio_in[1] = Clear
    output wire [7:0] uo_out,     // 8 bit thấp của bộ tích lũy acc[7:0]
    output wire [7:0] uio_out     // uio_out[0] = Flag bão hòa, uio_out[7:1] = acc[15:9]
);

    // Thanh ghi lưu giá trị tích lũy 16-bit
    reg [15:0] acc_reg;
    reg        sat_flag_reg;

    // Tín hiệu điều khiển
    wire add_en   = uio_in[0];
    wire clear_en = uio_in[1];

    // Biến tính toán phép cộng 17-bit để kiểm tra tràn
    wire [16:0] sum_ext = {1'b0, acc_reg} + {9'b0, ui_in};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_reg      <= 16'h0000;
            sat_flag_reg <= 1'b0;
        end else begin
            if (clear_en) begin
                // Xóa bộ tích lũy và cờ bão hòa
                acc_reg      <= 16'h0000;
                sat_flag_reg <= 1'b0;
            end else if (add_en) begin
                if (sat_flag_reg || sum_ext[16] || (sum_ext[15:0] == 16'hFFFF)) begin
                    // Đạt hoặc vượt ngưỡng cực đại (65535) -> Giữ ở bão hòa
                    acc_reg      <= 16'hFFFF;
                    sat_flag_reg <= 1'b1;
                end else begin
                    // Cộng bình thường
                    acc_reg      <= sum_ext[15:0];
                    sat_flag_reg <= 1'b0;
                end
            end
        end
    end

    // Gán ngõ ra
    assign uo_out      = acc_reg[7:0];
    assign uio_out[0]  = sat_flag_reg;
    assign uio_out[7:1] = acc_reg[15:9];

endmodule
