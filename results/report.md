# Báo Cáo Kỹ Thuật: Thiết Kế Và Triển Khai Bộ Tích Lũy Bão Hòa 16-Bit (16-Bit Saturating Accumulator)

**PDK Mục tiêu:** SkyWater 130nm (`sky130_fd_sc_hd`)  
**Kích thước diện tích (Footprint):** Tiny Tapeout 1x1 Tile ($100\,\mu\text{m} \times 160\,\mu\text{m}$)  
**Bộ công cụ sử dụng (Toolchain):** Icarus Verilog, Yosys, OpenSTA, OpenLane v1, KLayout, Git/GitHub Actions  

---

## 1. Tóm Tắt Tổng Quan (Executive Summary)

Báo cáo này trình bày chi tiết toàn bộ quy trình thiết kế, kiểm thử logic, tổng hợp mạch, và thiết kế vật lý (RTL-to-GDSII) cho vi mạch **Bộ tích lũy bão hòa 16-bit với giao tiếp I/O 8-bit**. Thiết kế đáp ứng chính xác các quy chuẩn diện tích khung khung $1\times1$ Tile của Tiny Tapeout trên công nghệ SkyWater 130nm. Mạch tích hợp logic bão hòa chống tràn tại giá trị tối đa `16'hFFFF` và hoàn tất quy trình kiểm tra signoff đạt 0 lỗi DRC/LVS.

---

## 2. Đặc Tả Kiến Trúc & Tín Hiệu Vào/Ra (Pinout)

### 2.1 Tổng Quan Kiến Trúc

Bộ tích lũy duy trì một thanh ghi nội bộ 16-bit (`acc`). Khi có xung điều khiển `add`, giá trị đầu vào 8-bit (`din`) sẽ được cộng dồn vào thanh ghi:

