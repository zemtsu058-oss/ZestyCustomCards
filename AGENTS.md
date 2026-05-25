# TTF Custom Cards — Agent Guide

Project custom card cho EDOPro (Yu-Gi-Oh! auto duel simulator). Repository này chứa script, database, ảnh của các custom card.

## Cấu trúc project

```
/
├── script/                  # Lua card scripts (cXXXXXXXXX.lua)
│   └── constants.lua        # Custom archetypes, setcodes, counters
├── pics/                    # Card artwork (.png/.jpg, tên = passcode)
├── template-card/           # Templates để sinh script mới
│   ├── README.md            # Agent guide chi tiết cho việc dùng template
│   ├── template_effect_monster.lua
│   ├── template_normal_spell.lua
│   ├── template_normal_trap.lua
│   ├── template_fusion_monster.lua
│   ├── template_synchro_monster.lua
│   ├── template_xyz_monster.lua
│   ├── template_link_monster.lua
│   ├── template_pendulum_monster.lua
│   ├── template_field_spell.lua
│   └── template_hand_trap.lua
├── docs/                    # Tài liệu
│   ├── card-scripting-guide.md    # API reference & patterns
│   └── testing-guide.md           # Test, validation, debug
├── scripts/                 # Công cụ tự động
│   ├── validate_scripts.ps1       # Kiểm tra syntax + structure
│   └── lint_scripts.ps1           # Lua linter
├── custom_cards_zesty.cdb   # Card database (SQLite)
├── strings.conf             # Archetype/counter name strings
└── AGENTS.md                # File này
```

## Workflow tạo card mới

### Bước 1: Nhận yêu cầu

User cung cấp thông tin:
- Tên card, loại (Monster/Spell/Trap), sub-type (Effect/Fusion/Synchro/...)
- Attribute, Level/Rank/Link, ATK/DEF, Race
- Effect text (tiếng Anh hoặc tiếng Việt)

### Bước 2: Phân tích effect → chọn template

Đọc effect text, xác định các loại effect và chọn template tương ứng:

| Mô tả effect | Loại | Template |
|-------------|------|----------|
| "If/When ... is Normal/Special Summoned: You can..." | Trigger O | `template_effect_monster.lua` |
| "Once per turn: You can..." (Main Phase) | Ignition | `template_effect_monster.lua` |
| "(Quick Effect): You can..." | Quick | `template_hand_trap.lua` |
| "When your opponent activates..." (negate từ tay) | Quick Hand | `template_hand_trap.lua` |
| Spell Card activation | Normal Spell | `template_normal_spell.lua` |
| Trap Card activation | Normal Trap | `template_normal_trap.lua` |
| Fusion Monster + effect | Fusion | `template_fusion_monster.lua` |
| Synchro Monster + effect | Synchro | `template_synchro_monster.lua` |
| Xyz Monster + detach effect | Xyz | `template_xyz_monster.lua` |
| Link Monster + effect | Link | `template_link_monster.lua` |
| Pendulum (scale + monster effect) | Pendulum | `template_pendulum_monster.lua` |
| Field Spell (activation + continuous + phase trigger) | Field | `template_field_spell.lua` |
| "All ... gain ATK/DEF" | Continuous | `template_synchro_monster.lua` (Effect 2) |
| Target + destroy | Destroy | `template_effect_monster.lua` (Effect 2) |
| Search/add từ Deck | Search | `template_effect_monster.lua` (Effect 1) |
| SS từ GY/Deck | Special Summon | `template_synchro_monster.lua` (Effect 1) |

Nếu card có nhiều effect, chọn template có số effect phù hợp nhất, rồi thêm/bớt effect block.

### Bước 3: Copy template → điền placeholder

```powershell
Copy-Item template-card\template_xxx.lua script\c<PASSCODE>.lua
```

Thay thế tất cả `<<PLACEHOLDER>>`:
- `<<CARD_NAME>>` → tên card
- `<<PASSCODE>>` → passcode (số 9 chữ số)
- `<<SETCODE>>` → archetype hex (tra `script/constants.lua`)
- `<<LEVEL>>`, `<<RANK>>`, `<<ATK>>`, `<<DEF>>` → chỉ số
- `<<ATK_VALUE>>`, `<<LP_AMOUNT>>` → giá trị hiệu ứng
- `<<LINK_COUNT>>`, `<<MIN_MATERIAL>>`, `<<MATERIAL_COUNT>>` → chỉ số summon

**Quan trọng**: Khi copy template, giữ nguyên header comment (phần `-- ============================================================`) và cập nhật effect text.

### Bước 4: Tùy chỉnh effect

- Nếu card chỉ có 1 effect: xóa block effect 2 + tất cả function liên quan
- Nếu card có 3+ effect: copy block `Effect.CreateEffect` → `RegisterEffect` và tăng số (`e3`, `e4`)
- Nếu effect khác pattern trong template: sửa trực tiếp logic trong target/operation function
- Ánh xạ `aux.Stringid(id,N)` — N=0 cho effect 1, N=1 cho effect 2, v.v.

### Bước 5: Validate

```powershell
.\scripts\validate_scripts.ps1
```

Sửa tất cả lỗi FAIL và WARN trước khi báo cáo hoàn thành.

### Bước 6: Cập nhật database

