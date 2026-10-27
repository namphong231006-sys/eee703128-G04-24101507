# G04 — Bộ tích luỹ có bão hoà 16-bit · Ghi chú thực hiện

## 1. Bài toán này thực chất là gì

Bề ngoài G04 là "cộng dồn rồi kẹp ở trần". Thực chất nó là bài toán **giữ tính đơn điệu của
một phép đo tích luỹ khi tài nguyên biểu diễn hữu hạn**.

Bối cảnh của Charter mục 1 nói rõ: công tơ điện tử cộng dồn năng lượng tiêu thụ. Một công tơ
là bộ đếm tích luỹ — **số đọc của nó phải không bao giờ giảm**. Đó không phải mong muốn thẩm
mỹ, đó là tính chất mà toàn bộ hệ thống phía trên dựa vào: phần mềm đọc công tơ tính **hiệu
số** giữa hai lần đọc để ra lượng tiêu thụ trong kỳ.

Khi bộ tích luỹ 16 bit đầy, phần cứng phải chọn một trong hai hành vi:

| | Quay vòng (mod 2¹⁶) | Bão hoà |
|---|---|---|
| `0xFFFF + 1` | `0x0000` | `0xFFFF` |
| Tính đơn điệu | ❌ **mất** | ✅ **giữ** |
| Hiệu số hai lần đọc | có thể **âm** hoặc sai 65535 | **0** — sai nhưng bị chặn |
| Người đọc hiểu là | *"khách hàng chưa dùng điện"* | *"thiết bị hết thang đo"* |
| Có dấu hiệu cảnh báo không | ❌ **không có gì cả** | ✅ cờ `sat` |

Quay vòng **sai không kiểm soát được**; bão hoà **sai theo một hướng duy nhất, bị chặn, và có
cảnh báo**. Trong đo lường thương mại, khác biệt đó là khác biệt giữa "ghi thiếu" và "sai hẳn
có thể bị coi là gian lận".

Bài toán còn có một nửa thứ hai ít người để ý: **giao diện chỉ cho ra 8 bit cao của một
trạng thái 16 bit**. Nửa này tưởng phụ, nhưng nó chính là thứ đã sinh ra lỗi trong hồ sơ.

## 2. Bản chất kỹ thuật — cơ chế hoạt động

Cơ chế cốt lõi gồm **ba bước**, và cái hay nằm ở chỗ cả ba đều rất rẻ:

```
   (1) Cong MO RONG 17 bit :  total_ext = {1'b0, acc_q} + {1'b0, inc_in}
   (2) Phat hien tran      :  sat_next  = total_ext[16]          <- BIT CARRY-OUT
   (3) Ep ve tran          :  acc_next[i] = total_ext[16] | total_ext[i]
```

**Bước (2) tốn 0 cell.** Carry-out của tầng cộng thứ 16 **vốn đã được tính** trong chuỗi
carry — ở một bộ cộng 16 bit thông thường nó chỉ bị vứt đi. Mở rộng lên 17 bit chỉ là *giữ
lại nó*. Đây đúng là điều Charter mục 10 yêu cầu (*"dùng bit carry"*).

**Bước (3) là phép OR, không phải mux.** Vì trần `0xFFFF` là **toàn bit 1**, "chọn giữa
`0xFFFF` và tổng thật" quy về `sat | total_ext[i]` — một cổng OR mỗi bit thay vì một mux 2:1.
Nếu trần là một giá trị tuỳ ý (ví dụ `0xF000`) thì phải dùng mux thật, đắt gấp đôi.

Nhưng đây mới là **nút thắt thật sự**, và nó không nằm ở số cell:

> **Bão hoà làm MỌI bit của bộ tích luỹ phụ thuộc vào carry-out của bit CAO NHẤT.**

Trong một bộ tích luỹ quay vòng, `acc_next[1] = s[1]` — chỉ cần `carry[1]`, khoảng 2 mức
logic, xong sau ~0,2 ns, và bit đó có slack gần bằng cả chu kỳ. Ở G04, `acc_next[1] =
c16 | s[1]` — nó phải đợi **toàn bộ 16 tầng carry**.

