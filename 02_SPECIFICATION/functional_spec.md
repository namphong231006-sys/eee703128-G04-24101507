# G04 · Đặc tả chức năng (Functional Specification)

> ## 🔴 CẢNH BÁO 1 — ĐỐI CHIẾU CHARTER MỤC 4: **CHƯA THOẢ — THIẾU CỔNG BẮT BUỘC**
>
> Charter mục 4 yêu cầu:
> `ui_in[7:0]` = mẫu · **`uio_in[0]` = cộng** · **`uio_in[1]` = xoá** ·
> `uo_out[7:0]` = 8 bit cao của tổng · `uio_out[0]` = cờ bão hoà.
> Ngân sách chân: 10 bit vào + 9 bit ra = 19 trên 24 chân.
>
> RTL thật (`04_IMPLEMENTATION/rtl/g04_sat_accum16.sv`) khai báo:
> `clk`, `rst_n`, `valid_in`, `inc_in[15:0]`, `valid_out`, `acc_out_hi[7:0]`, `sat`.
>
> | Chân Charter mục 4 | Cổng RTL | Trạng thái |
> |---|---|---|
> | `ui_in[7:0]` — mẫu **8 bit** | `inc_in[15:0]` — **16 bit** | 🔴 **SAI ĐỘ RỘNG.** RTL nhận số gia 16 bit; Charter chỉ cấp 8 chân vào |
> | `uio_in[0]` — **cộng** | `valid_in` | ⚠️ khớp chức năng, khác tên |
> | **`uio_in[1]` — xoá** | **KHÔNG CÓ** | 🔴 **THIẾU HẲN CỔNG.** RTL chỉ có `rst_n` |
> | `uo_out[7:0]` — 8 bit cao | `acc_out_hi[7:0]` | ✅ khớp |
> | `uio_out[0]` — cờ bão hoà | `sat` | ⚠️ khớp chức năng |
> | — | `valid_out` | Charter mục 4 **không** liệt kê cổng này |
> | — | `clk`, `rst_n` | Tiny Tapeout cấp từ harness |
>
> **Phán xử — ba vấn đề độc lập:**
> 1. **Thiếu cổng `xoá`.** Charter mục 8 bắt buộc ca *"xoá rồi cộng lại"* — ca này **không
>    thể thực hiện được** với RTL hiện tại. Dùng `rst_n` thay thế **không tương đương**:
>    `rst_n` là reset toàn khối (xoá cả `sat`, `valid_out`, và ở hệ thống thật thường là
>    reset chung của cả chip), còn `xoá` là lệnh **dữ liệu** chỉ đặt `acc_q ← 0`.
> 2. **Sai độ rộng số gia:** 16 bit thay vì 8 bit ⟹ vượt ngân sách chân (`interface.md` §3).
> 3. **Không có vỏ `tt_um_*`** với bộ chân `ui_in / uo_out / uio_*`; và **xung đột `uio[0]`
>    vừa vào vừa ra** mà chính Charter nêu vẫn chưa được đánh số lại.
>
> ⟹ **REQ-G04-002 CHƯA THOẢ** và **REQ-G04-010 CHƯA THOẢ** (thiếu ca bắt buộc).
> **Không tự sửa RTL** — cần giảng viên duyệt. Đề xuất bản vá: `known_issues.md` §6, Vá 4.

> ## ⚠️ CẢNH BÁO 2 — NGỮ NGHĨA CỦA `sat` CHƯA ĐƯỢC CHỐT
>
> RTL cài `sat` là **"phép cộng vừa rồi bị cắt"**, không phải **"bộ tích luỹ đang ở trần"**.
> Hệ quả: khi `acc_q = 0xFFFF` và `inc_in = 0`, mạch cho `sat = 0` dù vẫn đang ở trần.
> Charter mục 4 chỉ ghi *"cờ bão hoà"* — không phân biệt hai nghĩa. Xem §7 B-5 và §9.

---

## 1. Chức năng trong một câu

G04 cộng dồn các số gia 16-bit **không dấu** vào một bộ tích luỹ 16-bit; khi tổng vượt quá
`0xFFFF`, kết quả **dừng ở `0xFFFF`** (bão hoà) thay vì **quay vòng về 0**, và một cờ báo lần
cắt đó. Chỉ **8 bit cao** của bộ tích luỹ được đưa ra ngoài.

## 2. Ký hiệu

| Ký hiệu | Nghĩa |
|---|---|
| `MAX16` | `0xFFFF` = 65535 — giá trị trần |
| `acc(k)` | Giá trị bộ tích luỹ **sau** phép cộng thứ `k` |
| `inc(k)` | Số gia thứ `k` **được chấp nhận** (`valid_in = 1` tại cạnh lên) |
| `total_ext` | Tổng **17 bit** `{1'b0, acc_q} + {1'b0, inc_in}` — bit 16 là **carry-out** |

