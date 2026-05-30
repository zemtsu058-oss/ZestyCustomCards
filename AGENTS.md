# TTF Custom Cards — Agent Guide

Project custom card cho EDOPro (Yu-Gi-Oh! auto duel simulator).
Scripts Lua + database SQLite + artwork cho các card fan-made.

## Khởi động nhanh

```powershell
# Validate tất cả scripts
.\script-test\validate_scripts.ps1

# Kiểm tra đồng bộ database
python .\script-test\manage_db.py check-sync
```

Trước khi bắt đầu: đọc [`claude-progress.md`](claude-progress.md) để biết trạng thái phiên trước.

---

## Cấu trúc project

```
script/          # Lua scripts (cXXXXXXXXX.lua) + constants.lua
pics/            # Artwork (tên file = passcode)
template-card/   # Templates sinh script mới (xem README.md bên trong)
docs/            # Tài liệu (xem bảng điều hướng bên dưới)
script-test/     # validate_scripts.ps1, lint_scripts.ps1, manage_db.py
custom_cards_zesty.cdb  # Database SQLite
strings.conf     # Archetype/counter name strings
docs/queues/     # Hàng đợi card theo archetype (p_/w_/r_/d_/x_ prefix)
```

---

## Ràng buộc cứng (KHÔNG ĐƯỢC VI PHẠM)

1. **NEVER** copy code từ `script/` — toàn bộ đang có lỗi, chỉ dùng `template-card/`
2. **ALWAYS** `local s,id=GetID()` ở đầu mỗi script
3. **ALWAYS** validate trước khi báo DONE: `.\script-test\validate_scripts.ps1`
4. **NEVER** tự commit/push — chỉ khi user yêu cầu
5. **ALWAYS** cột `ot` = 32 khi thêm card vào database
6. **ALWAYS** tra cứu setcode của các official archetype trong [`docs/archetype_setcode_constants.lua`](file:///d:/TTF/TTFCustomCards/docs/archetype_setcode_constants.lua) (không search web hay tự đoán bừa setcode).

---

## Điều hướng theo tác vụ

| Tác vụ | Đọc file này |
|--------|-------------|
| Tạo card mới | [`docs/agent-workflow.md`](docs/agent-workflow.md) |
| Viết/review script | [`docs/agent-rules.md`](docs/agent-rules.md) |
| Tra setcode / passcode | [`docs/agent-constants.md`](docs/agent-constants.md) |
| Fix bug / effect lạ | [`docs/agent-bugfix.md`](docs/agent-bugfix.md) |
| API scripting đầy đủ | [`docs/card-scripting-guide.md`](docs/card-scripting-guide.md) |
| Debug / testing | [`docs/testing-guide.md`](docs/testing-guide.md) |
| Templates | [`template-card/README.md`](template-card/README.md) |
| Trạng thái card (queue) | [`feature_list.json`](feature_list.json) |
| Tiến độ phiên làm việc | [`claude-progress.md`](claude-progress.md) |