Số liệu thật xác nhận một cách không thể rõ hơn: **endpoint của đường tới hạn là `acc_q[1]`**
— bit thứ hai từ dưới lên — với arrival **6,71 ns**. Và trong cùng báo cáo, `acc_out_hi[2]`
cũng có arrival **6,71 ns**. Ở một bộ cộng quay vòng, hai bit này phải chênh nhau ~14 tầng
carry. Đồ thị phụ thuộc đã bị **san phẳng**: không còn bit nào "xong sớm", không còn dư địa
slack nào cho công cụ khai thác.

**Đó là cái giá thật của bão hoà — và nó không nhìn thấy được nếu chỉ đếm cell.**

## 3. Đọc mã nguồn: RTL làm gì, từng dòng quan trọng

**(a) Phép cộng mở rộng — dòng 16, trái tim của thiết kế:**

```systemverilog
    assign total_ext = {1'b0, acc_q} + {1'b0, inc_in};
```

`total_ext` khai `logic [16:0]` (dòng 12). Hai toán hạng được **mở rộng không dấu lên 17
bit** trước khi cộng, nên bit 16 của kết quả chính là carry-out — **không bị cắt mất**. Đây
là toàn bộ sự khác biệt giữa đúng và sai của đề này.

**(b) Phát hiện và ép — dòng 18–21:**

```systemverilog
    always_comb begin
        sat_next = total_ext[16];
        acc_next = total_ext[16] ? 16'hFFFF : total_ext[15:0];
    end
```

Hai dòng. `sat_next` là **dây thuần**, 0 cell. `acc_next` là 16 cổng OR (netlist: tín hiệu
tràn nằm ở net `_093_` với **15 tải**, trong đó **14 × `o21ai_0` chân `A1`**).

**(c) Nạp trạng thái — dòng 32–37:**

```systemverilog
            if (valid_in) begin
                acc_q      <= acc_next;
                acc_out_hi <= acc_next[15:8];
                sat        <= sat_next;
                valid_out  <= 1'b1;
            end
```

Chú ý: `acc_q` và `acc_out_hi` **luôn nhận cùng dữ liệu, cùng cạnh, cùng enable** ⟹ chúng
tương đương ở mọi thời điểm (INV-9). Yosys phát hiện điều đó và **gộp `acc_q[15:8]` vào
`acc_out_hi`**: netlist chỉ có `acc_q[0]`…`acc_q[7]`, **không tồn tại** `acc_q[8..15]`. Kết
quả: **18 flip-flop** thay vì 26.

**(d) Không có cổng `xoá` — dòng 1–9:** danh sách cổng gồm `clk`, `rst_n`, `valid_in`,
`inc_in`, `valid_out`, `acc_out_hi`, `sat`. Charter mục 4 yêu cầu `uio_in[1] = xoá`. **Thiếu.**

## 4. Vì sao chọn kiến trúc này

| Phương án | Phát hiện tràn | Chi phí thêm | Đánh giá |
|---|---|---|---|
| **A · Bit carry của cộng 17 bit** (đã chọn) | `total_ext[16]` | ≈ 1 cell (tầng carry) + ≈ 14 (ép) | ✅ **rẻ nhất, đúng nhất** |
| B · So sánh **trước** khi cộng: `inc > MAX − acc` | 1 bộ trừ + 1 bộ so sánh 16 bit | ≈ 40–60 cell | ⚠️ đúng nhưng đắt hơn nhiều |
| C · So sánh **sau** khi cộng: `(acc+inc) > 16'hFFFF` | — | — | ❌ **SAI — biểu thức luôn bằng 0** |
| D · Quay vòng (không bão hoà) | không có | 0 | ❌ phá vỡ mục đích của đề |

Phương án C là **cái bẫy mà Charter mục 10 cảnh báo**, và nó nguy hiểm vì: cú pháp hợp lệ,
Yosys tổng hợp bình thường, Icarus biên dịch sạch, và ABC còn "tối ưu" bằng cách **xoá luôn
tầng bão hoà** (vì `sat` trở thành hằng 0) — netlist nhỏ hơn, trông như tối ưu tốt.
Nó chỉ lộ ra ở ca vượt trần, mà testbench hiện tại **không có ca đó**.