## 3. Phương trình hành vi

```
  Dieu kien chap nhan: valid_in = 1 tai canh len cua clk va rst_n = 1

  (1) Cong mo rong 17 bit  — PHAT HIEN TRAN TRUOC KHI CAT
        total_ext[16:0] = {1'b0, acc_q[15:0]} + {1'b0, inc_in[15:0]}

  (2) Phat hien cham tran
        sat_next = total_ext[16]                      <- CHINH LA BIT CARRY-OUT

  (3) Bao hoa
        acc_next = total_ext[16] ? 16'hFFFF : total_ext[15:0]

  (4) Cap nhat
        acc_q      <- acc_next
        acc_out_hi <- acc_next[15:8]
        sat        <- sat_next
        valid_out  <- 1
```

**Rút gọn thành đặc tả thuần hành vi:**

```
     acc(k)        = min( acc(k-1) + inc(k) , 65535 )
     sat(k)        = 1  <=>  acc(k-1) + inc(k) > 65535
     acc_out_hi(k) = floor( acc(k) / 256 )  =  acc(k)[15:8]
     valid_out(k)  = 1  cho MOI k >= 1     <- KHONG co pha khoi dong
```

> Khác hẳn G01/G02/G03: G04 **không có thời gian khởi động**. Kết quả hợp lệ ngay từ phép
> cộng **đầu tiên**, vì bộ tích luỹ có giá trị xác định (`0`) ngay sau reset.

## 4. So sánh bão hoà với quay vòng — bảng hành vi

Trả lời Charter mục 2 câu 1: *"Bão hoà khác quay vòng ở chỗ nào?"*

| `acc_q` | `inc_in` | Tổng thật | **Bão hoà** (G04) | **Quay vòng** (mod 2¹⁶) | Sai số |
|---|---|---:|---:|---:|---|
| `0xFF00` | `0x0001` | 65281 | `0xFF01` · `sat=0` | `0xFF01` | giống nhau |
| `0xFF00` | `0x00FF` | **65535** | `0xFFFF` · `sat=0` | `0xFFFF` | giống nhau — **đúng biên, chưa tràn** |
| `0xFFFF` | `0x0001` | 65536 | **`0xFFFF`** · `sat=1` | **`0x0000`** | **65535** |
| `0xFF00` | `0xFFFF` | 130814 | **`0xFFFF`** · `sat=1` | `0xFEFF` | 253 |
| `0xFFFF` | `0x0000` | 65535 | `0xFFFF` · **`sat=0`** ⚠️ | `0xFFFF` | giống nhau |

### Vì sao quay vòng **nguy hiểm** với một công tơ điện

Bối cảnh Charter mục 1: *"cộng dồn năng lượng tiêu thụ trong công tơ điện tử"*.

| | Bão hoà | Quay vòng |
|---|---|---|
| Khi chạm trần, số đọc | **Đứng ở 65535** | **Về 0** |
| Người đọc hiểu là | "Thiết bị đã hết thang đo" — sai nhưng **theo hướng an toàn**, và **nhìn ra được** | "Khách hàng chưa dùng điện" — **sai hoàn toàn và không nhìn ra được** |
| Sai số | Đơn điệu, **luôn thiếu**, bị chặn | **Nhảy bậc 65535**, dấu đổi |
| Tính đơn điệu của phép đo | ✅ **giữ được**: `acc` không bao giờ giảm | ❌ **mất**: `acc` có thể giảm đột ngột |
| Phát hiện được không? | ✅ có cờ `sat` | ❌ không có dấu hiệu nào |
| Hậu quả thương mại | Ghi thiếu tiền điện | **Ghi sai hẳn, có thể gian lận** |

> 💡 **Tính chất quyết định là ĐƠN ĐIỆU.** Một công tơ là bộ đếm tích luỹ — nó **phải** đơn
> điệu không giảm. Quay vòng phá vỡ tính chất đó, và mọi phần mềm đọc công tơ (tính hiệu số
> giữa hai lần đọc) sẽ cho kết quả **âm** hoặc **sai khổng lồ**. Bão hoà giữ được đơn điệu,
> nên sai số vẫn **kiểm soát được**.

## 5. Độ trễ và giao thức

