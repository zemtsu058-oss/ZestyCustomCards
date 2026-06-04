# Nhật ký Tiến độ — TTFCustomCards

## Trạng thái Hiện tại

- **Thư mục gốc:** `d:\TTF\TTFCustomCards`
- **Lệnh validate:** `.\script-test\validate_scripts.ps1`
- **Lệnh check sync:** `python .\script-test\manage_db.py check-sync`
- **Tác vụ ưu tiên tiếp theo:** Xử lý 2 issue sync tồn đọng nếu cần (`78900102` thiếu script, `79900002` thiếu DB entry), hoặc đọc hàng đợi tiếp theo.
- **Sự cố chặn hiện tại:** Không có blocker.

---

## Nhật ký Phiên

> [!NOTE]
> Để giữ file nhật ký gọn gàng và dễ theo dõi, các phiên làm việc cũ đã được chuyển vào file lưu trữ.
> [Xem lịch sử các phiên trước đó (Phiên 001 - 024) tại đây](file:///d:/TTF/TTFCustomCards/docs/claude-progress-archive.md).

### Phiên 030 — 2026-06-04

- **Mục tiêu:** Chỉnh lại card Mikanko Fire Soul (`c34100003.lua`) để hiệu ứng kích hoạt từ field không kích hoạt được trong lượt đối phương.
- **Đã hoàn thành:**
  - Sửa đổi [c34100003.lua](file:///d:/TTF/TTFCustomCards/script/c34100003.lua):
    - Đổi hiệu ứng gửi card và quái vật trang bị từ field xuống GY để Special Summon quái Mikanko (Effect 2) từ Quick Effect (`EFFECT_TYPE_QUICK_O`) sang Ignition Effect (`EFFECT_TYPE_IGNITION`).
    - Loại bỏ code không cần thiết của Quick Effect/Free Chain: `SetHintTiming` và `SetCondition(s.con_main_phase)`.
    - Xóa function `s.con_main_phase` không còn sử dụng.
    - Sửa đổi hàm `tg_summon_deck_grave` để kiểm tra `Duel.GetMZoneCount(tp, ec) > 0` thay vì `Duel.GetLocationCount(tp, LOCATION_MZONE) > 0` nhằm xử lý chính xác trường hợp sân đầy hoặc chỉ có quái thú được trang bị khi kích hoạt hiệu ứng (vì quái thú này được gửi đi làm chi phí).
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 67 OK, 29 WARN, 0 FAIL (c34100003.lua OK).
  - `python .\script-test\manage_db.py check-sync` -> Kết quả khớp với database (chỉ còn 2 issue sync cũ).
  - `.\script-test\lint_scripts.ps1 script\c34100003.lua` -> Sạch linter.
- **Files/artifacts đã cập nhật:** [c34100003.lua](file:///d:/TTF/TTFCustomCards/script/c34100003.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 029 — 2026-06-04

- **Mục tiêu:** Sửa lỗi Ohime the Curious Mikanko (`c34100001.lua`) bị mất hiệu ứng và lỗi turn lock/response protection không hoạt động.
- **Đã hoàn thành:**
  - Sửa đổi database SQLite `custom_cards_zesty.cdb`:
    - Cập nhật `setcode` của 3 card custom Mikanko (`34100001`, `34100002`, `34100003`) từ `3356984` (hex `0x333938` - do nhập sai định dạng chuỗi "398") về đúng giá trị số `398` (hex `0x18e`).
    - Việc sửa setcode giúp hệ thống nhận diện đúng Ohime và các card Mikanko custom là thuộc archetype Mikanko, giúp Ohime không tự khóa hiệu ứng của chính mình khi register `EFFECT_CANNOT_ACTIVATE` cho non-Mikanko monsters trong lượt cô ấy được Special Summon.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 67 OK, 29 WARN, 0 FAIL.
  - `python .\script-test\manage_db.py check-sync` -> Hoàn thành khớp cơ sở dữ liệu (chỉ còn 2 issue sync cũ).
- **Files/artifacts đã cập nhật:** `custom_cards_zesty.cdb`, [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 028 — 2026-06-04

- **Mục tiêu:** Sửa lỗi "effect mộ vẫn không xài được" của card Verre Magic Mastery (`c29600004.lua`).
- **Đã hoàn thành:**
  - Sửa đổi [c29600004.lua](file:///d:/TTF/TTFCustomCards/script/c29600004.lua):
    - Loại bỏ điều kiện kiểm tra turn player `and Duel.IsTurnPlayer(tp)` trong hàm `s.con_search` vì hiệu ứng hoạt động trong Main Phase của cả hai người chơi.
    - Thêm `e3:SetHintTiming(0,TIMING_MAIN_END)` cho hiệu ứng Graveyard `e3` để EDOPro hiển thị prompt kích hoạt trong open game state (chain mode AUTO).
    - Dọn dẹp khoảng trắng thừa (trailing whitespace) ở các dòng comment 7-14.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 67 OK (c29600004.lua OK), 29 WARN, 0 FAIL.
  - `.\script-test\lint_scripts.ps1` -> c29600004.lua không còn bất kỳ lỗi/cảnh báo linter nào.
  - `python .\script-test\manage_db.py check-sync` -> Đồng bộ thành công, không phát sinh lỗi đồng bộ nào mới.
- **Files/artifacts đã cập nhật:** [c29600004.lua](file:///d:/TTF/TTFCustomCards/script/c29600004.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 027 — 2026-06-03

- **Mục tiêu:** Sửa lỗi response protection và lỗi hiệu ứng turn lock của Ohime the Curious Mikanko (`c34100001.lua`).
- **Đã hoàn thành:**
  - Sửa đổi [c34100001.lua](file:///d:/TTF/TTFCustomCards/script/c34100001.lua):
    - Đổi logic target `s.tg_destroy_spell_trap` luôn trả về `true` ở `chk==0` để đảm bảo `SetChainLimit` được gọi khi kích hoạt bắt buộc (mandatory trigger) kể cả khi sân không có Spell/Trap.
    - Sửa response protection thành `Duel.SetChainLimit(aux.FALSE)` (Option B) để ngăn chặn hoàn toàn việc chain các hiệu ứng quái vật hoặc bẫy nhằm bypass khóa hoặc phủ nhận hiệu ứng.
    - Sửa lỗi function `op_monster_lock` kiểm tra sai `c:IsRelateToEffect(e)` trên hiệu ứng continuous trigger; thêm client hint bằng `aux.Stringid(id,3)`.
    - Thêm custom activity counter `chainfilter` và field restriction `EFFECT_CANNOT_SPECIAL_SUMMON` để cấm Special Summon Ohime nếu người chơi đã kích hoạt hiệu ứng quái vật non-Mikanko trong lượt; tích hợp kiểm tra này vào `s.op_overlay`.
  - Cập nhật database SQLite `custom_cards_zesty.cdb`:
    - Đổi text mô tả card cho passcode `34100001` để khớp với việc cấm kích hoạt bài/hiệu ứng trong response.
    - Đăng ký chuỗi mô tả lock `'You cannot activate non-Mikanko monster effects'` vào `str4`.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 67 OK (c34100001.lua OK không còn cảnh báo structural/relation), 29 WARN, 0 FAIL.
  - `python .\script-test\manage_db.py check-sync` -> Hoàn thành sạch sẽ, kết quả khớp hoàn toàn với cơ sở dữ liệu.
- **Files/artifacts đã cập nhật:** [c34100001.lua](file:///d:/TTF/TTFCustomCards/script/c34100001.lua), `custom_cards_zesty.cdb`, [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 026 — 2026-06-03

- **Mục tiêu:** Sửa lỗi Once Per Turn bị nhầm thành HOPT của Iris (`c192200004.lua`) và Morpheus (`c192200005.lua`).
- **Đã hoàn thành:**
  - Sửa đổi [c192200004.lua](file:///d:/TTF/TTFCustomCards/script/c192200004.lua):
    - Đổi count limit của Effect 2 (Ignition Field Spell placement) từ HOPT (`{id, 1}` với `EFFECT_COUNT_CODE_OATH`) sang SOPT (`1`).
    - Đổi count limit của Effect 3 (Quick Effect negate) từ HOPT (`{id, 2}` với `EFFECT_COUNT_CODE_OATH`) sang SOPT (`1`).
  - Sửa đổi [c192200005.lua](file:///d:/TTF/TTFCustomCards/script/c192200005.lua):
    - Xóa hoàn toàn count limit của Effect 2 (Trigger Field Spell placement on SS by own effect) do text description không có giới hạn Once Per Turn (trước đây đặt nhầm `id+1` HOPT).
    - Đổi count limit của Effect 3 (Quick Effect negate) từ HOPT (`id+2` với `EFFECT_COUNT_CODE_OATH`) sang SOPT (`1`).
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 67 OK, 29 WARN, 0 FAIL (Cả hai script sửa đổi đều OK 100% không cảnh báo).
  - `python .\script-test\manage_db.py check-sync` -> Kết quả khớp với cơ sở dữ liệu (chỉ còn 2 lỗi đồng bộ cũ có sẵn).
- **Files/artifacts đã cập nhật:** [c192200004.lua](file:///d:/TTF/TTFCustomCards/script/c192200004.lua), [c192200005.lua](file:///d:/TTF/TTFCustomCards/script/c192200005.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 025 — 2026-06-02

- **Mục tiêu:** Sửa lỗi hiệu ứng sau khi đối thủ kích hoạt effect không hoạt động cho card `c79900003.lua` ("First Day of Witch") và `c42600002.lua` ("Memory of the White Forest").
- **Đã hoàn thành:**
  - Xác định nguyên nhân: Do EDOPro engine giới hạn cơ chế đếm của `AddCustomActivityCounter` (đặc biệt khi chạy kiểm tra hoạt động cho đối thủ `1-tp` trong môi trường tự thiết lập hoặc chạy local), dẫn tới việc hàm đếm `GetCustomActivityCount` hoạt động không ổn định hoặc luôn trả về `0`.
  - Sửa đổi [c79900003.lua](file:///d:/TTF/TTFCustomCards/script/c79900003.lua) và [c42600002.lua](file:///d:/TTF/TTFCustomCards/script/c42600002.lua):
    - Loại bỏ bộ đếm `AddCustomActivityCounter` và thay thế bằng việc đăng ký một hiệu ứng continuous toàn cục lắng nghe sự kiện `EVENT_CHAINING` để tự động thiết lập flag hiệu ứng `RESET_PHASE|PHASE_END` lên người chơi kích hoạt (`rp`).
    - Kiểm tra điều kiện bằng cách so khớp flag: `Duel.GetFlagEffect(1-tp, id) > 0` để đảm bảo tính chính xác 100% khi nhận diện hoạt động của đối thủ, không phụ thuộc vào bộ đếm nội bộ của simulator.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 67 OK, 29 WARN, 0 FAIL (Cả hai script sửa đổi đều OK 100% không cảnh báo).
  - `.\script-test\lint_scripts.ps1` -> Hoàn thành sạch sẽ, không có cảnh báo/lỗi định dạng mới nào.
  - `python .\script-test\manage_db.py check-sync` -> Kết quả khớp hoàn hảo với cơ sở dữ liệu.
- **Files/artifacts đã cập nhật:** [c79900003.lua](file:///d:/TTF/TTFCustomCards/script/c79900003.lua), [c42600002.lua](file:///d:/TTF/TTFCustomCards/script/c42600002.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

_Thêm phiên mới theo format trên. Giữ mục "Trạng thái Hiện tại" luôn cập nhật._
