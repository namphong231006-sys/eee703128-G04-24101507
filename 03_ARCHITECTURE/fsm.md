# G04 · Máy trạng thái (FSM)

---

## 1. Kết luận: G04 **không có FSM** — và là đề "ít FSM nhất" của nhóm G

G04 có 18 flip-flop, nhưng **17 trong số đó là dữ liệu** (`acc_q[7:0]` 8 + `acc_out_hi[7:0]`
8 + `sat` 1). Chỉ còn `valid_out` (1 bit) mang tính bắt tay, và nó là một **bản sao trễ một
chu kỳ của `valid_in`**, không phải trạng thái.

| Tiêu chí của một FSM | G04 có? | Bằng chứng trong RTL (41 dòng) |
|---|:-:|---|
| Có `typedef enum` / hằng trạng thái | ❌ | Không có |
| Có biến `state` / `next_state` | ❌ | Chỉ có `acc_q`, `total_ext`, `acc_next`, `sat_next` |
| Có `case` | ❌ | **Không có một `case` nào** |
| Có **bộ đếm** điều khiển | ❌ | Khác G01/G02/G03 — G04 **không có** `count_q` |
| Có **con trỏ địa chỉ** | ❌ | Khác G01/G02 — không có `wr_ptr` |
| Trạng thái kế tiếp rẽ nhánh theo đầu vào | ⚠️ **có, nhưng là dữ liệu** | `acc_next` phụ thuộc `total_ext[16]` — đó là **phép toán số học**, không phải chuyển trạng thái |

## 2. Nếu cố vẽ G04 thành FSM thì sao

Có thể trừu tượng hoá `acc_q` thành hai "chế độ", và việc này **có giá trị dạy học** vì nó
làm lộ ra ngữ nghĩa mơ hồ của `sat`:

```
                     inc_in sao cho acc + inc > 65535
      ┌────────────┐ ───────────────────────────────▶ ┌────────────┐
      │  DUOI TRAN │                                   │  O TRAN    │
      │ acc < FFFF │                                   │ acc = FFFF │
      └────────────┘ ◀─────────────────────────────── └────────────┘
         │      ▲           KHONG CO CUNG NAO            │       ▲
         │      │        (tru khi rst_n = 0)             │       │
         └──────┘                                        └───────┘
      inc nho, chua cham tran                    moi inc >= 0 deu giu nguyen

      rst_n = 0 :  moi trang thai ──────────────▶ DUOI TRAN (acc = 0)

      ⭐ sat = 1  CHI o cung chuyen DUOI TRAN -> O TRAN
                  va o cung tu vong O TRAN -> O TRAN khi inc >= 1.
         sat = 0  o cung tu vong O TRAN -> O TRAN khi inc = 0.   <- INV-6
```

| Vì sao đây **không** phải FSM thật | Giải thích |
|---|---|
| Đồ thị có **hai nút nhưng 65536 trạng thái thật** | "Dưới trần" gộp 65535 giá trị khác nhau. Đây là **trừu tượng hoá**, không phải mã hoá trạng thái |
| Không có thanh ghi trạng thái riêng | Netlist: 17/18 FF là dữ liệu. Không có flip-flop nào lưu "đang ở trần hay không" |
| Điều kiện chuyển là **phép toán số học**, không phải hàm logic của đầu vào | Cần cộng xong 16 bit mới biết |
| Nút "Ở trần" là **nút hút** (absorbing) | Chỉ `rst_n` thoát ra được — đúng nghĩa **bão hoà dính** (INV-5) |

> 🔎 **Nhưng đồ thị này rất đáng vẽ khi bảo vệ**, vì nó làm lộ ra ngay ngữ nghĩa mơ hồ của
> `sat`: trên hai cung **khác nhau** cùng dẫn tới nút "Ở trần", `sat` có giá trị **khác nhau**
> (1 khi `inc ≥ 1`, 0 khi `inc = 0`). Tức `sat` mô tả **CUNG**, không mô tả **NÚT**. Nếu
> Charter muốn `sat` báo "đang ở trần" thì nó phải mô tả **nút** — và khi đó cần thêm logic.
> Xem `functional_spec.md` Cảnh báo 2.

## 3. Bằng chứng từ netlist

