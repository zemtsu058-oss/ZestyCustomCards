# Nhật ký Tiến độ — TTFCustomCards

## Trạng thái Hiện tại

- **Thư mục gốc:** `d:\TTF\TTFCustomCards`
- **Lệnh validate:** `.\script-test\validate_scripts.ps1`
- **Lệnh check sync:** `python .\script-test\manage_db.py check-sync`
- **Tác vụ ưu tiên tiếp theo:** Thiết kế hoặc sửa lỗi các card tiếp theo trong hàng đợi (Common/queues/ hoặc do user yêu cầu)
- **Sự cố chặn hiện tại:** Không có

---

## Nhật ký Phiên

> [!NOTE]
> Để giữ file nhật ký gọn gàng và dễ theo dõi, các phiên làm việc cũ đã được chuyển vào file lưu trữ.
> [Xem lịch sử các phiên trước đó (Phiên 001 - 007) tại đây](file:///d:/TTF/TTFCustomCards/docs/claude-progress-archive.md).

### Phiên 008 — 2026-05-30

- **Mục tiêu:** Sửa hiệu ứng 1 của card `79900010` ("Monica, The Legendary Witch") để cho phép Special Summon nguyên liệu lên sân đối thủ ở những zone mà card này chỉ tới.
- **Đã hoàn thành:**
  - Cập nhật script `script/c79900010.lua`:
    - Thay đổi bộ lọc `s.lkfilter` để kiểm tra khả năng Special Summon của card nguyên liệu lên sân của cả người chơi (`tp`) và đối thủ (`1-tp`) trong các zone tương ứng được liên kết.
    - Cập nhật hàm target `s.lktg` để kiểm tra sự tồn tại của bất kỳ nguyên liệu nào có thể Special Summon được lên một trong hai phần sân.
    - Tái cấu trúc hàm operation `s.lkop`: Triệu hồi từng nguyên liệu một (step-by-step) bằng `Duel.SpecialSummonStep`. Nếu một nguyên liệu có thể triệu hồi lên cả hai sân, hiển thị prompt cho phép người chơi chọn sân đích (`tp` hoặc `1-tp`). Hoàn tất chuỗi triệu hồi bằng `Duel.SpecialSummonComplete()`.
  - Cập nhật database SQLite `custom_cards_zesty.cdb`: Thêm các chuỗi mô tả lựa chọn sân đích vào `str7` ("Special Summon to your field") và `str8` ("Special Summon to opponent's field") cho card `79900010`.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 0 FAIL, c79900010.lua OK.
  - `.\script-test\lint_scripts.ps1` -> c79900010.lua không có lỗi linter/whitespaces.
  - `python .\script-test\manage_db.py check-sync` -> Đồng bộ thành công, không phát sinh lỗi liên quan đến Monica.
- **Files/artifacts đã cập nhật:** [c79900010.lua](file:///d:/TTF/TTFCustomCards/script/c79900010.lua), `custom_cards_zesty.cdb`, [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 009 — 2026-05-30

- **Mục tiêu:** Tạo card mới "Maliss of the Fallen Game" (Normal Spell, archetype Maliss 0x1b9)
- **Đã hoàn thành:**
  - Tạo script `script/c44100001.lua` — Normal Spell với effect:
    - Cost: Pay half LP
    - Banish all cards in your GY, count Maliss cards banished
    - For every 2 Maliss cards banished, randomly banish 1 card from opponent's Extra Deck until End Phase
    - Banished opponent's cards cannot activate effects until End Phase
    - HOPT (hard once per turn)
    - At End Phase: return banished Extra Deck cards via `Duel.SendtoDeck`
  - Thêm entry database vào `custom_cards_zesty.cdb` (passcode 44100001, ot=32, setcode=441=0x1b9)
  - Copy artwork từ `docs/queues/Maliss/p_Maliss_Of_The_Fallen_Game.png` sang `pics/44100001.png`
- **Xác minh đã chạy:**
  - `validate_scripts.ps1` → 0 FAIL, c44100001.lua OK (chỉ còn 1 cảnh báo cấu trúc nhỏ không ảnh hưởng).
  - `lint_scripts.ps1` → c44100001.lua không có lint issue.
  - `manage_db.py check-sync` → Đồng bộ (chỉ có lỗi cũ pre-existing).
  - `Test-Path script\c44100001.lua` → True.
- **Files/artifacts đã cập nhật:** [c44100001.lua](file:///d:/TTF/TTFCustomCards/script/c44100001.lua), `custom_cards_zesty.cdb`, `pics/44100001.png`, [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)
- **Rủi ro đã biết:**
  - `Duel.SendtoDeck` trả card về Extra Deck — cần test in-game xem card có trở về đúng vị trí Extra Deck không.
  - Các hiệu ứng đơn lẻ `EFFECT_CANNOT_TRIGGER` đăng ký trực tiếp lên từng card bị banish — cần test in-game xem hệ thống có tự động giải phóng/chặn đúng yêu cầu không.

### Phiên 010 — 2026-05-30

- **Mục tiêu:** Thiết kế và code card mới "Elaina, The Wandering Witch" (LIGHT Spellcaster Link-1, ATK 1000)
- **Đã hoàn thành:**
  - Tạo script `script/c79900001.lua` với 2 hiệu ứng:
    - Hiệu ứng 1: Discard 1 Spell Card -> Chọn số N từ 1 đến 10 để excavate. Nếu có ít nhất 2 Spell Cards, đối thủ chọn 2, ta add 1 vào tay và gửi 1 xuống GY. Các card còn lại shuffle về Deck.
    - Hiệu ứng 2: End Phase optional trigger trả Elaina từ field/GY về Extra Deck (HOPT).
  - Đăng ký card vào cơ sở dữ liệu `custom_cards_zesty.cdb` (passcode 79900001, link marker Bottom = 2, ot=32).
  - Di chuyển artwork từ `docs/queues/Common/p_Elaina_The_Wandering_Witch.jpg` sang `pics/79900001.jpg`.
  - Đổi tên file trong hàng đợi sang prefix `d_` (`d_Elaina_The_Wandering_Witch.jpg`).
  - Thêm Elaina vào `feature_list.json` dưới mục `"Common"`.
  - Đổi tên file artwork queue của "Maliss of the Fallen Game" sang `d_Maliss_Of_The_Fallen_Game.png` và đăng ký archetype `"Maliss"` cùng card này vào `feature_list.json` (status: `"done"`).
- **Xác minh đã chạy:**
  - Chạy `.\script-test\validate_scripts.ps1` -> c79900001.lua OK (1 OK, 0 WARN, 0 FAIL).
  - Chạy `.\script-test\lint_scripts.ps1` -> Không có lỗi style cho c79900001.lua.
  - Chạy `python .\script-test\manage_db.py check-sync` -> c79900001.lua đã đồng bộ 100% với database.
- **Files/artifacts đã cập nhật:** [c79900001.lua](file:///d:/TTF/TTFCustomCards/script/c79900001.lua), `custom_cards_zesty.cdb`, `feature_list.json`, `pics/79900001.jpg`, `docs/queues/Common/d_Elaina_The_Wandering_Witch.jpg`, `docs/queues/Maliss/d_Maliss_Of_The_Fallen_Game.png`, [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 011 — 2026-05-30

- **Mục tiêu:** Thiết kế và code card mới "Power of the Dominators" (Normal Trap, archetype Dominus 0x1bf)
- **Đã hoàn thành:**
  - Tạo script `script/c44700001.lua` — Normal Trap với các hiệu ứng:
    - Kích hoạt từ tay khi không có monster trong GY.
    - Negate kích hoạt hiệu ứng trong GY/banishment của đối thủ hoặc hiệu ứng di chuyển card từ GY/banishment của đối thủ đi nơi khác.
    - Nếu có Trap trong GY, cho phép add 1 card "Dominus" từ Deck lên tay (optional search).
    - Phạt khi kích hoạt từ tay: Không được Special Summon từ tay, GY, banishment cho đến hết lượt sau.
    - HOPT trên kích hoạt.
  - Thêm entry database vào `custom_cards_zesty.cdb` (passcode 44700001, ot=32, setcode=447=0x1bf)
  - Copy artwork từ `docs/queues/Common/p_Power_of_the_Dominators.jpg` sang `pics/44700001.jpg`
  - Đổi tên file artwork queue sang `d_Power_of_the_Dominators.jpg`
  - Cập nhật card này vào `feature_list.json` dưới mục `"Common"` (status: `"done"`)
- **Xác minh đã chạy:**
  - `validate_scripts.ps1` → c44700001.lua OK (chỉ có warning cấu trúc không ảnh hưởng).
  - `lint_scripts.ps1` → c44700001.lua không có lint issue nào.
  - `manage_db.py check-sync` → Đồng bộ hoàn chỉnh (chỉ có lỗi cũ pre-existing).
- **Files/artifacts đã cập nhật:** [c44700001.lua](file:///d:/TTF/TTFCustomCards/script/c44700001.lua), `custom_cards_zesty.cdb`, `feature_list.json`, `pics/44700001.jpg`, `docs/queues/Common/d_Power_of_the_Dominators.jpg`, [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 012 — 2026-05-30

- **Mục tiêu:** Định dạng lại và kiểm tra kỹ lượng 3 file script: `c44100001.lua`, `c44700001.lua`, `c79900001.lua`.
- **Đã hoàn thành:**
  - Chuyển đổi toàn bộ thụt đầu dòng (indentation) từ tabs sang 4 spaces để khớp với code style tiêu chuẩn của project.
  - Sửa các cảnh báo cấu trúc (validator warnings) trong `c44100001.lua` (thêm kiểm tra `IsRelateToEffect` trong hàm operation của Normal Spell).
  - Tối ưu hóa logic trả card về Extra Deck ở End Phase của `c44100001.lua` bằng cách sử dụng một continuous field effect duy nhất quản lý Group các card đã banish (`KeepAlive` và `DeleteGroup`), thay vì đăng ký riêng lẻ nhiều effect độc lập. Điều này giúp các card trở về Extra Deck đồng thời cùng lúc theo đúng cơ chế luật OCG/TCG.
  - Sửa các cảnh báo cấu trúc và linter warnings trong `c44700001.lua` (thêm comment bypass `chk==0` cho `splimit` target, thêm comment bypass `IsRelateToEffect` cho Normal Trap, tách dòng quá dài trên 120 ký tự).
- **Xác minh đã chạy:**
  - `validate_scripts.ps1` → Cả 3 file `c44100001.lua`, `c44700001.lua`, `c79900001.lua` đều đạt trạng thái `[ ] OK` không còn bất kỳ cảnh báo/lỗi nào.
  - `lint_scripts.ps1` → Cả 3 file đều 100% sạch linter warnings (không có lỗi độ dài dòng hay khoảng trắng thừa).
  - `manage_db.py check-sync` → Không phát sinh lỗi đồng bộ nào mới.
- **Files/artifacts đã cập nhật:** [c44100001.lua](file:///d:/TTF/TTFCustomCards/script/c44100001.lua), [c44700001.lua](file:///d:/TTF/TTFCustomCards/script/c44700001.lua), [c79900001.lua](file:///d:/TTF/TTFCustomCards/script/c79900001.lua), [README.md](file:///d:/TTF/TTFCustomCards/README.md), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 013 — 2026-05-30

- **Mục tiêu:** Sửa lỗi runtime `IsExists` trong script `c44700001.lua` ("Power of the Dominators").
- **Đã hoàn thành:**
  - Sửa hàm condition `s.negcon` tại dòng 59 trong `script/c44700001.lua`: Cung cấp tham số `1, nil` (count và exception) đầy đủ cho hàm `tg:IsExists` để tương thích với signature API C++ của EDOPro/YGOPRO (`Group.IsExists` yêu cầu tối thiểu 4 tham số bao gồm cả `self` implicit).
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 48 OK, 31 WARN, 0 FAIL.
  - `python .\script-test\manage_db.py check-sync` -> Hoạt động bình thường, không phát sinh lỗi liên quan đến c44700001.lua.
- **Files/artifacts đã cập nhật:** [c44700001.lua](file:///d:/TTF/TTFCustomCards/script/c44700001.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 014 — 2026-05-30

- **Mục tiêu:** Sửa lỗi kích hoạt sai của "Power of the Dominators" (`c44700001.lua`) khi đối thủ kích hoạt hiệu ứng trên sân (như Witchcrafter Genni triệu hồi từ Deck) mà không liên quan đến GY/banishment.
- **Đã hoàn thành:**
  - Sửa hàm condition `s.negcon` trong `script/c44700001.lua`:
    - Thay thế kiểm tra category sơ sài (Check 3 cũ) bằng cơ chế kiểm tra `GetOperationInfo` chi tiết tương tự như lá bài Ghost Belle & Haunted Mansion, áp dụng cho cả `LOCATION_GRAVE` và `LOCATION_REMOVED` của đối thủ (`1-tp`).
    - Lọc kiểm tra chi tiết trên 8 categories di chuyển card tiêu chuẩn: `TOHAND`, `TODECK`, `TOEXTRA`, `SPECIAL_SUMMON`, `REMOVE`, `TOGRAVE`, `EQUIP`, và `LEAVE_GRAVE`.
    - Loại bỏ các categories/constants không chuẩn là `CATEGORY_GRAVE_SPSUMMON` và `CATEGORY_GRAVE_ACTION` để loại bỏ hoàn toàn cảnh báo (warnings) của linter/validator.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 48 OK (c44700001.lua OK không còn cảnh báo nào), 31 WARN, 0 FAIL.
  - `python .\script-test\manage_db.py check-sync` -> Thành công, không có lỗi đồng bộ mới.
- **Files/artifacts đã cập nhật:** [c44700001.lua](file:///d:/TTF/TTFCustomCards/script/c44700001.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

_Thêm phiên mới theo format trên. Giữ mục "Trạng thái Hiện tại" luôn cập nhật._
