# G04 · Sơ đồ khối bên trong (Block Diagram)

Vẽ theo **đúng 41 dòng** của `04_IMPLEMENTATION/rtl/g04_sat_accum16.sv`; mọi số cell lấy từ
`06_GDSII/synthesis/synth_stat.txt` và `netlist.v`.

---

## 1. Sơ đồ khối

```
   inc_in[15:0]                         ╔══════════════════════════╗
        │                               ║  THANH GHI TICH LUY 16b  ║
        │        ┌──────────────────────╢  acc_q[15:0]             ║◀──┐
        │        │                      ║  (VAT LY: 8 FF acc_q +   ║   │
        │        │                      ║   8 FF acc_out_hi — §3)  ║   │
        ▼        ▼                      ╚══════════════════════════╝   │
  ┌──────────────────────────────────────────────────────────────┐     │
  │  CONG MO RONG 17 BIT                                          │     │
  │     total_ext = {1'b0, acc_q} + {1'b0, inc_in}                │     │
  │                                                                │     │
  │   Hien thuc: 12 x maj3_1 (chuoi carry) + 26 x xnor2_1          │     │
  │              + 1 x xor2_1 (tong tung bit) + nand2b_1 x16       │     │
  └───────────┬──────────────────────────────────┬────────────────┘     │
              │ total_ext[16]  = CARRY-OUT       │ total_ext[15:0]      │
              │ = phat hien TRAN                 │                      │
              │                                  │                      │
              │  ┌───────────────────────────────┤                      │
              │  │                               │                      │
              ▼  ▼                               ▼                      │
   ┌─────────────────────────────────────────────────────┐              │
   │  TANG EP BAO HOA (16 bit)                            │              │
   │                                                       │              │
   │     acc_next[i] = total_ext[16] ? 1'b1                │              │
   │                                 : total_ext[i]        │              │
   │                 = total_ext[16] | total_ext[i]        │              │
   │                                                       │              │
   │   ⭐ ep ve 0xFFFF = EP MOI BIT LEN 1  =>  chi la OR   │              │
   │      Hien thuc: 14 x o21ai_0 nhan net _093_          │              │
   │      (_093_ = tin hieu tran, FANOUT 15)              │              │
   └──────────────────────┬────────────────────────────────┘              │
                          │ acc_next[15:0]                                │
              ┌───────────┼────────────────┬──────────────┐               │
              │           │                │              │               │
              ▼           ▼                ▼              │               │
   ╔══════════════╗  ╔══════════╗   ╔═════════════╗       │               │
   ║ acc_q [7:0]  ║  ║acc_out_hi║   ║  sat  1 FF  ║       └───────────────┘
   ║   8 FF       ║  ║  8 FF    ║   ║             ║
   ║ (byte THAP)  ║  ║(byte CAO ║   ║ = total_ext ║
   ║              ║  ║ + dau ra)║   ║      [16]   ║
   ╚══════════════╝  ╚═════╤════╝   ╚══════╤══════╝
                            │               │
                            ▼               ▼
                    acc_out_hi[7:0]        sat

        valid_in ──▶ ╔═════════════╗
                     ║ valid_out   ║──▶ valid_out
                     ║   1 FF      ║
                     ╚═════════════╝

  🔴 KHONG CO cong 'xoa' ma Charter muc 4 yeu cau (uio_in[1])
```

## 2. Bảng ánh xạ cấu trúc RTL → phần cứng sinh ra

| Dòng RTL | Cấu trúc RTL | Phần cứng sinh ra | Bằng chứng trong netlist |
|---|---|---|---|
| 11 | `logic [15:0] acc_q` | **16 flip-flop** — nhưng mang **hai tên**: `acc_q[0..7]` và `acc_out_hi[0..7]` | Xem §3 |
| 12 | `logic [16:0] total_ext` | Dây nội bộ, không có FF | `total_ext` không xuất hiện trong danh sách `.Q()` |
| 16 | `{1'b0,acc_q} + {1'b0,inc_in}` | **Bộ cộng 17 bit**: chuỗi carry + tổng từng bit | `maj3_1` ×12 (carry) · `xnor2_1` ×26 + `xor2_1` ×1 (tổng) · `nand2b_1` ×16 |
| 19 | `sat_next = total_ext[16]` | **0 cell** — chỉ là bit carry-out của tầng cuối | nét `_093_` từ `_136_/Y` |
| 20 | `acc_next = total_ext[16] ? 16'hFFFF : total_ext[15:0]` | ⭐ **KHÔNG phải mux 16 bit** — là **16 cổng OR** với bit tràn | `o21ai_0` ×17, trong đó **14 cell nhận `_093_` ở chân A1** |
| 23 | `always_ff @(posedge clk)` | Cả 18 FF là `dfxtp_1` ⟹ reset **đồng bộ** | Không có `dfrtp_1` nào |
| 24–28 | Nhánh reset | Gộp vào logic tổ hợp trước chân D | `a21boi_0` ×16 |
| 32–37 | `if (valid_in)` — mux giữ/nạp cho 18 FF | `a21boi_0` là tầng cuối trước **16/18** chân D | Xem §4 |
| 34 | `acc_out_hi <= acc_next[15:8]` | ⭐ **0 cell thêm** — Yosys nhận ra đây là **bản sao** của `acc_q[15:8]` và **gộp hai thanh ghi làm một** | §3 |

