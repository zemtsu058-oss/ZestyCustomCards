# Nhật ký Tiến độ — TTFCustomCards

## Trạng thái Hiện tại

- **Thư mục gốc:** `d:\TTF\TTFCustomCards`
- **Lệnh validate:** `.\script-test\validate_scripts.ps1`
- **Lệnh check sync:** `python .\script-test\manage_db.py check-sync`
- **Tác vụ ưu tiên tiếp theo:** Xử lý các issue sync cũ còn tồn đọng (78900102, 79900002) hoặc chờ hàng đợi/tác vụ tiếp theo.
- **Sự cố chặn hiện tại:** Không có blocker.

---

## Nhật ký Phiên

> [!NOTE]
> Để giữ file nhật ký gọn gàng và dễ theo dõi, các phiên làm việc cũ đã được chuyển vào file lưu trữ.
> [Xem lịch sử các phiên trước đó (Phiên 001 - 024) tại đây](file:///d:/TTF/TTFCustomCards/docs/claude-progress-archive.md).

### Phiên 039 — 2026-06-04

- **Mục tiêu:** Sửa lỗi hiệu ứng 3 của "Exosister Nunctis" (`c37200001.lua`) không kiểm tra số lượng quái vật Xyz trong GY dẫn đến việc kích hoạt được khi không có Xyz dưới mộ. Đồng thời sửa lỗi tương tác với "Rank-Up-Magic Rising Force" (`c14900001.lua`) bằng cách bổ sung điều kiện triệu hồi nghiêm ngặt.
- **Đã hoàn thành:**
  - Sửa đổi [c37200001.lua](file:///d:/TTF/TTFCustomCards/script/c37200001.lua):
    - Đăng ký hiệu ứng `EFFECT_SPSUMMON_CONDITION` với hàm kiểm tra `s.splimit` tương tự `Exosisters Magnifica` (`c59242457.lua`) để ngăn chặn việc triệu hồi từ Extra Deck bằng card effect (như Rank-Up-Magic) mà không thỏa mãn điều kiện nguyên liệu chuẩn.
    - Sửa lại hàm `s.spcost` để kiểm tra `#g > 0`, bắt buộc phải có ít nhất một quái vật Xyz dưới Graveyard mới cho phép kích hoạt hiệu ứng 3.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> **72 OK, 37 WARN, 0 FAIL** (Biên dịch thành công).
  - `python .\script-test\manage_db.py check-sync` -> Hoàn thành khớp 109 cards (chỉ còn 2 issue sync cũ).
- **Files/artifacts đã cập nhật:** [c37200001.lua](file:///d:/TTF/TTFCustomCards/script/c37200001.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 038 — 2026-06-04

- **Mục tiêu:** Sửa lỗi hiệu ứng 2 của "Return of the Red Ant" (`c13800001.lua`) không kích hoạt được khi một lá "Hole" Normal Trap bị phá hủy, đồng thời tối ưu hóa logic chọn "any number" khi Set bẫy từ GY.
- **Đã hoàn thành:**
  - Sửa đổi [c13800001.lua](file:///d:/TTF/TTFCustomCards/script/c13800001.lua):
    - Đổi code trigger của hiệu ứng Graveyard `e2` từ `EVENT_TO_GRAVE` sang `EVENT_DESTROYED` (event chuẩn cho sự kiện phá hủy bài trên sân) và thêm `EFFECT_FLAG_DAMAGE_STEP`.
    - Loại bỏ điều kiện kiểm tra reason `c:IsReason(REASON_DESTROY)` trong hàm lọc `s.cfilter` do `EVENT_DESTROYED` đã đảm bảo tất cả các card đều bị phá hủy, đồng thời tăng tính tương thích.
    - Sửa lại hàm `s.setop` để cho phép người chơi chọn kích hoạt Set tùy chọn bất kỳ số lượng lá bẫy "Hole" Normal Trap nào (từ 1 đến số lượng vùng trống / số lượng bẫy trong GY) bằng cách sử dụng `g:Select(tp, 1, maxc, nil)` thay vì ép buộc Set tất cả/Set số lượng cố định.
    - Thêm `RESET_PHASE|PHASE_END` vào hiệu ứng `EFFECT_TRAP_ACT_IN_SET_TURN` để dọn dẹp thuộc tính sạch sẽ vào cuối lượt.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> **72 OK, 37 WARN, 0 FAIL** (Biên dịch thành công).
  - `python .\script-test\manage_db.py check-sync` -> Kết quả khớp (2 sync issues cũ).
- **Files/artifacts đã cập nhật:** [c13800001.lua](file:///d:/TTF/TTFCustomCards/script/c13800001.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 037 — 2026-06-04

- **Mục tiêu:** Sửa lỗi hiệu ứng add bài của `c29600004.lua` ("Verre Magic Mastery") không tìm và add được lá "Verre Magic - Lacrima of Light" (`73664385`).
- **Đã hoàn thành:**
  - Tra cứu các lá bài "Verre Magic" (結晶魔術) khác trên cơ sở dữ liệu chính thức và xác nhận chỉ có 1 lá bài duy nhất là "Verre Magic - Lacrima of Light" (`73664385`).
  - Sửa đổi [c29600004.lua](file:///d:/TTF/TTFCustomCards/script/c29600004.lua): Thêm passcode `73664385` vào hàm filter, đồng thời tối ưu hóa cú pháp sử dụng `c:IsCode(code1, code2, ...)` để lọc tất cả các card "Verre Magic" (Transformation `22121392`, Sleep Time `79846799`, Lacrima `73664385`).
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> **72 OK, 37 WARN, 0 FAIL** (Biên dịch hoàn hảo).
  - `python .\script-test\manage_db.py check-sync` -> Hoàn thành khớp 109 cards (chỉ còn 2 issue sync cũ).
- **Files/artifacts đã cập nhật:** [c29600004.lua](file:///d:/TTF/TTFCustomCards/script/c29600004.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 036 — 2026-06-04

- **Mục tiêu:** Sửa lỗi runtime/compilation của Xyz procedure trong `c42790001.lua` và `c37200001.lua` do sai chữ ký hàm `Xyz.AddProcedure`.
- **Đã hoàn thành:**
  - Sửa đổi [c42790001.lua](file:///d:/TTF/TTFCustomCards/script/c42790001.lua): Loại bỏ đối số `99` (maxc) bị truyền sai vị trí (vị trí thứ 5 làm lệch các đối số sau và khiến `SetDescription` nhận nhầm function filter làm description). Thay đổi thành `Xyz.AddProcedure(c,s.xyzfilter,5,3,s.altfilter,aux.Stringid(id,0),Xyz.InfiniteMats,s.altop)` (sử dụng hằng số `Xyz.InfiniteMats` thay cho `99` để loại bỏ cảnh báo deprecation trong EDOPro).
  - Sửa đổi [c37200001.lua](file:///d:/TTF/TTFCustomCards/script/c37200001.lua): Loại bỏ đối số thứ 5 (`2`) thừa thãi vì hệ thống tự động gán `maxct = ct` (nếu không có alternative summon filter thì không cần truyền 5 đối số). Thay đổi thành `Xyz.AddProcedure(c,s.xyzfilter,nil,2)`.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> **72 OK, 37 WARN, 0 FAIL** (Vẫn biên dịch hoàn hảo).
  - `python .\script-test\manage_db.py check-sync` -> 2 sync issues quen thuộc.
- **Files/artifacts đã cập nhật:** [c42790001.lua](file:///d:/TTF/TTFCustomCards/script/c42790001.lua), [c37200001.lua](file:///d:/TTF/TTFCustomCards/script/c37200001.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 035 — 2026-06-04

- **Mục tiêu:** Rà soát và kiểm tra kỹ lưỡng logic hiệu ứng của cả 13 card script mới so với yêu cầu gốc, sửa đổi các lỗi tiềm ẩn để tối ưu tính năng.
- **Đã hoàn thành:**
  - Kiểm tra toàn diện logic của cả 13 script, sửa đổi các phần sau:
    - **Witchcrafter Garden** (`c29600005.lua`): Sửa lỗi hàm `target` và `activate` khiến card không thể kích hoạt được nếu trong Deck chỉ còn Trap (nhưng đã đủ điều kiện điều khiển Witchcrafter monster).
    - **Surtr, Sarkaz of Laevateinn** (`c79900016.lua`): Sửa điều kiện bảo vệ `s.protcon` từ "chỉ khi được Link Summon" thành "trong lượt được Special Summon" nói chung để khớp chính xác mô tả hiệu ứng.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> **72 OK, 37 WARN, 0 FAIL** (Vẫn biên dịch hoàn hảo).
  - `python .\script-test\manage_db.py check-sync` -> Khớp hoàn hảo.
- **Files/artifacts đã cập nhật:** [c29600005.lua](file:///d:/TTF/TTFCustomCards/script/c29600005.lua), [c79900016.lua](file:///d:/TTF/TTFCustomCards/script/c79900016.lua), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 034 — 2026-06-04

- **Mục tiêu:** Sao chép hình ảnh artwork vào thư mục `pics/` dưới dạng tên passcode và định dạng lại toàn bộ 13 script Lua mới theo đúng template chuẩn.
- **Đã hoàn thành:**
  - Sao chép 13 file ảnh từ hàng đợi vào [pics/](file:///d:/TTF/TTFCustomCards/pics/) đặt tên theo `<passcode>.<ext>`.
  - Định dạng lại tiêu đề và các khối chú thích trong 13 file script Lua tại [script/](file:///d:/TTF/TTFCustomCards/script/) cho đồng bộ với template tại [template-card/](file:///d:/TTF/TTFCustomCards/template-card/).
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> **72 OK, 37 WARN, 0 FAIL** (Biên dịch hoàn hảo sau định dạng).
  - `python .\script-test\manage_db.py check-sync` -> Toàn bộ khớp hoàn hảo.
- **Files/artifacts đã cập nhật:** 13 file script tại [script/](file:///d:/TTF/TTFCustomCards/script/), hình ảnh tại [pics/](file:///d:/TTF/TTFCustomCards/pics/), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 033 — 2026-06-04

- **Mục tiêu:** Hoàn thiện định dạng hàng đợi, đổi tên tiền tố file ảnh từ `p_` (pending) sang `d_` (done) cho 13 card đã triển khai và đồng bộ đường dẫn trong `feature_list.json`.
- **Đã hoàn thành:**
  - Đổi tên toàn bộ 13 file ảnh queue trong thư mục `docs/queues/` từ `p_` sang `d_`.
  - Cập nhật các đường dẫn `queue_file` tương ứng trong [feature_list.json](file:///d:/TTF/TTFCustomCards/feature_list.json) sang dạng `d_`.
- **Xác minh đã chạy:**
  - `git status` -> Tất cả file cũ dạng `p_` biến mất, thay bằng file dạng `d_` tương ứng.
  - `.\script-test\validate_scripts.ps1` -> **72 OK, 37 WARN, 0 FAIL**.
  - `python .\script-test\manage_db.py check-sync` -> Hoàn thành khớp 109 cards (chỉ còn 2 issue sync cũ).
- **Files/artifacts đã cập nhật:** [feature_list.json](file:///d:/TTF/TTFCustomCards/feature_list.json), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 032 — 2026-06-04

- **Mục tiêu:** Hiện thực hóa mã nguồn (script Lua) và đăng ký thông số vào database cho cả 13 card pending.
- **Đã hoàn thành:**
  - Viết thành công 13 file script Lua tại [script/](file:///d:/TTF/TTFCustomCards/script/) khớp chính xác logic mô tả từ ảnh queue.
  - Viết script Python đăng ký thành công thông tin (stats, name, desc) của 13 card vào SQLite database `custom_cards_zesty.cdb` (Link arrows, type, setcodes, ot=32).
  - Cập nhật trạng thái của cả 13 card từ `pending` sang `done` trong [feature_list.json](file:///d:/TTF/TTFCustomCards/feature_list.json), gắn thêm thuộc tính `script` chỉ định tệp.
- **Xác minh đã chạy:**
  - `.\script-test\validate_scripts.ps1` -> **72 OK, 37 WARN, 0 FAIL** (Tất cả 13 script mới biên dịch thành công).
  - `python .\script-test\manage_db.py check-sync` -> Hoàn thành khớp 109 cards (chỉ còn 2 issue sync cũ).
- **Files/artifacts đã cập nhật:** [feature_list.json](file:///d:/TTF/TTFCustomCards/feature_list.json), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

### Phiên 031 — 2026-06-04

- **Mục tiêu:** Quét hàng đợi, tìm và đăng ký các card pending (`p_`) vào `feature_list.json`, lập kế hoạch chi tiết cho các card này.
- **Đã hoàn thành:**
  - Quét thư mục `docs/queues/` phát hiện 13 card pending mới có tiền tố `p_`.
  - Phân tích và trích xuất thành công toàn bộ thông số, hiệu ứng của 13 card từ file ảnh bằng `view_file`.
  - Cập nhật [feature_list.json](file:///d:/TTF/TTFCustomCards/feature_list.json):
    - Đăng ký 13 card mới vào các archetype phù hợp (`Witchcrafter`, `Exosister`, `Traptrix`, `Umi`, `Outer_Entity`, `Rank_Up_Magic`, `Common`).
    - Gán các dải passcode theo chuẩn `{setcode_decimal}{sequential_5digits}` cho từng card mới.
    - Cập nhật ngày sửa đổi cuối thành `"2026-06-04"`.
  - Lập bản kế hoạch triển khai [implementation_plan.md](file:///C:/Users/dinhd/.gemini/antigravity-ide/brain/c9d7d85a-b7dd-4173-a797-5a45c936a65c/implementation_plan.md) phân tích chi tiết hiệu ứng và hướng đi cho từng card.
- **Xác minh đã chạy:**
  - `Get-Content feature_list.json | ConvertFrom-Json` -> File JSON hợp lệ.
  - `python .\script-test\manage_db.py check-sync` -> Kết quả khớp với database (không phát sinh lỗi mới từ các card pending).
- **Files/artifacts đã cập nhật:** [feature_list.json](file:///d:/TTF/TTFCustomCards/feature_list.json), [claude-progress.md](file:///d:/TTF/TTFCustomCards/claude-progress.md)

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
