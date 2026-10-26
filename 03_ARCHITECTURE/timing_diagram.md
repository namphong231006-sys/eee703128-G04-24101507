# G04 · Giản đồ thời gian (Timing Diagram)

---

## 0. Giản đồ này lấy ở đâu ra

G04 là mạch **tuần tự**, nên đây là **giản đồ dạng sóng theo chu kỳ clock**.

Giản đồ được **suy từng chu kỳ từ RTL thật** (`g04_sat_accum16.sv`, dòng 16–39) theo **đúng
chuỗi kích thích** của `05_VERIFICATION/testbench/g04_tb.sv` (dòng 36–56). Mô phỏng thật
**dừng ở chu kỳ C6** (`simulation.log`: `Time: 56`), và phần dự đoán từ mã chỉ ra rằng
**DUT đúng, vector của testbench sai**.

> ❗ Mọi dạng sóng ở đây là mô phỏng **hành vi (zero-delay)**: tín hiệu đổi **ngay** tại cạnh
> clock, độ trễ cổng = 0. Nó **không** minh hoạ độ trễ thật. Độ trễ thật của đường xấu nhất
> sau tổng hợp là **6,71 ns** (`sta/timing_report_max.txt`) — **67,1 %** chu kỳ giả định
> 10 ns — và còn tăng sau routing.

**Quy ước thời gian.** `always #5 clk = ~clk`, `clk = 0` tại `t = 0` ⟹ chu kỳ **10 ns**, cạnh
lên tại `t = 5, 15, 25, …`. Testbench kiểm kết quả tại `#1` **sau** mỗi cạnh.

---

## 1. Giao dịch điển hình — đúng chuỗi của testbench

```
 chu ky      C1    C2  │ C3     C4     C5     C6     C7   │ C8
 t (ns)       5    15  │ 25     35     45     55     65   │ 75
           ┌─┐   ┌─┐   │┌─┐    ┌─┐    ┌─┐    ┌─┐    ┌─┐   │┌─┐
 clk    ───┘ └───┘ └───┘│ └────┘ └────┘ └────┘ └────┘ └───┘│ └───
                        │                                  │
 ──────────── GIA TRI CO TAI CANH LEN (dau vao) ─────────────────────────
 rst_n       0     0    │  1      1      1      1      1   │  1
 valid_in    0     0    │  1      1      1      1      1   │  0
 inc_in    0000  0000   │ 0001   00FF   FE00   0001   0001 │ FFFF
                        │                                  │
 ════════ GIA TRI SAU CANH LEN (doc tu RTL dong 29-38) ══════════════════
 total_ext   -     -    │ 00001  00100  0FF00  0FF01  0FF02│   -
 total[16]   -     -    │   0      0      0      0      0  │   -
 acc_q     0000  0000   │ 0001   0100   FF00   FF01   FF02 │ FF02
 acc_out_hi  00    00   │  00     01     FF     FF     FF  │  FF
 sat         0     0    │   0      0      0      0      0  │   0
 valid_out   0     0    │   1      1      1      1      1  │   0
 ────────────────────────────────────────────────────────────────────────
 TB ky vong   -     -   │hi=00  hi=01  hi=FF  hi=FF  hi=FF │valid
                        │sat=0  sat=0  sat=0  sat=1  sat=1 │  =0
 Ket qua      -     -   │  ✅     ✅     ✅    🔴      -    │  -
                                                 │
        TB ky vong sat=1 nhung acc chi moi = 0xFF01, CHUA tran
        => $fatal "sat mismatch got=0 expected=1" @ t = 56
```

### Giải thích từng đoạn

| Chu kỳ | Điều gì xảy ra | Nhánh RTL | Vì sao đoạn này quan trọng |
|---|---|---|---|
| **C1** | `rst_n = 0` ⟹ xoá 18 flip-flop | 24–28 | Reset **đồng bộ** |
| **C2** | Vẫn reset; TB nhả `rst_n` ngay sau cạnh | 24–28 | Race **vô hại** vì C1 đã reset xong |
| **C3** | `+0x0001` ⟹ `acc = 0x0001`. **`valid_out = 1` ngay lần cộng đầu** | 32–36 | ⭐ G04 **không có pha khởi động** — khác hẳn G01/G02/G03 |
| **C4** | `+0x00FF` ⟹ `acc = 0x0100`, `hi = 0x01` | 16, 20 | Kiểm mang sang giữa hai byte |
| **C5** | `+0xFE00` ⟹ `acc = 0xFF00`, `hi = 0xFF` | 16, 20 | ⭐ **Đây là chỗ nảy sinh hiểu nhầm**: `hi = 0xFF` nhưng `acc` **chưa** ở trần — còn thiếu **255** đơn vị |
| **C6** | `+0x0001` ⟹ `acc = 0xFF01`, `total_ext[16] = 0` ⟹ **`sat = 0`** | 19 | 🔴 **FATAL.** TB kỳ vọng `sat = 1`. **DUT đúng** — `0xFF00 + 1 = 0xFF01 < 0xFFFF` |
| **C7** | (chưa chạy tới) `+0x0001` ⟹ `acc = 0xFF02`, `sat = 0` | 19 | TB cũng kỳ vọng `sat = 1` ⟹ sẽ lại FAIL |
| **C8** | `valid_in = 0` với `inc_in = 0xFFFF` ⟹ mọi thứ đứng yên | 30–32 | ⭐ Ca gating **thiết kế rất tốt**: nếu quên gating, `acc` sẽ nhảy vọt và `sat` bật — không thể bỏ sót |