## 5. Cách thực hiện — lộ trình 8 bước từ đặc tả tới GDSII

| Bước | Việc | Trạng thái thật của G04 |
|---|---|---|
| 1 | Đối chiếu Charter mục 4 với danh sách cổng **trước khi viết mã** | 🔴 **BỎ SÓT** — thiếu `xoá`, sai độ rộng `inc_in` |
| 2 | Viết mô hình chuẩn Python + ca biên chính xác | ✅ `reference_model.py` — **PASS 6/6**, gồm 5000 ca ngẫu nhiên |
| 3 | Viết RTL dùng **bit carry** để phát hiện tràn | ✅ đúng cả bốn ràng buộc Charter mục 10 |
| 4 | Viết testbench phủ 4 ca bắt buộc Charter mục 8 | 🔴 **0/4 ca thật sự đúng** (vector sai + thiếu cổng) |
| 5 | Mô phỏng RTL | 🔴 **RAN_WITH_ISSUES** — dừng `t = 56` |
| 6 | Tổng hợp | ✅ 119 cell · 18 FF · 1083,5392 µm² |
| 7 | STA + công suất | ✅ arrival 6,71 ns · slack 3,16 ns · 1,40e-04 W |
| 8 | P&R → DRC/LVS → GDSII | ⬜ **CHƯA CHẠY** |

> ⚠️ **Bước 1 là bước bị bỏ sót, và nó đắt nhất.** Nếu đối chiếu Charter mục 4 với danh sách
> cổng ngay từ đầu, cả hai vấn đề (thiếu `xoá`, sai độ rộng `inc_in`) đã lộ ra **trước khi**
> viết dòng RTL đầu tiên. Sửa bây giờ kéo theo phải chạy lại toàn bộ tầng vật lý — và sửa độ
> rộng `inc_in` còn **đổi cả kiến trúc** (phải nạp hai nhịp ⟹ sinh ra một FSM thật).

## 6. Số liệu thật đã đo được và cách đọc chúng

| Chỉ số | Giá trị | Nguồn |
|---|---:|---|
| Số cell | 119 | `synth_stat.txt` |
| Flip-flop | 18 | như trên |
| Diện tích | 1083,5392 µm² | như trên |
| Startpoint → Endpoint | `inc_in[1]` → `_206_` (= **`acc_q[1]`**) | `timing_report_max.txt` |
| Data arrival | **6,71 ns** | như trên |
| Slack | **3,16 ns** (MET) | như trên |
| Số cell trên đường tới hạn | **19**, trong đó **12 `maj3_1`** | như trên |
| WNS / TNS | 0,00 / 0,00 | `wns.txt`, `tns.txt` |
| Công suất | 1,40e-04 W (tổ hợp **36,0 %** · tuần tự 64,0 %) | `power_report.txt` |

**Những con số này CHỨNG MINH:**
- RTL tổng hợp được ra standard cell sky130 thật.
- **18 flip-flop** khớp **chính xác** với Charter mục 10 (*"16 ô nhớ tích luỹ + 1 cờ ≈ 17–18"*)
  — nhưng chỉ vì Yosys đã **gộp 8 flip-flop** (§3c). Không gộp thì là 26.
- Logic bão hoà **tồn tại thật** trong netlist: net `_093_` với 15 tải, 14 trong đó là tầng ép.
- Ở góc `tt_025C_1v80` với chu kỳ giả định 10 ns, đường dài nhất còn dư 3,16 ns.

**Những con số này KHÔNG chứng minh:**
- **Không** chứng minh mạch làm đúng chức năng — mô phỏng dừng ở chu kỳ thứ sáu (dù phán xử
  cho thấy **DUT đúng, testbench sai**).
- **Không** chứng minh "G04 chạy được ở 100 MHz" — chưa ký sinh dây, một góc PVT, skew = 0,
  và phụ thuộc giả định `set_input_delay 1.0`.
