# G04 · Đánh đổi kiến trúc (Trade-off Analysis)

---

## 1. Câu hỏi trung tâm của đề

> Charter mục 9: *"Bão hoà và quay vòng là hai hành vi tràn khác nhau, và bão hoà **tốn thêm
> logic**. **Định lượng chi phí đó**: chạy flow **một lần có bão hoà, một lần để quay vòng**,
> so sánh diện tích trong báo cáo."*
>
> Charter mục 10 — *chỗ hay tắc:* *"Phát hiện bão hoà **SAU** khi đã cộng tràn — phải phát
> hiện **TRƯỚC** hoặc dùng **bit carry**."*

## 2. ⚠️ Trạng thái trung thực của câu trả lời

| Việc Charter yêu cầu | Trạng thái | Cần gì |
|---|:-:|---|
| Chạy flow phiên bản **có bão hoà** | ✅ **ĐÃ CHẠY** | — (chính là RTL trong hồ sơ) |
| Chạy flow phiên bản **quay vòng** | ⬜ **CHƯA CHẠY** | Bỏ dòng 19–20 của RTL, chạy lại `02_run_synth.sh` + `03_run_sta.tcl` |
| So sánh **diện tích** hai phiên bản | ⬜ **chưa có số** | Kết quả tổng hợp của biến thể |
| So sánh **thời gian** hai phiên bản | ⬜ **chưa có số** | Kết quả STA của biến thể |

> **Không được bịa hai con số này.** §3 và §4 dưới đây là (a) phân tích cấu trúc từ **netlist
> thật** và (b) phân rã đường tới hạn từ **STA thật** — đó là những gì có thể khẳng định. §7
> là script cần chạy để có con số A/B mà Charter đòi.

## 3. Bão hoà so với quay vòng — bốn phương án

| # | Kiến trúc | Phát hiện tràn | Cell thêm | Vòng hồi tiếp | Dùng khi |
|---|---|---|---|---|---|
| **A** | **Bão hoà bằng bit carry** (G04 chọn) | `total_ext[16]` của phép cộng **17 bit** | 0 cho phát hiện + ≈14 cho ép bão hoà | Dài — mọi bit đợi `c16` | Công tơ, đo lường, DSP |
| **B** | **Quay vòng** (mod 2¹⁶) | không phát hiện gì | **0** | Ngắn — bit `i` chỉ đợi `c[i]` | Bộ đếm vòng, địa chỉ, timestamp |
| **C** | Bão hoà bằng **so sánh sau khi cộng** | `(acc + inc) > 16'hFFFF` trên **16 bit** | — | — | ❌ **SAI — luôn cho 0** (§5) |
| **D** | Bão hoà bằng **so sánh trước khi cộng** | `inc > (MAX − acc)` | 1 bộ trừ + 1 bộ so sánh 16 bit | **Dài hơn A** | Khi không lấy được bit carry (ví dụ dùng macro cộng có sẵn) |

### 3.1 Vì sao phương án A là đúng — và rẻ hơn D nhiều

```
   PHUONG AN A (G04):                    PHUONG AN D:

   {0,acc} + {0,inc}  -> 17 bit          tmp = MAX - acc     (1 bo tru 16 bit)
        │                                sat = (inc > tmp)   (1 bo so sanh 16 bit)
        └─ bit 16 = TRAN  (mien phi)     acc_next = sat ? MAX : acc + inc
                                                                (1 bo cong 16 bit)
   Chi phi them: 1 tang carry            Chi phi them: ~2 khoi 16 bit
                 (~1 cell)                             (~40-60 cell)
```

Bit carry-out của tầng cộng thứ 16 **vốn đã được tính** trong chuỗi carry — chỉ là ở một bộ
cộng 16 bit thông thường nó bị vứt đi. Mở rộng lên 17 bit chỉ là **giữ lại nó**. Đây chính là
điều Charter mục 10 yêu cầu.

### 3.2 Ép về `0xFFFF` là phép OR, không phải mux — phát hiện đọc từ netlist

```
     acc_next[i] = sat ? 1'b1 : total_ext[i]   =   sat | total_ext[i]
```

Vì `0xFFFF` là **toàn bit 1**, không cần mux 2:1 mà chỉ cần **một cổng OR mỗi bit**. Netlist
xác nhận: tín hiệu tràn nằm ở net `_093_` và có **15 tải** — **14 × `o21ai_0` chân `A1`**
(tầng ép bão hoà) + 1 × `nand2_1` chân `B` (nhánh tới FF `sat`).

