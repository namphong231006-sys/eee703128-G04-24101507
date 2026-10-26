# G04 · Bảng yêu cầu (Requirements)

> 🔧 **ĐỀ NÀY ĐÃ ĐƯỢC VÁ LỖI**
>
> Mô phỏng ban đầu không đạt. Lỗi đã được chẩn đoán, vá và **xác minh lại bằng
> công cụ thật**. Mọi số liệu trong hồ sơ là số liệu **sau khi vá**.
>
> * Mã nguồn gốc: [`08_ORIGINAL_SOURCE/`](08_ORIGINAL_SOURCE/) — giữ nguyên, quay lui được
> * Nhật ký vá: [`08_ORIGINAL_SOURCE/PATCHLOG.md`](08_ORIGINAL_SOURCE/PATCHLOG.md)
> * Chẩn đoán đầy đủ: [`05_VERIFICATION/known_issues.md`](05_VERIFICATION/known_issues.md)



Mọi yêu cầu đều **suy trực tiếp từ Project Charter — G04**. Cột *Nguồn* chỉ rõ mục nào
của Charter sinh ra yêu cầu đó. Không có yêu cầu nào do người soạn tự thêm.

Mức: **M** = bắt buộc · **S** = nên có · **O** = tuỳ chọn.

---

## 1. Yêu cầu chức năng và cấu trúc

| ID | Mức | Nội dung yêu cầu | Nguồn |
|---|---|---|---|
| REQ-G04-001 | M | Khối thực hiện đúng chức năng mô tả trong Charter mục 1: *Bộ tích luỹ có bão hoà 16-bit*. | mục 1 |
| REQ-G04-002 | M | Giao diện đúng ánh xạ chân Charter mục 4 (xem `02_SPECIFICATION/interface.md`). | mục 4 |
| REQ-G04-003 | M | Loại mạch phải đúng phân loại Charter: **Tuần tự** — có ô nhớ, đồng bộ theo clock. | mục 10 |
| REQ-G04-004 | M | Quy mô nằm trong khoảng hợp lý cho ô 1×1 tile (Charter ước lượng ~200–290 cell · 1×1 tile). | metadata |

## 2. Yêu cầu kiểm chứng

| ID | Mức | Nội dung yêu cầu | Nguồn |
|---|---|---|---|
| REQ-G04-010 | M | Chạy đủ các ca kiểm thử bắt buộc của Charter mục 8 (xem §4). | mục 8 |
| REQ-G04-011 | M | Bổ sung **ít nhất hai ca tự xây dựng**, trong đó có **ca biên**. | mục 8 |
| REQ-G04-012 | M | Mỗi khẳng định phải đi kèm **bằng chứng** và **điều kiện tạo ra bằng chứng**. | mục 6 |
| REQ-G04-013 | S | Thu một **artifact số có chú thích** và nêu điều kiện tạo ra nó. | mục 3, 5 |

## 3. Yêu cầu phân tích riêng (đặc thù của G04)

> Charter mục 9 — bắt buộc trả lời bằng số liệu của chính mình:
>
> Bão hoà và quay vòng là hai hành vi tràn khác nhau, và bão hoà tốn thêm logic. Định lượng chi phí đó: chạy flow một lần có bão hoà, một lần để quay vòng, so sánh diện tích trong báo cáo.
> Bắt buộc trả lời bằng số liệu của chính mình. Mỗi đề một câu khác nhau.

| ID | Mức | Nội dung |
|---|---|---|
| REQ-G04-020 | M | Trả lời câu phân tích riêng ở trên bằng dữ liệu do chính mình sinh ra. |
| REQ-G04-021 | M | Trả lời các câu hỏi kỹ thuật Charter mục 2 (xem §5) bằng bằng chứng. |

## 4. Ca kiểm thử bắt buộc (Charter mục 8)

- Cộng tới sát giới hạn · cộng vượt giới hạn (phải bão hoà) · xoá rồi cộng lại · cộng giá trị 0
- Bổ sung ít nhất hai ca tự xây dựng, trong đó có ca biên.

Danh sách thực thi và kết quả: `05_VERIFICATION/test_matrix.csv`.

## 5. Câu hỏi kỹ thuật của Charter (mục 2)

1. **Bão hoà khác quay vòng ở chỗ nào — và vì sao quay vòng là nguy hiểm với một công tơ?**
2. **Phát hiện chạm trần bằng logic gì, tốn bao nhiêu cell?**
3. **Bộ tích luỹ 16 bit nhưng chỉ xuất 8 bit cao — quyết định đó mất mát gì?**

> Sinh viên được phép thay bằng câu hỏi của mình, miễn là cụ thể và trả lời được bằng bằng
> chứng — không viết "tìm hiểu về…". *(Charter mục 2)*

Câu trả lời kèm bằng chứng: `05_VERIFICATION/verification_report.md` và `06_GDSII/physical_report.md`.

## 6. Yêu cầu bàn giao (Charter mục 5)

- Hồ sơ phân tích đủ tám thành phần, có số phiên bản và ngày sửa.
- Bảng giao diện: tên tín hiệu, chiều, độ rộng, mức tích cực, giả định.
- Một artifact số có chú thích và nêu điều kiện tạo ra nó.
- Kết luận nêu rõ đã chứng minh được gì và chưa chứng minh được gì.

## 7. Mốc thực hiện (Charter mục 7)

- M1 · T7. Chốt đề và viết charter: ứng dụng, mục tiêu, 2–3 câu hỏi kỹ thuật.
- M2 · T8–9. Bảng hành vi suy từ đặc tả; đọc RTL và waveform; lập danh sách ca kiểm thử.
- M3 · T11–12. Sơ đồ khối hỗ trợ; thu artifact số, chú thích và đối chiếu bảng hành vi.
- M4 · T13–14. Hoàn thiện bảng giao diện, RTM-lite, sơ đồ vòng đời; rà từng khẳng định.
- M5 · T15. Nộp hồ sơ và trình bày; trả lời câu phân tích riêng bằng số của chính mình.

## 8. Rủi ro chính (Charter mục 10)

> Chỗ hay tắc: Phát hiện bão hoà SAU khi đã cộng tràn — phải phát hiện TRƯỚC hoặc dùng bit carry.
> Dấu hiệu làm đúng: 16 ô nhớ tích luỹ + 1 cờ ≈ 17–18 ô nhớ.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Nguồn chuẩn: `Project_Charter_80_De.docx`, mục G04.*
