# G04 · Phần điều khiển (Control)

G04 là mạch **tuần tự**, nhưng phần điều khiển của nó là **nhỏ nhất trong cả nhóm G**: không
bộ đếm, không con trỏ, không trạng thái khởi động. Chỉ có **hai tín hiệu vào** và **một
flip-flop** thuần điều khiển.

---

## 1. Toàn bộ phần điều khiển

```
  ┌────────────────────── KHOI DIEU KHIEN ────────────────────────┐
  │                                                                │
  │   rst_n ────▶ ┌─────────────┐                                  │
  │               │ RESET DONG  │──▶ xoa acc_q, acc_out_hi,        │
  │               │     BO      │    sat, valid_out ve 0           │
  │               └─────────────┘                                  │
  │                                                                │
  │   valid_in ─▶ ┌─────────────┐                                  │
  │               │   GATING    │──▶ cho phep nap acc_q,           │
  │               │  (dong 32)  │    acc_out_hi, sat               │
  │               └──────┬──────┘                                  │
  │                      │                                         │
  │                      └────────────────────▶ ╔═════════════╗   │
  │                                             ║ valid_out   ║   │
  │                                             ║   1 FF      ║   │
  │                                             ╚═════════════╝   │
  │                                                                │
  │   🔴 KHONG CO tin hieu 'xoa' ma Charter muc 4 yeu cau          │
  │   ⬛ KHONG CO bo dem khoi dong (khac G01/G02/G03)              │
  │   ⬛ KHONG CO con tro dia chi (khac G01/G02)                   │
  └────────────────────────────────────────────────────────────────┘
```

**1 flip-flop điều khiển trên 18** = **5,6 %**. Đây là mạch **datapath thuần** nhất của nhóm G.

## 2. Bảng tín hiệu điều khiển và tác dụng

| Tín hiệu | Nguồn | Rộng | Tác dụng lên datapath | Dòng RTL |
|---|---|---:|---|---|
| `rst_n` | cổng vào | 1 | Xoá **toàn bộ** 18 flip-flop về 0 tại cạnh lên kế tiếp. **Đồng bộ**, tích cực thấp | 24–28 |
| `valid_in` | cổng vào | 1 | **Cổng chủ**: khi bằng 0, `acc_q`, `acc_out_hi`, `sat` **không đổi**; `valid_out` về 0 | 30–37 |
| `total_ext[16]` | **nội bộ, từ datapath** | 1 | ⭐ Vừa là **dữ liệu** (`sat_next`) vừa là **điều khiển** (chọn giữa `0xFFFF` và tổng thật) | 19–20 |
| **`xoá`** | — | — | 🔴 **KHÔNG TỒN TẠI** — Charter mục 4 yêu cầu `uio_in[1]` | — |

### `total_ext[16]` — tín hiệu điều khiển sinh ra từ chính datapath

Đây là nét kiến trúc đáng nói nhất của G04. Ở G01/G02/G03, mọi tín hiệu điều khiển đều đến
từ **bộ đếm** hoặc từ **cổng vào**. Ở G04, tín hiệu điều khiển quan trọng nhất
(`total_ext[16]`) được sinh ra **ở cuối chuỗi carry của chính bộ cộng**.

| Hệ quả | Giải thích |
|---|---|
| Nó là **đường dài nhất** tới mọi flip-thanh ghi dữ liệu | Muốn biết có tràn hay không thì phải cộng xong 16 bit — `datapath.md` §4 |
| Fanout **15** | Một bit phải lái tầng ép bão hoà của 14 bit + nhánh tới FF `sat`. Netlist: 14 × `o21ai_0/A1` + 1 × `nand2_1/B` trên net `_093_` |
| Nó **không thể tính trước** | Khác với `count_q >= 7` của G02 (biết từ chu kỳ trước), `total_ext[16]` phụ thuộc **dữ liệu của chính chu kỳ này** |
| Đây chính là lý do Charter mục 10 cảnh báo | *"Phát hiện bão hoà SAU khi đã cộng tràn — phải phát hiện **TRƯỚC** hoặc dùng **bit carry**."* Dùng bit carry là đúng, nhưng phải chấp nhận nó đến **muộn** |

## 3. Quan hệ điều khiển ↔ datapath

```
                  ┌──────────────────────────────────────────┐
  valid_in ──────▶│ AND voi enable cua 17 FF du lieu          │
                  └──┬──────────┬──────────┬─────────────────┘
                     │          │          │
                     ▼          ▼          ▼
                 acc_q[7:0]  acc_out_hi   sat
                  (8 FF)      (8 FF)     (1 FF)
                     ▲          ▲          ▲
                     │          │          │
        ┌────────────┴──────────┴──────────┘
        │  acc_next[i] = total_ext[16] | total_ext[i]
        │                ▲
        │                │ tu CUOI chuoi carry (net _093_, fanout 15)
        └────────────────┘

  valid_in ──────────────────────────────────▶ ▣ valid_out   (duong RIENG, chi 2 cell)
```

