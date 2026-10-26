# G04 · Phán xử lỗi mô phỏng (Known Issues)

## 0. Trạng thái: ✅ **ĐÃ ÁP DỤNG** — 2026-09-24

> **Giảng viên đã duyệt áp dụng bản vá.** Vá 1, Vá 2 và Vá 5 ở §6 **đã được ghi vào**
> `05_VERIFICATION/testbench/g04_tb.sv`. Nhật ký chi tiết: `08_ORIGINAL_SOURCE/PATCHLOG.md`.
>
> **Phần chẩn đoán §1–§9 giữ nguyên** — nó là tài liệu dạy học và vẫn mô tả đúng lỗi gốc.
> Mọi câu "chưa áp dụng" trong §6/§8 nay phải đọc theo mục §0 này.

| Bản vá §6 | Trạng thái | Ghi chú |
|---|:-:|---|
| Vá 1 — sửa vector sai, chèn ca biên chính xác | ✅ **Đã áp dụng** | = P-1 trong PATCHLOG |
| Vá 2 — kiểm white-box `dut.acc_q` | ✅ **Đã áp dụng** | = P-2 |
| Vá 5 — ca CC-4 (cộng 0 khi đang ở trần) | ✅ **Đã áp dụng** | = P-3 |
| Vá 3 — đổi `always_comb` → `assign` | ❌ **Không áp dụng** | Chính §6 kết luận *"không nên"*; cảnh báo vô hại (§5) |
| Vá 4 — thêm cổng `clr_in` | ⏸ **Hoãn** | §6 đòi thầy chốt 2 quyết định đặc tả trước; đổi giao diện module |
| Vá 6 — `$dumpfile`/`$dumpvars` | ❌ **Không áp dụng** | Nên bật qua cờ ở script, mà script ngoài ranh giới vá |

**Kết quả xác minh bằng công cụ thật, sau khi vá:**

| Bước | Kết quả |
|---|---|
| Mô hình chuẩn Python | ✅ `G04 golden reference PASS`, mã thoát 0 (**không sửa**) |
| Biên dịch `iverilog -g2012` | ✅ Thành công (vẫn 2 cảnh báo `sorry:` vô hại — cố ý không áp Vá 3) |
| Mô phỏng `vvp` | ✅ `G04 TB completed`, `$finish` tại `t = 96 ns` — không còn `FATAL`/`mismatch` |
| Tổng hợp `yosys` + sky130hd | ✅ **119 cell / 18 FF / 1083,5392 µm²** — **không đổi** (RTL không bị sửa) |

Độ phủ Charter mục 8 sau khi vá: **3/4** (CC-1 ✅, CC-2 ✅, CC-4 ✅; CC-3 ❌ — bất khả thi tới
khi có Vá 4).

---

> Tài liệu này chỉ tồn tại vì BRIEF G04 ghi **Mô phỏng RTL: RAN_WITH_ISSUES**.
> Mục tiêu: **phán xử** lỗi nằm ở đâu, chứng minh bằng mã, và đề xuất bản vá tối thiểu.
> **Bản vá CHƯA được áp dụng** — xem §8.
>
> G04 có **hai** vấn đề độc lập cần phán xử: một **lỗi làm mô phỏng dừng** (§1–§4) và hai
> **cảnh báo biên dịch** (§5). Chúng **không liên quan tới nhau**.

---

## 1. Trích nguyên văn thông báo lỗi

### 1.1 Lỗi mô phỏng

Nguồn: `05_VERIFICATION/simulation.log` (trùng với BRIEF G04).

```
FATAL: .../runs/G04/work/g04_tb.sv:31: sat mismatch got=0 expected=1
       Time: 56  Scope: g04_tb.send
```

### 1.2 Cảnh báo biên dịch

Nguồn: `05_VERIFICATION/iverilog_compile.log`.

```
.../g04_sat_accum16.sv:18: sorry: constant selects in always_* processes are not
    currently supported (all bits will be included).
.../g04_sat_accum16.sv:18: sorry: constant selects in always_* processes are not
    currently supported (all bits will be included).
```

