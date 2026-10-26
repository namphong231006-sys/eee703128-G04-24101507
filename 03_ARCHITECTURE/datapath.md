# G04 · Đường dữ liệu (Datapath)

---

## 1. G04 gần như **hoàn toàn là datapath**

```
  ┌──── DATAPATH ──────────────────────────────────┐   ┌─ DIEU KHIEN ──────────┐
  │                                                 │   │                       │
  │  inc_in ─┐                                      │◀──┤  valid_in (gating)    │
  │          ├─▶ CONG 17 BIT ─▶ EP BAO HOA ─▶ acc_q │   │  rst_n                │
  │  acc_q ──┘        │                       │     │   │                       │
  │                   └─ total_ext[16] ─▶ sat │     │   │  (KHONG co bo dem,    │
  │  acc_q[15:8] ────────────────────▶ acc_out_hi   │   │   KHONG co con tro)   │
  └─────────────────────────────────────────────────┘   └───────────────────────┘
          16 + 1 = 17 flip-flop du lieu                      1 flip-flop (valid_out)
```

Tỉ lệ **17 : 1** — cao nhất nhóm G. G04 **không có** bộ đếm khởi động, **không có** con trỏ,
**không có** bộ đệm. Đó là lý do nó nhỏ nhất nhóm (119 cell).

## 2. Bảng các đường dữ liệu

| Đường | Độ rộng | Từ | Đến | Bản chất |
|---|---:|---|---|---|
| `inc_in[15:0]` | 16 | cổng vào | bộ cộng | Số gia |
| `acc_q[15:0]` | 16 | thanh ghi | bộ cộng (**hồi tiếp**) | ⭐ **Vòng hồi tiếp duy nhất**. Vật lý: `acc_q[7:0]` + `acc_out_hi[7:0]` |
| `total_ext[15:0]` | 16 | bộ cộng | tầng ép bão hoà | Tổng **chưa cắt** |
| **`total_ext[16]`** | **1** | carry-out tầng 16 | ⭐ **16 bit của `acc_next` + FF `sat`** | **Tín hiệu quan trọng nhất của mạch.** Fanout **15** (net `_093_`) |
| `acc_next[15:0]` | 16 | tầng ép bão hoà | `acc_q`, `acc_out_hi` | Kết quả sau bão hoà |
| `acc_next[15:8]` | 8 | trích bit | `acc_out_hi` | **0 cell** — và Yosys đã gộp với `acc_q[15:8]` |
| `sat_next` | 1 | `total_ext[16]` | FF `sat` | **0 cell** — chỉ là dây |
| `acc_out_hi[7:0]` | 8 | thanh ghi | cổng ra **và** hồi tiếp về bộ cộng | ⚠️ **Vừa là đầu ra vừa là bộ nhớ trong** (`block_diagram.md` §3) |
| `sat` | 1 | thanh ghi | cổng ra | Cờ |
| `valid_out` | 1 | thanh ghi | cổng ra | Bắt tay |

## 3. Đồ thị phụ thuộc — và vì sao nó **không giống** một bộ cộng bình thường

`▣` = ranh giới flip-flop.

```
  ================ TRONG MOT CHU KY CLOCK ================

   inc_in[15:0]        ▣ acc_q[15:0]
        │                    │
        └──────────┬─────────┘
                   ▼
   ┌───────────────────────────────────────────────────────────┐
   │  CHUOI CARRY 16 BIT   (muc 0 .. 15)                        │
   │                                                             │
   │   c0 ─▶ c1 ─▶ c2 ─▶ … ─▶ c14 ─▶ c15 ─▶ c16                 │
   │   │     │     │           │      │      │                  │
   │   ▼     ▼     ▼           ▼      ▼      │                  │
   │  s0    s1    s2    …     s14    s15     │                  │
   └───┬─────┬─────┬───────────┬──────┬──────┼──────────────────┘
       │     │     │           │      │      │
       │     │     │           │      │      ▼ total_ext[16] = TRAN
       │     │     │           │      │      │
       │     │     │           │      │      ├──────────────────┐
       │     │     │           │      │      │                  │
       ▼     ▼     ▼           ▼      ▼      ▼                  ▼
   ┌─────────────────────────────────────────────┐       ▣ sat
   │  TANG EP BAO HOA:  acc_next[i] = c16 | s[i] │       (muc 17)
   │  ⚠️ MOI BIT deu phu thuoc c16               │
   └──────────────┬──────────────────────────────┘
                  │ acc_next[15:0]           (muc 16..17)
         ┌────────┴────────┐
         ▼                 ▼
   ▣ acc_q[7:0]      ▣ acc_out_hi[7:0] ──▶ chan ra
   (muc 18)          (muc 18)
```

> ⭐ **Đọc kỹ tầng ép bão hoà.** Trong một bộ tích luỹ **quay vòng**, `acc_next[i] = s[i]`,
> tức bit `i` chỉ cần `carry[i]` ⟹ **bit thấp xong sớm, bit cao xong muộn**. Ở G04,
> `acc_next[i] = c16 | s[i]` ⟹ **MỌI bit đều cần `c16`**, tức **mọi bit đều phải đợi hết
> chuỗi carry**. Đồ thị phụ thuộc bị **san phẳng**: không còn bit nào "xong sớm".

