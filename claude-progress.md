# Nhật ký Tiến độ — TTFCustomCards

## Trạng thái Hiện tại

- **Thư mục gốc:** `d:\TTF\TTFCustomCards`
- **Lệnh validate:** `.\script-test\validate_scripts.ps1`
- **Lệnh check sync:** `python .\script-test\manage_db.py check-sync`
- **Tác vụ ưu tiên tiếp theo:** Chờ hàng đợi (queue) hoặc yêu cầu tạo card mới từ user.
- **Sự cố chặn hiện tại:** Không có blocker.

---

## Nhật ký Phiên

> [!NOTE]
> Để giữ file nhật ký gọn gàng và dễ theo dõi, các phiên làm việc cũ đã được chuyển vào file lưu trữ.
> [Xem lịch sử các phiên trước đó (Phiên 001 - 050) tại đây](file:///d:/TTF/TTFCustomCards/docs/claude-progress-archive.md).

### Phiên 054 — 2026-06-08

- **Mục tiêu:**
  - Tinh gọn script test và sửa lỗi Tiếng Việt.
- **Đã hoàn thành:**
  - Trích xuất 993 hằng số EDOPro chuẩn từ `validate_scripts.ps1` ra `script-test/edopro_constants.txt`.
  - Tinh gọn `validate_scripts.ps1` từ 1334 dòng xuống còn 346 dòng (giảm ~75%), tải hằng số động một lần duy nhất lúc khởi tạo.
  - Sửa lỗi mã hóa Tiếng Việt (Unicode) trên Windows console bằng cách thiết lập mã hóa UTF-8 cho toàn bộ PowerShell script (`validate_scripts.ps1`, `lint_scripts.ps1`, `fetch_official.ps1`) and Python script (`manage_db.py`, `manage_harness.py`).
  - Cập nhật hàm `run_command` trong `manage_harness.py` sử dụng `encoding='utf-8'` khi giải mã output từ sub-process con.
  - Xây dựng script [archive_progress.py](file:///d:/TTF/TTFCustomCards/script-test/archive_progress.py) để tự động hóa việc di chuyển các phiên cũ (chỉ giữ lại tối đa 25 phiên) từ `claude-progress.md` sang [docs/claude-progress-archive.md](file:///d:/TTF/TTFCustomCards/docs/claude-progress-archive.md).
  - Tích hợp Step 6 tự động chạy script này vào cuối pipeline `verify` của [manage_harness.py](file:///d:/TTF/TTFCustomCards/script-test/manage_harness.py).
  - Di chuyển thư mục `template-card/` ở root vào trong [script-test/templates/](file:///d:/TTF/TTFCustomCards/script-test/templates/) để gom toàn bộ "Developer Tooling" về một mối và làm sạch root directory.
  - Cập nhật đường dẫn `"template_dir"` trong [manage_harness.py](file:///d:/TTF/TTFCustomCards/script-test/manage_harness.py) và đồng bộ hóa cấu trúc mới vào các file tài liệu [AGENTS.md](file:///d:/TTF/TTFCustomCards/AGENTS.md), [README.md](file:///d:/TTF/TTFCustomCards/README.md), [docs/agent-rules.md](file:///d:/TTF/TTFCustomCards/docs/agent-rules.md) và [script-test/templates/README.md](file:///d:/TTF/TTFCustomCards/script-test/templates/README.md).
- **Xác minh đã chạy:**
  - `python .\script-test\manage_db.py check-sync` -> **100% OK**.
  - `.\script-test\validate_scripts.ps1 -Quiet` -> **122 OK, 0 FAIL** (hoạt động tốt với file txt hằng số).
  - `python .\script-test\manage_db.py query 79900002` -> Tiếng Việt có dấu hiển thị chuẩn xác, sắc nét trên console.
  - `python .\script-test\manage_harness.py verify 192300010` -> Chạy pipeline harness thành công (bao gồm cả Step 6 auto archive).
- **Files/artifacts đã cập nhật:** `validate_scripts.ps1`, `lint_scripts.ps1`, `fetch_official.ps1`, `manage_db.py`, `manage_harness.py`, `edopro_constants.txt`, `archive_progress.py`, `claude-progress.md`, `AGENTS.md`, `README.md`, `docs/agent-rules.md`, `script-test/templates/README.md`

### Phiên 053 — 2026-06-08

- **Mục tiêu:**
  - Rà soát sự cần thiết của skill `vibe-card` cũ trong thư mục `.claude/`.
- **Đã hoàn thành:**
  - Xác nhận skill `vibe-card` cũ trong `.claude/` đã lỗi thời và xung đột với luồng plaintext JSON Specs & Harness CLI mới (do gọi các script python cũ ghi đè CDB trực tiếp).
  - Trích xuất tài liệu tra cứu bitmask CDB hữu ích từ skill cũ và di trú sang tài liệu chính thức [cdb-schema.md](file:///d:/TTF/TTFCustomCards/docs/cdb-schema.md).
  - Xóa bỏ hoàn toàn thư mục `.claude/` để ngăn chặn IDE kích hoạt nhầm skill cũ.
  - Cập nhật liên kết tài liệu trong [AGENTS.md](file:///d:/TTF/TTFCustomCards/AGENTS.md) và [agent-workflow.md](file:///d:/TTF/TTFCustomCards/docs/agent-workflow.md) để hỗ trợ tra cứu bitmask khi điền JSON specs.
- **Xác minh đã chạy:**
  - Thư mục `.claude/` đã được xóa sạch.
  - `python .\script-test\manage_db.py check-sync` -> **100% OK** (Tương thích đồng bộ hoàn hảo).
  - `.\script-test\validate_scripts.ps1` -> **76 OK, 46 WARN, 0 FAIL** (Biên dịch thành công).
- **Files/artifacts đã cập nhật:** [AGENTS.md](file:///d:/TTF/TTFCustomCards/AGENTS.md), [agent-workflow.md](file:///d:/TTF/TTFCustomCards/docs/agent-workflow.md), [cdb-schema.md](file:///d:/TTF/TTFCustomCards/docs/cdb-schema.md), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 052 — 2026-06-08

- **Mục tiêu:**
  - Thiết lập Git và quy trình để tiếp tục duy trì, theo dõi file database nhị phân `custom_cards_zesty.cdb` theo yêu cầu của user.
- **Đã hoàn thành:**
  - Cập nhật quy định trong [agent-rules.md](file:///d:/TTF/TTFCustomCards/docs/agent-rules.md) yêu cầu commit file CDB nhị phân chung với specs JSON và Lua script.
  - Cập nhật tài liệu quy trình [agent-workflow.md](file:///d:/TTF/TTFCustomCards/docs/agent-workflow.md) làm rõ việc luôn phải chạy lệnh compile để đồng bộ dữ liệu vào CDB trước khi commit.
  - Chạy biên dịch SQLite database từ specs JSON để cập nhật file `custom_cards_zesty.cdb`.
- **Xác minh đã chạy:**
  - `python .\script-test\manage_db.py compile` -> Biên dịch thành công 122 card specs.
  - `python .\script-test\manage_db.py check-sync` -> **100% OK** (Đồng bộ hoàn hảo giữa DB, Specs JSON và scripts).
  - `.\script-test\validate_scripts.ps1` -> **76 OK, 46 WARN, 0 FAIL** (Biên dịch thành công).
- **Files/artifacts đã cập nhật:** `custom_cards_zesty.cdb`, [agent-rules.md](file:///d:/TTF/TTFCustomCards/docs/agent-rules.md), [agent-workflow.md](file:///d:/TTF/TTFCustomCards/docs/agent-workflow.md), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 051 — 2026-06-08

- **Mục tiêu:**
  - Brainstorm phương án tối ưu hóa dự án theo triết lý Harness Engineering và xử lý triệt để 2 lỗi lệch đồng bộ lâu ngày.
- **Đã hoàn thành:**
  - Tạo tài liệu phân tích thiết kế chi tiết tại [analysis_results.md](file:///C:/Users/dinhd/.gemini/antigravity-ide/brain/7e6708b6-b46b-4d23-8ebc-118e9c455d53/analysis_results.md) với 4 trụ cột chính: Tổ chức, Quản lý, Vibe, và Sửa lỗi.
  - Giải quyết lỗi sync `78900102`: Bổ sung hoàn chỉnh script Field Spell [c78900102.lua](file:///d:/TTF/TTFCustomCards/script/c78900102.lua) cho "Ttf Holy Sanctuary".
  - Giải quyết lỗi sync `79900002`: Đăng ký card "Ttf Cat Luna" vào SQLite database `custom_cards_zesty.cdb`.
- **Xác minh đã chạy:**
  - `python .\script-test\manage_db.py check-sync` -> **100% OK** (All local card scripts and database entries are in perfect sync!).
  - `.\script-test\validate_scripts.ps1` -> **76 OK, 46 WARN, 0 FAIL** (Biên dịch thành công).
- **Files/artifacts đã cập nhật:** `custom_cards_zesty.cdb`, [c78900102.lua](file:///d:/TTF/TTFCustomCards/script/c78900102.lua), [analysis_results.md](file:///C:/Users/dinhd/.gemini/antigravity-ide/brain/7e6708b6-b46b-4d23-8ebc-118e9c455d53/analysis_results.md), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

_Thêm phiên mới theo format trên. Giữ mục "Trạng thái Hiện tại" luôn cập nhật._