| Log khác | Nội dung |
|---|---|
| `python_reference_run.log` | `G04 golden reference PASS` — **6/6 test**, gồm `test_randomized` với **5000 ca ngẫu nhiên** |
| `yosys.log` | Tổng hợp **PASS** — 119 cell, 18 FF, 1083,5392 µm² |
| `sta.log` | **PASS**, `wns max 0.00`, `tns max 0.00` |

Ba dữ kiện đọc ngay từ dòng lỗi mô phỏng:
1. Lỗi ở **dòng 31** — assertion `sat == exp_sat`. Các assertion trước nó
   (`valid_out` dòng 25, `acc_out_hi` dòng 27) **đã PASS**, tức byte cao **đúng**.
2. `got=0 expected=1` ⟹ DUT nói *"không tràn"*, testbench nói *"phải tràn"*.
3. `Time: 56` ⟹ cạnh clock tại `t = 55` = chu kỳ **C6** = lệnh `send` thứ **tư**
   (`g04_tb.sv` dòng 44).

## 2. Định vị: lỗi nằm ở file nào

| File | Bị nhắc trong log? | Kết luận sơ bộ |
|---|:-:|---|
| `04_IMPLEMENTATION/rtl/g04_sat_accum16.sv` (**DUT**) | ✅ (chỉ ở **cảnh báo**, dòng 18) | Bên **bị kiện** |
| `05_VERIFICATION/golden_model/reference_model.py` | ❌ | PASS 6/6 |
| `05_VERIFICATION/testbench/g04_tb.sv` | ✅ **dòng 31** | Bên **phát hiện** — hoặc bên **sai** |
| `05_VERIFICATION/testbench/properties.sv` | ❌ | Bị `ifdef G04_SVA` tắt |
| Icarus Verilog 12.0 | ✅ (2 cảnh báo `sorry:`) | Xem §5 — **vô hại** |

## 3. Đoạn mã gây tranh chấp

### Bên A — DUT, `g04_sat_accum16.sv` dòng 16–21:

```systemverilog
16    assign total_ext = {1'b0, acc_q} + {1'b0, inc_in};
17
18    always_comb begin
19        sat_next = total_ext[16];
20        acc_next = total_ext[16] ? 16'hFFFF : total_ext[15:0];
21    end
```

### Bên B — Testbench, `g04_tb.sv` dòng 41–47:

```systemverilog
41        send(16'h0001,8'h00,0);
42        send(16'h00FF,8'h01,0);
43        send(16'hFE00,8'hFF,0);
44        send(16'h0001,8'hFF,1);     // <<<<<< VECTOR NGHI PHAN
45
46        // Once saturated, further positive increments remain saturated.
47        send(16'h0001,8'hFF,1);
```

### Bên C — Mô hình chuẩn, `reference_model.py` dòng 3–7 và 20–22:

```python
def update(acc, inc):
    total = acc + inc
    sat = total > MAX16          # MAX16 = 0xFFFF
    nxt = MAX16 if sat else total
    return nxt, sat

def test_exact_boundary():
    assert update(65535, 0) == (65535, False)
    assert update(65534, 1) == (65535, False)
```

## 4. 🔨 PHÁN XỬ

### Kết luận một dòng

> **Lỗi nằm trong TESTBENCH (`g04_tb.sv`, dòng 44), không nằm trong DUT, không nằm trong
> mô hình chuẩn.** Người viết vector đã nhầm **`acc_out_hi = 0xFF`** (8 bit cao) với
> **`acc_q = 0xFFFF`** (16 bit đầy đủ). Sau ba lệnh `send` đầu, bộ tích luỹ mới ở `0xFF00` —
> **còn thiếu 255 đơn vị nữa mới tới trần**. DUT hành xử **đúng đặc tả** trong suốt.

### Tầng thứ nhất — tính bằng tay bốn lệnh `send` đầu

| # | Dòng TB | `acc_q` trước | `inc_in` | Tổng thật | `total_ext[16]` | `acc_q` sau | `acc_out_hi` | `sat` thật | TB kỳ vọng |
|---|---|---|---|---:|:-:|---|---|:-:|:-:|
| 1 | 41 | `0x0000` | `0x0001` | 1 | 0 | `0x0001` | `0x00` | 0 | 0 ✅ |
| 2 | 42 | `0x0001` | `0x00FF` | 256 | 0 | `0x0100` | `0x01` | 0 | 0 ✅ |
| 3 | 43 | `0x0100` | `0xFE00` | 65280 | 0 | `0xFF00` | `0xFF` | 0 | 0 ✅ |
| 4 | **44** | `0xFF00` | `0x0001` | **65281** | **0** | `0xFF01` | `0xFF` | **0** | **1** 🔴 |