### Kiểm chứng số flip-flop

```
   Dem theo RTL (ngay tho):
     acc_q 16  +  acc_out_hi 8  +  sat 1  +  valid_out 1   =  26 FF

   Netlist THUC TE:
     acc_q[0..7]      8 FF      <- byte THAP cua bo tich luy
     acc_out_hi[0..7] 8 FF      <- byte CAO cua bo tich luy, DONG THOI la dau ra
     sat              1 FF
     valid_out        1 FF
     ─────────────────────
     TONG            18 FF      <- bot duoc 8 FF
```

`synth_stat.txt` ghi `sky130_fd_sc_hd__dfxtp_1  18`. **Khớp.**

> Đối chiếu Charter mục 10: *"Dấu hiệu làm đúng: **16 ô nhớ tích luỹ + 1 cờ ≈ 17–18 ô nhớ**."*
> Thực tế **18** — khớp **chính xác** đầu trên của khoảng. Nhưng phải hiểu **vì sao**: nếu
> Yosys **không** gộp được, con số sẽ là **26** và Charter sẽ trông như sai. Xem §3.

## 3. ⭐ Tám flip-flop biến mất — công cụ đã làm gì

Trong RTL, `acc_q` và `acc_out_hi` là **hai biến khác nhau**:

```systemverilog
33                acc_q      <= acc_next;          // 16 bit
34                acc_out_hi <= acc_next[15:8];    //  8 bit
```

Nhưng chúng **luôn nhận cùng một dữ liệu, tại cùng một cạnh, với cùng một enable** — tức
`acc_out_hi[i] ≡ acc_q[i+8]` ở **mọi** thời điểm (đó là INV-9). Yosys phát hiện hai thanh
ghi tương đương và **gộp chúng làm một** (*register merging* / loại bỏ thanh ghi trùng lặp).

**Bằng chứng từ netlist:** duyệt toàn bộ 18 `dfxtp_1`, chỉ có `acc_q[0]`…`acc_q[7]` — **không
tồn tại `acc_q[8]`…`acc_q[15]`**. Byte cao của bộ tích luỹ được lưu trong chính các flip-flop
mang tên `acc_out_hi[0..7]`, và các flip-flop đó **vừa là bộ nhớ trong vừa là chân ra**.

```
   Y tuong trong RTL:                  Thuc te trong netlist:

   acc_next[15:8] ──┬──▶ ▣ acc_q[15:8]      acc_next[15:8] ──▶ ▣ acc_out_hi[7:0] ──┬──▶ chan ra
                    │       │ (hoi tiep)                              │             │
                    └──▶ ▣ acc_out_hi ──▶ chan ra                     └─────────────┴──▶ hoi tiep
        26 FF                                        18 FF   ve bo cong
```

| Câu hỏi | Trả lời |
|---|---|
| Có phải lỗi không? | ❌ **Không.** Tối ưu hợp lệ, giữ nguyên hành vi ở mọi cạnh clock |
| Tiết kiệm được gì? | **8 flip-flop = 30,8 %** số ô nhớ, và toàn bộ logic mux giữ/nạp của 8 bit đó |
| Rủi ro | ⚠️ Netlist **không còn ánh xạ 1-1** với RTL. Muốn dò `acc_q[15:8]` khi gỡ lỗi gate-level, phải tìm dưới tên `acc_out_hi` |
| Xác nhận chắc chắn 100 % | Mô phỏng gate-level (ca **G-2** trong `corner_cases.md` §7 — **CHƯA CHẠY**) hoặc kiểm tương đương hình thức |
| Nếu RTL đổi để `acc_out_hi` **chốt trễ một chu kỳ** thì sao? | Gộp **không còn hợp lệ** ⟹ quay về 26 FF. Đó là cách kiểm giả thuyết này |

> 💡 **Điểm dạy học:** đây là ví dụ đối xứng với G02. Ở G02, công cụ **thêm** 3 flip-flop
> (nhân bản con trỏ để tách fanout); ở G04, công cụ **bớt** 8 flip-flop (gộp thanh ghi trùng
> lặp). Cả hai đều cho thấy: **đếm `always_ff` rồi khẳng định số ô nhớ trong netlist là sai
> phương pháp.** Phải đọc netlist.