| Đại lượng | Giá trị | Bằng chứng |
|---|---|---|
| Trạng thái sau reset | `acc_q=0x0000`, `acc_out_hi=0x00`, `sat=0`, `valid_out=0` | RTL dòng 24–28 |
| Kiểu reset | **Đồng bộ**, tích cực thấp | `always_ff @(posedge clk) if (!rst_n)`; netlist dùng **18 × `dfxtp_1`** (không có chân reset) |
| Độ trễ vào → ra | **1 chu kỳ clock** | `acc_out_hi`, `sat`, `valid_out` đều là đầu ra flip-flop |
| Thời gian khởi động | **0 mẫu** | Không có `count_q` |
| Thông lượng | 1 số gia / 1 chu kỳ | Không có trạng thái chờ |
| Back-pressure | **không có** | Không có `ready` |
| Lệnh **xoá** | 🔴 **KHÔNG CÓ** | Xem Cảnh báo 1 |

## 6. Tính chất bất biến (Invariants)

| ID | Phát biểu | Kiểm bằng |
|---|---|---|
| **INV-1** | `valid_out` chỉ lên 1 nếu `valid_in` bằng 1 tại cạnh trước đó. | TB dòng 50–52 (ca gap) |
| **INV-2** | ⭐ **Đơn điệu không giảm:** `acc(k) >= acc(k−1)` với mọi `k`, giữa hai lần reset. | Vì `inc_in` không dấu và `min(x, MAX)` đơn điệu. Đây là tính chất **quan trọng nhất** của một công tơ |
| **INV-3** | **Bị chặn:** `0 <= acc(k) <= 65535`. Không bao giờ tràn ra ngoài 16 bit. | Cấu trúc: `acc_next` là `16'hFFFF` hoặc `total_ext[15:0]` |
| **INV-4** | **Đúng đắn:** `acc(k) = min(acc(k−1) + inc(k), 65535)`. | `reference_model.test_randomized` — **5000 ca ngẫu nhiên PASS** |
| **INV-5** | **Dính (sticky) có điều kiện:** nếu `acc_q = 0xFFFF` và `inc_in >= 1` thì `acc` giữ `0xFFFF` và `sat = 1`. | `properties.sv` `assert_no_wrap_after_saturation`; `test_sticky_saturation` |
| **INV-6** | ⚠️ `sat` báo **phép cộng vừa rồi bị cắt**, **KHÔNG** báo "đang ở trần". `acc_q = 0xFFFF`, `inc_in = 0` ⟹ `sat = 0`. | `test_exact_boundary`: `update(65535, 0) = (65535, False)` |
| **INV-7** | **Biên chính xác:** `acc + inc = 65535` **không** kích hoạt bão hoà. | `test_exact_boundary`: `update(65534, 1) = (65535, False)` |
| **INV-8** | Khi `valid_in = 0`: `acc_q`, `acc_out_hi`, `sat` **không đổi**; chỉ `valid_out` về 0. | RTL dòng 30–37 |
| **INV-9** | `acc_out_hi = acc_q[15:8]` **luôn luôn** — hai thanh ghi này không bao giờ lệch nhau. | Cùng nhận `acc_next` tại cùng cạnh, cùng enable. Netlist **xác nhận mạnh hơn**: Yosys đã **gộp** `acc_q[15:8]` vào `acc_out_hi` ⟹ chúng là **cùng một** flip-flop vật lý |
| **INV-10** | **Mất thông tin ở đầu ra:** `acc_out_hi` không phân biệt được 256 giá trị `acc` liên tiếp. | `test_upper_byte`: `0x1200` và `0x12FF` cho cùng `0x12` |
| **INV-11** | Phát hiện tràn dùng **bit carry**, không dùng phép so sánh sau khi đã cắt. | RTL dòng 16, 19: `total_ext` rộng 17 bit; `sat_next = total_ext[16]` |

## 7. Điều kiện biên và hành vi không xác định

| # | Tình huống | Hành vi | Ghi chú |
|---|---|---|---|
| B-1 | `rst_n = 0` nhưng không có cạnh lên | **Reset không xảy ra** | Reset đồng bộ |
| B-2 | Nhả `rst_n` đúng tại cạnh lên | **Không xác định** (race) | TB G04 có 2 cạnh reset (t=5, 15) ⟹ **vô hại** |
| B-3 | `acc + inc = 65535` (đúng biên) | `acc = 0xFFFF`, **`sat = 0`** | INV-7. Đây là ca dễ hiểu nhầm nhất |
| B-4 | `acc = 0xFFFF`, `inc >= 1` | `acc = 0xFFFF`, `sat = 1` | INV-5 |
| B-5 | `acc = 0xFFFF`, `inc = 0` | `acc = 0xFFFF`, **`sat = 0`** | ⚠️ INV-6 — ngữ nghĩa chưa chốt (Cảnh báo 2) |
| B-6 | `acc = 0`, `inc = 0xFFFF` | `acc = 0xFFFF`, `sat = 0` | Một bước tới trần, chưa tràn |
| B-7 | `inc = 0` liên tục | `acc` không đổi, `valid_out = 1` mỗi chu kỳ | Charter mục 8 yêu cầu ca này — **THIẾU trong TB** |
| B-8 | **Xoá rồi cộng lại** | 🔴 **KHÔNG THỰC HIỆN ĐƯỢC** | Thiếu cổng `xoá` — Cảnh báo 1 |
| B-9 | Đọc `acc_out_hi` khi `valid_out = 0` | Giá trị **vẫn đúng** (giữ nguyên) nhưng chưa cập nhật | Khác G02/G03: `acc_out_hi` luôn phản ánh trạng thái hiện tại |
| B-10 | Muốn biết `acc` có đang ở trần không | ❌ **Không thể** từ bên ngoài | `acc_out_hi = 0xFF` ứng với **256** giá trị `acc` khác nhau (`0xFF00`…`0xFFFF`). Cần `sat` **và** phải hiểu đúng ngữ nghĩa của nó (INV-6) |
| B-11 | `inc_in` có dấu | ⬛ **Ngoài phạm vi** | Charter mục 3: "Tích luỹ có dấu" nằm ngoài phạm vi |