## 2. Soi kỹ C5 → C6 — cạnh mà mô phỏng chết

```
                    C5 (t=45)                 C6 (t=55)
                 ─────────────────┬──────────────────────────
  clk        ────┐  ┌─────────────┐  ┌──────────────────────
                 └──┘             └──┘
                    ▲                 ▲
                    │                 │
  acc_q (truoc)  0100 ────────────▶ FF00 ──────────────▶ FF01
  inc_in         FE00                0001
  total_ext     0FF00                0FF01
  total_ext[16]    0                   0     <- KHONG TRAN
  acc_q (sau)    FF00                FF01
  acc_out_hi     FF                  FF      <- KHONG DOI! ca hai deu 0xFF
  sat             0                   0      <- DUNG theo dac ta
                                      │
                    TB ky vong sat = 1 ──────┘  🔴 VECTOR SAI

  ┌────────────────────────────────────────────────────────────────┐
  │  Truc so 16 bit:                                                │
  │                                                                 │
  │   0x0000 ........................ 0xFF00 ... 0xFF01 ... 0xFFFF │
  │                                      ▲          ▲          ▲   │
  │                                      │          │          │   │
  │                                   sau C5     sau C6      TRAN  │
  │                                      │◀────── 255 don vi ─────▶│
  │                                                                 │
  │   acc_out_hi = 0xFF cho CA MOT DOAN 256 gia tri nay             │
  │   => nhin tu ben ngoai, C5 va C6 va "cham tran" GIONG HET NHAU  │
  └────────────────────────────────────────────────────────────────┘
```

**Nguồn gốc sai lầm của testbench:** sau C5, `acc_out_hi = 0xFF`. Người viết đọc `0xFF` ở
đầu ra và kết luận *"bộ tích luỹ đã đầy"*. Nhưng `acc_out_hi = 0xFF` chỉ nói `acc_q` nằm
trong `0xFF00`…`0xFFFF` — còn **255 đơn vị** nữa mới tới trần.

