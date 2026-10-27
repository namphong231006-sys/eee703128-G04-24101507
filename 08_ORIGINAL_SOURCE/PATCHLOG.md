# G04 · Nhật ký vá (PATCHLOG)

**Ngày vá:** 2026-09-24 · **Người duyệt:** giảng viên đã duyệt áp dụng toàn bộ bản vá

Tham chiếu chẩn đoán: `05_VERIFICATION/known_issues.md` (giữ nguyên, không sửa phần phán xử).

## 1. Tóm tắt

| # | File | Loại lỗi | Mô tả một dòng | Ảnh hưởng số liệu |
|---|---|---|---|---|
| P-1 | `05_VERIFICATION/testbench/g04_tb.sv` | Lỗi testbench | Vector kỳ vọng `sat=1` ở phép cộng `0xFF00 + 0x0001` vốn **không hề tràn**; chèn một lệnh `send` đưa bộ tích luỹ tới đúng trần trước khi vượt trần | **Không** — chỉ đụng testbench |
| P-2 | `05_VERIFICATION/testbench/g04_tb.sv` | Độ chắc chắn kiểm chứng | Thêm tham số `exp_acc` và assertion white-box `dut.acc_q == exp_acc` để chặn tái diễn kiểu lỗi "nhìn 8 bit cao, suy ra 16 bit" | **Không** |
| P-3 | `05_VERIFICATION/testbench/g04_tb.sv` | Thiếu độ phủ | Thêm ca CC-4 (L-Z): cộng `0` khi đang ở trần ⟹ `sat` phải về `0` | **Không** |

Không có dòng RTL nào bị sửa. `04_IMPLEMENTATION/rtl/g04_sat_accum16.sv` **giữ nguyên bản gốc**,
đúng như phán xử §4 của `known_issues.md`: DUT đúng.

## 2. Chi tiết từng bản vá

### P-1 — sửa vector sai và bổ sung ca biên chính xác

**File:** `05_VERIFICATION/testbench/g04_tb.sv` · **Dòng:** 41–47 (bản gốc) ·
**Phán xử:** lỗi ở **testbench**

**Trước:**
```systemverilog
        send(16'h0001,8'h00,0);
        send(16'h00FF,8'h01,0);
        send(16'hFE00,8'hFF,0);
        send(16'h0001,8'hFF,1);

        // Once saturated, further positive increments remain saturated.
        send(16'h0001,8'hFF,1);
```

**Sau:**
```systemverilog
        send(16'h0001,8'h00,0,16'h0001);
        send(16'h00FF,8'h01,0,16'h0100);
        send(16'hFE00,8'hFF,0,16'hFF00);
        // CC-1 (L-E): 0xFF00 + 0x00FF = 0xFFFF -> DUNG BANG tran, CHUA tran => sat = 0
        send(16'h00FF,8'hFF,0,16'hFFFF);
        // CC-2 (L-O): 0xFFFF + 0x0001 = 0x10000 -> VUOT tran => bao hoa, sat = 1
        send(16'h0001,8'hFF,1,16'hFFFF);

        // Once saturated, further positive increments remain saturated.
        send(16'h0001,8'hFF,1,16'hFFFF);
```

**Vì sao:** sau ba lệnh `send` đầu, `acc_q = 0xFF00`, **không phải** `0xFFFF`. Cộng thêm `1`
cho `0xFF01 = 65281 < 65535` ⟹ không tràn ⟹ `sat = 0`. Testbench kỳ vọng `1` vì người viết
nhìn `acc_out_hi = 0xFF` (8 bit cao) rồi suy ra bộ tích luỹ đã đầy. Lệnh `send(16'h00FF, …)`
được chèn thêm đưa `acc_q` tới **đúng** `0xFFFF` (ca biên `>` so với `>=`), sau đó lệnh `+1`
mới thật sự tràn.

**Hệ quả:** hồ sơ có thêm hai ca bắt buộc của Charter mục 8 (CC-1 biên chính xác, CC-2 vượt
trần) mà trước đây **chưa hề được kiểm ở mức Verilog**.

### P-2 — kiểm white-box `acc_q` (phòng tái diễn)

**File:** `05_VERIFICATION/testbench/g04_tb.sv` · **Dòng:** 16–34 · **Phán xử:** củng cố
testbench, không phải sửa lỗi DUT

**Trước:**
```systemverilog
    task automatic send(
        input logic [15:0] inc,
        input logic [7:0] exp_hi,
        input logic exp_sat
    );
        …
            assert(sat==exp_sat)
                else $fatal(1,"sat mismatch got=%b expected=%b",sat,exp_sat);
            valid_in=1'b0;
```