- **Không** chứng minh chi phí của bão hoà — cần chạy A/B (Charter mục 9, **chưa chạy**).

**Ba con số đáng bàn nhất:**

*(a) Endpoint là `acc_q[1]`.* Bit thứ hai từ dưới lên là endpoint của đường tới hạn. Ở một
bộ cộng bình thường đây là một trong những đường **ngắn nhất**. Đây là dấu vân tay không thể
nhầm của bão hoà (§2).

*(b) Phân rã đường tới hạn.*

| Đoạn | Thời gian | Tỉ lệ |
|---|---:|---:|
| Độ trễ vào (giả định) | 1,00 ns | 14,9 % |
| Đầu chuỗi carry | 0,21 ns | 3,1 % |
| **Chuỗi carry 16 bit** (12 `maj3`) | **4,71 ns** | **70,2 %** |
| Sinh tín hiệu tràn (`_136_`, fanout 15) | 0,47 ns | 7,0 % |
| **Ép bão hoà + mux giữ/nạp** | **0,32 ns** | **4,8 %** |

Phần **chắc chắn** thuộc về bão hoà là **0,79 ns = 11,8 %**. Nhưng như §2 đã nói, chi phí
**cấu trúc** lớn hơn nhiều và chỉ lộ ra khi chạy A/B.

*(c) G04 là đề NHỎ NHẤT nhóm G (119 cell, 1083,5392 µm²) nhưng có đường tới hạn DÀI THỨ HAI
(6,71 ns).* Diện tích chỉ bằng **26,6 %** của G02, nhưng arrival **dài hơn 53 %**.

## 7. Trả lời các câu hỏi kỹ thuật của Charter (mục 2)

**Câu 1 — Bão hoà khác quay vòng ở chỗ nào, và vì sao quay vòng nguy hiểm với công tơ?**
✅ **Trả lời được.** Khác nhau ở hành vi khi vượt trần: bão hoà dừng ở `0xFFFF`, quay vòng về
`0x0000`. Nguy hiểm vì quay vòng **phá vỡ tính đơn điệu** — tính chất mà mọi phần mềm đọc
công tơ dựa vào để tính hiệu số. Bão hoà sai theo một hướng, bị chặn, và có cờ `sat` báo;
quay vòng sai 65535 đơn vị và **không có dấu hiệu nào**. Bảng đầy đủ: `functional_spec.md` §4.

**Câu 2 — Phát hiện chạm trần bằng logic gì, tốn bao nhiêu cell?**
✅ **Trả lời được một phần.** Bằng **bit carry-out của phép cộng mở rộng 17 bit**
(`total_ext[16]`) — chi phí **phát hiện** là **0 cell** vì bit đó vốn đã tồn tại trong chuỗi
carry. Chi phí **ép về trần** đọc từ netlist: tín hiệu tràn (net `_093_`) có 15 tải, trong đó
**14 × `o21ai_0`** là tầng ép ⟹ **≈ 14 cell = 11,8 %** của 119 cell.
⚠️ Đây là **ước lượng từ cấu trúc netlist**, không phải hiệu số A/B. Con số Charter thật sự
đòi hỏi (§8) **chưa có**.

**Câu 3 — Bộ tích luỹ 16 bit nhưng chỉ xuất 8 bit cao — mất mát gì?**
✅ **Trả lời được, và có bằng chứng sống.**

| Mất mát | Định lượng |
|---|---|
| Độ phân giải quan sát | 1 LSB ngoài = **256** LSB trong |
| Không phân biệt "gần trần" với "đúng trần" | `acc_out_hi = 0xFF` ⟺ `acc ∈ [0xFF00, 0xFFFF]` — **256 giá trị** |
| Sai số cắt cụt, luôn thiếu | `floor(acc/256)`, sai số ∈ `[0, 255]` |
| ⭐ **Làm chính người viết testbench nhầm** | `simulation.log`: `sat mismatch got=0 expected=1` |

**Được gì:** tiết kiệm 8 chân ra trên ngân sách 24 chân — đủ chỗ cho `sat` và `valid_out`.

## 8. Trả lời câu phân tích riêng (Charter mục 9)