`0xFF00 + 0x0001 = 0xFF01 = 65281`, và `65281 < 65535`. **Không có tràn nào cả.**
Mô hình chuẩn đồng ý: `update(0xFF00, 1)` trả `(0xFF01, False)`.

### Tầng thứ hai — nguồn gốc của hiểu nhầm

Sau lệnh `send` thứ ba, cái mà testbench **quan sát được** là `acc_out_hi = 0xFF`.
Nhưng:

```
   acc_out_hi = 0xFF   <=>   acc_q thuoc [0xFF00 .. 0xFFFF]     <- 256 gia tri!

   0x0000 ....................... 0xFF00 ... 0xFF01 ......... 0xFFFF
                                     ▲          ▲                ▲
                                 sau send#3  sau send#4        TRAN
                                     │◀───── con 255 don vi ────▶│
```

Người viết vector nhìn `0xFF` rồi kết luận *"đã đầy"*. Đây **chính xác** là mất mát mà
Charter mục 2 câu 3 hỏi tới: *"Bộ tích luỹ 16 bit nhưng chỉ xuất 8 bit cao — quyết định đó
mất mát gì?"*

> ⭐ **Câu trả lời đầy đủ nhất cho câu hỏi đó nằm ngay trong hồ sơ này: nó làm chính người
> viết testbench nhầm lẫn và tạo ra một cáo buộc sai nhắm vào một thiết kế đúng.**

### Tầng thứ ba — DUT đúng, và đúng theo cách Charter yêu cầu

| Yêu cầu Charter mục 10 | RTL có thoả? | Bằng chứng |
|---|:-:|---|
| Phát hiện tràn **TRƯỚC** khi cắt, hoặc dùng **bit carry** | ✅ | `total_ext` rộng **17 bit**, `sat_next = total_ext[16]` |
| Không được so sánh sau khi đã cắt về 16 bit | ✅ | Không có biểu thức nào kiểu `(acc+inc) > 16'hFFFF` |
| Bão hoà **dính** | ✅ | `acc_q = 0xFFFF`, `inc ≥ 1` ⟹ `total_ext[16] = 1` ⟹ giữ `0xFFFF` |
| Biên chính xác: `acc+inc = 65535` **không** tràn | ✅ | `total_ext = 0x0FFFF`, bit 16 = 0 |

Và mô hình chuẩn Python đã kiểm **5000 ca ngẫu nhiên** (`test_randomized`) với đúng công
thức `min(acc+inc, MAX16)` — **PASS**. Ba nguồn (RTL, Python, toán học) **hoàn toàn thống
nhất**; chỉ testbench lệch.

### Tầng thứ tư — nếu sửa vector thì phần còn lại có PASS không?

Chèn **một** lệnh `send` để đưa `acc` tới đúng trần, rồi mô phỏng bằng tay:

| # | `inc_in` | `acc_q` trước | Tổng | `acc_q` sau | `acc_out_hi` | `sat` | TB kỳ vọng |
|---|---|---|---:|---|---|:-:|:-:|
| 1 | `0x0001` | `0x0000` | 1 | `0x0001` | `0x00` | 0 | ✅ |
| 2 | `0x00FF` | `0x0001` | 256 | `0x0100` | `0x01` | 0 | ✅ |
| 3 | `0xFE00` | `0x0100` | 65280 | `0xFF00` | `0xFF` | 0 | ✅ |
| **4 (mới)** | `0x00FF` | `0xFF00` | **65535** | `0xFFFF` | `0xFF` | **0** | ✅ ⭐ biên chính xác |
| 5 | `0x0001` | `0xFFFF` | **65536** | `0xFFFF` | `0xFF` | **1** | ✅ ⭐ vượt trần |
| 6 | `0x0001` | `0xFFFF` | 65536 | `0xFFFF` | `0xFF` | 1 | ✅ bão hoà dính |
| 7 | (gap) | — | — | không đổi | `0xFF` | 1 | `valid_out = 0` ✅ |

