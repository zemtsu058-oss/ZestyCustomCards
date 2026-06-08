# TTF Custom Cards — Agent Guide

Hệ thống phát triển custom card cho EDOPro (Yu-Gi-Oh! simulator).
Dữ liệu sử dụng **Specs JSON** (thư mục `card-data/`) làm Single Source of Truth để biên dịch ra SQLite database `custom_cards_zesty.cdb`.

---

## Khởi động nhanh (Harness CLI)

Mọi hoạt động vòng đời của card (tạo mới, xác thực, đổi trạng thái) được tự động hóa qua `manage_harness.py`:

```powershell
# 1. Khởi tạo một card mới (tự động copy template, tạo spec JSON, cập nhật feature_list và queue status)
python .\script-test\manage_harness.py start <passcode> "<tên_card>" <loại_template>

# 2. Biên dịch CDB, kiểm tra lỗi cú pháp, linter, đồng bộ và hoàn thành card (chuyển sang trạng thái done)
python .\script-test\manage_harness.py verify <passcode>

# 3. Tra cứu nhanh thông tin card trong database
$env:PYTHONIOENCODING="utf-8"; python .\script-test\manage_db.py query <passcode_hoặc_tên>
```

*Trước khi bắt đầu:* Luôn đọc [`claude-progress.md`](claude-progress.md) để biết trạng thái phiên trước.

---

## Ràng buộc cứng (BẮT BUỘC — TUYỆT ĐỐI KHÔNG VI PHẠM)

1. **LUÔN LUÔN sử dụng Harness CLI (`manage_harness.py`)** để tạo mới (`start`) hoặc hoàn thành (`verify`) card. Tuyệt đối không tự ý copy file, đổi tên file ảnh queue hay chỉnh sửa `feature_list.json` thủ công.
2. **LUÔN LUÔN commit cả file CDB nhị phân (`custom_cards_zesty.cdb`)** cùng với các file specs JSON (`card-data/`) và script Lua tương ứng trong một commit duy nhất (không tách biệt). Tệp CDB nhị phân phải được biên dịch mới nhất bằng lệnh `compile` (hoặc tự động qua `verify`) trước khi commit.
3. **NEVER** copy, tham chiếu hoặc bắt chước code trực tiếp từ các tệp custom cũ trong `script/` (ngoại trừ các file hệ thống như `constants.lua`) vì phần lớn code cũ có lỗi timing/logic nghiêm trọng.
4. **ALWAYS** dùng các tệp mẫu trong `script-test/templates/` làm base (khung cơ sở) bắt buộc khi viết card mới. Nếu cần tham khảo logic chạy thực tế, chỉ sử dụng các script card official làm mẫu (tải qua `fetch_official.ps1` lưu tại `docs/official-reference/`).
5. **ALWAYS** `local s,id=GetID()` ở đầu mỗi script Lua mới.
6. **ALWAYS** dùng `Card.GetRelatedHandler(c, e)` thay cho việc gọi trực tiếp `c` trong các hàm operation khi xử lý các card trigger/continuous (xem chi tiết tại [`docs/agent-rules.md`](docs/agent-rules.md)).
7. **ALWAYS** đặt cột `ot` = 32 khi cấu hình card trong specs JSON.
8. **ALWAYS** tra cứu setcode của các official archetype trong [`docs/archetype_setcode_constants.lua`](docs/archetype_setcode_constants.lua) (không search web hay tự đoán bừa setcode).
9. **ALWAYS** sử dụng `.\script-test\fetch_official.ps1 <passcode>` để tải card official làm mẫu (lưu tại `docs/official-reference/c<passcode>.lua`), không tự ý tải thủ công từ bên ngoài.

---

## Quy chuẩn Comment & Commit (BẮT BUỘC)

