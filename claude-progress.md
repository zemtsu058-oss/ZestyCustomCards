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

### Phiên 003 — 2026-05-30

- **Mục tiêu:** Tạo card mới "Teardrop the Rikka Fairy" (Xyz Rank 12 WATER Plant)
- **Đã hoàn thành:**
  - Tạo script `script/c32100001.lua` — Xyz monster với 4 effects:
    - Effect 0: Immunity (unaffected by non-Rikka effects)
    - Effect 1: Detach 1 → return Plant → look hand → destroy 2 (HOPT)
    - Effect 2: Negate activation + banish (Trigger/Quick)
    - Effect 3: Board wipe — detach 2 → destroy all opponent's field
    - Tất cả effects 1-3 có dual Ignition/Quick-O dựa trên Plant overlay material
    - Alt Xyz Summon: overlay trên "Teardrop the Rikka Queen" (33779875)
  - Thêm entry database vào `custom_cards_zesty.cdb` (passcode 32100001, ot=32)
  - Thêm archetype Rikka vào `feature_list.json`
- **Xác minh đã chạy:**
  - `validate_scripts.ps1` → 0 FAIL, c32100001.lua OK
  - `lint_scripts.ps1` → c32100001.lua không có issue
  - `manage_db.py check-sync` → card đồng bộ
  - `manage_db.py query 32100001` → thông tin chính xác
  - `Test-Path script\c32100001.lua` → True
- **Bằng chứng đã ghi lại:** Script, database, feature_list.json
- **Commit:** _(chưa commit — theo yêu cầu AGENTS.md)_
- **Files/artifacts đã cập nhật:** script/c32100001.lua, custom_cards_zesty.cdb, feature_list.json, claude-progress.md
- **Rủi ro đã biết:** 
  - RACE_PLANT value (0x400=1024) cần verify nếu card không load đúng trong EDOPro
  - Alt Xyz Summon cần test trong game để verify xyzfilter hoạt động đúng
- **Bước tốt nhất tiếp theo:** _(do user xác định)_

### Phiên 004 — 2026-05-30

- **Mục tiêu:** Double check script c32100001.lua, copy artwork, cập nhật tài liệu hướng dẫn setcode, sửa database card 998716 (The Grand Stage of Maliss).
- **Đã hoàn thành:**
  - Cải tiến script `script/c32100001.lua`:
    - Sửa logic target/operation của Effect 1: cho phép chọn Plant từ cả field/GY/banished của đối thủ (đúng với text "Banish/GY/Field"), và kiểm tra card được trả về hand/extra deck thành công rồi mới thực hiện look hand + destroy 2.
    - Cải tiến Effect 2a (không có Plant material) thành `EFFECT_TYPE_QUICK_O` giới hạn lượt của mình (`Duel.GetTurnPlayer()==tp`) để đúng quy tắc chain và negate activation trong YGO.
  - Copy ảnh card từ `docs/queues/Rikka/p_Teardrop_the_Rikka_Fairy.jpg` sang `pics/32100001.jpg`.
  - Cập nhật quy chuẩn tra cứu setcode cho các archetype official trong `AGENTS.md` (ràng buộc cứng #6) và `docs/agent-constants.md` chỉ định rõ file `docs/archetype_setcode_constants.lua`.
  - Sửa lỗi thiếu text hiệu ứng (str1, str2, str3) gây hiển thị `???` cho card `998716` ("The Grand Stage of Maliss") trong cơ sở dữ liệu `custom_cards_zesty.cdb`.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 0 FAIL, c32100001.lua và c998716.lua OK.
  - `python .\script-test\manage_db.py check-sync` -> đồng bộ thành công.
  - `python .\script-test\manage_db.py query 32100001` và `query 998716` -> thông tin và các strings hiệu ứng hiển thị chính xác.
- **Files/artifacts đã cập nhật:** [c32100001.lua](file:///d:/TTF/TTFCustomCards/script/c32100001.lua), [AGENTS.md](file:///d:/TTF/TTFCustomCards/AGENTS.md), [agent-constants.md](file:///d:/TTF/TTFCustomCards/docs/agent-constants.md), `pics/32100001.jpg`, [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 005 — 2026-05-30

- **Mục tiêu:** Fix lỗi hiển thị `???` thay cho lựa chọn "Add to hand" của card `998716` ("The Grand Stage of Maliss") và `22121392` ("Verre Magic: Transformation").
- **Đã hoàn thành:**
  - Sửa script `script/c998716.lua` và `script/c22121392.lua`: Thay thế system string `1190` bằng custom string tương ứng từ database (`aux.Stringid(id,3)` cho 998716 và `aux.Stringid(id,4)` cho 22121392).
  - Cập nhật database SQLite `custom_cards_zesty.cdb`: Thêm `'Add to hand'` vào `str4` cho card `998716` và `str5` cho card `22121392`.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 0 FAIL, c998716.lua và c22121392.lua OK.
  - `python .\script-test\manage_db.py check-sync` -> đồng bộ thành công (không phát sinh lỗi mới).
- **Files/artifacts đã cập nhật:** [c998716.lua](file:///d:/TTF/TTFCustomCards/script/c998716.lua), [c22121392.lua](file:///d:/TTF/TTFCustomCards/script/c22121392.lua), `custom_cards_zesty.cdb`, [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 006 — 2026-05-30

- **Mục tiêu:** Sửa lỗi hiển thị menu chọn Battle Phase / End Phase khi kích hoạt chuyển End Phase từ Main Phase của card `90178` ("Farewell Labrynth").
- **Đã hoàn thành:**
  - Cập nhật script `script/c90178.lua`: Trong hàm `s.ep_check`, thêm đăng ký hiệu ứng `EFFECT_CANNOT_BP` lên turn player (`turnp`) có reset timing `RESET_PHASE|PHASE_END` trước khi thực hiện `Duel.SkipPhase`. Việc này ngăn không cho người chơi chọn Battle Phase, giúp game tự động chuyển trực tiếp sang End Phase mà không hiển thị prompt lựa chọn.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 0 FAIL, c90178.lua OK.
  - `python .\script-test\manage_db.py check-sync` -> Hoạt động bình thường.
- **Files/artifacts đã cập nhật:** [c90178.lua](file:///d:/TTF/TTFCustomCards/script/c90178.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 007 — 2026-05-30

- **Mục tiêu:** Sửa lỗi `8 Parameters are needed` của card `c192200014` ("Castle of Dreams - Fall").
- **Đã hoàn thành:**
  - Cập nhật script `script/c192200014.lua`: Sửa cuộc gọi `Duel.SelectMatchingCard` ở dòng 107 để truyền đủ 8 tham số bằng cách thêm `1-tp` làm tham số `player_of_self_location` (để lọc từ phần bài của đối thủ).
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 0 FAIL.
  - `python .\script-test\manage_db.py check-sync` -> Hoạt động bình thường.
- **Files/artifacts đã cập nhật:** [c192200014.lua](file:///d:/TTF/TTFCustomCards/script/c192200014.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

_Thêm phiên mới theo format trên. Giữ mục "Trạng thái Hiện tại" luôn cập nhật._