> ⟹ **Chỉ cần chèn MỘT dòng vào testbench là toàn bộ mô phỏng G04 PASS.** Không một dòng
> RTL nào phải đổi.

### Bảng phán xử

| Khả năng | Có phải không? | Lập luận |
|---|:-:|---|
| Lỗi trong **DUT** | ❌ **KHÔNG** | Tính tay bốn `send` đầu khớp hoàn toàn với `reference_model.update`. RTL thoả cả bốn ràng buộc Charter mục 10. `0xFF00 + 1` **không** tràn — đây là **số học**, không phải quan điểm |
| Lỗi trong **mô hình chuẩn** | ❌ **KHÔNG** | PASS 6/6 gồm 5000 ca ngẫu nhiên; `test_exact_boundary` chốt đúng ranh giới `>` (không phải `>=`) |
| Lỗi trong **testbench** | ✅ **CHÍNH LÀ ĐÂY** | Dòng 44 kỳ vọng `sat = 1` ở một phép cộng **không hề tràn**. Nguyên nhân: nhầm `acc_out_hi` (8 bit) với `acc_q` (16 bit) |
| **Giới hạn công cụ** (Icarus) | ❌ **KHÔNG** cho lỗi này | Hai cảnh báo `sorry:` **vô hại** và **không liên quan** — xem §5 |

## 5. Phán xử riêng cho hai cảnh báo biên dịch

```
g04_sat_accum16.sv:18: sorry: constant selects in always_* processes are not
    currently supported (all bits will be included).
```

Dòng 18 là `always_comb begin`. Icarus đang nói về **danh sách nhạy ngầm** của khối đó.

### Icarus đang phàn nàn điều gì

Trong `always_comb`, công cụ phải **tự suy ra** danh sách nhạy từ các tín hiệu được đọc.
Thân khối đọc `total_ext[16]` và `total_ext[15:0]` — hai **constant part-select**. Icarus
12.0 **chưa hỗ trợ** phân tích ở mức từng bit, nên nó lùi về phương án an toàn: **đưa toàn
bộ `total_ext` (cả 17 bit) vào danh sách nhạy** — đúng như thông báo nói
(*"all bits will be included"*).

### Vì sao điều đó **vô hại**

| Câu hỏi | Trả lời |
|---|---|
| Danh sách nhạy rộng hơn cần thiết có sai không? | ❌ **Không.** Nó làm khối được đánh giá lại **nhiều hơn** mức tối thiểu. Kết quả **luôn đúng**, chỉ tốn thêm chút thời gian mô phỏng |
| Nếu hẹp hơn cần thiết thì sao? | ✅ **Đó mới là lỗi** (thiếu tín hiệu ⟹ đầu ra không cập nhật). Ở đây là trường hợp **ngược lại** |
| Có ảnh hưởng tổng hợp không? | ❌ **Không.** Yosys phân tích riêng, và `yosys.log` **PASS không cảnh báo**. Netlist chứa đủ 12 `maj3` + tầng ép bão hoà |
| Có liên quan tới lỗi ở §1.1 không? | ❌ **Không.** Lỗi §1.1 là **giá trị kỳ vọng sai trong testbench**, giải thích được hoàn toàn bằng số học `0xFF00 + 1 = 0xFF01` |
| Có nên "sửa" để hết cảnh báo không? | ⚠️ **Có thể**, nhưng là sửa cho sạch log, không phải sửa lỗi. Xem Vá 3 |

### Bảng phán xử cảnh báo

| Khả năng | Có phải không? |
|---|:-:|
| Lỗi trong DUT | ❌ Mã hợp chuẩn IEEE 1800; `always_comb` với part-select là cách viết bình thường |
| **Giới hạn công cụ (Icarus 12.0)** | ✅ **CHÍNH LÀ ĐÂY** — và Icarus đã lùi về phương án **bảo thủ và an toàn** |
| Có gây ra lỗi mô phỏng không | ❌ **KHÔNG** |