## 4. Tầng ép bão hoà — trả lời Charter mục 2 câu 2

> *"Phát hiện chạm trần bằng logic gì, tốn bao nhiêu cell?"*

### Phát hiện bằng logic gì

**Bằng bit carry-out của một phép cộng mở rộng 17 bit** — không phải bằng so sánh:

```systemverilog
16    assign total_ext = {1'b0, acc_q} + {1'b0, inc_in};   // 17 bit
19        sat_next = total_ext[16];                        // chinh la carry-out
```

Chi phí của việc **phát hiện**: **0 cell thêm**. Bit `total_ext[16]` là carry-out tự nhiên
của tầng cộng thứ 16 — nó vốn đã tồn tại trong chuỗi carry, chỉ là trước đây bị vứt đi.
Đây chính là điều Charter mục 10 yêu cầu (*"dùng bit carry"*).

### Ép về `0xFFFF` tốn bao nhiêu cell

Điểm tinh tế: `0xFFFF` là **toàn bit 1**, nên "chọn giữa `0xFFFF` và `total_ext`" **không
cần mux** — nó chỉ là **phép OR**:

```
     acc_next[i] = sat ? 1'b1 : total_ext[i]  =  sat | total_ext[i]
```

**Bằng chứng từ netlist:** tín hiệu tràn nằm ở net `_093_` (do `_136_ o21ai_0` lái).
Tra toàn bộ netlist, `_093_` có **15 tải**:

| Loại tải | Số lượng | Vai trò |
|---|---:|---|
| `o21ai_0` chân `A1` | **14** | Tầng ép bão hoà cho 14 bit của `acc_next` |
| `nand2_1` chân `B` | **1** | Nhánh tới flip-flop `sat` |

| Hạng mục | Số cell | Tỉ lệ / 119 cell |
|---|---:|---:|
| Phát hiện tràn (`total_ext[16]`) | **0** (dùng carry sẵn có) | 0 % |
| Tầng ép bão hoà (`o21ai_0` nhận `_093_`) | **≈ 14** | **11,8 %** |
| Cell lái tín hiệu tràn (`_136_`) | 1 | 0,8 % |

> ⚠️ **Đây là con số đọc được từ netlist, KHÔNG phải hiệu số giữa hai lần chạy flow.** ABC
> gộp và ánh xạ lại logic, nên chi phí **thật** của bão hoà chỉ đo được bằng cách chạy flow
> **hai lần** (một có bão hoà, một quay vòng) rồi lấy hiệu — đúng như Charter mục 9 yêu cầu.
> Việc đó **CHƯA CHẠY**. Xem `tradeoff.md` §6.

## 5. Bộ cộng 17 bit — nơi tiêu tiền nhiều nhất

| Cell | Số lượng | Vai trò |
|---|---:|---|
| `xnor2_1` | **26** | Bit tổng (`sum[i] = a ^ b ^ carry`, ABC dựng bằng cặp `xnor`) |
| `nand2b_1` | **16** | Sinh tín hiệu `propagate`/`generate` cho chuỗi carry |
| `maj3_1` | **12** | ⭐ **Chuỗi carry** — `carry[i+1] = maj(a[i], b[i], carry[i])` |
| `o21ai_0` | 17 | 14 cho tầng bão hoà + 3 khác |
| `a21boi_0` | **16** | Tầng cuối trước chân D của 16/18 flip-flop (mux giữ/nạp + reset) |
| `xor2_1` | 1 | Bit tổng còn lại |
| khác | 11 | `nand2_1` 5, `a21oi_1` 2, `and2_0` 2, `nor2_1` 2, `lpflow_*` 2 |

**Ước tính theo chức năng:**

| Khối | Cell ước tính | Tỉ lệ |
|---|---:|---:|
| Bộ cộng 17 bit (`xnor2` 26 + `nand2b` 16 + `maj3` 12 + `xor2` 1) | ≈ **55** | ≈ 46 % |
| Tầng ép bão hoà (`o21ai_0` nhận `_093_`) | ≈ **14** | ≈ 12 % |
| Mux giữ/nạp + reset (`a21boi_0` 16) | ≈ **16** | ≈ 13 % |
| Flip-flop | **18** | ≈ 15 % |
| Còn lại (đệm, gating, `valid_out`) | ≈ 16 | ≈ 14 % |

> 🔎 **Phát hiện:** gần **một nửa** diện tích G04 là **bộ cộng 16 bit**. Bão hoà — thứ mà
> tên đề nhấn mạnh — chỉ chiếm ≈ 12 %. Nhưng về **thời gian** thì tỉ lệ ngược lại: bão hoà
> chiếm **0,79 ns trên 6,71 ns** đường tới hạn nhưng nó **ép toàn bộ 16 bit phải đợi chuỗi
> carry hoàn tất** (§6). **Rẻ về diện tích, đắt về cấu trúc thời gian.**

