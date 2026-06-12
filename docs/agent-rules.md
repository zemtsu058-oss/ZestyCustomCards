# Quy Tắc Lập Trình & Hướng Dẫn Tra Cứu Kỹ Thuật (LUA/CDB)

Tài liệu này bao gồm toàn bộ các quy tắc viết mã Lua, quy tắc chọn Passcode, Setcode và bảng tra cứu bitmask cho SQLite Database.

---

## 1. Quy Tắc Viết Script Lua (EDOPro Standards)

Các quy tắc lập trình bắt buộc để đảm bảo script tương thích và chạy ổn định trên Simulator EDOPro:

1. **ALWAYS** `local s,id=GetID()` ở đầu file.
2. **ALWAYS** `function s.initial_effect(c) ... end` làm hàm khởi tạo hiệu ứng.
3. **ALWAYS** `aux.Stringid(id,N)` khi gán mô tả hiệu ứng (`SetDescription`) với `N` bắt đầu từ `0` cho hiệu ứng 1, `1` cho hiệu ứng 2, v.v.
4. **ALWAYS** sử dụng `if chk==0 then return ... end` trong target function để kiểm tra tính hợp lệ (legality). **NEVER** sử dụng `chk==1` để check legality.
5. **ALWAYS** đăng ký `Duel.SetOperationInfo` trong target function nếu hiệu ứng thực hiện di chuyển card (destroy, search, summon, banish, etc.).
6. **ALWAYS** kiểm tra số lượng ô trống trên bàn bằng `Duel.GetLocationCount` (hoặc `GetMZoneCount`) trước khi Special Summon.
7. **ALWAYS** trong hàm operation của trigger/continuous effect, lấy handler theo mẫu chuẩn official: `local c=e:GetHandler()` rồi kiểm tra `c:IsRelateToEffect(e)` (kèm `c:IsFaceup()` nếu cần) trước khi áp dụng hiệu ứng lên chính nó. **KHÔNG** dùng helper tự chế `Card.GetRelatedHandler` cho card mới (helper này nằm trong `constants.lua`, chỉ giữ lại cho các card cũ đã load file đó).
8. **ALWAYS** kiểm tra quan hệ hiệu ứng bằng `tc:IsRelateToEffect(e)` trong hàm operation trước khi áp dụng hiệu ứng lên card mục tiêu (hoặc handler).
9. **NEVER** quên `c:RegisterEffect(e1)` sau khi tạo effect và thiết lập phạm vi hoạt động bằng `SetRange` cho các hiệu ứng không phải là SINGLE.
10. **CRITICAL — NEVER** tham chiếu, bắt chước hoặc sao chép code trực tiếp từ các tệp tin custom cũ trong thư mục `script/` (ngoại trừ các file cấu hình hệ thống như `constants.lua`). Hầu hết code cũ trong thư mục này chứa nhiều lỗi nghiêm trọng về timing, logic, reset và category.
11. **ALWAYS** sử dụng các tệp mẫu trong `script-test/templates/` làm khung cơ sở bắt buộc khi viết card mới. Nếu cần tham khảo logic chạy thực tế, chỉ sử dụng các script của card official làm mẫu (tải qua công cụ `fetch_official.ps1` lưu tại `docs/official-reference/`).
12. **CRITICAL — EDOPro KHÔNG tự load `script/constants.lua`.** Nếu script sử dụng BẤT KỲ định danh nào định nghĩa trong file đó (`SET_*`, `COUNTER_*`, helper như `Card.GetRelatedHandler`...), bắt buộc phải có `Duel.LoadScript("constants.lua")` ngay sau `local s,id=GetID()`. Thiếu dòng này sẽ crash runtime `attempt to call/index a nil value`. Validator tự động FAIL nếu vi phạm.
13. **NEVER** gọi hàm API không xuất hiện trong script official tham khảo hoặc tài liệu EDOPro — hàm "nghe có vẻ hợp lý" nhưng không tồn tại (ví dụ `Cost.DetachFromSelf`) sẽ crash runtime. Khi phát hiện một hàm ma mới, thêm nó vào `script-test/phantom_apis.txt` để validator chặn vĩnh viễn.

---

## 2. Quy Tắc Chọn Passcode & Setcode

### 2.1 Quy tắc chọn Passcode
Passcode của custom card bắt buộc sử dụng **9 chữ số** (để tránh trùng với card official vốn tối đa chỉ 8 chữ số).
* **Công thức:** `{setcode_decimal}{5_digit_seq}`
* **Ví dụ:** Card đầu tiên của archetype Witchcrafter (`setcode` decimal là 296) sẽ là `29600001`, card tiếp theo là `29600002`.