Câu hỏi: *"chạy flow một lần có bão hoà, một lần để quay vòng, so sánh diện tích."*

**Trạng thái: ⬜ CHƯA CHẠY phiên bản quay vòng.** REQ-G04-020 **CHƯA THOẢ**. Bảng phải điền
và script cần chạy nằm ở `03_ARCHITECTURE/tradeoff.md` §7. **Không bịa số.**

**Những gì đã trả lời được từ một lần chạy:**

1. **Chi phí diện tích ước lượng từ netlist:** ≈ 17 cell (1 tầng carry + 14 cell ép bão hoà
   + 2 cho FF `sat`) ≈ **14 %** của 119 cell.
2. **Chi phí thời gian trực tiếp:** **0,79 ns = 11,8 %** đường tới hạn (phần nằm **sau** khi
   chuỗi carry đã xong ở 5,92 ns).
3. ⭐ **Chi phí cấu trúc — phát hiện quan trọng nhất:** bão hoà **san phẳng đồ thị phụ thuộc**.
   Bằng chứng: `acc_q[1]` và `acc_out_hi[2]` có arrival **bằng nhau (6,71 ns)**; endpoint
   đường tới hạn là một **bit thấp**. Ở bản quay vòng, 15/16 bit sẽ có slack lớn — dư địa mà
   ABC dùng để chọn cell nhỏ hơn, chậm hơn, ít rò hơn. Bão hoà lấy mất dư địa đó.
   ⟹ **Chi phí diện tích thật (A/B) sẽ LỚN HƠN con số ≈17 cell ở trên**, vì nó bao gồm cả
   hiệu ứng "phải dùng cell to hơn ở khắp nơi". Đây chính là lý do Charter đòi chạy A/B thay
   vì cộng cell bằng tay.
4. **Cấu trúc phụ:** bão hoà **xung khắc** với biểu diễn carry-save (thủ thuật tăng tốc mà
   G02 dùng được), vì nó cần carry-out của bit cao nhất ⟹ phải giải quyết xong carry-save.

## 9. Những chỗ sinh viên hay sai và cách phát hiện

| # | Sai lầm | Hậu quả | Phát hiện bằng bằng chứng nào |
|---|---|---|---|
| 1 | `sat = ((acc_q + inc_in) > 16'hFFFF)` trên 16 bit | **Luôn bằng 0** ⟹ mạch quay vòng; ABC còn xoá luôn tầng bão hoà | Ca vượt trần (`0xFFFF + 1` phải cho `0xFFFF`, `sat = 1`). Và đếm cell: bản sai **thiếu ≈14 cell** |
| 2 | Dùng `>=` thay `>`: `sat = (total >= 16'hFFFF)` | Bão hoà **sớm một đơn vị**: `acc + inc = 65535` bị báo tràn oan | Ca biên chính xác: `update(65534, 1)` phải cho `(65535, False)` — `test_exact_boundary` |
| 3 | ⭐ **Nhầm `acc_out_hi` với `acc_q`** | Suy sai về trạng thái trong; viết vector kiểm thử sai | 🔴 **Đây là lỗi thật của đề.** `acc_out_hi = 0xFF` ⟺ `acc ∈ [0xFF00, 0xFFFF]`. Cách chắc chắn: kiểm white-box `dut.acc_q` |
| 4 | Tưởng `sat` nghĩa là *"đang ở trần"* | `acc = 0xFFFF`, `inc = 0` cho `sat = 0` ⟹ tầng ngoài tưởng đã thoát trần | INV-6; `test_exact_boundary`: `update(65535, 0) = (65535, False)` |
| 5 | Bão hoà **không dính** (chỉ cắt một lần) | Sau khi chạm trần, lần cộng sau lại quay vòng | Ca `test_sticky_saturation`: cộng `1, 2, 255, 65535` liên tiếp từ `0xFFFF`, `acc` phải giữ `0xFFFF` |
| 6 | Dùng mux 2:1 cho tầng ép bão hoà | Tốn gấp đôi cell so với cổng OR | Vì trần là **toàn bit 1** nên `sat \| total_ext[i]` là đủ. Đối chiếu `o21ai_0` trong netlist |
| 7 | Đếm flip-flop từ RTL (26) rồi khẳng định netlist phải khớp | Netlist chỉ có **18** | Yosys **gộp** `acc_q[15:8]` vào `acc_out_hi` (INV-9). Tra netlist: **không tồn tại** `acc_q[8..15]` |
| 8 | Dự đoán endpoint đường tới hạn là `acc_q[15]` | Thực tế là **`acc_q[1]`** | Bão hoà làm mọi bit phụ thuộc `c16` ⟹ đồ thị bị san phẳng |
| 9 | Coi cảnh báo `sorry: constant selects…` là nguyên nhân lỗi mô phỏng | Đi sửa nhầm chỗ | Cảnh báo đó **không giải thích được** `sat mismatch`. Nó chỉ nói danh sách nhạy của `always_comb` rộng hơn cần thiết — **vô hại** |
| 10 | Không đối chiếu Charter mục 4 với danh sách cổng | Thiếu `xoá` ⟹ **một ca bắt buộc trở nên bất khả thi** | So bảng cổng RTL với Charter mục 4 — việc phải làm **trước** khi viết testbench |
| 11 | Sửa DUT cho `sat` bật sớm để mô phỏng xanh | **Phá một thiết kế đúng** và tạo lỗi thật ở biên `0xFFFF` | Phán xử `known_issues.md` §4: `0xFF00 + 1 = 0xFF01 < 0xFFFF` là **số học**, không phải quan điểm |

