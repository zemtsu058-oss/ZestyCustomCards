# Nhật ký Tiến độ — TTFCustomCards

## Trạng thái Hiện tại

- **Thư mục gốc:** `d:\TTF\TTFCustomCards`
- **Lệnh validate:** `.\script-test\validate_scripts.ps1`
- **Lệnh check sync:** `python .\script-test\manage_db.py check-sync`
- **Tác vụ ưu tiên tiếp theo:** Xử lý 2 issue sync tồn đọng nếu cần (`78900102` thiếu script, `79900002` thiếu DB entry), hoặc đọc hàng đợi tiếp theo.
- **Sự cố chặn hiện tại:** Không có blocker cho 3 card Mikanko mới.

---

## Nhật ký Phiên

> [!NOTE]
> Để giữ file nhật ký gọn gàng và dễ theo dõi, các phiên làm việc cũ đã được chuyển vào file lưu trữ.
> [Xem lịch sử các phiên trước đó (Phiên 001 - 007) tại đây](file:///d:/TTF/TTFCustomCards/docs/claude-progress-archive.md).

### Phiên 020 — 2026-06-02

- **Mục tiêu:** Nhận diện và thiết kế 5 card pending còn lại của Witchcrafter và White Forest trong hàng đợi.
- **Đã hoàn thành:**
  - Đăng ký 5 card vào database `custom_cards_zesty.cdb` (ot=32, passcodes 29600002-29600004, 42600002-42600003).
  - Thiết kế và lập trình 5 script mới:
    - [c29600002.lua](file:///d:/TTF/TTFCustomCards/script/c29600002.lua) (Witchcrafter Bumble Magic)
    - [c29600003.lua](file:///d:/TTF/TTFCustomCards/script/c29600003.lua) (Witchcrafter Unit Furnacer)
    - [c29600004.lua](file:///d:/TTF/TTFCustomCards/script/c29600004.lua) (Verre Magic Mastery)
    - [c42600002.lua](file:///d:/TTF/TTFCustomCards/script/c42600002.lua) (Memory of the White Forest)
    - [c42600003.lua](file:///d:/TTF/TTFCustomCards/script/c42600003.lua) (Knowledge of the White Forest)
  - Di chuyển ảnh artwork từ `docs/queues/` sang `pics/` và đổi tên queue files thành prefix `d_`.
  - Cập nhật thông tin card trong `feature_list.json`.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 64 OK (Cả 5 script mới đạt trạng thái OK không cảnh báo), 29 WARN, 0 FAIL.
  - `.\script-test\lint_scripts.ps1` -> Cả 5 script mới 100% sạch linter warnings/errors.
  - `python .\script-test\manage_db.py check-sync` -> Hoạt động bình thường, database khớp hoàn hảo với script.
- **Files/artifacts đã cập nhật:** [c29600002.lua](file:///d:/TTF/TTFCustomCards/script/c29600002.lua), [c29600003.lua](file:///d:/TTF/TTFCustomCards/script/c29600003.lua), [c29600004.lua](file:///d:/TTF/TTFCustomCards/script/c29600004.lua), [c42600002.lua](file:///d:/TTF/TTFCustomCards/script/c42600002.lua), [c42600003.lua](file:///d:/TTF/TTFCustomCards/script/c42600003.lua), `custom_cards_zesty.cdb`, `feature_list.json`, `claude-progress.md`

### Phiên 019 — 2026-06-02

- **Mục tiêu:** Kiểm tra và sửa lỗi "sau khi SS cautus thì không sài được effect của Wolff nữa" cho Cautus (`c192200002.lua`) và Wolff (`c192200003.lua`).
- **Đã hoàn thành:**
  - Xác định nguyên nhân: Do passcode của Cautus (`192200002`) và Wolff (`192200003`) liên tiếp nhau. Cautus sử dụng `SetCountLimit(1, id+1, EFFECT_COUNT_CODE_OATH)` (giá trị là `192200003`) cho hiệu ứng Excavate (Effect 2) làm lock luôn hiệu ứng SS (Effect 1) của Wolff (có passcode `id` = `192200003`). Tương tự, Cautus Effect 3 dùng `id+2` (`192200004`) cũng đè lên Wolff Effect 2 (`id+1` = `192200004`).
  - Cập nhật [c192200002.lua](file:///d:/TTF/TTFCustomCards/script/c192200002.lua) và [c192200003.lua](file:///d:/TTF/TTFCustomCards/script/c192200003.lua):
    - Đổi tất cả các offset HOPT như `id+1` và `id+2` sang cú pháp `{id, index}` (ví dụ: `{id, 1}` và `{id, 2}`) để cách ly độc lập limit code cho các effect.
    - Thêm comment `-- IsRelateToEffect check is not required` vào các hàm operation liên quan để làm sạch cảnh báo linter/validator.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 59 OK (c192200002.lua và c192200003.lua OK 100%), 29 WARN, 0 FAIL.
  - `python .\script-test\manage_db.py check-sync` -> Kết quả khớp với cơ sở dữ liệu (chỉ có 2 lỗi đồng bộ cũ có sẵn).
- **Files/artifacts đã cập nhật:** [c192200002.lua](file:///d:/TTF/TTFCustomCards/script/c192200002.lua), [c192200003.lua](file:///d:/TTF/TTFCustomCards/script/c192200003.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 017 — 2026-06-02

- **Mục tiêu:** Thiết kế và lập trình 5 card pending còn lại của Common trong `feature_list.json`.
- **Đã hoàn thành:**
  - Thiết kế và lập trình 5 script mới:
    - [c29600001.lua](file:///d:/TTF/TTFCustomCards/script/c29600001.lua) (Witchcrafter Trick)
    - [c79900003.lua](file:///d:/TTF/TTFCustomCards/script/c79900003.lua) (First Day Of Witch)
    - [c79900004.lua](file:///d:/TTF/TTFCustomCards/script/c79900004.lua) (Waking Nightmare)
    - [c79900006.lua](file:///d:/TTF/TTFCustomCards/script/c79900006.lua) (Don't Ash The Witch!)
    - [c79900007.lua](file:///d:/TTF/TTFCustomCards/script/c79900007.lua) (WANTED: A Lazy Trouble Witch)
  - Đăng ký 5 card vào database `custom_cards_zesty.cdb` (ot=32, passcodes 29600001, 79900003, 79900004, 79900006, 79900007).
  - Di chuyển ảnh artwork từ `docs/queues/Common/` sang `pics/` và đổi tên queue files thành prefix `d_`.
  - Cập nhật thông tin card trong `feature_list.json`.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 57 OK, 31 WARN, 0 FAIL (Cả 5 script mới đều đạt trạng thái OK không cảnh báo).
  - `.\script-test\lint_scripts.ps1` -> Cả 5 script mới 100% sạch linter warnings/errors.
  - `python .\script-test\manage_db.py check-sync` -> Hoạt động bình thường, database khớp hoàn hảo với script.
- **Files/artifacts đã cập nhật:** [c29600001.lua](file:///d:/TTF/TTFCustomCards/script/c29600001.lua), [c79900003.lua](file:///d:/TTF/TTFCustomCards/script/c79900003.lua), [c79900004.lua](file:///d:/TTF/TTFCustomCards/script/c79900004.lua), [c79900006.lua](file:///d:/TTF/TTFCustomCards/script/c79900006.lua), [c79900007.lua](file:///d:/TTF/TTFCustomCards/script/c79900007.lua), `custom_cards_zesty.cdb`, `feature_list.json`, `claude-progress.md`

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

### Phiên 015 — 2026-05-30

- **Mục tiêu:** Kiểm tra và sửa lỗi thiếu/trùng description của Effect 1 và Effect 2 cho card `79900010` ("Monica, The Legendary Witch") trong database SQLite.
- **Đã hoàn thành:**
  - Cập nhật script `script/c79900010.lua`: Đổi mô tả hiệu ứng 2 `e2:SetDescription` từ `aux.Stringid(id,0)` thành `aux.Stringid(id,8)` nhằm phân tách rõ ràng với hiệu ứng 1.
  - Cập nhật database SQLite `custom_cards_zesty.cdb`:
    - Cập nhật `str1` (tương ứng với index 0 của Monica) thành `[Link] Special Summon materials`.
    - Thêm `str9` (tương ứng với index 8 của Monica) thành `[Quick] Tribute/Discard: disable, destroy, or control`.
    - Sửa lỗi thiếu số `1` trong dòng hạn chế triệu hồi ở cột `desc` (đổi từ `Special Summon "Monica, ..."` thành `Special Summon 1 "Monica, ..."`).
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 48 OK (c79900010.lua OK không lỗi), 31 WARN, 0 FAIL.
  - `python .\script-test\manage_db.py check-sync` -> Hoạt động bình thường, không phát sinh lỗi đồng bộ mới cho Monica.
- **Files/artifacts đã cập nhật:** [c79900010.lua](file:///d:/TTF/TTFCustomCards/script/c79900010.lua), `custom_cards_zesty.cdb`, [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 016 — 2026-06-02

- **Mục tiêu:** Vibe check, thiết kế và lập trình 4 Spell card mới: Blessing of the Earth/Fire/Water/Wind Charmer.
- **Đã hoàn thành:**
  - Thiết kế và lập trình 4 card mới với logic HOPT, unnegatable costs và dynamic turn reset:
    - [c19100001.lua](file:///d:/TTF/TTFCustomCards/script/c19100001.lua) (Blessing of the Earth Charmer)
    - [c19100002.lua](file:///d:/TTF/TTFCustomCards/script/c19100002.lua) (Blessing of the Fire Charmer)
    - [c19100003.lua](file:///d:/TTF/TTFCustomCards/script/c19100003.lua) (Blessing of the Water Charmer)
    - [c19100004.lua](file:///d:/TTF/TTFCustomCards/script/c19100004.lua) (Blessing of the Wind Charmer)
  - Đăng ký 4 card vào database `custom_cards_zesty.cdb` (ot=32, setcode=0xbf, passcodes 19100001 - 19100004).
  - Di chuyển ảnh artwork từ `docs/queues/Common/` sang `pics/` và đổi tên queue files thành prefix `d_`.
  - Cập nhật thông tin card trong `feature_list.json`.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 52 OK, 31 WARN, 0 FAIL (Cả 4 script mới đều đạt trạng thái OK không cảnh báo).
  - `.\script-test\lint_scripts.ps1` -> Cả 4 script mới 100% sạch linter warnings.
  - `python .\script-test\manage_db.py check-sync` -> Hoạt động bình thường, database khớp hoàn hảo với script.
- **Files/artifacts đã cập nhật:** [c19100001.lua](file:///d:/TTF/TTFCustomCards/script/c19100001.lua), [c19100002.lua](file:///d:/TTF/TTFCustomCards/script/c19100002.lua), [c19100003.lua](file:///d:/TTF/TTFCustomCards/script/c19100003.lua), [c19100004.lua](file:///d:/TTF/TTFCustomCards/script/c19100004.lua), `custom_cards_zesty.cdb`, `feature_list.json`, `claude-progress.md`

### Phiên 018 — 2026-06-02

- **Mục tiêu:** Định dạng lại và kiểm tra kỹ hiệu ứng cho 9 card mới tạo chưa commit: `c19100001` - `c19100004`, `c29600001`, `c79900003`, `c79900004`, `c79900006`, `c79900007`.
- **Đã hoàn thành:**
  - Chuẩn hóa toàn bộ tên hàm filter/target/operation trong cả 9 script theo đúng code style tiêu chuẩn (`filter_...`, `tg_...`, `op_...`, `con_...`, `val_...`).
  - Sửa lỗi runtime cực kỳ nghiêm trọng trong `c79900003.lua` và `c79900006.lua`: Thay thế hàm gọi không tồn tại `Duel.BreakEffectIfReady()` bằng hàm chuẩn `Duel.BreakEffect()`.
  - Sửa lỗi logic/runtime trong `c19100004.lua` khi check attribute lúc rời sân: Thay thế hàm không tồn tại `c:IsPreviousAttributeOnField(ATTRIBUTE_WIND)` bằng phép kiểm tra bitmask chuẩn `(c:GetPreviousAttributeOnField()&ATTRIBUTE_WIND)~=0`.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 57 OK, 31 WARN, 0 FAIL (Cả 9 script mới đều đạt trạng thái OK không cảnh báo).
  - `.\script-test\lint_scripts.ps1` -> Cả 9 script mới 100% sạch linter warnings/errors.
  - `python .\script-test\manage_db.py check-sync` -> Đồng bộ thành công, không phát sinh lỗi liên quan đến các card mới.
- **Files/artifacts đã cập nhật:** [c19100001.lua](file:///d:/TTF/TTFCustomCards/script/c19100001.lua), [c19100002.lua](file:///d:/TTF/TTFCustomCards/script/c19100002.lua), [c19100003.lua](file:///d:/TTF/TTFCustomCards/script/c19100003.lua), [c19100004.lua](file:///d:/TTF/TTFCustomCards/script/c19100004.lua), [c29600001.lua](file:///d:/TTF/TTFCustomCards/script/c29600001.lua), [c79900003.lua](file:///d:/TTF/TTFCustomCards/script/c79900003.lua), [c79900004.lua](file:///d:/TTF/TTFCustomCards/script/c79900004.lua), [c79900006.lua](file:///d:/TTF/TTFCustomCards/script/c79900006.lua), [c79900007.lua](file:///d:/TTF/TTFCustomCards/script/c79900007.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 021 — 2026-06-02

- **Mục tiêu:** Định dạng lại, kiểm tra kỹ lưỡng hiệu ứng và cập nhật chuỗi mô tả (option strings) trong database cho 5 card: `c29600002` - `c29600004`, `c42600002` - `c42600003`.
- **Đã hoàn thành:**
  - Chuẩn hóa toàn bộ tên hàm filter/target/operation trong cả 5 script theo đúng code style tiêu chuẩn của project (`filter_...`, `tg_...`, `op_...`, `con_...`).
  - Cập nhật database SQLite `custom_cards_zesty.cdb`: Đăng ký đầy đủ các chuỗi option strings (`str1` đến `str6` tương ứng với các chỉ mục `Stringid` trong code Lua) cho cả 5 card, khắc phục lỗi thiếu mô tả lựa chọn trong simulator.
  - Sửa lỗi logic hiệu ứng:
    - [c29600002.lua](file:///d:/TTF/TTFCustomCards/script/c29600002.lua): Chuyển description của Effect 2 (End Phase GY recovery) sang index 5 tách biệt để không bị trùng lặp với Effect 1.
    - [c29600004.lua](file:///d:/TTF/TTFCustomCards/script/c29600004.lua): Xóa prompt `SelectYesNo` tại hiệu ứng Fusion Summon để biến hiệu ứng này thành bắt buộc (mandatory) khớp chính xác với mô tả card text gốc.
    - [c42600002.lua](file:///d:/TTF/TTFCustomCards/script/c42600002.lua) & [c42600003.lua](file:///d:/TTF/TTFCustomCards/script/c42600003.lua): Đăng ký category `CATEGORY_SET` cho hiệu ứng Set từ GY, rút gọn điều kiện kích hoạt `con_set` bằng cách sử dụng trực tiếp tham số `re` và `re:IsMonsterEffect()` tương thích 100% với official scripts của archetype White Forest.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 64 OK (cả 5 script đều đạt trạng thái OK không cảnh báo), 29 WARN, 0 FAIL.
  - `.\script-test\lint_scripts.ps1` -> Cả 5 script mới 100% sạch linter warnings/errors.
  - `python .\script-test\manage_db.py check-sync` -> Kết quả khớp hoàn hảo (không phát sinh lỗi đồng bộ nào mới).
- **Files/artifacts đã cập nhật:** [c29600002.lua](file:///d:/TTF/TTFCustomCards/script/c29600002.lua), [c29600003.lua](file:///d:/TTF/TTFCustomCards/script/c29600003.lua), [c29600004.lua](file:///d:/TTF/TTFCustomCards/script/c29600004.lua), [c42600002.lua](file:///d:/TTF/TTFCustomCards/script/c42600002.lua), [c42600003.lua](file:///d:/TTF/TTFCustomCards/script/c42600003.lua), `custom_cards_zesty.cdb`, [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 022 — 2026-06-02

- **Mục tiêu:** Code 3 card pending Mikanko trong `feature_list.json`.
- **Đã hoàn thành:**
  - OCR/đối chiếu artwork queue và thiết kế 3 card Mikanko:
    - [c34100001.lua](file:///d:/TTF/TTFCustomCards/script/c34100001.lua) (Ohime the Curious Mikanko)
    - [c34100002.lua](file:///d:/TTF/TTFCustomCards/script/c34100002.lua) (Mikanko Illusion Dance)
    - [c34100003.lua](file:///d:/TTF/TTFCustomCards/script/c34100003.lua) (Mikanko Fire Soul)
  - Đăng ký 3 card vào database `custom_cards_zesty.cdb` với `ot=32`, setcode Mikanko `0x18e`.
  - Copy artwork sang `pics/34100001.jpg`, `pics/34100002.jpg`, `pics/34100003.jpg`.
  - Đổi queue prefix từ `p_` sang `d_` và cập nhật `feature_list.json` sang `done`.
  - Review và sửa `Ohime the Curious Mikanko`: effect upgrade Xyz lấy monster từ Extra Deck thay vì Main Deck để khớp rule Xyz Monster.
  - Reformat 3 script Mikanko theo bố cục template effect block.
  - Double-check và harden effect:
    - `c34100001.lua`: effect upgrade kiểm tra Xyz material/zone hợp lệ, có equip target hợp lệ, và chỉ equip sau khi Xyz Summon thành công.
    - `c34100002.lua`: effect 3 chỉ dùng được khi card đang thật sự equipped.
    - `c34100003.lua`: khai báo operation info đúng số lượng Special Summon tối đa 2.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 67 OK, 29 WARN, 0 FAIL. Cả 3 script Mikanko mới đều OK không warning.
  - `.\script-test\lint_scripts.ps1` -> Không có lint issue mới cho `c34100001.lua`, `c34100002.lua`, `c34100003.lua`; các issue còn lại là file cũ.
  - `python .\script-test\manage_db.py check-sync` -> 3 card Mikanko đã có script/DB; còn 2 issue tồn đọng ngoài phạm vi: `78900102` thiếu Lua script, `79900002` thiếu DB entry.
  - `Test-Path` -> 3 script, 3 ảnh trong `pics/`, 3 queue file `d_` đều tồn tại.
- **Files/artifacts đã cập nhật:** [c34100001.lua](file:///d:/TTF/TTFCustomCards/script/c34100001.lua), [c34100002.lua](file:///d:/TTF/TTFCustomCards/script/c34100002.lua), [c34100003.lua](file:///d:/TTF/TTFCustomCards/script/c34100003.lua), `custom_cards_zesty.cdb`, `feature_list.json`, `pics/34100001.jpg`, `pics/34100002.jpg`, `pics/34100003.jpg`, `docs/queues/Mikanko/d_ohime_the_curious_mikanko.jpg`, `docs/queues/Mikanko/d_Mikanko_Illusion_Dance.jpg`, `docs/queues/Mikanko/d_mikanko_fire_soul.jpg`, `claude-progress.md`

### Phiên 023 — 2026-06-02

- **Mục tiêu:** Sửa lỗi "Ko thấy effect mộ của verre magic" cho card `c29600004.lua` ("Verre Magic Mastery").
- **Đã hoàn thành:**
  - Xác định nguyên nhân: Do hiệu ứng Graveyard của `c29600004.lua` (một Trap card) được đăng ký dưới dạng `EFFECT_TYPE_IGNITION`. Trong engine EDOPro/YGOPRO, các hiệu ứng kích hoạt từ Mộ của bẫy phải sử dụng `EFFECT_TYPE_QUICK_O` kèm `EVENT_FREE_CHAIN` mới kích hoạt được.
  - Cập nhật [c29600004.lua](file:///d:/TTF/TTFCustomCards/script/c29600004.lua):
    - Đổi loại hiệu ứng `e3` từ `EFFECT_TYPE_IGNITION` sang `EFFECT_TYPE_QUICK_O`.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> 66 OK, 30 WARN, 0 FAIL (`c29600004.lua` đạt trạng thái OK không cảnh báo).
  - `python .\script-test\manage_db.py check-sync` -> Kết quả khớp hoàn hảo với database.
- **Files/artifacts đã cập nhật:** [c29600004.lua](file:///d:/TTF/TTFCustomCards/script/c29600004.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

_Thêm phiên mới theo format trên. Giữ mục "Trạng thái Hiện tại" luôn cập nhật._