| Nếu trần là giá trị khác `0xFFFF` | Chi phí |
|---|---|
| `0xFFFF` (toàn 1) — **trường hợp của G04** | 16 cổng **OR** |
| `0x0000` (toàn 0) | 16 cổng **AND** |
| Giá trị bất kỳ, ví dụ `0xF000` | **16 mux 2:1** — đắt gấp đôi |

> 💡 **Bài học thiết kế:** chọn trần là `2^N − 1` **không phải ngẫu nhiên** — nó làm logic bão
> hoà rẻ đi một nửa. Nếu đề yêu cầu trần ở một giá trị tuỳ ý, chi phí sẽ khác hẳn.

### 3.3 Ước lượng chi phí **diện tích** từ netlist (không phải A/B)

| Hạng mục | Cell | Tỉ lệ / 119 | Nguồn |
|---|---:|---:|---|
| Phát hiện tràn (bit carry thứ 17) | **≈ 1** | 0,8 % | Một tầng carry thêm |
| Tầng ép bão hoà | **≈ 14** | **11,8 %** | Đếm cell nhận net `_093_` |
| Flip-flop `sat` + logic của nó | **≈ 2** | 1,7 % | `_204_` + `_138_` |
| **Tổng ước lượng chi phí bão hoà** | **≈ 17** | **≈ 14 %** | |

⚠️ Đây là **ước lượng từ cấu trúc netlist**, không phải hiệu số A/B. ABC gộp và ánh xạ lại
logic, nên con số thật có thể lệch đáng kể theo cả hai chiều. **Bảng §7 mới là câu trả lời
mà Charter mục 9 đòi hỏi.**

## 4. ⭐ Chi phí **thời gian** của bão hoà — phần định lượng được ngay

Đây là phần có giá trị nhất của hồ sơ G04, vì nó đo được từ **một** lần chạy.

### 4.1 Phân rã đường tới hạn thật

| Đoạn | Thời gian | Tỉ lệ | Có ở phiên bản **quay vòng** không? |
|---|---:|---:|---|
| Độ trễ vào (giả định) | 1,00 ns | 14,9 % | ✅ có |
| Đầu chuỗi carry | 0,21 ns | 3,1 % | ✅ có |
| **Chuỗi carry 16 bit** (12 `maj3`) | **4,71 ns** | **70,2 %** | ✅ có |
| Sinh tín hiệu tràn (`_136_`, fanout 15) | 0,47 ns | 7,0 % | ❌ **chỉ có ở bão hoà** |
| Ép bão hoà + mux giữ/nạp | 0,32 ns | 4,8 % | ⚠️ mux giữ/nạp vẫn có; phần ép bão hoà thì không |
| **Tổng arrival** | **6,71 ns** | 100 % | |

⟹ Phần **chắc chắn** thuộc về bão hoà: **≈ 0,79 ns = 11,8 %** đường tới hạn.

### 4.2 Chi phí **cấu trúc** — lớn hơn nhiều và không nhìn thấy trong bảng trên

> **Endpoint của đường tới hạn là `acc_q[1]` — bit thứ hai từ dưới lên.**

Trong bộ tích luỹ **quay vòng**, `acc_next[1] = s[1]`, chỉ cần `carry[1]` ⟹ khoảng **2 mức
logic**, cỡ **0,2 ns**, slack gần **9,8 ns**. Ở G04, cùng bit đó mất **6,71 ns**.

```
   QUAY VONG — do sau khac nhau theo bit:
      acc_next[0]  : 1 muc            slack ~9,8 ns   <- du dia RAT lon
      acc_next[1]  : 2 muc            slack ~9,7 ns
      ...
      acc_next[15] : 16 tang carry    slack ~4,0 ns   <- chi bit nay cang

   BAO HOA — do sau BANG NHAU o moi bit:
      acc_next[i]  = c16 | s[i]   voi MOI i
      => MOI bit deu phai doi het chuoi carry
      => slack ~3,2 ns o TAT CA 16 bit                <- khong con du dia nao
```

**Bằng chứng trực tiếp:** trong báo cáo STA, `acc_q[1]` và `acc_out_hi[2]` có arrival
**bằng nhau: 6,71 ns**. Ở một bộ cộng quay vòng, hai bit này phải chênh nhau ~14 tầng carry.
Đồ thị phụ thuộc đã bị **san phẳng**.

