# G04 · Sơ đồ hệ thống (System Diagram)

---

## 1. Bối cảnh ứng dụng — công tơ điện tử

Charter mục 1: *"Khối cộng dồn năng lượng tiêu thụ trong công tơ điện tử: chạm trần thì dừng
ở trần chứ không quay về 0."*

```
  ┌──────────────────────── CONG TO DIEN TU ──────────────────────────────────┐
  │                                                                            │
  │  ┌─────────┐          ┌──────────┐        ┌──────────────┐                │
  │  │ Bien ap │─ u(t) ──▶│          │        │ Nhan u x i   │  cong suat     │
  │  │  do ap  │          │   ADC    │───────▶│  tuc thoi    │  tuc thoi      │
  │  └─────────┘          │  kenh u  │        │ (KHONG thuoc │  16 bit        │
  │                       └──────────┘        │   de nay)    │─────────┐      │
  │  ┌─────────┐          ┌──────────┐        └──────────────┘         │      │
  │  │ Bien do │─ i(t) ──▶│   ADC    │───────▶        ▲                │      │
  │  │  dong   │          │  kenh i  │                │                │      │
  │  └─────────┘          └──────────┘                │                ▼      │
  │                                                    │      ╔═════════════╗  │
  │                                          data_ready│      ║             ║  │
  │                                                    └─────▶║    G04      ║  │
  │                                                   valid_in║ Tich luy co ║  │
  │                                                           ║  bao hoa    ║  │
  │                                   clk, rst_n ────────────▶║   16 bit    ║  │
  │                                                           ╚══╤═══════╤══╝  │
  │                                    acc_out_hi[7:0] ◀─────────┘       │     │
  │                                    sat ◀─────────────────────────────┘     │
  │                                           │              │                 │
  │                                           ▼              ▼                 │
  │                                    ┌─────────────┐  ┌──────────────┐      │
  │                                    │  Hien thi   │  │ Canh bao "het│      │
  │                                    │   kWh (LCD) │  │  thang do"   │      │
  │                                    └─────────────┘  └──────────────┘      │
  │                                           │                                │
  │                                           ▼                                │
  │                                    ┌──────────────────┐                    │
  │                                    │ Bo nho khong bay │ (tang ngoai:       │
  │                                    │ hoi + doc tu xa  │  mo rong dai do)   │
  │                                    └──────────────────┘                    │
  └────────────────────────────────────────────────────────────────────────────┘

        ╔═══╗ = pham vi de G04      ┌───┐ = tang ngoai, KHONG thuoc de nay
```

### Vì sao ứng dụng này bắt buộc bão hoà, không được quay vòng

| Đặc điểm của công tơ | Hệ quả thiết kế |
|---|---|
| Số đọc phải **đơn điệu không giảm** — đó là định nghĩa của một bộ đếm tích luỹ | **INV-2**. Quay vòng phá vỡ tính chất này: `acc` nhảy từ 65535 về 0 |
| Phần mềm đọc công tơ tính **hiệu số** giữa hai lần đọc | Quay vòng cho hiệu số **âm** hoặc sai khổng lồ. Bão hoà cho hiệu số **0** — sai nhưng **theo hướng an toàn và nhìn ra được** |
| Tranh chấp thương mại về hoá đơn | Sai theo hướng **thiếu** (bão hoà) dễ bảo vệ hơn sai theo hướng **ngẫu nhiên** (quay vòng) |
| Cần biết khi nào số đọc hết tin cậy | Cờ `sat` là **tín hiệu duy nhất** nói điều đó. Quay vòng **không có dấu hiệu nào** |

### Hai điểm giới hạn phải nêu ngay

| Giới hạn | Nội dung |
|---|---|
| **Dải đo chỉ 16 bit** | Một công tơ thật cần hàng chục bit. G04 là **tầng tích luỹ nhanh**; việc mở rộng dải (đếm số lần chạm trần và ghi vào bộ nhớ không bay hơi) thuộc **tầng ngoài** |
| 🔴 **Thiếu lệnh `xoá`** | Charter mục 4 yêu cầu `uio_in[1] = xoá`; RTL **không có**. Một công tơ không xoá được số đọc sau khi chốt kỳ là **không dùng được**. Xem cảnh báo `functional_spec.md` |

