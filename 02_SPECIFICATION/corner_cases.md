# G04 · Ca biên và ca góc (Corner Cases)

> Mỗi ca phải trả lời được: *"ca này bắt được lỗi gì mà ca khác không bắt được?"*

Nguồn đối chiếu: testbench thật `05_VERIFICATION/testbench/g04_tb.sv` (57 dòng) và
mô hình chuẩn `05_VERIFICATION/golden_model/reference_model.py`.

---

## 1. Tiêu chí phân loại riêng của G04

Toàn bộ độ khó của G04 tập trung vào **một điểm duy nhất trên trục số**: ranh giới `65535`.
Vì vậy cách phân loại có ý nghĩa là **theo khoảng cách tới ranh giới đó**:

| Lớp | Vị trí so với trần | Loại lỗi bắt được |
|---|---|---|
| **L-F** (Far) | `acc + inc ≪ 65535` | Phép cộng cơ bản sai, nối nhầm bit |
| **L-E** (Exact) | `acc + inc = 65535` **đúng bằng** | ⭐ Lỗi `>` vs `>=` trong điều kiện bão hoà |
| **L-O** (Over) | `acc + inc > 65535` | Phát hiện tràn sai (C-2), quay vòng thay vì bão hoà |
| **L-S** (Sticky) | Đã ở trần rồi cộng tiếp | Bão hoà không dính |
| **L-Z** (Zero) | `inc = 0` | Cập nhật vô cớ, `sat` bật nhầm |
| **L-V** (Visibility) | Khác nhau **chỉ ở byte thấp** | ⭐ Lỗi do chỉ quan sát được 8 bit cao |
| **L-G** (Gating) | `valid_in = 0` | Tích luỹ tự chạy |
| **L-C** (Clear) | Xoá rồi cộng lại | 🔴 **Không thực hiện được — thiếu cổng** |

> Lớp **L-V** là lớp đặc thù của G04 mà các đề khác không có: bộ tích luỹ rộng **16 bit**
> nhưng chỉ **8 bit cao** ra ngoài ⟹ có **256 trạng thái trong không phân biệt được từ
> ngoài**. Chính lớp này sinh ra lỗi testbench đang làm mô phỏng dừng (§5).

---

## 2. Ca bắt buộc của Charter mục 8

Charter mục 8: *"Cộng tới sát giới hạn · cộng vượt giới hạn (phải bão hoà) · xoá rồi cộng lại
· cộng giá trị 0"*.

| ID | Ca Charter | Lớp | Vì sao ca này tồn tại — lý do kỹ thuật | Đã có trong TB? |
|---|---|:-:|---|---|
| **CC-1** | **Cộng tới sát giới hạn** | L-E | ⭐ Ca phân biệt `>` với `>=`. `acc + inc = 65535` **đúng bằng trần** ⟹ **chưa** tràn, `sat` phải bằng **0**. Nếu ai viết `sat = (total >= 16'hFFFF)` thì ca này lộ ngay | 🔴 **TB VIẾT SAI CA NÀY** — xem §5 |
| **CC-2** | **Cộng vượt giới hạn** | L-O | Ca cốt lõi. Nó **đồng thời** kiểm hai thứ: kết quả phải là `0xFFFF` (không quay vòng) **và** `sat` phải bằng 1 | ⚠️ có nhưng **vector sai** — §5 |
| **CC-3** | **Xoá rồi cộng lại** | L-C | Chứng minh `acc` về 0 sạch và bão hoà **không dính qua lệnh xoá** | 🔴 **KHÔNG THỂ CÓ** — RTL thiếu cổng `xoá` |
| **CC-4** | **Cộng giá trị 0** | L-Z | Hai khẳng định: `acc` **không đổi**, và `valid_out` **vẫn** lên 1 (vì `valid_in = 1`). Bắt lỗi nhầm `valid_in` với `inc_in != 0`. Đặc biệt quan trọng ở trần: `acc = 0xFFFF`, `inc = 0` ⟹ `sat` phải về **0** (INV-6) | ❌ **THIẾU** trong TB |

---

## 3. Ca tự xây dựng bổ sung (REQ-G04-011 yêu cầu ≥ 2, có ca biên)