### Độ sâu logic

| Đích (chân D) | Đường dài nhất | Số cell | Arrival (ns) | Nguồn |
|---|---|---:|---:|---|
| **`acc_q[1]`** | `inc_in[1]` → chuỗi carry 16 bit → bão hoà | **19** | **6,71** | **đường tới hạn** |
| `acc_out_hi[2]` | tương tự | 19 | 6,71 | đường thứ hai (`_215_`) |
| `sat` | `inc_in[?]` → chuỗi carry → `_138_ a21boi_0` | ≈ 18 | — | rất gần đường tới hạn |
| `valid_out` | `valid_in` → `and2_0` | ≈ 2 | — | rất ngắn |

> Điểm đáng chú ý: **arrival của `acc_q[1]` và `acc_out_hi[2]` bằng nhau (6,71 ns)** — bằng
> chứng trực tiếp cho việc đồ thị đã bị san phẳng. Ở một bộ cộng quay vòng, hai bit này phải
> chênh nhau ~14 tầng carry.

## 4. Dự đoán đường tới hạn từ RTL — và chỗ dự đoán **sai**

### Dự đoán (đọc RTL, chưa xem STA)

```systemverilog
16    assign total_ext = {1'b0, acc_q} + {1'b0, inc_in};
19        sat_next = total_ext[16];
20        acc_next = total_ext[16] ? 16'hFFFF : total_ext[15:0];
```

Dự đoán hợp lý nhất khi đọc: *"Đường dài nhất là chuỗi carry 16 bit, kết ở **`acc_q[15]`**
— bit cao nhất, vì nó cần `carry[15]`."*

### Kết quả STA thật

```
  Startpoint: inc_in[1] (input port clocked by clk)
  Endpoint:   _206_  =  acc_q[1]            <- BIT THU HAI TU DUOI LEN (!)
  arrival 6,71 ns · slack 3,16 ns (MET) · 19 cell

  inc_in[1] ▶ nor2 ▶ o21ai                              1,21 ns
            ▶ 12 x maj3_1  (chuoi carry)                5,92 ns
            ▶ a21oi_1                                   6,07 ns
            ▶ o21ai_0  (fanout 15)  = tin hieu TRAN     6,39 ns
            ▶ o21ai_0  (ep bao hoa bit 1)               6,62 ns
            ▶ a21boi_0 (mux giu/nap)                    6,71 ns
            ▶ acc_q[1]/D
```

| Điểm dự đoán | Thực tế | Lệch |
|---|---|---|
| Chuỗi carry 16 bit chiếm phần lớn đường | ✅ 12 `maj3`, **4,71 ns / 6,71 ns = 70 %** | Không |
| Logic bão hoà nằm **sau** chuỗi carry | ✅ từ 5,92 → 6,71 ns | Không |
| **Endpoint là `acc_q[15]`** | 🔴 **`acc_q[1]`** | ⭐ **SAI — và đây là bài học chính** |
| Startpoint là `acc_q[?]` (reg→reg) | 🔴 **`inc_in[1]`** (cổng vào) | Do `set_input_delay 1,00` |

### Giải thích chỗ lệch

**(a) Vì sao endpoint là bit THẤP.**
Bão hoà làm `acc_next[i] = c16 | s[i]` cho **mọi** `i`. Nghĩa là **tất cả 16 bit đều có cùng
một tiền tố đường** (chuỗi carry tới `c16`); chúng chỉ khác nhau ở **vài cổng cuối**. Công cụ
chọn endpoint là bit mà mấy cổng cuối đó **đắt nhất** — hoá ra là `acc_q[1]`. Đó là chuyện
ngẫu nhiên của việc ánh xạ cell, **không** mang ý nghĩa kiến trúc.

Ý nghĩa kiến trúc thật sự nằm ở chỗ khác, và nó quan trọng hơn nhiều:

> **Bão hoà đã biến `acc_q[1]` — vốn là một trong những đường NGẮN NHẤT của một bộ cộng
> (≈ 2 mức logic, cỡ 0,2 ns) — thành đường DÀI NHẤT của toàn mạch (6,71 ns).**

**(b) Vì sao startpoint là cổng vào chứ không phải thanh ghi.**
`inc_in` mang `set_input_delay 1,00 ns` (giả định của `design.sdc`), còn `acc_q` xuất phát từ
flip-flop với `clk→Q ≈ 0,36 ns`. Cả hai đường đi qua **cùng** chuỗi carry, nên đường nào khởi
hành muộn hơn thì thắng — và `1,00 > 0,36`. ⚠️ Đây là hệ quả của **một giả định trong SDC**,
không phải tính chất nội tại. Nếu hệ thống thật cấp `inc_in` sớm hơn 0,36 ns, đường tới hạn
sẽ đổi sang `acc_q[?] → acc_q[1]` và arrival giảm khoảng 0,64 ns.

