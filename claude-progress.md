# Nhật ký Tiến độ — TTFCustomCards

## Trạng thái Hiện tại

- **Thư mục gốc:** `d:\TTF\TTFCustomCards`
- **Lệnh validate:** `.\script-test\validate_scripts.ps1`
- **Lệnh check sync:** `python .\script-test\manage_db.py check-sync`
- **Tác vụ ưu tiên tiếp theo:** _(cập nhật khi bắt đầu phiên mới)_
- **Sự cố chặn hiện tại:** Không có

---

## Nhật ký Phiên

### Phiên 001 — 2026-05-29

- **Mục tiêu:** Setup lại project theo Harness Engineering (walkinglabs.github.io/learn-harness-engineering)
- **Đã hoàn thành:**
  - Tái cấu trúc `AGENTS.md` → routing file ~60 dòng
  - Tạo sub-docs: `docs/agent-workflow.md`, `docs/agent-rules.md`, `docs/agent-constants.md`, `docs/agent-bugfix.md`
  - Tạo `feature_list.json` — track trạng thái card theo archetype
  - Tạo `claude-progress.md` (file này)
- **Xác minh đã chạy:** Không có script Lua nào bị thay đổi — không cần validate
- **Bằng chứng đã ghi lại:** File mới tạo trong repo
- **Commit:** _(chưa commit — theo yêu cầu AGENTS.md)_
- **Files/artifacts đã cập nhật:** AGENTS.md, feature_list.json, docs/agent-*.md, claude-progress.md
- **Rủi ro đã biết:**
  - `feature_list.json` cần được cập nhật thủ công khi thêm card mới — passcode của các card Castle of Dreams chưa được điền đầy đủ (không có trong queue files)
- **Bước tốt nhất tiếp theo:** _(do user xác định)_

### Phiên 002 — 2026-05-29

- **Mục tiêu:** Điều chỉnh timing/condition của Labrynth Party (c90177.lua) từ "During your Main Phase" thành "During Main Phase"
- **Đã hoàn thành:**
  - Cập nhật script `script/c90177.lua`: loại bỏ điều kiện kiểm tra turn player `Duel.GetTurnPlayer()==tp` trong hàm condition `s.setcon2`, và cập nhật chú thích mô tả effect ở dòng 13 và 131.
  - Đổi kiểu của Effect 2 trong script từ `EFFECT_TYPE_IGNITION` thành `EFFECT_TYPE_QUICK_O` và set code thành `EVENT_FREE_CHAIN` để cho phép kích hoạt trong lượt đối phương (Quick Effect).
  - Cập nhật text mô tả card trong cơ sở dữ liệu SQLite (`custom_cards_zesty.cdb`) cho passcode 90177.
- **Xác minh đã chạy:**
  - Chạy validate `.\script-test\validate_scripts.ps1` thành công (0 FAIL, c90177.lua OK).
  - Chạy `python .\script-test\manage_db.py check-sync` và `query 90177` xác nhận DB và Script đồng bộ.
- **Bằng chứng đã ghi lại:** Thay đổi trực tiếp trong file script và cơ sở dữ liệu.
- **Commit:** _(chưa commit — theo yêu cầu AGENTS.md)_
- **Files/artifacts đã cập nhật:** script/c90177.lua, custom_cards_zesty.cdb, claude-progress.md
- **Rủi ro đã biết:** Không có
- **Bước tốt nhất tiếp theo:** _(do user xác định)_

---

_Thêm phiên mới theo format trên. Giữ mục "Trạng thái Hiện tại" luôn cập nhật._