## 2. Ranh giới khối

| Hạng mục | Thuộc G04? | Ghi chú |
|---|:-:|---|
| Bộ cộng mở rộng 17 bit | ✅ | `total_ext` — **phát hiện tràn bằng bit carry** |
| Logic bão hoà (ép về `0xFFFF`) | ✅ | ≈ 14 cell `o21ai_0` nhận tín hiệu tràn |
| Thanh ghi tích luỹ 16 bit | ✅ | Vật lý: `acc_q[7:0]` + `acc_out_hi[7:0]` (xem `block_diagram.md` §3) |
| Thanh ghi `sat`, `valid_out` | ✅ | 2 flip-flop |
| **Nhân `u × i`** (tính công suất tức thời) | ❌ | Tầng trước — G04 chỉ nhận số gia đã tính sẵn |
| **Tạo `clk`, `rst_n`** | ❌ | Harness / POR |
| **Tạo `valid_in`** | ❌ | `data_ready` của tầng nhân |
| **Mở rộng dải đo** (đếm số lần chạm trần) | ❌ | Tầng ngoài — đây là cách hệ thống thật vượt giới hạn 16 bit |
| **Bộ nhớ không bay hơi** | ❌ | Tầng ngoài |
| **Lệnh `xoá`** | 🔴 **PHẢI CÓ nhưng CHƯA CÓ** | Charter mục 4 |
| **Lớp vỏ 24 chân `tt_um_*`** | ⚠️ **CHƯA CÓ** | |

### Hợp đồng với tầng ngoài

1. `valid_in` chỉ lên 1 khi `inc_in` đã ổn định và là một số gia mới.
2. Giữ `rst_n = 0` qua **≥ 1 cạnh lên** của `clk` (reset **đồng bộ**).
3. **Theo dõi `sat`**: khi `sat = 1`, số đọc đã mất tin cậy ⟹ tầng ngoài phải tăng bộ đếm
   tràn của riêng nó.
4. ⚠️ **Hiểu đúng ngữ nghĩa `sat`**: nó báo **lần cắt vừa xảy ra**, không báo *"đang ở trần"*.
   Với `acc = 0xFFFF` và `inc = 0`, `sat` về **0** dù vẫn ở trần (INV-6).
5. ⚠️ **Không suy ra `acc` từ `acc_out_hi`**: `acc_out_hi = 0xFF` ứng với **256** giá trị
   `acc` khác nhau. Đây chính là lỗi mà người viết testbench đã mắc phải.
6. Luôn sẵn sàng nhận kết quả (không có `ready`).

## 3. Vòng đời RTL → GDSII — trạng thái thật

```
  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
  │ 1. Dac ta    │    │ 2. RTL       │    │ 3. Mo phong  │    │ 4. Tong hop  │
  │    + Charter │───▶│ SystemVerilog│───▶│  RTL         │───▶│  Yosys 0.33  │
  │      ⚠️      │    │      ⚠️      │    │ 🔴 DUNG SOM  │    │      ✅      │
  └──────────────┘    └──────────────┘    └──────┬───────┘    └──────┬───────┘
     REQ-G04-002          thieu cong              │                   │
     CHUA THOA            'xoa'                   │                   │
                                                  │                   │
             iverilog_compile.log: 2 canh bao "sorry: constant        │
             selects..." -> GIOI HAN CONG CU, VO HAI (known_issues §5)│
                                                  │                   │
             simulation.log: "sat mismatch got=0 expected=1" @56       │
             -> known_issues.md: LOI O TESTBENCH (vector sai)          │
                                                                      ▼
  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
  │ 8. GDSII     │    │ 7. DRC / LVS │    │ 6. P&R       │    │ 5. STA + Pwr │
  │      ⬜      │◀───│      ⬜      │◀───│  LibreLane   │◀───│  OpenSTA 3.1 │
  └──────────────┘    └──────────────┘    │      ⬜      │    │      ✅      │
                                          └──────────────┘    └──────────────┘

  ⬛ KHONG AP DUNG (Charter muc 3 — ngoai pham vi):
     tich luy co dau · nhieu kenh · chia trung binh ·
     thiet ke analog muc transistor · physical design thu cong · sign-off · tape-out
```