| Quan hệ | Chi tiết |
|---|---|
| **Gating rất "rẻ"** | `valid_in` chỉ cần đi vào tầng cuối trước chân D. Netlist: `a21boi_0` ×16 là tầng cuối của 16/18 flip-flop — nó gộp *mux giữ/nạp* và *reset* vào **một** cell |
| **`valid_out` đi đường riêng** | `valid_in → and2_0 → valid_out`, ~2 cell. Nó **không** đợi bộ cộng |
| **Không có back-pressure** | Không có `ready`; nếu tầng sau không nhận kịp thì mất số liệu — với một công tơ, đó là **mất tiền** |
| **Không có trạng thái khởi động** | `valid_out = 1` ngay từ phép cộng đầu tiên, vì `acc_q` có giá trị xác định (`0`) ngay sau reset |
| ⚠️ **Bộ cộng không bị gating** | Bộ cộng và tầng bão hoà chạy **liên tục**, kể cả khi `valid_in = 0`. Nếu `inc_in` đổi trong lúc nghỉ, toàn bộ chuỗi carry vẫn chuyển mạch ⟹ **công suất động lãng phí**. Công suất tổ hợp của G04 là **36,0 %** — cao nhất nhóm G |

## 4. Ba khẳng định về điều khiển, có bằng chứng từ netlist

| Khẳng định | Bằng chứng |
|---|---|
| Reset là **đồng bộ** | Cả **18** flip-flop đều là `sky130_fd_sc_hd__dfxtp_1` — loại **không có chân reset**. Nếu bất đồng bộ, Yosys phải dùng `dfrtp_1` |
| `valid_in` và reset được **gộp vào một tầng cell** | `a21boi_0` ×16 lái chân D của 15 bit tích luỹ + FF `sat`. Cell này thực hiện `Y = !((A1·A2) | !B1_N)` — đủ để mã hoá cả "giữ hay nạp" lẫn "reset hay không" |
| Tín hiệu bão hoà là **nút cổ chai fanout** | Net `_093_` có **15 tải**; cell lái nó (`_136_ o21ai_0`) có `Delay 0,32 ns` với `Slew 0,34` — chậm hơn hẳn các cell fanout thấp trên cùng đường |

## 5. Vì sao điều khiển **không** phải một FSM

Xem `fsm.md`. Tóm tắt: G04 **không có biến trạng thái điều khiển nào cả**. `acc_q` là dữ
liệu, `sat` là đầu ra đăng ký, `valid_out` là bắt tay. Không có `case`, không có bộ đếm,
không có đồ thị chuyển trạng thái.

## 6. 🔴 Cổng điều khiển còn **thiếu**: lệnh `xoá`

Charter mục 4 yêu cầu `uio_in[1] = xoá`. RTL **không có**. Đây **không** phải chi tiết nhỏ:

| Vấn đề | Hệ quả |
|---|---|
| Ca bắt buộc Charter mục 8 *"xoá rồi cộng lại"* | 🔴 **Không thể thực hiện** ⟹ REQ-G04-010 **CHƯA THOẢ** |
| Dùng `rst_n` thay thế? | ❌ **Không tương đương.** `rst_n` ở hệ thống thật thường là reset chung của cả chip (POR / watchdog), không phải lệnh dữ liệu. Xoá bộ tích luỹ sau mỗi kỳ chốt số là **hoạt động bình thường**, không phải sự kiện bất thường |
| Trong ứng dụng công tơ | Sau mỗi kỳ chốt số (tháng), phải xoá bộ tích luỹ. Không có lệnh `xoá` thì **không chốt kỳ được** |
| `sat` có bị xoá theo không? | Đây là câu hỏi đặc tả **chưa có lời giải** vì cổng chưa tồn tại. Đề nghị: `xoá` đặt `acc_q ← 0` **và** `sat ← 0` |

Bản vá đề xuất (**chưa áp dụng**): `05_VERIFICATION/known_issues.md` §6, Vá 4.

## 7. Nghĩa vụ hợp đồng của tầng ngoài

| # | Nghĩa vụ | Nếu vi phạm |
|---|---|---|
| 1 | Giữ `rst_n = 0` qua **≥ 1 cạnh lên** của `clk` | Bộ tích luỹ không được xoá — với công tơ là **số đọc rác lúc khởi động** |
| 2 | `valid_in` chỉ lên 1 khi `inc_in` đã ổn định | Cộng nhầm giá trị — **sai số tích luỹ vĩnh viễn**, không tự sửa được |
| 3 | **Theo dõi `sat`** và đếm số lần tràn ở tầng ngoài | Mất toàn bộ phần năng lượng vượt trần |
| 4 | ⚠️ Hiểu `sat` là **"lần cộng vừa rồi bị cắt"**, không phải "đang ở trần" | `acc = 0xFFFF`, `inc = 0` cho `sat = 0` — tầng ngoài tưởng đã thoát trần (INV-6) |
| 5 | ⚠️ **Không suy ra `acc` từ `acc_out_hi`** | `acc_out_hi = 0xFF` ứng với **256** giá trị `acc`. Chính lỗi này làm testbench sai (`known_issues.md`) |
| 6 | Luôn sẵn sàng nhận (không có `ready`) | Mất số liệu đo |
| 7 | Giữ `inc_in` ổn định khi `valid_in = 0` (nếu muốn tiết kiệm công suất) | Chuỗi carry 16 bit chuyển mạch vô ích |
| 8 | Đồng bộ hoá `inc_in`/`valid_in` nếu đến từ domain khác | Metastability |

> ⚠️ **Nghĩa vụ 4 và 5 là hai cái bẫy lớn nhất của G04**, và cả hai đều bắt nguồn từ cùng
> một quyết định thiết kế: **giao diện quan sát hẹp hơn trạng thái trong**. Đây chính là
> điều Charter mục 2 câu 3 hỏi (*"chỉ xuất 8 bit cao — quyết định đó mất mát gì?"*).

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-G04-003, Charter mục 2 câu 3, mục 4.*