> 💡 **Đối lập rất đáng dạy:** ở đề **D02**, một cảnh báo/lỗi của Icarus đã **cứu** hồ sơ khỏi
> một sai số âm thầm. Ở đây, cảnh báo của Icarus **chỉ là tiếng ồn**. Kỹ năng cần có là
> **phân biệt `sorry:` (chưa hỗ trợ, đã lùi về phương án an toàn) với `error:` (từ chối)** —
> và luôn kiểm xem cảnh báo có **giải thích được** triệu chứng hay không. Ở đây nó **không**.

## 6. 🔧 Bản vá tối thiểu (đề xuất — **chưa áp dụng**)

### Vá 1 — sửa vector testbench (bắt buộc, sửa được lỗi ở §1.1)

`05_VERIFICATION/testbench/g04_tb.sv`

```diff
         send(16'h0001,8'h00,0);
         send(16'h00FF,8'h01,0);
         send(16'hFE00,8'hFF,0);
+        // 0xFF00 + 0x00FF = 0xFFFF : DUNG BANG tran, CHUA tran => sat = 0
+        send(16'h00FF,8'hFF,0);
+        // 0xFFFF + 0x0001 = 0x10000 : VUOT tran => bao hoa, sat = 1
         send(16'h0001,8'hFF,1);
```

**Vì sao vá như vậy:**
1. `0xFF00 + 0x00FF = 0xFFFF` đưa bộ tích luỹ tới **đúng trần** mà **chưa** tràn ⟹ ca **L-E**
   (biên chính xác) — ca phân biệt `>` với `>=`, hiện đang **hoàn toàn thiếu**.
2. Lệnh kế tiếp (`+1`) mới thật sự tràn ⟹ ca **L-O**, cũng đang thiếu.
3. Không đổi một dòng RTL nào.
4. Hai ca này chính là **CC-1** và **CC-2** — hai trong bốn ca **bắt buộc** của Charter mục 8
   mà hồ sơ đang thiếu (`corner_cases.md` §4).

### Vá 2 — kiểm white-box `acc_q` để tránh tái diễn (nên có)

Gốc rễ của lỗi là **giao diện quan sát hẹp hơn trạng thái trong**. Cách chắc chắn nhất là
cho testbench nhìn thẳng vào `acc_q`:

```diff
     task automatic send(
         input logic [15:0] inc,
         input logic [7:0]  exp_hi,
-        input logic        exp_sat
+        input logic        exp_sat,
+        input logic [15:0] exp_acc      // gia tri DAY DU 16 bit
     );
         begin
             inc_in=inc; valid_in=1'b1;
             @(posedge clk); #1;
             assert(valid_out)      else $fatal(1,"valid_out missing");
             assert(acc_out_hi==exp_hi)  else $fatal(1,"upper byte mismatch ...");
             assert(sat==exp_sat)        else $fatal(1,"sat mismatch ...");
+            assert(dut.acc_q==exp_acc)
+                else $fatal(1,"acc_q mismatch got=%h expected=%h",dut.acc_q,exp_acc);
             valid_in=1'b0;
         end
     endtask
```

Với vá này, lỗi ở §1 sẽ lộ ra dưới dạng *"acc_q = FF00, không phải FFFF"* ngay ở lệnh `send`
thứ ba — **chỉ đúng chỗ**, thay vì đổ oan cho `sat` ở lệnh thứ tư.

### Vá 3 — làm sạch cảnh báo Icarus (tuỳ chọn, **không bắt buộc**)

```diff
-    always_comb begin
-        sat_next = total_ext[16];
-        acc_next = total_ext[16] ? 16'hFFFF : total_ext[15:0];
-    end
+    // Dung assign thay always_comb: khong con danh sach nhay ngam
+    assign sat_next = total_ext[16];
+    assign acc_next = total_ext[16] ? 16'hFFFF : total_ext[15:0];
```

⚠️ Vá này đụng **RTL**, nên kéo theo phải chạy lại toàn bộ tầng 06_GDSII. Vì cảnh báo là
**vô hại** (§5), **không nên** áp dụng chỉ để log sạch. Ghi ở đây để đầy đủ.

### Vá 4 — 🔴 bổ sung cổng `xoá` mà Charter mục 4 yêu cầu (**bắt buộc về yêu cầu**)