### 1. Quy cách Comment trong Script Lua
* **Header Block (Đầu file):** Bắt buộc ở đầu mỗi script:
  ```lua
  -- ============================================================
  -- Card Name: <Tên Card>
  -- Passcode  : <9 chữ số>
  -- Type      : <Loại card, ví dụ: Monster / Effect, Spell / Field>
  -- Archetype : <Tên Archetype> (<Hex Code>)
  -- ============================================================
  -- Effect 1  : <Tóm tắt chi tiết hiệu ứng 1>
  -- Effect 2  : <Tóm tắt chi tiết hiệu ứng 2>
  -- ============================================================
  ```
* **Section Separators:** Phân chia các khối bằng dòng kẻ `-- =====` (ví dụ: `Effect 1 — GY: Banish to Special Summon`).
* **Inline Comments:** Ghi chú ngắn gọn tại các dòng logic phức tạp hoặc sửa lỗi.

### 2. Quy chuẩn Git Commit
* **Nguyên tắc gom file:** Commit 3 file cùng lúc: `card-data/c<passcode>.json`, `script/c<passcode>.lua`, `custom_cards_zesty.cdb`.
* **Cấu trúc Commit Message:** `[<Tên_Dev>] [<Type>]: <Mô tả bằng tiếng Anh>`
  - `<Tên_Dev>` lấy từ Git User (ví dụ: `Doanh`, `Zemtsu`).
  - `<Type>` viết hoa chữ đầu: `Fix`, `Feature`, `Refactor`, `Chore`.
  - *Ví dụ:* `[Doanh] [Fix]: fix interaction with Dark Law / Macro Cosmos`
  - Nếu sửa nhiều card, ghi chi tiết ở body:
    ```
    [Doanh] [Fix]: update mechanics for Wezaemon/Tachikaze cards
    
    c192300005: replace IsCode with GetPreviousCode in leave-field check.
    c192300006, c192300007, c192300008: change GY effects to IGNITION.
    ```

---

## Cấu trúc project

```
script/          # Lua scripts (cXXXXXXXXX.lua) + constants.lua (chứa custom setcode)
card-data/       # Single Source of Truth - Specs JSON cho mỗi card
pics/            # Artwork (tên file = passcode)
docs/            # Tài liệu hướng dẫn & Queues hàng đợi card
script-test/     # Bộ công cụ CLI & templates:
  ├── templates/        # Templates sinh script mới (xem README.md bên trong)
  ├── manage_harness.py # Quản lý quy trình (Harness CLI)
  ├── manage_db.py      # Quản lý CDB (CDB Compiler)
  ├── validate_scripts.ps1
  └── lint_scripts.ps1
custom_cards_zesty.cdb  # Database SQLite nhị phân (phải được compile & commit)
strings.conf     # Tên archetype/counter
```

---

## Điều hướng theo tác vụ

| Tác vụ | Tài liệu | Mô tả |
|--------|----------|-------|
| Tạo card mới, Sửa bug & Chạy thử | [`docs/agent-workflow.md`](docs/agent-workflow.md) | Hướng dẫn sử dụng CLI, quy trình fix bug, checklist QA và setup test trong game. |
| Quy tắc viết script, Passcode & Bitmasks | [`docs/agent-rules.md`](docs/agent-rules.md) | Quy chuẩn code Lua, hằng số setcode/passcode, schema database và bảng bitmask. |
| API scripting đầy đủ | [`docs/card-scripting-guide.md`](docs/card-scripting-guide.md) | Tham khảo API EDOPro Lua đầy đủ. |
| Danh sách setcode Archetype official | [`docs/archetype_setcode_constants.lua`](docs/archetype_setcode_constants.lua) | Hằng số setcode của toàn bộ archetype OCG/TCG chính thức. |
| Trạng thái hàng đợi phát triển | [`feature_list.json`](feature_list.json) | Danh sách trạng thái card. |
| Nhật ký tiến độ phiên làm việc | [`claude-progress.md`](claude-progress.md) | Trạng thái và tiến độ phiên làm việc hiện tại. |