## 10. Câu hỏi mentor nên đặt khi bảo vệ

| # | Câu hỏi | Đáp án mong đợi |
|---|---|---|
| 1 | Vì sao `total_ext` rộng **17** bit chứ không phải 16? | Để giữ lại **carry-out**. Nếu cộng trên 16 bit, kết quả bị cắt và mọi phép so sánh sau đó đều vô nghĩa — Charter mục 10 cảnh báo đúng chỗ này |
| 2 | `acc = 0xFFFF`, `inc = 0`. `sat` bằng mấy? Vì sao? | **0**. `sat` báo *"phép cộng vừa rồi bị cắt"*, không báo *"đang ở trần"* (INV-6). Đây là ngữ nghĩa cần thầy chốt |
| 3 | `acc = 65534`, `inc = 1`. Có bão hoà không? | **Không.** `= 65535` là **đúng bằng** trần, chưa vượt. Ranh giới là `>` chứ không phải `>=` |
| 4 | Ép về `0xFFFF` tốn mux hay tốn OR? Vì sao? | **OR.** Vì `0xFFFF` toàn bit 1 ⟹ `sat \| total_ext[i]`. Nếu trần là giá trị tuỳ ý thì mới cần mux, đắt gấp đôi |
| 5 | Netlist có 18 flip-flop mà RTL mô tả 26 bit trạng thái. Giải thích. | Yosys **gộp** `acc_q[15:8]` vào `acc_out_hi` vì hai thanh ghi luôn giống hệt nhau (INV-9). Netlist **không có** `acc_q[8..15]` |
| 6 | Endpoint đường tới hạn là `acc_q[1]` — bit thấp. Vì sao? | Vì bão hoà làm `acc_next[i] = c16 \| s[i]` với **mọi** `i` ⟹ mọi bit phải đợi hết chuỗi carry. Ở bản quay vòng, `acc_q[1]` sẽ là đường ngắn nhất |
| 7 | Bão hoà tốn bao nhiêu ns, bao nhiêu cell? | Trực tiếp: **0,79 ns** (11,8 %) và **≈ 14 cell** (11,8 %). Nhưng chi phí **cấu trúc** lớn hơn — chỉ đo được bằng A/B, và A/B **chưa chạy** |
| 8 | Hai cảnh báo `sorry: constant selects…` là lỗi gì? | **Giới hạn công cụ, vô hại.** Icarus không phân tích được part-select trong danh sách nhạy ngầm của `always_comb` nên đưa **cả 17 bit** vào — rộng **hơn** mức cần, tức **bảo thủ và an toàn** |
| 9 | Mô phỏng đỏ. Lỗi ở DUT, testbench hay mô hình chuẩn? | **Testbench.** Vector dòng 44 kỳ vọng `sat = 1` ở phép cộng `0xFF00 + 1 = 0xFF01` — không hề tràn. Người viết nhầm `acc_out_hi = 0xFF` với `acc_q = 0xFFFF` |
| 10 | Testbench đã phủ hết Charter mục 8 chưa? | **Chưa — 0/4.** Ca "sát giới hạn" và "vượt giới hạn" **không thật sự tồn tại** (vector sai); ca "cộng 0" thiếu; ca "xoá rồi cộng lại" **không thể chạy** vì RTL thiếu cổng |
| 11 | RTL có thoả Charter mục 4 không? | **Không.** Thiếu cổng `xoá` (`uio_in[1]`), `inc_in` 16 bit thay vì mẫu 8 bit, chưa có vỏ `tt_um_*`, và xung đột `uio[0]` chưa quyết |
| 12 | Nếu sửa `inc_in` xuống 8 bit cho đúng ngân sách chân thì sao? | Phải **nạp hai nhịp** ⟹ sinh ra một **FSM thật** (`LOW/HIGH`). Lỗi giao diện này đổi cả kiến trúc, không chỉ đổi số chân |
| 13 | Số `6,71 ns` cho phép kết luận gì về tần số? | **Không gì cả.** Chưa ký sinh dây, một góc PVT, skew = 0, phụ thuộc `set_input_delay 1.0` giả định |