| ID | Ca | Lớp | Lý do kỹ thuật | Trạng thái |
|---|---|:-:|---|---|
| **CC-5** | **Bão hoà dính**: đã ở trần rồi cộng tiếp `1` | L-S | Bắt lỗi bão hoà "một lần rồi thôi". `properties.sv` có assertion tương ứng (`assert_no_wrap_after_saturation`) nhưng đang bị `ifdef` tắt | ✅ TB dòng 47 |
| **CC-6** | **Khoảng nghỉ của `valid_in`** với `inc_in = 0xFFFF` | L-G | ⭐ Ca **thiết kế rất tốt**: đặt `inc_in` ở giá trị **cực đại** trong lúc `valid_in = 0`. Nếu quên gating, `acc` sẽ nhảy vọt và `sat` bật — sai lệch **cực lớn**, không thể bỏ sót | ✅ TB dòng 50–52 |
| **CC-7** | **Ca biên tuyệt đối**: `acc = 0` + `inc = 0xFFFF` | L-E | Một bước duy nhất tới **đúng trần**, `sat = 0`. Ca "xa nhất tới biên trong một nhịp" | ⚠️ chỉ ở Python (`test_no_overflow` gián tiếp) |
| **CC-8** | ⭐ **Ca phân biệt `0xFF00` với `0xFFFF`** | L-V | **Ca quan trọng nhất mà hồ sơ đang thiếu.** Cả hai đều cho `acc_out_hi = 0xFF`. Chỉ có `sat` (ở nhịp cộng tiếp theo) mới phân biệt được. Đây chính là ca mà **người viết testbench đã hiểu sai** | 🔴 **THIẾU, và sự thiếu vắng của nó đã gây ra lỗi** |
| **CC-9** | **5000 ca ngẫu nhiên** đối chiếu `min(acc+inc, MAX)` | L-F+L-O | Phủ vét cạn thống kê toàn bộ không gian | ✅ chỉ ở Python (`test_randomized`, **PASS**) |
| **CC-10** | **Chuỗi dài `inc` nhỏ** tới khi chạm trần | L-O | Kiểm tính **đơn điệu** (INV-2) trên nhiều nhịp — tính chất sống còn của một công tơ | ❌ **THIẾU** ở cả hai |

---

## 4. Đối chiếu độ phủ: testbench thật đã có gì, thiếu gì

Đọc từ `g04_tb.sv` dòng 36–56:

```
 dong 41   send(16'h0001, 8'h00, 0);   acc: 0x0000 -> 0x0001   hi=00  sat=0   ✅ L-F
 dong 42   send(16'h00FF, 8'h01, 0);   acc: 0x0001 -> 0x0100   hi=01  sat=0   ✅ L-F
 dong 43   send(16'hFE00, 8'hFF, 0);   acc: 0x0100 -> 0xFF00   hi=FF  sat=0   ✅ L-F
 dong 44   send(16'h0001, 8'hFF, 1);   acc: 0xFF00 -> 0xFF01   hi=FF  sat=0   🔴 TB ky vong sat=1
 dong 47   send(16'h0001, 8'hFF, 1);   (chua chay toi)                        L-S
 dong 50-52 valid_in=0; inc_in=0xFFFF; assert(!valid_out)                     L-G
```

| Lớp | Ca | TB Verilog | Python | Ghi chú |
|---|---|:-:|:-:|---|
| L-F | CC-9 | ✅ 3 vector | ✅ 5000 ca | |
| **L-E** | CC-1, CC-7 | 🔴 **0/2 — và TB tưởng là có** | ✅ `test_exact_boundary` | ⭐ Lỗ hổng gốc rễ |
| **L-O** | CC-2 | 🔴 **0/1** (vector sai) | ✅ `test_overflow` | |
| L-S | CC-5 | ⚠️ có nhưng chưa chạy tới | ✅ `test_sticky_saturation` | |
| **L-Z** | CC-4 | ❌ **THIẾU** | ⚠️ gián tiếp | Charter mục 8 **bắt buộc** |
| **L-V** | CC-8 | ❌ **THIẾU** | ⚠️ `test_upper_byte` | ⭐ Nguyên nhân của lỗi |
| L-G | CC-6 | ✅ | ❌ | Python không có `valid_in` |
| **L-C** | CC-3 | 🔴 **KHÔNG THỂ** | ❌ | RTL thiếu cổng `xoá` |