**Sau:**
```systemverilog
    task automatic send(
        input logic [15:0] inc,
        input logic [7:0] exp_hi,
        input logic exp_sat,
        input logic [15:0] exp_acc   // gia tri DAY DU 16 bit cua bo tich luy
    );
        …
            assert(sat==exp_sat)
                else $fatal(1,"sat mismatch got=%b expected=%b",sat,exp_sat);
            assert(dut.acc_q==exp_acc)
                else $fatal(1,"acc_q mismatch got=%h expected=%h",
                            dut.acc_q,exp_acc);
            valid_in=1'b0;
```

**Vì sao:** gốc rễ của P-1 là **giao diện quan sát hẹp hơn trạng thái trong** — một giá trị
`acc_out_hi` ứng với 256 giá trị `acc_q`. Với assertion này, lỗi kiểu đó lộ ra **đúng chỗ**
(ngay lệnh `send` nào làm sai trạng thái) thay vì đổ oan cho `sat` ở lệnh kế tiếp.

**Hệ quả:** đổi chữ ký task `send` ⟹ mọi lệnh gọi phải thêm tham số thứ tư. Không đổi giao
diện module, không ảnh hưởng tổng hợp. Đây là tham chiếu phân cấp (`dut.acc_q`) nên chỉ dùng
được ở mô phỏng RTL, không dùng lại được cho mô phỏng gate-level.

### P-3 — bổ sung ca CC-4 (cộng 0 khi đang ở trần)

**File:** `05_VERIFICATION/testbench/g04_tb.sv` · **Phán xử:** thiếu độ phủ so với Charter mục 8

**Sau:**
```systemverilog
        // CC-4 (L-Z): cong 0 khi DANG o tran -> khong tran nua => sat ve 0
        send(16'h0000,8'hFF,0,16'hFFFF);
```

**Vì sao:** `0xFFFF + 0x0000 = 0x0FFFF`, bit 16 = 0 ⟹ `sat_next = 0`. Ca này chốt ngữ nghĩa
*"`sat` là cờ của **lần cộng này**, không phải cờ dính của trạng thái"* — một điểm dễ hiểu sai
và trước đây chưa ca nào kiểm. Kết quả: DUT hành xử đúng như kỳ vọng.

**Hệ quả:** không.

## 3. Kết quả xác minh sau khi vá

| Bước | Trước khi vá | Sau khi vá |
|---|---|---|
| Mô hình chuẩn Python | `G04 golden reference PASS`, mã thoát 0 | `G04 golden reference PASS`, mã thoát 0 (**không sửa file này**) |
| Biên dịch (iverilog 12.0) | Thành công, kèm 2 cảnh báo `sorry: constant selects…` | Thành công, **vẫn 2 cảnh báo đó** (vô hại — xem `known_issues.md` §5; cố ý **không** áp Vá 3) |
| Mô phỏng | ❌ `FATAL: g04_tb.sv:31: sat mismatch got=0 expected=1`, `Time: 56` | ✅ `G04 TB completed`, `$finish` tại `t = 96 ns` — **không** `ERROR`/`FATAL`/`mismatch` |
| Tổng hợp (yosys + sky130hd) | 119 cell / 18 FF / 1083,5392 µm² | **119 cell / 18 FF / 1083,5392 µm²** — *không đổi*, đúng như dự kiến vì RTL không bị sửa |

FF là `sky130_fd_sc_hd__dfxtp_1` × 18. Số wire: 116.

Lệnh đã chạy để xác minh:

```bash
D=.../out/G04_Bo_tich_luy_co_bao_hoa_16bit
T=$(mktemp -d)
LIB=.../sky130hd.lib

python3 $D/05_VERIFICATION/golden_model/reference_model.py

iverilog -g2012 -o $T/sim.vvp \
   $D/04_IMPLEMENTATION/rtl/*.sv \
   $D/05_VERIFICATION/testbench/*.sv
cd $T && vvp sim.vvp | tail -20

yosys -Q -p "read_verilog -sv $D/04_IMPLEMENTATION/rtl/*.sv; \
   hierarchy -check -top g04_sat_accum16; proc; opt; fsm; opt; memory; opt; techmap; opt; \
   dfflibmap -liberty $LIB; abc -liberty $LIB; setundef -zero; splitnets; opt_clean -purge; \
   stat -liberty $LIB"
```

(Ghi chú: G04 **không** có `05_VERIFICATION/golden_model/*.sv`, chỉ có mô hình chuẩn Python,
nên dòng `golden_model/*.sv` trong mẫu lệnh của SPEC bị bỏ trống.)

## 4. Cách quay lui

```bash
cp 08_ORIGINAL_SOURCE/rtl/*            04_IMPLEMENTATION/rtl/
cp 08_ORIGINAL_SOURCE/golden_model/*   05_VERIFICATION/golden_model/
cp 08_ORIGINAL_SOURCE/testbench/*      05_VERIFICATION/testbench/
```

## 5. Việc còn lại

Ba bản vá còn lại trong `known_issues.md` §6 **cố ý không áp dụng**, lý do ghi rõ ở đây:

