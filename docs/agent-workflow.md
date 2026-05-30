# Workflow Tạo Card Mới

> Đọc file này khi: nhận yêu cầu tạo card mới từ user.

---

## Bước 1: Nhận yêu cầu

User cung cấp thông tin:
- Tên card, loại (Monster/Spell/Trap), sub-type (Effect/Fusion/Synchro/...)
- Attribute, Level/Rank/Link, ATK/DEF, Race
- Effect text (tiếng Anh hoặc tiếng Việt)

---

## Bước 2: Phân tích effect → chọn template

Đọc effect text, xác định loại effect và chọn template tương ứng:

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

Chi tiết hơn: xem [`template-card/README.md`](../template-card/README.md)

---

## Bước 3: Copy template → điền placeholder

```powershell
Copy-Item template-card\template_xxx.lua script\c<PASSCODE>.lua
```

Thay thế tất cả `<<PLACEHOLDER>>`:
- `<<CARD_NAME>>` → tên card
- `<<PASSCODE>>` → passcode (số 9 chữ số, xem [`docs/agent-constants.md`](agent-constants.md))
- `<<SETCODE>>` → archetype hex (xem [`docs/agent-constants.md`](agent-constants.md))
- `<<LEVEL>>`, `<<RANK>>`, `<<ATK>>`, `<<DEF>>` → chỉ số
- `<<ATK_VALUE>>`, `<<LP_AMOUNT>>` → giá trị hiệu ứng
- `<<LINK_COUNT>>`, `<<MIN_MATERIAL>>`, `<<MATERIAL_COUNT>>` → chỉ số summon

**Quan trọng**: Giữ nguyên header comment (`-- ============================================================`) và cập nhật effect text.

---

## Bước 4: Tùy chỉnh effect

- Nếu card chỉ có 1 effect: xóa block effect 2 + tất cả function liên quan
- Nếu card có 3+ effect: copy block `Effect.CreateEffect` → `RegisterEffect` và tăng số (`e3`, `e4`)
- Nếu effect khác pattern trong template: sửa trực tiếp logic trong target/operation function
- Ánh xạ `aux.Stringid(id,N)` — N=0 cho effect 1, N=1 cho effect 2, v.v.

Khi template không đủ → xem [`docs/agent-bugfix.md`](agent-bugfix.md) mục "Khi template không đủ".

---

## Bước 5: Validate

```powershell
.\script-test\validate_scripts.ps1
```

Sửa tất cả lỗi FAIL và WARN trước khi báo cáo hoàn thành.

---

## Bước 6: Cập nhật database

Công cụ CLI:
```powershell
# Xem thông tin card
python .\script-test\manage_db.py query <passcode_hoặc_tên>

# Kiểm tra đồng bộ
python .\script-test\manage_db.py check-sync

# Cập nhật text/mô tả
python .\script-test\manage_db.py update-text <passcode> --desc "Văn bản"
```

Hoặc dùng DataEditorX mở `custom_cards_zesty.cdb`:
- Thêm entry mới với passcode, stats, effect text
- **BẮT BUỘC** đặt cột `ot` = 32 (Custom format)
- Nếu có custom archetype mới: thêm vào `constants.lua` và `strings.conf`

---

## Checklist hoàn thành

Trước khi báo DONE, chạy đủ 4 lệnh:

```powershell
# 1. Validate cú pháp + cấu trúc
.\script-test\validate_scripts.ps1

# 2. Linter kiểm tra style
.\script-test\lint_scripts.ps1

# 3. Đồng bộ database
python .\script-test\manage_db.py check-sync

# 4. Xác nhận file tồn tại
Test-Path script\c<PASSCODE>.lua
```

Nếu validate hoặc check-sync báo lỗi → **sửa ngay, không báo DONE**.