| Bằng chứng | Giá trị | Diễn giải |
|---|---|---|
| Flip-flop | **18** `dfxtp_1` | 17 dữ liệu + 1 bắt tay |
| Flip-flop "điều khiển" | **0** | Không bộ đếm, không con trỏ, không thanh ghi trạng thái |
| Cell đặc trưng | `xnor2_1` ×26, `maj3_1` ×12, `a21boi_0` ×16, `o21ai_0` ×17 | Vân tay của **bộ cộng + tầng OR ép bão hoà** |
| Vân tay của FSM (`nor4`/`and4` nhiều ngõ, one-hot decode) | ❌ **không có** | |
| Công suất nhóm Combinational | **36,0 %** — cao nhất nhóm G | Mạch bị chi phối bởi **logic số học**, không bởi trạng thái |

## 4. So sánh với ba đề còn lại của nhóm G

| Đề | Bộ đếm khởi động | Con trỏ địa chỉ | Thanh ghi trạng thái | FSM? |
|---|:-:|:-:|:-:|:-:|
| G01 | ✅ `count_q` | ✅ `wr_ptr` | ❌ | ❌ |
| G02 | ✅ `count_q` (4 bit) | ✅ `wr_ptr` (3 bit) | ❌ | ❌ |
| G03 | ✅ `count_q` (2 bit) | ❌ | ❌ | ❌ |
| **G04** | ❌ | ❌ | ❌ | ❌ |

G04 là đề duy nhất của nhóm **không có bất kỳ flip-flop điều khiển nào** ngoài `valid_out`.
Lý do bản chất: bộ tích luỹ **không có cửa sổ**, nên không cần đếm xem đã đủ mẫu chưa.

## 5. Trường hợp nào FSM **sẽ** xuất hiện

| Nếu thêm yêu cầu… | FSM xuất hiện vì… | Trạng thái ước tính |
|---|---|---|
| ⭐ **Lệnh `xoá` mà Charter mục 4 yêu cầu** | Nếu `xoá` chỉ là gán `acc_q ← 0` thì **vẫn không cần FSM**. Nhưng nếu `xoá` phải **chốt số đọc ra ngoài trước khi xoá** (hành vi thật của công tơ) thì cần: `LATCH → CLEAR → RUN` | 3 |
| **Mở rộng dải đo bằng bộ đếm tràn trong khối** | Phải xử lý carry lên tầng đếm cao | 2–3 |
| **Nạp `inc_in` 16 bit qua 8 chân** (đúng ngân sách Charter mục 4) | Phải nhớ đang ở nhịp byte thấp hay byte cao | `LOW / HIGH` — 2 |
| **Back-pressure** (`ready`) | Phải nhớ "đang giữ kết quả" | 2 |
| **Tích luỹ nhiều kênh** (Charter mục 3: *ngoài phạm vi*) | Phải quay vòng qua các kênh | `N` kênh |
| **Ghi vào bộ nhớ không bay hơi** | Chu trình ghi cần nhiều chu kỳ và bắt tay | ≥ 4 |

> 🔎 Trường hợp thứ ba đáng chú ý nhất: Charter mục 4 chỉ cấp **8 chân vào** cho "mẫu", trong
> khi RTL nhận **16 bit**. Sửa cho đúng ngân sách chân sẽ **bắt buộc** phải nạp hai nhịp, và
> khi đó G04 **sẽ có FSM thật**. Nói cách khác: **lỗi giao diện ở `functional_spec.md` Cảnh
> báo 1 không chỉ là chuyện đánh số chân — nó đổi cả kiến trúc.**

## 6. Sai lầm hay gặp

| Sai lầm | Vì sao sai | Cách phát hiện |
|---|---|---|
| "Mạch tuần tự ⟹ phải vẽ FSM" | Bộ tích luỹ là mạch tuần tự thuần datapath | Tìm `case (state)` — không có thì đừng bịa |
| "`sat` là trạng thái ⟹ G04 có FSM 2 trạng thái" | `sat` là **đầu ra đăng ký**, mô tả **cung** chứ không mô tả **nút** (§2). Nó không điều khiển gì cả | Tra netlist: `sat` không lái chân điều khiển nào, chỉ ra chân |
| "Vẽ FSM `RESET / ACCUM / SATURATED`" | `RESET` không phải trạng thái (reset **đồng bộ**); `ACCUM`/`SATURATED` là **trừu tượng hoá giá trị `acc_q`**, không phải mã hoá trạng thái | Netlist không có flip-flop nào ngoài 18 đã liệt kê |
| "Không có FSM ⟹ bỏ trống mục này" | SPEC §0.7: phải giải thích vì sao | Chính là tài liệu này |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-G04-003.*