## 8. Ràng buộc cấu trúc bắt buộc

Charter mục 10 — *chỗ hay tắc*: *"Phát hiện bão hoà **SAU** khi đã cộng tràn — phải phát hiện
**TRƯỚC** hoặc dùng **bit carry**."*

| Ràng buộc | Nội dung | RTL có thoả? |
|---|---|:-:|
| **C-1** | Phải phát hiện tràn bằng **bit carry của phép cộng mở rộng**, không phải bằng so sánh sau khi kết quả đã bị cắt về 16 bit | ✅ dòng 16, 19 — `total_ext` rộng **17** bit |
| **C-2** | Không được viết `if (acc_q + inc_in > 16'hFFFF)` — biểu thức này **luôn sai** vì phép so sánh diễn ra trên 16 bit đã tràn | ✅ RTL không làm vậy |
| **C-3** | Bão hoà phải **dính**: đã ở trần thì không quay về | ✅ INV-5 |
| **C-4** | Bộ tích luỹ đúng **16 bit**, đầu ra đúng **8 bit cao** | ✅ `acc_q[15:0]`, `acc_next[15:8]` |
| **C-5** | Không tích luỹ có dấu, không nhiều kênh, không chia trung bình | ✅ Charter mục 3: ngoài phạm vi |

### Vì sao C-2 là bẫy thật, không phải lo xa

```systemverilog
    // SAI — cach viet nay KHONG BAO GIO phat hien duoc tran:
    logic [15:0] total_bad;
    assign total_bad = acc_q + inc_in;          // da bi cat ve 16 bit o day
    assign sat_bad   = (total_bad > 16'hFFFF);  // LUON = 0, vi 16 bit khong the > 0xFFFF
```

Với `acc_q = 0xFFFF`, `inc_in = 1`: `total_bad = 0x0000`, `sat_bad = 0`, và bộ tích luỹ
**quay vòng về 0** — đúng hành vi mà đề này tồn tại để ngăn chặn. Trình tổng hợp **không
cảnh báo gì cả**, vì về mặt cú pháp đây là mã hợp lệ.

## 9. Chênh lệch đã phát hiện giữa đặc tả và mã nguồn

| # | Vấn đề | Nơi | Mức |
|---|---|---|---|
| 1 | **Thiếu cổng `xoá`** mà Charter mục 4 yêu cầu | RTL | 🔴 **CHƯA THOẢ** |
| 2 | `inc_in` 16 bit thay vì mẫu 8 bit | RTL | 🔴 **CHƯA THOẢ** — vượt ngân sách chân |
| 3 | Không có vỏ `tt_um_*`; xung đột `uio[0]` chưa quyết | RTL / Charter | ⚠️ chờ giảng viên |
| 4 | Ngữ nghĩa `sat` (lần cắt / đang ở trần) chưa chốt | Charter mục 4 mơ hồ | ⚠️ cần quyết |
| 5 | Mô phỏng RTL dừng tại một assertion | `simulation.log` | 🔴 phán xử: **lỗi ở TESTBENCH** — `known_issues.md` |
| 6 | Icarus cảnh báo `sorry: constant selects…` ×2 | `iverilog_compile.log` | ℹ️ **giới hạn công cụ, vô hại** — `known_issues.md` §5 |
| 7 | RTL và mô hình chuẩn Python **thống nhất hoàn toàn** | `reference_model.py` PASS 6/6 | ✅ không lệch |
| 8 | `valid_out` không nằm trong danh mục chân của Charter mục 4 | RTL | ℹ️ cổng thừa, vô hại về chức năng nhưng tính vào ngân sách chân |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
