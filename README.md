# G04 — Bộ tích luỹ có bão hoà 16-bit

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
| **Mã đề** | G04 |
| **Nhóm** | G · Xử lý tín hiệu số đơn giản |
| **Độ khó** | Trung bình |
| **Loại mạch** | Tuần tự |
| **Quy mô ước lượng (Charter)** | ~200–290 cell · 1×1 tile |
| **Top module** | `g04_sat_accum16` |
| **Phiên bản hồ sơ** | v1.0 · 2026-09-24 |

---

## 1. Tóm tắt kết quả

| Tầng | Trạng thái | Kết quả chính |
|---|---|---|
| 01 Yêu cầu | ✅ | Yêu cầu truy vết từ Charter G04 |
| 02 Đặc tả | ✅ | Giao diện đọc trực tiếp từ RTL; ràng buộc timing đã lập |
| 03 Kiến trúc | ✅ | Sơ đồ khối, datapath, điều khiển, đánh đổi |
| 04 Hiện thực | ✅ | RTL + SDC + 4 script chạy được |
| 05 Kiểm chứng | ✅ | ✅ PASS — testbench chạy hết, không có assertion nào vi phạm |
| 06 GDSII | 🟡 một phần | Synthesis ✅ · STA ✅ · Power ✅ · P&R ⬜ |
| 07 Truy vết | ✅ | RTM + chỉ mục bằng chứng + giới hạn |

### Số liệu đo được (không phải ước lượng)

| Chỉ số | Giá trị | Công cụ |
|---|---:|---|
| Mô hình chuẩn Python | PASS | CPython 3 |
| Mô phỏng RTL | PASS | Icarus Verilog 12.0 (stable) |
| Số cell | **119** | Yosys 0.33 (git sha1 2584903a060) |
| Flip-flop | **18** | như trên |
| Diện tích | **1083,5392 µm²** | như trên |
| Đường tới hạn | `inc_in[1]` → `_206_` | OpenSTA 3.1.0 |
| **Độ trễ** | **6,71 ns** | như trên |
| Công suất (ước lượng) | 1.40e-04 W | như trên |

## 2. Đọc từ đâu

| Bạn là | Đọc theo thứ tự |
|---|---|
| **Muốn nắm bản chất nhanh** | **[`implementation-notes_G04.md`](implementation-notes_G04.md)** — hoặc mở bản `.html` |
| **Giảng viên chấm bài** | `07_TRACEABILITY/limitations.md` → `RTM.csv` → `06_GDSII/physical_report.md` |
| **Sinh viên nhận đề** | `01_REQUIREMENT/application.md` → `02_SPECIFICATION/` → `03_ARCHITECTURE/` → `04_IMPLEMENTATION/README.md` |
| **Muốn chạy lại** | `07_TRACEABILITY/evidence_index.md` §5 |

## 3. Cây thư mục

```
G04/
├── implementation-notes_G04.md      ← phân tích bản chất + cách thực hiện
├── implementation-notes_G04.html    ← bản đọc trên trình duyệt (tự chứa)
├── 01_REQUIREMENT/     application · requirements · scope · acceptance_criteria
├── 02_SPECIFICATION/   functional_spec · interface · timing · corner_cases · parameters
├── 03_ARCHITECTURE/    system_diagram · block_diagram · datapath · control · fsm
│                       timing_diagram · tradeoff
├── 04_IMPLEMENTATION/  rtl/ · constraints/ · scripts/ · README
├── 05_VERIFICATION/    golden_model/ · testbench/ · assertions/ · waveforms/
│                       testplan · test_matrix.csv · verification_report
├── 06_GDSII/           synthesis/ sta/ power/ floorplan/ placement/ cts/
│                       routing/ drc/ lvs/ gds/ · physical_report
└── 07_TRACEABILITY/    RTM.csv · evidence_index · limitations
```

## 4. Chạy lại toàn bộ

```bash
python3 05_VERIFICATION/golden_model/reference_model.py
bash    04_IMPLEMENTATION/scripts/01_run_sim.sh
bash    04_IMPLEMENTATION/scripts/02_run_synth.sh
sta -no_splash -exit 04_IMPLEMENTATION/scripts/03_run_sta.tcl
bash    04_IMPLEMENTATION/scripts/04_run_librelane.sh     # cần PDK sky130A
```



---

*Nguồn chuẩn: `Project_Charter_80_De.docx` — mục G04. Gói nguồn: `G04_FINAL_MENTOR_PACKAGE_v1_0`.*
*Hồ sơ này không đưa ra khẳng định nào về sign-off, tape-out, chế tạo hay kiểm tra sau chế
tạo — những mục nằm ngoài phạm vi đề tài theo Charter mục 3.*
