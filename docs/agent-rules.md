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
7. **ALWAYS** sử dụng hàm helper toàn cục `Card.GetRelatedHandler(c, e)` thay cho việc gọi trực tiếp handler `c` trong các hàm operation khi xử lý các card trigger/continuous (tránh lỗi card rời sân trước khi effect resolve).
8. **ALWAYS** kiểm tra quan hệ hiệu ứng bằng `tc:IsRelateToEffect(e)` trong hàm operation trước khi áp dụng hiệu ứng lên card mục tiêu (hoặc handler).
9. **NEVER** quên `c:RegisterEffect(e1)` sau khi tạo effect và thiết lập phạm vi hoạt động bằng `SetRange` cho các hiệu ứng không phải là SINGLE.
10. **CRITICAL — NEVER** tham chiếu hay sao chép code trực tiếp từ các file trong thư mục `script/`. Hầu hết code cũ chứa lỗi timing/logic nghiêm trọng. Chỉ sử dụng các tệp trong `script-test/templates/` làm khung cơ sở hoặc tải card official làm tham khảo.

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
* **Bảng `datas` (Metadata):** Chứa các thuộc tính số của card.
  - `id`: Passcode của card (9 chữ số).
  - `ot`: **Luôn đặt là 32** (Custom card).
  - `alias`: ID của card gốc nếu là Alt-art (0 = không có).
  - `setcode`: Archetype code (dạng decimal được hệ thống tự động mã hóa Big-endian ASCII).
  - `type`: Loại card (dạng bitmask).
  - `atk`, `def`: ATK/DEF (-2 đại diện cho `?`).
  - `level`: Cấp độ/Rank/Link rating. Với **Pendulum scale**, scale được mã hóa vào cột level theo công thức: `level = base_level + (left_scale << 24) + (right_scale << 16)`.
  - `race`: Tộc quái vật (dạng bitmask).
  - `attribute`: Hệ quái vật (dạng bitmask).
  - `category`: Phân loại hiệu ứng (dạng bitmask).
* **Bảng `texts` (Văn bản):** Chứa `name`, `desc` và `str1` đến `str16` (các option prompt khi chọn hiệu ứng).

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
