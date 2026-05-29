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

---

_Thêm phiên mới theo format trên. Giữ mục "Trạng thái Hiện tại" luôn cập nhật._