| Bước | Trạng thái | Công cụ | Bằng chứng | Kết quả then chốt |
|---|:-:|---|---|---|
| 1 · Đặc tả | ⚠️ | — | `01_`, `02_` | REQ-G04-002 **CHƯA THOẢ** — thiếu cổng `xoá`, sai độ rộng `inc_in` |
| 2 · RTL | ⚠️ | — | `g04_sat_accum16.sv` (41 dòng) | Chức năng **đúng**, giao diện **thiếu** |
| 2b · Mô hình chuẩn | ✅ | Python 3 | `python_reference_run.log` | `PASS` — 6/6 test, gồm **5000 ca ngẫu nhiên** |
| 3 · Mô phỏng RTL | 🔴 | Icarus 12.0 | `simulation.log` | Dừng `t = 56` — **lỗi ở testbench** |
| 4 · Tổng hợp | ✅ | Yosys 0.33 | `synth_stat.txt` | **119 cell · 18 FF · 1083,5392 µm²** |
| 5 · STA | ✅ | OpenSTA 3.1.0 | `timing_report_max.txt` | arrival **6,71 ns**, slack **3,16 ns** |
| 5b · Công suất | ✅ | OpenSTA 3.1.0 | `power_report.txt` | **1,40e-04 W** (tuần tự 64,0 %) |
| 6 · P&R | ⬜ | LibreLane | — | Cần PDK sky130A |
| 7 · DRC / LVS | ⬜ | Magic / Netgen | — | — |
| 8 · GDSII | ⬜ | KLayout | — | — |

## 4. G04 trong họ đề nhóm G

Cùng bộ công cụ, cùng `design.sdc`, cùng thư viện ⟹ so chéo hợp lệ.

| Đề | Chức năng | Cell | FF | Diện tích (µm²) | Arrival (ns) | Slack (ns) | % chu kỳ |
|---|---|---:|---:|---:|---:|---:|---:|
| G01 | Trung bình trượt 4 điểm | 260 | 58 | 2623,7664 | 4,56 | 5,36 | 45,6 % |
| G02 | Trung bình trượt 8 điểm | 380 | 94 | 4078,912 | 4,38 | 5,48 | 43,8 % |
| G03 | Trung vị 3 điểm | 189 | 27 | 1576,512 | 7,82 | 2,10 | 78,2 % |
| **G04** | **Tích luỹ bão hoà 16 bit** | **119** | **18** | **1083,5392** | **6,71** | **3,16** | **67,1 %** |

> 🔎 **Hai quan sát đáng giá:**
>
> **(a) G04 là đề NHỎ NHẤT nhóm G (119 cell) nhưng có đường tới hạn DÀI THỨ HAI (6,71 ns).**
> Diện tích chỉ bằng **26,6 %** của G02, nhưng arrival **dài hơn 53 %**. Lý do: G02 dùng bộ
> cộng **11 bit** trong khi G04 dùng bộ cộng **16 bit**, và quan trọng hơn — **bão hoà bắt
> mọi bit của bộ tích luỹ phải đợi carry-out của bit cao nhất** (`datapath.md` §4).
>
> **(b) So G02 (11 bit, không bão hoà) với G04 (16 bit, có bão hoà):** 12 tầng `maj3` so với
> 6, và thêm **0,79 ns** logic bão hoà sau khi chuỗi carry đã xong. Đây là bằng chứng định
> lượng trực tiếp cho Charter mục 9 — xem `tradeoff.md` §3.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-G04-001, Charter mục 1, mục 9.*