Nếu cần thêm card vào database:
- Dùng DataEditorX mở `custom_cards_zesty.cdb` 
- Thêm entry mới với passcode, stats, effect text
- Nếu có custom archetype mới: thêm vào `constants.lua` và `strings.conf`

---

## Critical Rules (BẮT BUỘC TUÂN THỦ)

### Script rules
1. **ALWAYS** `local s,id=GetID()` ở đầu file
2. **ALWAYS** `function s.initial_effect(c) ... end`
3. **ALWAYS** `aux.Stringid(id,N)` cho SetDescription
4. **ALWAYS** `if chk==0 then return ... end` trong target function
5. **ALWAYS** `Duel.SetOperationInfo` nếu effect destroy/search/SS
6. **ALWAYS** check `c:IsRelateToEffect(e)` trong operation nếu dùng handler
7. **ALWAYS** check `Duel.GetLocationCount(tp,LOCATION_MZONE)>0` trước SS
8. **NEVER** dùng `chk==1` — luôn `chk==0` để check legality
9. **NEVER** quên `c:RegisterEffect(e1)` sau khi tạo effect
10. **NEVER** quên `SetRange` cho effect non-SINGLE
11. **NEVER** copy code từ script hiện có trong `script/` — chúng có thể có bug
12. **ALWAYS** dùng template trong `template-card/` làm base

### Code quality
- Hàm filter/target/operation dùng tên có ý nghĩa: `filter_search`, `tg_destroy`, `op_revive`, v.v.
- Mỗi effect block phải có comment `-- Effect N — Mô tả ngắn gọn`
- Giữ text effect gốc trong header comment của file
- Hàm filter đặt trước hàm target, hàm target trước hàm operation

---

## Kiểm tra trước khi báo cáo

Trước khi báo DONE, chạy:

```powershell
# 1. Validate cú pháp + cấu trúc
.\scripts\validate_scripts.ps1

# 2. Xác nhận file tồn tại đúng vị trí
Test-Path script\c<PASSCODE>.lua
```

Nếu validate báo FAIL → sửa ngay, không báo DONE.

---

## Khi template không đủ

Nếu card cần pattern không có trong template, tìm kiếm theo thứ tự:

### 1. Docs nội bộ
```
docs/card-scripting-guide.md          — API đầy đủ, tất cả pattern
docs/testing-guide.md                 — Debug & common bugs
template-card/README.md               — Bảng lookup pattern → source
```

### 2. Constants cục bộ
```
script/constants.lua                  — SET_xxx, COUNTER_xxx của project
strings.conf                          — !setname, !countername
```

### 3. CardScripts Wiki (qua WebFetch)
```
https://github.com/ProjectIgnis/CardScripts/wiki/1-%E2%80%90-Scripting-Library
https://github.com/ProjectIgnis/CardScripts/wiki/5-%E2%80%90-Filter-Functions
https://github.com/ProjectIgnis/CardScripts/wiki/4-%E2%80%90-Understanding-a-card-script
https://github.com/ProjectIgnis/CardScripts/wiki/6-%E2%80%90-How-archetypes-and-their-values-work
```

### 4. Raw source files (từ GitHub)
```
https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/utility.lua
https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/constant.lua
https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/proc_fusion.lua
https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/proc_synchro.lua
https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/proc_xyz.lua
https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/proc_link.lua
https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/proc_ritual.lua
https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/proc_pendulum.lua
```

### 5. Official card scripts (tìm card có effect tương tự)
```
Tìm passcode trên https://yugipedia.com/ → lấy code
Fetch: https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/official/c{code}.lua
```

---

## Custom constants của project

```lua
-- Từ script/constants.lua
SET_TTF            = 0x789    -- TTF
SET_ATERMIS        = 0x780    -- Atermis
SET_CAT            = 0x781    -- Cat
SET_DESIRE_HERO    = 0x927    -- Desire HERO
SET_BUCKLE         = 0x315    -- Buckle
SET_HYPERDIMENSION = 0x1291   -- Hyperdimension
COUNTER_MANA       = 0x177    -- Mana counter
```

```conf
# Từ strings.conf
!setname 0x789 TTF
!setname 0x780 Atermis
!setname 0x781 Cat
!setname 0x315 Buckle
!setname 0x927 Desire HERO
!setname 0x1291 Hyperdimension
```

Khi tạo archetype mới:
1. Thêm `SET_XXX = 0xYYY` vào `script/constants.lua`
2. Thêm `!setname 0xYYY TênArchetype` vào `strings.conf`
3. Chọn hex code không trùng với archetype đã có

---

## Bug fix workflow

Khi user báo bug:

1. **Đọc script** liên quan
2. **Xác định effect** bị lỗi (đọc text card → tìm effect tương ứng)
3. **Check từng phần**: Condition → Cost → Target → Operation
4. **Tìm pattern sai**: xem `docs/testing-guide.md` mục Common Bugs
5. **Sửa** → chạy `.\scripts\validate_scripts.ps1`
6. **Không sửa file khác** nếu không liên quan

## Git commits

- **KHÔNG tự động commit** — chỉ commit khi user yêu cầu
- **KHÔNG tự động push** — chỉ push khi user yêu cầu
- File trong `docs/`, `template-card/`, `scripts/` là infrastructure, cần giữ sạch
