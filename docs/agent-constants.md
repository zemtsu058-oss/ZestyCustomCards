# Constants, Setcodes & Passcode Guide

> Đọc file này khi: cần tra cứu setcode, passcode, hoặc tạo archetype mới.

---

## Custom Constants của Project

```lua
-- Từ script/constants.lua
SET_TTF              = 0x789    -- TTF
SET_ATERMIS          = 0x780    -- Atermis
SET_CAT              = 0x781    -- Cat
SET_DESIRE_HERO      = 0x927    -- Desire HERO
SET_BUCKLE           = 0x315    -- Buckle
SET_HYPERDIMENSION   = 0x1291   -- Hyperdimension
SET_CASTLE_OF_DREAMS = 0x782    -- Castle of Dreams
COUNTER_MANA         = 0x177    -- Mana counter
```

```conf
# Từ strings.conf
!setname 0x789 TTF
!setname 0x780 Atermis
!setname 0x781 Cat
!setname 0x315 Buckle
!setname 0x927 Desire HERO
!setname 0x1291 Hyperdimension
!setname 0x782 Castle of Dreams
```

---

## Archetypes Official trong Queue

> [!IMPORTANT]
> **TRA CỨU SETCODE CHO ARCHETYPE:**
> - Đối với các archetype official (Dragonmaid, Labrynth, White Forest, Rikka, v.v.), bạn **BẮT BUỘC** phải tra cứu setcode trong file [`docs/archetype_setcode_constants.lua`](file:///d:/TTF/TTFCustomCards/docs/archetype_setcode_constants.lua).
> - **KHÔNG** được search web hay tự đoán setcode vì có thể sai lệch giữa các bản simulator khác nhau. File này chứa toàn bộ setcode chuẩn OCG/TCG được hỗ trợ trong dự án.

Các archetype official có trong `docs/queues/` (tra đầy đủ tại [`docs/archetype_setcode_constants.lua`](file:///d:/TTF/TTFCustomCards/docs/archetype_setcode_constants.lua)):

| Archetype | Setcode | Hằng số |
|-----------|---------|---------|
| Dragonmaid | `0x133` | SET_DRAGONMAID |
| Labrynth | `0x17f` | SET_LABRYNTH |
| White Forest | `0x1aa` | SET_WHITE_FOREST |
| Witchcrafter | `0x128` | SET_WITCHCRAFTER |
| Branded | `0x160` | SET_BRANDED |

**Ghi chú về archetype official:** Khi viết script cho card có archetype official, dùng setcode ở trên — **không cần thêm vào `constants.lua`** vì EDOPro đã có sẵn.

**Archetypes phụ trợ liên quan:**
- Diabell (`0x203`), Diabellstar (`0x1203`), Sinful Spoils (`0x204`) — dùng cho White Forest
- Welcome Labrynth (`0x117f`) — dùng cho Labrynth

---

## Quy tắc chọn Passcode

Passcode dùng **9 chữ số** để tránh trùng card official (vốn chỉ dùng tối đa 8 chữ số).

**Công thức:** `{setcode_decimal}{sequential_5digits}`

| Archetype | Setcode hex | Decimal | Passcode range |
|-----------|-------------|---------|----------------|
| Dragonmaid | 0x133 | 307 | 30700001 ~ 30799999 |
| Witchcrafter | 0x128 | 296 | 29600001 ~ 29699999 |
| Labrynth | 0x17f | 383 | 38300001 ~ 38399999 |
| White Forest | 0x1aa | 426 | 42600001 ~ 42699999 |
| Branded | 0x160 | 352 | 35200001 ~ 35299999 |
| Castle of Dreams | 0x782 | 1922 | 192200001 ~ 192299999 |

**Ví dụ:** Card đầu tiên của White Forest → `42600001`, card tiếp theo → `42600002`.

**Lưu ý:**
- Đã dùng passcode nào thì đánh dấu vào `feature_list.json` để tránh trùng
- Card có archetype đã có sẵn passcode pattern riêng (vd: TTF = 789xxx) thì giữ nguyên pattern cũ

---

## Thêm Archetype Mới (fan-made)

1. Thêm `SET_XXX = 0xYYY` vào `script/constants.lua`
2. Thêm `!setname 0xYYY TênArchetype` vào `strings.conf`
3. Chọn hex code không trùng với archetype đã có
4. Thêm entry mới vào `feature_list.json`
