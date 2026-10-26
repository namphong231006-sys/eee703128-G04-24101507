# G04 · Bối cảnh ứng dụng

> 🔧 **ĐỀ NÀY ĐÃ ĐƯỢC VÁ LỖI**
>
> Mô phỏng ban đầu không đạt. Lỗi đã được chẩn đoán, vá và **xác minh lại bằng
> công cụ thật**. Mọi số liệu trong hồ sơ là số liệu **sau khi vá**.
>
> * Mã nguồn gốc: [`08_ORIGINAL_SOURCE/`](08_ORIGINAL_SOURCE/) — giữ nguyên, quay lui được
> * Nhật ký vá: [`08_ORIGINAL_SOURCE/PATCHLOG.md`](08_ORIGINAL_SOURCE/PATCHLOG.md)
> * Chẩn đoán đầy đủ: [`05_VERIFICATION/known_issues.md`](05_VERIFICATION/known_issues.md)



| | |
|---|---|
| Mã đề | **G04** |
| Tên đề | Bộ tích luỹ có bão hoà 16-bit |
| Nhóm đề | G · Xử lý tín hiệu số đơn giản |
| Độ khó | Trung bình |
| Loại mạch | **Tuần tự** |
| Quy mô ước lượng (Charter) | ~200–290 cell · 1×1 tile |
| Nguồn gốc | Project Charter — G04, mục 1 |

---

## 1. Mục tiêu và bối cảnh ứng dụng

Trích nguyên văn Charter mục 1:

> Phân tích khối số “Bộ tích luỹ có bão hoà 16-bit” ở mức khối. Bối cảnh ứng dụng: Khối cộng dồn năng lượng tiêu thụ trong công tơ điện tử: chạm trần thì dừng ở trần chứ không quay về 0.

## 2. Vị trí khối G04 trong hệ thống

```
   ┌──────────────┐      ┌──────────────────────────────┐      ┌──────────────┐
   │  Nguồn tín   │─────▶│      ►►► KHỐI G04 ◄◄◄        │─────▶│  Tầng tiêu   │
   │  hiệu / dữ   │      │  Bộ tích luỹ có bão hoà 16-bi │      │  thụ kết quả │
   │  liệu vào    │      │  Loại mạch: Tuần tự          │      │              │
   └──────────────┘      └──────────────────────────────┘      └──────────────┘
```

> Sơ đồ chi tiết có chú thích: `03_ARCHITECTURE/system_diagram.md`.

## 3. Phân loại analog / digital / mixed

| Khối | Phân loại | Ghi chú |
|---|---|---|
| Cảm biến / nguồn tín hiệu vật lý (nếu có) | Analog | Đại lượng liên tục |
| Chuyển đổi ADC/DAC (nếu có) | Mixed-signal | Ranh giới analog–số |
| **G04 — Bộ tích luỹ có bão hoà 16-bit** | **Digital, tuần tự** | Có ô nhớ, hoạt động theo cạnh clock |
| Tầng xử lý phía sau | Digital | Tiêu thụ kết quả của G04 |

Bằng chứng cho dòng phân loại của G04: tổng hợp thật cho **18 flip-flop**
(`06_GDSII/synthesis/synth_stat.txt`).

---

**Truy vết:** yêu cầu sinh từ tài liệu này được đánh số `REQ-G04-0xx` trong
`01_REQUIREMENT/requirements.md`, và truy vết đến bằng chứng trong `07_TRACEABILITY/RTM.csv`.

*Phiên bản: v1.0 · Ngày: 2026-09-24*