Đây chính là câu trả lời sống động cho **Charter mục 2 câu 3** (*"bộ tích luỹ 16 bit nhưng
chỉ xuất 8 bit cao — quyết định đó mất mát gì?"*): **nó làm chính người viết testbench nhầm
lẫn**. Phán xử đầy đủ: `05_VERIFICATION/known_issues.md`.

## 3. Giản đồ của chuỗi vector **ĐÚNG** (đề xuất, chưa áp dụng)

Chỉ cần chèn **một** lệnh `send` để đưa `acc` tới đúng trần:

```
 chu ky      C3     C4     C5     C6(moi)  C7     C8     C9    │ C10
 inc_in     0001   00FF   FE00    00FF    0001   0001   0000   │ FFFF
 valid_in     1      1      1       1       1      1      1    │  0
 ─────────────────────────────────────────────────────────────────────
 total_ext  00001  00100  0FF00   0FFFF   10000  10000  0FFFF  │  -
 total[16]    0      0      0       0        1      1      0   │  -
 acc_q      0001   0100   FF00    FFFF     FFFF   FFFF   FFFF  │ FFFF
 acc_out_hi   00     01     FF      FF       FF     FF     FF  │  FF
 sat           0      0      0       0        1      1      0  │   0
 valid_out     1      1      1       1        1      1      1  │   0
 ─────────────────────────────────────────────────────────────────────
 lop ca      L-F    L-F    L-F     L-E      L-O    L-S    L-Z  │ L-G
              │      │      │       │        │      │      │   │
              │      │      │       │        │      │      │   └─ gating
              │      │      │       │        │      │      └─ INV-6: o tran
              │      │      │       │        │      │         nhung sat = 0
              │      │      │       │        │      └─ bao hoa DINH
              │      │      │       │        └─ VUOT tran -> sat = 1
              │      │      │       └─ DUNG BANG tran -> sat = 0  (INV-7)
              └──────┴──────┴─ cong binh thuong, xa tran
```

> ⭐ **Chu kỳ C6 mới là chu kỳ có giá trị dạy học cao nhất của cả đề:** `acc` **đúng bằng**
> `0xFFFF` nhưng `sat = 0`, vì `65535` **chưa vượt** `65535`. Đây là ranh giới giữa `>` và
> `>=` — chỗ mà mọi lỗi bão hoà đều nằm.
>
> Và **C9** là chu kỳ chứng minh ngữ nghĩa của `sat`: bộ tích luỹ **vẫn ở trần**, nhưng vì
> `inc = 0` nên không có phép cắt nào xảy ra ⟹ `sat` về **0** (INV-6).

## 4. Bão hoà so với quay vòng — cùng một chuỗi vào

```
 chu ky        C5     C6(moi)  C7     C8
 inc_in       FE00    00FF    0001   0001
 ─────────────────────────────────────────────
 BAO HOA (G04):
   acc_q      FF00    FFFF    FFFF   FFFF     <- DON DIEU khong giam (INV-2)
   acc_out_hi   FF      FF      FF     FF
   sat           0       0       1      1     <- co bao
 ─────────────────────────────────────────────
 QUAY VONG (neu bo tang ep bao hoa):
   acc_q      FF00    FFFF    0000   0001     <- 🔴 NHAY VE 0, mat don dieu
   acc_out_hi   FF      FF      00     00     <- 🔴 man hinh cong to ve 0
   sat           -       -       -      -     <- KHONG CO dau hieu nao
 ─────────────────────────────────────────────
                                 ▲
                                 └── chenh lech 65535 don vi,
                                     khong the phat hien tu ben ngoai
```

Đây là hình ảnh trực quan trả lời **Charter mục 2 câu 1** và giải thích vì sao quay vòng
nguy hiểm với một công tơ.

## 5. Đường tới hạn trên trục thời gian (số liệu thật)

```
  canh clk k                                                canh clk k+1
      │                                                          │
      │◀──────────────── chu ky 10,00 ns (GIA DINH) ────────────▶│
      │                                                          │
      │ input_delay (gia dinh)                                   │
      │◀── 1,00 ──▶│                                             │
      │            │ inc_in[1] ▶ nor2 ▶ o21ai        (1,21 ns)   │
      │            │◀─0,21─▶│                                    │
      │            │        │ 12 x maj3_1 = CHUOI CARRY 16 BIT   │
      │            │        │◀──────── 4,71 ns (70,2 %) ───────▶ │  (5,92 ns)
      │            │                 │ a21oi ▶ o21ai(fanout 15)  │
      │            │                 │◀─ 0,47 ─▶ = TIN HIEU TRAN │  (6,39 ns)
      │            │                           │ ep bao hoa+mux  │
      │            │                           │◀─ 0,32 ─▶       │  (6,71 ns)
      │                                                          │
      │◀─────────── arrival 6,71 ns ───────────▶│                │
      │                                         │◀── 3,16 ───▶│  │
      │                                                      │◀─▶│ setup 0,12
      │                                              required 9,88 ns
```

| Đoạn | Thời gian | Tỉ lệ | Ghi chú |
|---|---:|---:|---|
| Độ trễ vào (**giả định**) | 1,00 ns | 14,9 % | `set_input_delay 1.0` |
| Đầu chuỗi | 0,21 ns | 3,1 % | |
| ⭐ **Chuỗi carry 16 bit** | **4,71 ns** | **70,2 %** | 12 × `maj3_1` |
| Sinh tín hiệu tràn | 0,47 ns | 7,0 % | `_136_`, **fanout 15** — cell đắt nhất |
| ⭐ **Ép bão hoà + mux** | **0,32 ns** | **4,8 %** | |
| **Tổng** | **6,71 ns** | 100 % | slack **3,16 ns** (MET) |

> ⚠️ **Đọc cho đúng:** `0,79 ns` (sinh tràn + ép bão hoà) **không phải** toàn bộ chi phí thời
> gian của bão hoà. Chi phí lớn hơn là **cấu trúc**: bão hoà bắt **mọi** bit của bộ tích luỹ
> phải đợi carry-out của bit cao nhất, trong khi bộ tích luỹ quay vòng có các bit thấp xong
> rất sớm. Xem `datapath.md` §5. Chi phí thật chỉ đo được bằng cách **chạy flow hai lần** —
> Charter mục 9 yêu cầu đúng điều đó và nó **CHƯA CHẠY** (`tradeoff.md` §6).

Số này **chưa có ký sinh dây**, **một góc PVT** (`tt_025C_1v80`), **skew = 0**.
**Không** được diễn dịch thành tần số hoạt động.

## 6. Waveform thật đã thu được

| Hạng mục | Trạng thái |
|---|---|
| File VCD | ⬜ **Không có** — `g04_tb.sv` không có `$dumpfile`/`$dumpvars`, và mô phỏng dừng bằng `$fatal` tại `t = 56` |
| Log mô phỏng | ✅ `05_VERIFICATION/simulation.log` (2 dòng) |
| Log biên dịch | ⚠️ `05_VERIFICATION/iverilog_compile.log` — **2 cảnh báo `sorry: constant selects…`**. Phán xử: **giới hạn công cụ, VÔ HẠI**, không liên quan tới lỗi ở §2. Xem `known_issues.md` §5 |

Muốn có waveform, cần thêm (**chưa áp dụng**):

```systemverilog
    initial begin
        $dumpfile("g04_waves.vcd");
        $dumpvars(0, g04_tb);
    end
```

⚠️ Riêng với G04, waveform nên dump cả `dut.acc_q` (16 bit đầy đủ) — vì nhìn từ chân ra chỉ
thấy 8 bit cao, và đó chính là nguồn gốc của lỗi.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-G04-010, REQ-G04-012, Charter mục 2 câu 1 và 3.*