Đây **không** phải lỗi mô phỏng, mà là **thiếu sót so với Charter** (`functional_spec.md`
Cảnh báo 1). Ca bắt buộc *"xoá rồi cộng lại"* hiện **không thể thực hiện**.

```diff
 module g04_sat_accum16 (
     input  logic        clk,
     input  logic        rst_n,
     input  logic        valid_in,
+    input  logic        clr_in,        // Charter muc 4: uio_in[1] = xoa
     input  logic [15:0] inc_in,
     ...
         end else begin
             valid_out <= 1'b0;
 
-            if (valid_in) begin
+            if (clr_in) begin
+                acc_q      <= 16'h0000;
+                acc_out_hi <= 8'h00;
+                sat        <= 1'b0;     // xoa CA co — can thay chot ngu nghia
+            end else if (valid_in) begin
                 acc_q      <= acc_next;
```

**Hai quyết định đặc tả cần thầy chốt trước khi áp:**
1. `clr_in` có **thắng** `valid_in` không (ưu tiên xoá)? Bản vá trên giả định **có**.
2. `xoá` có xoá luôn cờ `sat` không? Bản vá trên giả định **có**.

### Vá 5 — bổ sung ca kiểm thử còn thiếu của Charter mục 8 (nên có)

Charter mục 8 có **bốn** ca bắt buộc; sau Vá 1 mới có 2/4.

```systemverilog
    //  CC-4 (L-Z): cong gia tri 0 khi DANG o tran -> sat phai ve 0  (INV-6)
    send(16'h0000, 8'hFF, 0);
    //  CC-3 (L-C): xoa roi cong lai  -- CHI chay duoc SAU khi ap Va 4
    //  clr_in = 1; @(posedge clk); #1;
    //  send(16'h0010, 8'h00, 0);
```

### Vá 6 — sinh waveform (Charter mục 3 yêu cầu artifact số)

```systemverilog
    initial begin
        $dumpfile("g04_waves.vcd");
        $dumpvars(0, g04_tb);
        $dumpvars(1, dut.acc_q);   // BAT BUOC: 16 bit day du, khong chi 8 bit cao
    end
```

## 7. Việc Charter yêu cầu mà **chưa làm được**

| Yêu cầu | Trạng thái | Ghi chú |
|---|:-:|---|
| Ca *"cộng tới sát giới hạn"* (CC-1) | 🔴 **chưa có** | Vá 1 bổ sung |
| Ca *"cộng vượt giới hạn"* (CC-2) | 🔴 **chưa có** | Vector hiện tại **sai** |
| Ca *"xoá rồi cộng lại"* (CC-3) | 🔴 **KHÔNG THỂ** | RTL thiếu cổng — Vá 4 |
| Ca *"cộng giá trị 0"* (CC-4) | ❌ **thiếu** | Vá 5 |
| Charter mục 9: chạy flow **bão hoà** và **quay vòng**, so diện tích | ⬜ **chưa chạy** | `tradeoff.md` §7 |

⟹ **REQ-G04-010 CHƯA THOẢ** (0/4 ca bắt buộc thật sự được thực hiện đúng) và
**REQ-G04-020 CHƯA THOẢ**.

## 8. ⚠️ Trạng thái bản vá

> 🕐 **MỤC NÀY ĐÃ LỖI THỜI kể từ 2026-09-24 — xem §0 ở đầu tài liệu.** Giữ lại nguyên văn để
> thấy trạng thái tại thời điểm phán xử. Vá 1, 2, 5 nay **đã áp dụng**; Vá 3, 4, 6 thì không.

- **Chưa áp dụng.** Cả sáu vá ở §6 **không** được ghi vào file nào.
  `04_IMPLEMENTATION/rtl/` và `05_VERIFICATION/` **giữ nguyên bản gốc của thầy**.
- Lý do: quy trình của hồ sơ này là **phán xử, không sửa**. Vá 1, 2, 5, 6 đụng testbench;
  **Vá 3 và Vá 4 đụng RTL** và kéo theo phải chạy lại toàn bộ tầng 06_GDSII.
- Thứ tự đề nghị sau khi duyệt: **Vá 1** → chạy lại `01_run_sim.sh` (kỳ vọng PASS) →
  **Vá 2** → **Vá 6** → **Vá 5** (phần CC-4) → rồi mới xét **Vá 4** (cần chốt hai quyết định
  đặc tả) → **Vá 3** chỉ khi thầy muốn log sạch.