> 🔎 **Kết luận độ phủ:** testbench G04 **không một lần nào** đưa `acc_q` tới đúng `0xFFFF`.
> Nó đi từ `0xFF00` rồi cộng `1` — và **tưởng** rằng như vậy là đã chạm trần. Toàn bộ lớp
> **L-E** (biên chính xác) và **L-O** (vượt biên) vì vậy **chưa hề được kiểm ở mức Verilog**.
> Hai trong bốn ca bắt buộc của Charter mục 8 (**CC-1**, **CC-2**) **chưa thật sự tồn tại**,
> một ca (**CC-4**) thiếu hẳn, và một ca (**CC-3**) **không thể thực hiện** vì RTL thiếu cổng.
> ⟹ **REQ-G04-010 CHƯA THOẢ** — 0/4 ca bắt buộc thật sự được thực hiện đúng.

### Ca đề nghị bổ sung để bịt toàn bộ lỗ hổng (chưa áp dụng)

```systemverilog
    //  CC-1 (L-E): di tung buoc toi DUNG tran, sat van phai = 0
    send(16'h0001,8'h00,0);   // acc = 0x0001
    send(16'h00FF,8'h01,0);   // acc = 0x0100
    send(16'hFE00,8'hFF,0);   // acc = 0xFF00
    send(16'h00FF,8'hFF,0);   // acc = 0xFFFF  <-- DUNG TRAN, chua tran => sat = 0

    //  CC-2 (L-O): buoc tiep theo moi that su tran
    send(16'h0001,8'hFF,1);   // 0xFFFF + 1 -> bao hoa, sat = 1

    //  CC-5 (L-S): dinh
    send(16'hFFFF,8'hFF,1);   // van 0xFFFF, sat = 1

    //  CC-4 (L-Z): cong 0 khi DANG o tran -> sat phai ve 0  (INV-6)
    send(16'h0000,8'hFF,0);   // acc khong doi, sat = 0

    //  CC-8 (L-V): phan biet 0xFF00 voi 0xFFFF — chi kiem duoc bang WHITE-BOX
    //  vi acc_out_hi cho ca hai deu la 0xFF.
    assert(dut.acc_q == 16'hFFFF)
        else $fatal(1,"acc_q = %h, khong phai FFFF", dut.acc_q);
```

> Dòng cuối là **điểm mấu chốt**: với giao diện chỉ 8 bit cao, testbench **bắt buộc** phải
> hoặc (a) dò `dut.acc_q` theo kiểu white-box, hoặc (b) thiết kế vector sao cho byte thấp
> luôn suy ra được từ lịch sử. Người viết testbench hiện tại đã chọn (b) nhưng **tính nhầm**.

---

## 5. Ca có trong TB nhưng **viết sai** — CC-1 và CC-2

```systemverilog
43        send(16'hFE00,8'hFF,0);    // acc = 0x0100 + 0xFE00 = 0xFF00,  hi = FF  ✅
44        send(16'h0001,8'hFF,1);    // acc = 0xFF00 + 0x0001 = 0xFF01
          //                            hi = FF ✅  nhung  sat = 0, TB ky vong 1  🔴
```

`simulation.log`: `FATAL: g04_tb.sv:31: sat mismatch got=0 expected=1 · Time: 56`

**Nguồn gốc sai lầm:** sau dòng 43, `acc_out_hi = 0xFF`. Người viết testbench đọc `0xFF` ở
đầu ra và kết luận *"bộ tích luỹ đã đầy"* — nhưng `acc_out_hi = 0xFF` chỉ nói `acc_q` nằm
trong khoảng `0xFF00`…`0xFFFF`, tức **còn 255 đơn vị nữa mới tới trần**.

Đây chính là lớp **L-V** đang thiếu: **lỗi sinh ra từ việc nhầm 8 bit quan sát được với 16
bit thật sự tồn tại.** Phán xử đầy đủ và bản vá: `05_VERIFICATION/known_issues.md`.

> 💡 Bài học ca góc: **một ca kiểm thử sai còn nguy hiểm hơn một ca kiểm thử thiếu.** Ở đây
> nó vừa báo động giả (DUT bị kiện oan) vừa **che mất** việc lớp L-E/L-O thật sự chưa được
> kiểm lần nào.