## 6. Khối con nào nằm trên đường tới hạn

Đường tới hạn thật (`06_GDSII/sta/timing_report_max.txt`, arrival **6,71 ns**, slack **3,16 ns**):

```
  inc_in[1]  (cong vao, input_delay 1,00 ns)
    ▶ _107_ nor2_1 ▶ _109_ o21ai_0                             t = 1,21
    ▶ _111_ _112_ _114_ _116_ _118_ _120_ _122_
      _123_ _124_ _125_ _126_ _127_   maj3_1 x12   <- CHUOI CARRY 16 BIT
                                                                t = 5,92
    ▶ _130_ a21oi_1                                             t = 6,07
    ▶ _136_ o21ai_0   (fanout 15)  <- TIN HIEU TRAN _093_       t = 6,39
    ▶ _144_ o21ai_0                <- TANG EP BAO HOA cua bit 1 t = 6,62
    ▶ _145_ a21boi_0               <- mux giu/nap               t = 6,71
    ▶ _206_/D  =  acc_q[1]                                      t = 6,71

  TONG: 19 cell
```

| Khối con | Trên đường tới hạn? | Bằng chứng |
|---|:-:|---|
| **Chuỗi carry 16 bit** | ✅ **chiếm trọn phần giữa** | 12 `maj3_1` liên tiếp, từ `t = 1,21` tới `t = 5,92` ⟹ **4,71 ns = 70 %** đường |
| **Tín hiệu tràn `total_ext[16]`** | ✅ | `_136_`, fanout 15, `t = 6,39` |
| **Tầng ép bão hoà** | ✅ | `_144_`, `t = 6,62` |
| **Mux giữ/nạp (`valid_in`)** | ✅ | `_145_ a21boi_0`, `t = 6,71` |
| Thanh ghi `acc_q[1]` | ✅ là **endpoint** | `_206_` có `.Q(\acc_q[1])` |
| `acc_out_hi`, `sat`, `valid_out` | ❌ | Đường tới chúng ngắn hơn (đường thứ hai trong báo cáo kết ở `_215_` = `acc_out_hi[2]`) |

### ⭐ Phát hiện quan trọng nhất của đề G04

> **Endpoint của đường tới hạn là `acc_q[1]` — BIT THỨ HAI TỪ DƯỚI LÊN — và nó phải đợi
> carry-out của BIT CAO NHẤT.**

Trong một bộ tích luỹ **quay vòng** thông thường, `acc_q[1]` chỉ phụ thuộc
`inc_in[1:0]` và `acc_q[1:0]` ⟹ khoảng **2 mức logic**, độ trễ cỡ **0,2 ns**. Ở đây nó mất
**6,71 ns**. Lý do:

```
   Quay vong:      acc_next[1] = sum[1]                     <- 2 muc logic
                                  ^^^^^^ chi can carry[1]

   Bao hoa:        acc_next[1] = total_ext[16] | sum[1]     <- 2 muc + CA CHUOI CARRY
                                  ^^^^^^^^^^^^^ can carry[16] = TOAN BO 16 tang
```

**Bão hoà biến một bit thấp — vốn là đường ngắn nhất của mạch — thành đường dài nhất.**
Đó là cái giá cấu trúc thật sự của bão hoà, và nó **không nhìn thấy được** nếu chỉ đếm cell.

### Dự đoán từ RTL vs STA

| Điểm | Dự đoán khi đọc RTL | STA thật | Lệch? |
|---|---|---|---|
| Chuỗi carry 16 bit chiếm phần lớn đường | ✅ | ✅ 12 `maj3`, 70 % thời gian | Không |
| Logic bão hoà nằm **sau** chuỗi carry | ✅ | ✅ `t = 5,92 → 6,71` | Không |
| Endpoint là **bit cao** (`acc_q[15]`) | ❌ dự đoán sai | **`acc_q[1]`** | ⭐ **Sai — và chỗ sai này chính là bài học** |
| Startpoint là `acc_q[0]` (reg→reg) | ❌ | **`inc_in[1]` (cổng vào)** | Do `set_input_delay 1,00 ns` giả định |

Dự đoán "endpoint là bit cao" sai vì trực giác cho rằng bit cao ổn định muộn nhất. Đúng — ở
mạch **quay vòng**. Nhưng bão hoà làm **mọi** bit phụ thuộc bit cao nhất, nên endpoint có
thể là **bất kỳ** bit nào; công cụ chọn bit nào có tầng ép bão hoà đắt nhất.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-G04-003, Charter mục 2 câu 2, mục 10.*