| Bản vá trong `known_issues.md` | Trạng thái | Lý do |
|---|---|---|
| **Vá 3** — đổi `always_comb` thành `assign` để hết cảnh báo Icarus | ❌ **Không áp dụng** | Chính `known_issues.md` §6 kết luận *"cảnh báo là vô hại, **không nên** áp dụng chỉ để log sạch"*. Vá này đụng RTL ⟹ kéo theo chạy lại toàn bộ tầng 06. Sửa mã đang đúng để dọn một dòng log không phải là sửa lỗi |
| **Vá 4** — thêm cổng `clr_in` (Charter mục 4) | ⏸ **Hoãn — cần thầy chốt đặc tả** | `known_issues.md` §6 ghi rõ *"hai quyết định đặc tả cần thầy chốt **trước khi áp**"*: (1) `clr_in` có thắng `valid_in` không; (2) xoá có xoá luôn cờ `sat` không. Vá này còn **đổi giao diện module**, mà SPEC §4.2 yêu cầu tránh trừ khi bản vá đòi hỏi. Hệ quả: **REQ-G04-010 ca CC-3 ("xoá rồi cộng lại") vẫn CHƯA THOẢ** |
| **Vá 6** — `$dumpfile`/`$dumpvars` sinh waveform | ❌ **Không áp dụng** | Sẽ ghi một file `.vcd` vào thư mục chạy mỗi lần mô phỏng. Nếu thầy muốn artifact waveform theo Charter mục 3, nên bật bằng cờ `+define+DUMP` ở script chạy — mà `04_IMPLEMENTATION/scripts/` nằm ngoài ranh giới được sửa của lần vá này (SPEC §0) |

Trạng thái độ phủ Charter mục 8 sau khi vá: **3/4 ca** (CC-1 ✅, CC-2 ✅, CC-4 ✅, CC-3 ❌ —
bất khả thi tới khi có Vá 4).

## 6. Áp dụng lại (2026-09-24)

**Vì sao phải làm lại:** một bước sinh tài liệu tự động (`generate2.py`) đã chép mã nguồn cũ từ
`runs/<mã>/work/` **đè lên** `04_IMPLEMENTATION/rtl/`, `05_VERIFICATION/golden_model/` và
`05_VERIFICATION/testbench/`, xoá mất cả ba bản vá P-1, P-2, P-3. Lỗi của bộ sinh đã được sửa.
Trước khi áp dụng lại, ba thư mục này đã được đối chiếu với `08_ORIGINAL_SOURCE/` và **trùng
khít** — xác nhận chúng đã quay về đúng trạng thái chưa vá.

**Đã áp dụng lại:** **3/3** bản vá, tất cả trong `05_VERIFICATION/testbench/g04_tb.sv`, đúng
nguyên văn các khối "Sau" ở §2:

- **P-1** — chèn `send(16'h00FF,8'hFF,0,16'hFFFF)` (CC-1, đúng bằng trần) trước lệnh `+1` gây
  tràn, và sửa vector kỳ vọng `sat` cho đúng.
- **P-2** — thêm tham số thứ tư `exp_acc` vào task `send` và assertion white-box
  `dut.acc_q == exp_acc`; **mọi** lời gọi `send` đã được cập nhật đủ bốn tham số.
- **P-3** — thêm ca CC-4 (L-Z): `send(16'h0000,8'hFF,0,16'hFFFF)`.

RTL **không bị chạm**, đúng như §1. Không phát hiện chênh lệch nào giữa mô tả trong PATCHLOG và
bản vá thực tế.

**Kết quả xác minh lần này** (chạy bằng đúng lệnh ở §3):

| Bước | Kết quả đo lần này | Khớp §3? |
|---|---|---|
| Mô hình chuẩn Python | `G04 golden reference PASS`, mã thoát 0 | ✅ |
| Biên dịch iverilog 12.0 | thành công, mã thoát 0, **vẫn đúng 2 cảnh báo** `sorry: constant selects…` ở `g04_sat_accum16.sv:18` (vô hại, cố ý không áp Vá 3) | ✅ |
| Mô phỏng | `G04 TB completed`, `$finish` tại `t = 96`, mã thoát 0, không `ERROR`/`FATAL`/`mismatch` | ✅ |
| Tổng hợp yosys 0.33 + sky130hd | **119 cell / 18 FF (`dfxtp_1`) / 1 083,5392 µm²**, 116 wire | ✅ khớp chính xác |

Số cell, số flip-flop, diện tích và số wire **trùng khớp tuyệt đối** với §3. Mục §5 (Vá 3, Vá 4,
Vá 6 cố ý không áp dụng; REQ-G04-010 ca CC-3 vẫn chưa thoả) giữ nguyên — lần áp dụng lại này
không thêm bản vá nào ngoài P-1…P-3.
