# Tài liệu Đặc tả Kỹ thuật - Saturation Accumulator 16-bit

## 1. Tổng quan
Bộ tích lũy 16-bit có tính năng bão hòa (Saturation Accumulator), nhận các mẫu ngõ vào 8-bit không dấu và cộng dồn vào thanh ghi tích lũy 16-bit. Khi tổng đạt đến giá trị tối đa (65535), mạch duy trì ở giá trị bão hòa cực đại `16'hFFFF` và bật cờ báo bão hòa (`uio_out[0]`).

## 2. Bảng mô tả tín hiệu (Pinout Table)
| Tín hiệu | Hướng | Độ rộng bit | Mô tả |
| :--- | :--- | :--- | :--- |
| `clk` | Input | 1 bit | Clock hệ thống |
| `rst_n` | Input | 1 bit | Reset cứng (Active-low, đồng bộ/bất đồng bộ) |
| `ui_in[7:0]` | Input | 8 bit | Mẫu dữ liệu ngõ vào (Unsigned 8-bit) |
| `uio_in[0]` | Input | 1 bit | Tín hiệu điều khiển cộng (Add enable) |
| `uio_in[1]` | Input | 1 bit | Tín hiệu xóa bộ tích lũy (Clear enable) |
| `uo_out[7:0]` | Output | 8 bit | 8 bit thấp của giá trị tích lũy (`acc[7:0]`) |
| `uio_out[0]` | Output | 1 bit | Cờ báo bão hòa (1 = Saturation/Overflow) |
| `uio_out[7:1]`| Output | 7 bit | 7 bit cao của giá trị tích lũy (`acc[15:9]`) |

## 3. Quy tắc hoạt động và Ưu tiên
1. **Reset (`rst_n = 0`)**: Đưa bộ tích lũy về `16'h0000`, `uio_out[0] = 0`.
2. **Clear (`uio_in[1] = 1`)**: Ưu tiên cao hơn Add. Đưa bộ tích lũy về `16'h0000`, xóa cờ bão hòa (`uio_out[0] = 0`).
3. **Add (`uio_in[0] = 1` và `uio_in[1] = 0`)**:
   - Nếu `acc + ui_in >= 65535`, giá trị tích lũy giữ nguyên tại `16'hFFFF` và `uio_out[0] = 1`.
   - Ngược lại, `acc <= acc + ui_in`.