**(c) Vì sao 12 `maj3` chứ không phải 16.**
ABC rút gọn chuỗi carry bằng cách gộp vài tầng vào cell phức hợp (`o21ai_0`, `a21oi_1` ở đầu
và cuối chuỗi). So sánh với G02 (bộ cộng 11 bit, 6 `maj3`) cho thấy quy luật xấp xỉ
**`maj3 ≈ 0,75 × số bit`** trong bộ công cụ này.

## 5. Phân rã thời gian của đường tới hạn — số liệu trả lời Charter mục 9

Đây là phần có giá trị định lượng cao nhất của hồ sơ G04.

| Đoạn | Từ → Đến | Thời gian | Tỉ lệ |
|---|---|---:|---:|
| Độ trễ vào (**giả định**) | — → `inc_in[1]` | 1,00 ns | 14,9 % |
| Logic đầu chuỗi | `_107_` → `_109_` | 0,21 ns | 3,1 % |
| ⭐ **Chuỗi carry 16 bit** | `_111_` → `_127_` (12 `maj3`) | **4,71 ns** | **70,2 %** |
| Kết chuỗi + sinh tín hiệu tràn | `_130_` → `_136_` | 0,47 ns | 7,0 % |
| ⭐ **Tầng ép bão hoà + mux giữ/nạp** | `_144_` → `_145_` | **0,32 ns** | **4,8 %** |
| **Tổng arrival** | | **6,71 ns** | 100 % |

### Đọc bảng này cho đúng

| Câu hỏi | Trả lời có căn cứ |
|---|---|
| Bão hoà tốn bao nhiêu **ns**? | Phần logic **nằm sau** chuỗi carry là `6,71 − 5,92 = 0,79 ns` (**11,8 %**), trong đó `0,32 ns` là hai cổng ép bão hoà cuối và `0,47 ns` là cell `_136_` sinh tín hiệu tràn với **fanout 15** |
| Đó có phải **toàn bộ** chi phí của bão hoà không? | ❌ **Không.** Chi phí lớn hơn là **cấu trúc**: bão hoà bắt **mọi** bit phải đợi `c16`. Một mạch quay vòng cũng có chuỗi carry 4,71 ns nhưng chỉ **bit cao nhất** phải đợi hết; các bit thấp xong sớm và có **slack lớn** — dư địa mà công cụ có thể dùng để giảm diện tích hoặc công suất |
| Con số `0,79 ns` có phải đo bằng A/B không? | ❌ **Không.** Nó là phân rã của **một** đường trong **một** lần chạy. Chi phí thật phải lấy bằng hiệu giữa hai lần chạy flow — Charter mục 9 yêu cầu đúng điều đó và nó **CHƯA CHẠY** |
| Cell nào đắt nhất trên đường? | `_136_ o21ai_0` với **fanout 15**: `Slew 0,34`, `Delay 0,32 ns` — đắt hơn hẳn một `maj3` (~0,39 ns nhưng fanout 2). Nó chính là **tín hiệu bão hoà** phải lái 15 tải |

## 6. Vòng hồi tiếp — ràng buộc kiến trúc

```
      ┌───────────────────────────────────────────────┐
      │                                               │
      ▼                                               │
  ╔════════════════════╗   ┌──────────────────────┐   │
  ║ acc_q[7:0]         ║──▶│ cong 17 bit + ep bao │───┘
  ║ acc_out_hi[7:0]    ║   │ hoa                  │
  ╚════════════════════╝   └──────────────────────┘
       ▲                                   6,71 ns (co input_delay 1,00 ns)
       └── chu ky clock PHAI >= 6,71 + setup 0,12 = 6,83 ns
```

| Hệ quả | Giải thích |
|---|---|
| **Không pipeline được** nếu giữ nguyên ngữ nghĩa | `acc_q` phải sẵn sàng **ngay chu kỳ sau** để nhận số gia kế tiếp |
| Cách rút ngắn **đúng** | Dùng bộ cộng nhanh hơn (carry-lookahead / carry-select) — vẫn giữ nguyên phương trình. Hoặc giữ `acc_q` ở dạng carry-save, nhưng khi đó **không so sánh được với trần** trong một chu kỳ ⟹ mâu thuẫn với bão hoà |
| ⭐ Bão hoà **xung khắc** với carry-save | Bão hoà cần biết carry-out của bit cao nhất, tức cần **giải quyết xong** biểu diễn carry-save. Đây là lý do sâu xa khiến bộ tích luỹ **có bão hoà** khó tăng tốc hơn bộ tích luỹ quay vòng |
| Độ rộng ảnh hưởng tuyến tính | 16 bit ⟹ 12 `maj3`; G02 với 11 bit chỉ có 6. Giảm xuống 8 bit sẽ gần như chia đôi đoạn 4,71 ns |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-G04-020, Charter mục 2 câu 2, mục 9.*