| Hệ quả thực tế | Giải thích |
|---|---|
| Công cụ **mất hết dư địa** để tối ưu | Ở bản quay vòng, 15/16 bit có slack lớn ⟹ ABC dùng cell nhỏ, chậm, ít rò để giảm diện tích và công suất. Ở bản bão hoà, **mọi** bit đều căng ⟹ phải dùng cell nhanh hơn |
| ⟹ Chi phí diện tích thật của bão hoà **lớn hơn** con số ≈14 cell ở §3.3 | Vì nó còn bao gồm phần "phải dùng cell to hơn ở khắp nơi" — thứ chỉ lộ ra khi chạy A/B |
| Bão hoà **xung khắc** với carry-save | Bão hoà cần carry-out của bit cao nhất, tức cần giải quyết xong biểu diễn carry-save ⟹ không dùng được thủ thuật tăng tốc của G02 |

> 🔎 **Đây là phát hiện trung tâm của đề G04, và nó trả lời Charter mục 9 sâu hơn câu hỏi
> đặt ra:** Charter hỏi *"bão hoà tốn thêm bao nhiêu diện tích"*. Câu trả lời đầy đủ là:
> **bão hoà tốn ít diện tích trực tiếp (≈14 cell) nhưng phá huỷ cấu trúc slack của bộ cộng,
> làm mọi bit đều căng thời gian.** Con số diện tích A/B (§7) sẽ **bao gồm cả** hiệu ứng gián
> tiếp này — và đó là lý do phải chạy thật thay vì cộng cell bằng tay.

## 5. Vì sao phương án C **sai** — bẫy mà Charter mục 10 cảnh báo

```systemverilog
    // SAI HOAN TOAN:
    logic [15:0] total_bad;
    assign total_bad = acc_q + inc_in;           // DA BI CAT ve 16 bit o day
    assign sat_bad   = (total_bad > 16'hFFFF);   // LUON = 0
```

Với `acc_q = 0xFFFF`, `inc_in = 1`: `total_bad = 0x0000`, `sat_bad = 0` ⟹ bộ tích luỹ
**quay vòng về 0** — đúng hành vi mà đề này tồn tại để ngăn chặn.

| Vì sao bẫy này nguy hiểm | Giải thích |
|---|---|
| **Không có cảnh báo nào** | Cú pháp hợp lệ; Yosys tổng hợp bình thường; Icarus biên dịch sạch |
| Logic tổng hợp ra **cũng "hợp lý"** | ABC thấy `sat_bad` là hằng 0 và **loại bỏ toàn bộ tầng bão hoà** ⟹ netlist nhỏ hơn, trông như "tối ưu tốt" |
| Chỉ lộ ra ở **một** ca kiểm thử | Ca vượt trần (CC-2). Nếu testbench không có ca đó — và **testbench hiện tại thật sự không có**, xem `corner_cases.md` §4 — lỗi lọt hoàn toàn |
| Cách phát hiện chắc chắn | Đếm flip-flop và cell: bản sai sẽ **thiếu hẳn** ≈14 cell của tầng bão hoà; và `sat` sẽ bị tối ưu thành hằng `0` |

**G04 làm ĐÚNG**: dùng `total_ext` rộng **17 bit** và lấy `total_ext[16]`.

## 6. Trả lời Charter mục 2 câu 3: chỉ xuất 8 bit cao thì mất gì

| Mất mát | Định lượng | Bằng chứng |
|---|---|---|
| **Độ phân giải quan sát** | 1 LSB của `acc_out_hi` = **256** LSB trong. `0x1200` và `0x12FF` cho cùng `0x12` | `reference_model.test_upper_byte` |
| **Không phân biệt được "gần trần" với "đúng trần"** | `acc_out_hi = 0xFF` ứng với **256** giá trị `acc` (`0xFF00`…`0xFFFF`) | INV-10 |
| **Sai số cắt cụt (truncation), luôn thiếu** | `acc_out_hi = floor(acc / 256)`, sai số ∈ `[0, 255]` LSB trong | `acc_next[15:8]` |
| ⭐ **Làm chính người viết testbench nhầm** | `simulation.log`: `sat mismatch got=0 expected=1` | `known_issues.md` |
| **Không kiểm chứng được từ bên ngoài** | Testbench **buộc phải** dò `dut.acc_q` kiểu white-box, hoặc thiết kế vector tính được byte thấp | `corner_cases.md` §3 CC-8 |

**Được gì:** tiết kiệm **8 chân ra** trên ngân sách 24 chân của Tiny Tapeout — đủ để cả `sat`
và `valid_out` cùng có chỗ. Với một công tơ đọc theo tháng, độ phân giải 256 đơn vị là **chấp
nhận được**; tầng ngoài đếm số lần `sat` để mở rộng dải đo.