## 11. Giới hạn: đã chứng minh được gì, chưa chứng minh được gì

**Đã chứng minh:**
- Mô hình chuẩn Python nhất quán với đặc tả trên **5000 ca ngẫu nhiên** (`test_randomized`),
  cộng các ca biên chính xác, tràn, dính và byte cao — PASS 6/6.
- RTL **thoả cả bốn ràng buộc** của Charter mục 10: dùng bit carry, không so sánh sau khi
  cắt, bão hoà dính, biên chính xác.
- RTL tổng hợp được ra 119 standard cell sky130, **18 flip-flop** — khớp Charter mục 10.
- Logic bão hoà tồn tại thật trong netlist: net `_093_`, 15 tải, 14 cell ép.
- Đường tới hạn ở mức sau tổng hợp: `inc_in[1] → acc_q[1]`, 19 cell, 6,71 ns, slack MET;
  phân rã được tới từng đoạn.
- ⭐ Phát hiện cấu trúc: bão hoà **san phẳng đồ thị phụ thuộc** — `acc_q[1]` và
  `acc_out_hi[2]` có arrival bằng nhau.
- Lỗi mô phỏng đã được **định vị và phán xử**: nằm ở **testbench**, không ở thiết kế; và hai
  cảnh báo biên dịch là **giới hạn công cụ vô hại**.

**Chưa chứng minh:**
- Chức năng của RTL — mô phỏng dừng ở chu kỳ C6 (dù phán xử cho thấy DUT đúng).
- Độ phủ Charter mục 8 — **0/4 ca bắt buộc** thật sự được thực hiện đúng. REQ-G04-010
  **CHƯA THOẢ**.
- REQ-G04-020 (Charter mục 9) — **chưa chạy** phiên bản quay vòng, chưa có bảng A/B.
- REQ-G04-002 — **thiếu cổng `xoá`**, `inc_in` sai độ rộng, chưa có vỏ `tt_um_*`.
  **CHƯA THOẢ**.
- Ngữ nghĩa của `sat` (lần cắt / đang ở trần) — **chưa được chốt** với giảng viên.
- Việc Yosys gộp `acc_q[15:8]` vào `acc_out_hi` có bảo toàn hành vi — cần mô phỏng
  gate-level hoặc kiểm tương đương hình thức (ca **G-2**, chưa chạy).
- Netlist tương đương RTL, độ trễ thật sau routing, biên an toàn qua các góc PVT, công suất
  thật của ứng dụng.
- Layout, DRC, LVS, GDSII — chưa chạy flow vật lý.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
