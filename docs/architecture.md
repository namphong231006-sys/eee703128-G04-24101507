# Sơ đồ Kiến trúc Hardware - Saturation Accumulator 16-bit (G04)

## 1. Sơ đồ khối tổng quan

````text
                    +-----------------------------------+
                    |          Control Logic            |
                    |    - Add   (uio_in[0])            |
                    |    - Clear (uio_in[1])            |
                    +-----------------+-----------------+
                                      |
                                      | add_en, clr
                                      v
            +-----------+      +--------------+
ui_in[7:0] >| Zero Ext  |----->| 17-bit Adder |<------------------+
            |  (8->17)  |      +------+-------+                   |
            +-----------+             |                           |
                                      | sum_ext[16:0]             |
                                      v                           |
                              +---------------+                   |
                              | Sat Detector  |                   |
                              | & Limit Logic |                   |
                              +-------+-------+                   |
                                      |                           |
                                      | next_acc[15:0], sat       |
                                      v                           |
                              +---------------+                   |
clk   ----------------------->| 16-bit Reg    |                   |
rst_n ----------------------->|   (acc_reg)   |-------------------+
                              +-------+-------+   acc_reg[15:0]
                                      |
                  +-------------------+-------------------+
                  |                                       |
                  v                                       v
             uo_out[7:0]                             uio_out[7:0]
           (acc_reg[7:0])                          (acc_reg[15:8])

                      sat_flag ----> (chân riêng)
````
## 2. Các thành phần chính trong Datapath

1. **Zero Extension (Khối mở rộng bit):**
   - Chuyển ngõ vào mẫu `ui_in[7:0]` (8-bit) thành 17-bit (`{9'b0, ui_in}`) để phục vụ phép cộng không dấu với thanh ghi 16-bit mà không bị tràn bit.

2. **17-bit Adder (Bộ cộng 17-bit):**
   - Thực hiện phép cộng `sum_ext = {1'b0, acc_reg} + {9'b0, ui_in}`.
   - Bit thứ 16 (`sum_ext[16]`) đóng vai trò là Carry-out (Cờ tràn hardware).

3. **Saturation Detector & Limit Logic (Bộ phát hiện bão hòa):**
   - Kiểm tra xem `sum_ext[16] == 1` hoặc `acc_reg` đã ở mức `16'hFFFF`.
   - Nếu điều kiện bão hòa xảy ra: Giữ nguyên `acc_reg = 16'hFFFF` và bật `sat_flag = 1`.

4. **16-bit Accumulator Register (`acc_reg`):**
   - Thanh ghi lưu giữ giá trị cộng dồn qua từng chu kỳ xung clock.
   - Được xoá về `16'h0000` khi `rst_n = 0` hoặc `uio_in[1] (Clear) = 1`.