### 2.2 Phân biệt Archetype Official và Fan-made
* **Archetype Official (Dragonmaid, Labrynth, White Forest, Witchcrafter, Branded...):**
  - Tra cứu setcode hex chuẩn xác tại [`docs/archetype_setcode_constants.lua`](file:///d:/TTF/TTFCustomCards/docs/archetype_setcode_constants.lua).
  - Sử dụng trực tiếp setcode hex này trong JSON specs (dưới dạng số decimal). EDOPro đã tích hợp sẵn các setcode này, **không được thêm chúng vào `script/constants.lua`**.
* **Archetype Fan-made mới:**
  1. Đăng ký hằng số `SET_XXX = 0xYYY` vào [script/constants.lua](file:///d:/TTF/TTFCustomCards/script/constants.lua).
  2. Đăng ký chuỗi hiển thị tên archetype `!setname 0xYYY TênArchetype` vào [strings.conf](file:///d:/TTF/TTFCustomCards/strings.conf).

---

## 3. CDB SQLite Schema Reference

Tệp SQLite database của dự án là `custom_cards_zesty.cdb`. Mọi thay đổi thuộc tính của card đều phải được chỉnh sửa trong tệp JSON Specs tương ứng tại `card-data/c<passcode>.json` (được xem là **Single Source of Truth**), sau đó CLI biên dịch tự động vào database.

### 3.1 Cấu trúc Bảng Database
Schema và quy tắc đóng gói dữ liệu tuân theo **Datacorn** (trình editor CDB chính thức của ProjectIgnis, source tham khảo tại `docs/resources/Datacorn/`).

* **Bảng `datas` (Metadata):** Chứa các thuộc tính số của card.
  - `id`: Passcode của card (9 chữ số).
  - `ot`: **Luôn đặt là 32** (Custom card). Compiler sẽ báo lỗi nếu khác 32.
  - `alias`: ID của card gốc nếu là Alt-art (0 = không có).
  - `setcode`: Tối đa **4 setcode 16-bit** đóng gói trong 1 số 64-bit: `setcode = sc1 | (sc2 << 16) | (sc3 << 32) | (sc4 << 48)`.
  - `type`: Loại card (dạng bitmask). Phải có **đúng 1** trong 3 bit khung: Monster (`0x1`) / Spell (`0x2`) / Trap (`0x4`).
  - `atk`, `def`: ATK/DEF (-2 đại diện cho `?`).
  - `level`: Cấp độ/Rank/Link rating (0–13). Với **Pendulum scale**, scale được mã hóa vào cột level theo công thức Datacorn: `level = (base_level & 0x800000FF) | (left_scale << 24) | (right_scale << 16)`.
  - `race`: Tộc quái vật (bitmask, monster phải có **đúng 1 bit**).
  - `attribute`: Hệ quái vật (bitmask, monster phải có **đúng 1 bit**).
  - `category`: Phân loại hiệu ứng (dạng bitmask).
  - **Link Monster:** cột `def` KHÔNG phải DEF mà là **bitfield link marker**: `0x1` Bottom-Left, `0x2` Bottom, `0x4` Bottom-Right, `0x8` Left, `0x20` Right, `0x40` Top-Left, `0x80` Top, `0x100` Top-Right (bit `0x10` không dùng). Link rating nằm trong cột `level`.
  - **Spell/Trap:** các cột `atk`, `def`, `level`, `race`, `attribute` phải bằng 0.
* **Bảng `texts` (Văn bản):** Chứa `name`, `desc` và `str1` đến `str16` (các option prompt khi chọn hiệu ứng).

### 3.2 Field thân thiện trong Specs JSON (khuyến nghị dùng)
Ngoài giá trị thô đã đóng gói, compiler hỗ trợ các field dễ đọc sau (ưu tiên dùng khi viết card mới — compiler tự đóng gói và validate):

| Field JSON | Ý nghĩa | Ví dụ |
|------------|---------|-------|
| `"setcodes": [...]` | Danh sách tối đa 4 setcode (tự đóng gói vào `setcode`) | `"setcodes": [296, 4444]` |
| `"lscale"` / `"rscale"` | Pendulum Scale trái/phải (tự đóng gói vào `level`) | `"lscale": 4, "rscale": 4` |
| `"linkmarkers": [...]` | Tên link marker (tự đóng gói vào `def`) | `"linkmarkers": ["Top", "Bottom"]` |
| `"atk"` / `"def"`: `"?"` | ATK/DEF `?` (tự chuyển thành -2) | `"atk": "?"` |

Lưu ý: không khai báo đồng thời field thô và field thân thiện với giá trị mâu thuẫn (compiler báo lỗi).

### 3.3 Validation & Compile Atomic
* `python .\script-test\manage_db.py validate` — kiểm tra toàn bộ specs theo quy tắc Datacorn mà **không ghi CDB** (nhanh, dùng khi đang sửa spec).
* `python .\script-test\manage_db.py compile` — validate trước, chỉ khi **0 lỗi** mới biên dịch ra file tạm rồi thay thế CDB (atomic; nếu có lỗi, CDB cũ giữ nguyên và exit code = 1).
* Các lỗi bị chặn: `ot` ≠ 32, thiếu/thừa bit khung Monster-Spell-Trap, monster thiếu hoặc multi-bit race/attribute, link marker không hợp lệ hoặc rỗng, scale > 13, level > 13, Spell/Trap có chỉ số khác 0, `strings` > 16, `id` không khớp tên file...

---

## 4. Bảng Tra Cứu Bitmasks Thập Phân (Decimal)

Khi điền Specs JSON tại `card-data/`, bạn bắt buộc phải điền **giá trị thập phân (Decimal)** của các bitmask.

### 4.1 Card Type Bitmask (`type`)

| Loại Card | Giá trị Hex | Thập phân (Dec) |
|-----------|-------------|-----------------|
| Normal Monster | `0x11` | **17** |
| Effect Monster | `0x21` | **33** |
| Fusion Effect Monster | `0x61` | **97** |
| Synchro Monster | `0x2021` | **8225** |
| Xyz Monster | `0x800021` | **8388641** |
| Link Monster | `0x4000021` | **67108897** |
| Pendulum Effect Monster | `0x1000021` | **16777249** |
| Tuner Effect Monster | `0x1021` | **4129** |
| Normal Spell | `0x2` | **2** |
| Quick-Play Spell | `0x10002` | **65538** |
| Continuous Spell | `0x20002` | **131074** |
| Field Spell | `0x80002` | **524290** |
| Equip Spell | `0x40002` | **262146** |
| Normal Trap | `0x4` | **4** |
| Continuous Trap | `0x20004` | **131076** |
| Counter Trap | `0x100004` | **1048580** |

### 4.2 Monster Race Bitmask (`race`)

| Tộc (Race) | Giá trị Hex | Thập phân (Dec) |
|------------|-------------|-----------------|
| Warrior | `0x1` | **1** |
| Spellcaster | `0x2` | **2** |
| Fairy | `0x4` | **4** |
| Fiend | `0x8` | **8** |
| Zombie | `0x10` | **16** |
| Machine | `0x20` | **32** |
| Aqua | `0x40` | **64** |
| Pyro | `0x80` | **128** |
| Rock | `0x100` | **256** |
| Winged Beast | `0x200` | **512** |
| Plant | `0x400` | **1024** |
| Insect | `0x800` | **2048** |
| Thunder | `0x1000` | **4096** |
| Dragon | `0x2000` | **8192** |
| Beast | `0x4000` | **16384** |
| Beast-Warrior | `0x8000` | **32768** |
| Dinosaur | `0x10000` | **65536** |
| Fish | `0x20000` | **131072** |
| Sea Serpent | `0x40000` | **262144** |
| Reptile | `0x80000` | **524288** |
| Psychic | `0x100000` | **1048576** |
| Wyrm | `0x800000` | **8388608** |
| Cyberse | `0x1000000` | **16777216** |
| Illusion | `0x2000000` | **33554432** |

### 4.3 Monster Attribute Bitmask (`attribute`)

| Hệ (Attribute) | Giá trị Hex | Thập phân (Dec) |
|----------------|-------------|-----------------|
| EARTH | `0x1` | **1** |
| WATER | `0x2` | **2** |
| FIRE | `0x4` | **4** |
| WIND | `0x8` | **8** |
| LIGHT | `0x10` | **16** |
| DARK | `0x20` | **32** |
| DIVINE | `0x40` | **64** |

### 4.4 Effect Category Bitmask (`category`)

| Category | Giá trị Hex | Thập phân (Dec) |
|----------|-------------|-----------------|
| `CATEGORY_DESTROY` | `0x1` | **1** |
| `CATEGORY_RELEASE` | `0x2` | **2** |
| `CATEGORY_REMOVE` | `0x4` | **4** |
| `CATEGORY_TOHAND` | `0x8` | **8** |
| `CATEGORY_TODECK` | `0x10` | **16** |
| `CATEGORY_TOGRAVE` | `0x20` | **32** |
| `CATEGORY_DECKDES` | `0x40` | **64** |
| `CATEGORY_HANDES` | `0x80` | **128** |
| `CATEGORY_SUMMON` | `0x100` | **256** |
| `CATEGORY_SPECIAL_SUMMON` | `0x200` | **512** |
| `CATEGORY_POSITION` | `0x400` | **1024** |
| `CATEGORY_DISABLE` | `0x800` | **2048** |
| `CATEGORY_EQUIP` | `0x1000` | **4096** |
| `CATEGORY_CONTROL` | `0x2000` | **8192** |
| `CATEGORY_DICE` | `0x4000` | **16384** |
| `CATEGORY_COIN` | `0x8000` | **32768** |
| `CATEGORY_DRAW` | `0x10000` | **65536** |
| `CATEGORY_SEARCH` | `0x20000` | **131072** |
| `CATEGORY_LVCHANGE` | `0x40000` | **262144** |
| `CATEGORY_DAMAGE` | `0x80000` | **524288** |
| `CATEGORY_RECOVER` | `0x100000` | **1048576** |
| `CATEGORY_ATKCHANGE` | `0x200000` | **2097152** |
| `CATEGORY_DEFCHANGE` | `0x400000` | **4194304** |
| `CATEGORY_COUNTER` | `0x800000` | **8388608** |
| `CATEGORY_TOKEN` | `0x1000000` | **16777216** |
| `CATEGORY_FUSION_SUMMON` | `0x2000000` | **33554432** |
| `CATEGORY_LEAVE_GRAVE` | `0x4000000` | **67108864** |
| `CATEGORY_NEGATE` | `0x10000000` | **268435456** |