* **Chế độ hoạt động bình thường:** Nếu $\text{acc} + \text{din} \le \text{16'hFFFF}$, thanh ghi `acc` cập nhật giá trị tổng mới.
* **Chế độ Bão hòa (Saturation):** Nếu $\text{acc} + \text{din} > \text{16'hFFFF}$, thanh ghi `acc` được giữ cố định tại giá trị cực đại `16'hFFFF`.
* **Chế độ Xóa (Clear):** Khi tín hiệu `clear` lên mức tích cực High, thanh ghi `acc` tự động reset về `16'h0000`.
* **Đa hợp Đầu ra (Multiplexed Output):** Tín hiệu đầu ra 8-bit `dout` hiển thị Byte thấp `acc[7:0]` hoặc Byte cao `acc[15:8]` tùy thuộc vào chân chọn `sel_hi`.

### 2.2 Bảng Chân Tín Hiệu (Pin Mapping)

| Tên Tín Hiệu | Hướng Tín Hiệu | Độ Rộng (Bits) | Mô Tả Chức Năng |
| :--- | :--- | :--- | :--- |
| `clk` | Input | 1 | Xung đồng hồ hệ thống (Master clock) |
| `rst_n` | Input | 1 | Tín hiệu Reset cứng (Active-low) |
| `clear` | Input | 1 | Xóa giá trị bộ tích lũy về 0 |
| `add` | Input | 1 | Cho phép cộng dồn dữ liệu đầu vào |
| `sel_hi` | Input | 1 | Chọn Byte đầu ra (`0`: Chọn Byte thấp `acc[7:0]`, `1`: Chọn Byte cao `acc[15:8]`) |
| `din` | Input | 8 | Dữ liệu đầu vào 8-bit không dấu |
| `dout` | Output | 8 | Dữ liệu đầu ra 8-bit dạng đa hợp (Multiplexed) |

---

## 3. Kiểm Thử RTL & Luồng Tự Động CI/CD

### 3.1 Chiến Lược Kiểm Thử (Testbench)

Môi trường mô phỏng tự động (`tb/tb_sat_accumulator.v`) được xây dựng trên Icarus Verilog để kiểm tra các kịch bản:

1. Trạng thái Khởi tạo (Reset) và Xóa mạch (`clear`).
2. Chuỗi phép cộng dồn liên tiếp ở dải giá trị thường.
3. Điều kiện biên tràn dữ liệu (`16'hFFFF`) và duy trì khóa bão hòa.
4. Chuyển đổi chọn Byte đầu ra (`sel_hi`) trong quá trình tính toán.

### 3.2 Tự Động Hóa CI (Continuous Integration)

Hệ thống CI/CD được thiết lập qua **GitHub Actions** (`.github/workflows/simulation.yml`). Mỗi commit đẩy lên nhánh `main` sẽ tự động kích hoạt Icarus Verilog (`iverilog`) biên dịch và chạy `vvp` để đảm bảo tính đúng đắn của thiết kế trước khi tổng hợp.

---

## 4. Tổng Hợp Mạch Logic (Logic Synthesis)

Tổng hợp mạch được thực thi bằng công cụ **Yosys** nhằm chuyển đổi mã RTL Verilog sang Netlist cổng logic chuẩn (Standard Cells).

### 4.1 Kết Quả & Tối Ưu Mạch

* **Khống chế Latch:** Xác nhận không phát sinh chốt Latch ngoài ý muốn (100% phần tử lưu trữ được ánh sáng sang D-Flip-Flop kích hoạt theo cạnh xung clock).
* **Phân bố Cell:** Tổng số lượng cổng logic nằm trong phạm vi dự toán $150 \sim 290$ standard cells.
* **Tối ưu mạch cộng/bão hòa:** Cấu trúc mạch cộng 16-bit và logic so sánh được tối ưu độ sâu logic tổ hợp nhằm đạt hiệu năng tối đa.

---

## 5. Thiết Kế Vật Lý (Physical Design - OpenLane v1)

Thiết kế vật lý được thực hiện qua OpenLane v1 quy chuẩn cho khung $1\times1$ Tile ($100\,\mu\text{m} \times 160\,\mu\text{m}$) của Tiny Tapeout.

### 5.1 Quy Hoạch Mặt Bằng & Lưới Nguồn (Floorplan & Power Grid)

* **Diện tích Chip (Die Area):** `0 0 100 160` ($\mu\text{m}$)
* **Diện tích Lõi (Core Area):** `5.52 10.88 94.48 149.12` ($\mu\text{m}$)
* **Lưới phân phối nguồn:** Mạng lưới đường nguồn VDD/VSS được định tuyến qua các lớp kim loại Metal 1 và Metal 2.

### 5.2 Định Vị Cell & Tổng Hợp Cây Xung Đồng Hồ (Placement & CTS)

* Định vị Standard Cell đạt mật độ cao, không xảy ra nghẽn đường nối dây (congestion).
* CTS bổ sung các đệm buffer xung đồng hồ nhằm cân bằng độ lệch (skew) giữa 16 Flip-Flops nội bộ.

### 5.3 Định Tuyến Đường Dây & Kiểm Tra Chuẩn (Routing & Signoff)

* **Lớp Kim Loại Tối Đa:** `met4` (Metal 4) để tránh cản trở định tuyến của khung vi mạch tổng.
* **Kiểm tra DRC (Magic):** Đạt **0 lỗi** về khoảng cách hình học.
* **Kiểm tra LVS (Netgen):** Sơ đồ vi mạch Layout khớp 100% với sơ đồ nguyên lý Netlist.
* **Xuất File GDSII:** File Layout hoàn chỉnh được lưu tại `results/sat_accumulator.gds`.

---

## 6. Phân Tích Thời Gian Tĩnh (Static Timing Analysis - STA)

Phân tích timing ở tần số hoạt động mục tiêu $10\,\text{MHz}$ (Chu kỳ xung clock $100\,\text{ns}$):

| Thông Số Thời Gian | Ràng Buộc (Constraint) | Giá Trị Thực Tế | Đơn Vị | Trạng Thái |
| :--- | :--- | :--- | :--- | :--- |
| Chu kỳ Clock (Period) | $100.00$ | $100.00$ | $\text{ns}$ | MET |
| Slack Âm Lớn Nhất (WNS) | $\ge 0.00$ | $> 0.00$ | $\text{ns}$ | MET |
| Tổng Slack Âm (TNS) | $0.00$ | $0.00$ | $\text{ns}$ | MET |
| Vi phạm Setup (Setup Violations) | $0$ | $0$ | Lỗi | PASS |
| Vi phạm Hold (Hold Violations) | $0$ | $0$ | Lỗi | PASS |

---

## 7. Cấu Trúc Cây Thư Mục Dự Án

```text
sat_accumulator/
├── .github/
│   └── workflows/
│       └── simulation.yml      # Cấu hình GitHub Actions CI tự động
├── docs/
│   ├── architecture.md         # Tài liệu đặc tả kiến trúc
│   └── technical_report.md     # Báo cáo kỹ thuật tổng hợp (Tiếng Việt)
├── openlane/
│   └── sat_accumulator/
│       └── config.tcl          # Cấu hình Physical Design OpenLane v1
├── rtl/
│   └── sat_accumulator.v      # Mã nguồn RTL Verilog
├── results/
│   └── sat_accumulator.gds    # File Layout GDSII hoàn chỉnh
├── sta/
│   ├── constraint.sdc          # File ràng buộc thời gian SDC
│   └── run_sta.tcl             # Script phân tích OpenSTA
├── synth/
│   ├── sat_accumulator_netlist.v
│   └── synth.ys                # Script tổng hợp Yosys
└── tb/
    └── tb_sat_accumulator.v    # Testbench tự động kiểm tra
```

---

## 8. Kết Luận

Dự án **Bộ tích lũy bão hòa 16-bit** đã chứng minh và hoàn thiện thành công toàn bộ luồng thiết kế vi mạch ASIC từ RTL đến GDSII trên thư viện công nghệ SkyWater 130nm. Tất cả các yêu cầu về chức năng, thời gian (timing), diện tích khung đóng gói Tiny Tapeout và các quy tắc vật lý DRC/LVS đều được nghiệm thu hoàn hảo. File thiết kế vi mạch cuối cùng `results/sat_accumulator.gds` đã sẵn sàng cho công đoạn chế tạo.