- **Tuyệt đối không sửa RTL để "làm cho mô phỏng xanh"**. Phán xử §4 đã chứng minh DUT đúng.

## 9. Giá trị dạy học

| # | Bài học | Vì sao đáng dạy |
|---|---|---|
| 1 | ⭐ **Giao diện quan sát hẹp hơn trạng thái trong là một nguồn lỗi kiểm chứng.** `acc_out_hi = 0xFF` ứng với **256** giá trị `acc` khác nhau | Đây là câu trả lời sống động nhất cho Charter mục 2 câu 3. Lỗi này **không** nằm trong thiết kế — nó nằm trong **cách người ta suy luận về thiết kế** qua một cửa sổ quan sát hẹp |
| 2 | **Testbench sai đổ oan cho DUT đúng.** Log nói `sat mismatch`, phản xạ đầu tiên là đi sửa logic bão hoà | Nếu ai đó "sửa" DUT cho `sat` bật sớm, họ sẽ **phá một thiết kế đang hoàn toàn đúng** và tạo ra lỗi thật ở biên `0xFFFF` |
| 3 | **Ranh giới `>` và `>=`.** `acc + inc = 65535` là **chưa tràn**; `= 65536` mới là tràn | Mọi lỗi bão hoà đều nằm ở đúng một điểm này. `test_exact_boundary` của mô hình chuẩn tồn tại **chỉ để** chốt nó |
| 4 | **Phát hiện tràn phải dùng bit carry, không dùng so sánh sau khi cắt.** `(acc+inc) > 16'hFFFF` trên 16 bit **luôn bằng 0** | Charter mục 10 cảnh báo thẳng. Cái bẫy nguy hiểm ở chỗ nó **không có cảnh báo tổng hợp nào**, và ABC còn "tối ưu" bằng cách xoá luôn tầng bão hoà |
| 5 | **Phân biệt `sorry:` với `error:`.** `sorry:` nghĩa là công cụ **chưa hỗ trợ** và đã lùi về phương án **bảo thủ an toàn** | Ở đây danh sách nhạy rộng **hơn** mức cần ⟹ vô hại. Nếu hẹp **hơn** mới là lỗi |
| 6 | **Một cảnh báo phải GIẢI THÍCH ĐƯỢC triệu chứng thì mới là thủ phạm.** Cảnh báo `sorry:` không giải thích được `sat mismatch` | Kỹ năng gỡ lỗi: đừng vơ cảnh báo gần nhất làm nguyên nhân. Ở đề D02 cảnh báo Icarus **là** thủ phạm; ở đây thì **không** |
| 7 | **Yosys có thể GỘP hai thanh ghi trùng lặp.** `acc_q[15:8]` và `acc_out_hi` là một ⟹ 18 FF chứ không 26 | Netlist **không** ánh xạ 1-1 với RTL. Muốn dò `acc_q[15:8]` ở gate-level phải tìm dưới tên `acc_out_hi` (`block_diagram.md` §3) |
| 8 | **Bão hoà rẻ về diện tích nhưng đắt về cấu trúc thời gian.** Nó biến `acc_q[1]` — vốn là đường ngắn nhất — thành đường dài nhất | Bằng chứng: endpoint đường tới hạn là **bit thứ hai từ dưới lên**, arrival 6,71 ns, và `acc_q[1]` với `acc_out_hi[2]` có arrival **bằng nhau** |
| 9 | **Một testbench "gần đúng" che mất lỗ hổng độ phủ.** Vì vector sai, lớp ca **L-E** và **L-O** chưa hề được kiểm ở mức Verilog | Nghĩa là ngay cả khi mô phỏng "xanh" bằng cách sửa DUT, hai ca **bắt buộc** của Charter mục 8 vẫn thiếu |
| 10 | **Thiếu một cổng trong giao diện có thể làm cả một ca bắt buộc trở nên bất khả thi.** Không có `xoá` ⟹ không kiểm được *"xoá rồi cộng lại"* | Đối chiếu Charter mục 4 với danh sách cổng RTL là việc **phải làm trước khi viết dòng testbench đầu tiên** |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