---

## 6. Ca **KHÔNG** áp dụng cho G04 — và vì sao

| Ca | Vì sao không áp dụng |
|---|---|
| **Tràn có dấu / cờ overflow hai chiều** | Giao diện **không dấu**. Charter mục 3: "Tích luỹ có dấu" nằm **ngoài phạm vi**. Không có khái niệm bão hoà xuống `0x0000` |
| **Nhiều kênh tích luỹ** | Charter mục 3: ngoài phạm vi |
| **Chia trung bình** | Charter mục 3: ngoài phạm vi. G04 chỉ cộng dồn, không chia (khác G01/G02) |
| **Ca warm-up / cửa sổ chưa đầy** | G04 **không có pha khởi động** — `valid_out = 1` ngay từ phép cộng đầu tiên |
| **Ca sai số làm tròn của phép cộng** | Phép cộng số nguyên **chính xác tuyệt đối**. Mất mát duy nhất là ở **đầu ra** (`acc_out_hi` bỏ byte thấp) — đó là lớp L-V |
| **Ca theo nhánh FSM** | G04 **không có FSM** — xem `03_ARCHITECTURE/fsm.md` |
| **Metastability / CDC** | Một domain clock duy nhất |
| **Glitch trên đầu ra** | `acc_out_hi`, `sat`, `valid_out` đều là đầu ra flip-flop |
| **Ca `inc_in` > 16 bit** | `inc_in` khai đúng 16 bit; giá trị lớn hơn không biểu diễn được |

---

## 7. Ca phải bổ sung khi chuyển sang gate-level / post-layout

`test_matrix.csv` ghi `L4-GATE` và `L5-SDF` là **CHƯA CHẠY**.

| ID | Ca | Mục đích | Cần gì |
|---|---|---|---|
| **G-1** | Chạy lại CC-1…CC-10 trên `netlist.v` | Chứng minh netlist tương đương RTL | Thư viện mô phỏng `sky130_fd_sc_hd` |
| **G-2** | ⭐ **Kiểm `acc_q[15:8]` và `acc_out_hi` là cùng một flip-flop** | Yosys đã **gộp** hai thanh ghi này (18 FF thay vì 26 — `block_diagram.md` §3). Phải xác nhận việc gộp không đổi hành vi | Netlist + kiểm tương đương hình thức |
| **G-3** | Ca kích hoạt đúng đường tới hạn: đổi `inc_in[1]` sao cho **carry lan hết 16 bit** rồi **kích hoạt bão hoà** | Đường tới hạn `inc_in[1] → acc_q[1]` (6,71 ns) đi qua **toàn bộ chuỗi carry** rồi mới tới logic bão hoà. Vector: `acc_q = 0xFFFE`, `inc_in = 0x0002` | Netlist + SDF |
| **G-4** | Kiểm **hold** trên đường ngắn nhất `_204_ → _204_` (= FF `sat`), hold slack **`0,44 ns` (MET)** sau tổng hợp | Hold vi phạm **không sửa được bằng hạ tần số**; con số hiện tại chưa tính skew clock thật (CTS chưa chạy) | SDF sau CTS |
| **G-5** | SDF ở góc `ss` và `ff` | `6,71 ns` mới ở một góc `tt_025C_1v80`; slack còn **3,16 ns** trên chu kỳ 10 ns | Liberty + SDF nhiều góc |
| **G-6** | VCD từ G-1 nạp lại OpenSTA tính công suất | `1,40e-04 W` dùng hoạt động mặc định | VCD gate-level |
| **G-7** | Ca `X`-propagation: không reset, `acc_q` khởi động ngẫu nhiên | Ở silicon flip-flop khởi động ngẫu nhiên; một công tơ khởi động với `acc` rác là lỗi nghiêm trọng | Netlist |

> ⚠️ **G-2 là ca đặc thù quan trọng nhất của G04.** Việc Yosys gộp `acc_q[15:8]` vào
> `acc_out_hi` là một tối ưu **đúng** (hai thanh ghi luôn giống hệt nhau — INV-9), nhưng nó
> làm netlist **không còn ánh xạ 1-1** với RTL. Chỉ mô phỏng gate-level hoặc kiểm tương đương
> hình thức mới xác nhận được.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