## 7. Script cần chạy để hoàn thành Charter mục 9 (chưa chạy)

```bash
# 1. Tao bien the QUAY VONG: sao rtl/g04_sat_accum16.sv -> g04_wrap_accum16.sv
#    va thay dong 16-20 bang:
#        assign total_ext = {1'b0, acc_q} + {1'b0, inc_in};
#        always_comb begin
#            sat_next = 1'b0;                 // KHONG bao hoa
#            acc_next = total_ext[15:0];      // quay vong
#        end
# 2. Tong hop rieng, CUNG thu vien, CUNG script
yosys -p "read_verilog -sv rtl/g04_wrap_accum16.sv; \
          synth -top g04_wrap_accum16; \
          dfflibmap -liberty \$LIB; abc -liberty \$LIB; \
          stat -liberty \$LIB; write_verilog netlist_wrap.v"
# 3. STA voi CUNG design.sdc
sta -exit scripts/03_run_sta.tcl        # doi duong dan netlist sang netlist_wrap.v
# 4. Dien cac o ??? trong bang duoi
```

| Chỉ số | A · **có bão hoà** (đã đo) | B · quay vòng | Chênh = **chi phí bão hoà** |
|---|---:|---:|---|
| Cell | **119** | ⬜ chưa chạy | ⬜ |
| Flip-flop | **18** | ⬜ | ⬜ (dự kiến **không đổi** — `sat` có thể bị loại ⟹ 17) |
| Diện tích (µm²) | **1083,5392** | ⬜ | ⬜ |
| Arrival (ns) | **6,71** | ⬜ | ⬜ |
| Slack (ns) | **3,16** | ⬜ | ⬜ |
| Endpoint đường tới hạn | `acc_q[1]` | ⬜ (dự đoán: một **bit cao**) | ⬜ |
| Công suất (W) | **1,40e-04** | ⬜ | ⬜ |

> ⚠️ **Lưu ý khi so:** phiên bản quay vòng sẽ **mất luôn cổng `sat`**, nên nó có 17 FF chứ
> không 18. Muốn so công bằng về logic, nên giữ `sat` như một cờ "đã từng tràn" (sticky) để
> hai phiên bản có cùng số cổng ra.
>
> ⬜ **Đây là bảng phải điền để đề G04 đạt REQ-G04-020. Hiện tại yêu cầu đó CHƯA THOẢ.**

## 8. Những đánh đổi **KHÔNG** được phép trong đề này

| Cám dỗ | Vì sao không được |
|---|---|
| Phát hiện tràn bằng `(acc + inc) > 16'hFFFF` trên 16 bit | Charter mục 10 cảnh báo thẳng; biểu thức **luôn sai** (§5) |
| Bỏ bão hoà cho "nhanh hơn / nhỏ hơn" | Phá huỷ toàn bộ mục đích của đề; quay vòng làm công tơ **mất tính đơn điệu** |
| Tích luỹ **có dấu** | Charter mục 3: **ngoài phạm vi** |
| **Nhiều kênh** tích luỹ | Charter mục 3: ngoài phạm vi |
| **Chia trung bình** | Charter mục 3: ngoài phạm vi (đó là G01/G02) |
| Xuất đủ 16 bit cho dễ kiểm thử | Vi phạm Charter mục 4 (`uo_out[7:0]` = 8 bit cao) và vượt ngân sách chân. Cách đúng: kiểm white-box trong testbench |
| **Sửa RTL để mô phỏng PASS** | Phán xử `known_issues.md` kết luận lỗi ở **testbench**. Sửa DUT ở đây là **phá một thiết kế đang đúng** |
| Bỏ qua cảnh báo `sorry: constant selects…` mà không phán xử | Phải nói rõ đó là **giới hạn công cụ vô hại** và **không** liên quan tới lỗi mô phỏng — `known_issues.md` §5 |
| Kết luận "G04 chạy được ở X MHz" từ 6,71 ns | Chưa ký sinh dây, một góc PVT, skew = 0 |
| Sửa netlist bằng tay | Charter mục 3: ngoài phạm vi |
| **Tự thêm cổng `xoá`** vào RTL mà chưa được duyệt | Dù Charter mục 4 yêu cầu, quy trình hồ sơ này là **phán xử, không sửa**. Đề xuất ở `known_issues.md` §6 Vá 4 |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-G04-020, REQ-G04-021, Charter mục 2, mục 9, mục 10.*
