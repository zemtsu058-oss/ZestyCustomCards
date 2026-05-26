# Card Text Changes — Castle of Dreams Archetype

File này ghi lại tất cả thay đổi text effect so với ảnh gốc. Dùng để update lại card artwork.

**Ngày**: 2026-05-26
**Lý do thay đổi**: Fix lỗi chính tả + điều chỉnh effect "negate redirection" thành dạng implementable trong EDOPro.

---

## Thay đổi toàn archetype

| Ảnh gốc | Đã sửa | Lý do |
|---------|--------|-------|
| `Castel of Dreams` (trap) | `Castle of Dreams` | Typo — tên archetype đúng là Castle |
| `Casle of Dreams` (Corruptor) | `Castle of Dreams` | Typo — thiếu chữ t |
| `once of there effect` | `1 of these effects` | Ngữ pháp sai |
| `Both play` | `Both players` | Thiếu chữ |
| `was Special Summoned` (plural subject) | `were Special Summoned` | Ngữ pháp |
| `control a monster` | `controls a monster` | Ngữ pháp |
| `your opponent Deck` | `your opponent's Deck` | Thiếu possessive |

## Thay đổi cơ học (negate redirection)

### Lý do
EDOPro không hỗ trợ "change what an effect resolves into" mid-resolution. Pattern mới: **negate activation + opponent chọn replacement effect**.

### Card bị ảnh hưởng

**Castle of Dreams - Fairytale**
- CŨ: "Each turn, the first time a card or effect resolve that would negate another card effects, change that effect to 1 of there effect (your opponent choice):"
- MỚI: "Each turn, when your opponent activates a card or effect that would negate the activation or effect of another card (Quick Effect): You can negate the activation, and if you do, your opponent chooses 1 of these effects for you to apply."

**Castle of Dreams - Stage**
- CŨ: "Each turn, the first time a card or effect resolve that would negate another card effects, change that effect to 1 of there effect (your opponent choice):"
- MỚI: "Each turn, when your opponent activates a card or effect that would negate the activation or effect of another card (Quick Effect): You can negate the activation, and if you do, your opponent chooses 1 of these effects for you to apply."

**Iris, Master of the Castle of Dreams**
- CŨ: "That effect become once of there effect (your opponent choice);"
- MỚI: "You can negate the activation, and if you do, your opponent chooses 1 of these effects for you to apply."

**Morpheus, Dreamspinner of the Castle of Dreams**
- CŨ: "That effect become once of there effect (your opponent choice);"
- MỚI: "You can negate the activation, and if you do, your opponent chooses 1 of these effects for you to apply."

---

## Thay đổi theo từng card

### Bena, Guardian of the Castle of Dreams
- `"to your field"` ở effect 1 → `"from your Deck to your field"` (rõ nguồn)
- `"from your GY, instead"` → `"from your GY instead"` (bỏ dấu phẩy thừa)

### Cautus, Keeper of the Castle of Dreams
- Không thay đổi đáng kể (text vốn đã sạch)

### Wolff, Servant of the Castle of Dreams
- `"You can Tribute this card, Special Summon"` → `"You can Tribute this card; Special Summon"` (dấu chấm phẩy phân cách cost/effect)

### Morpheus, Corruptor of the Castle of Dreams
- `"2 monsters, include a"` → `"2 monsters, including a"` 
- `"Casle of Dreams Trap"` → `"Castle of Dreams Traps"`
- `"non-Link 'Castle of Dreams' monster"` → `"non-Link 'Castle of Dreams' monsters"` (số nhiều)

### Wandering Ghost of the Castle of Dreams
- Dòng material `"1 'Castle of Dreams' monster"` đưa lên đầu card (theo format Link Monster chuẩn)

### Castle of Dreams - Dream Show
- Không thay đổi đáng kể (chỉ sửa `control` → `controls`)

### Castle of Dreams - Iris's Necklace
- Không thay đổi đáng kể

### Castle of Dreams - Betrayal
- `"was Special Summoned"` → `"were Special Summoned"`
- `"take control of a Effect Monster"` → `"took control of an Effect Monster"`

### Castle of Dreams - Breakout
- `"was Special Summoned"` → `"were Special Summoned"`
- `"card on field"` → `"cards on the field"`

### Castle of Dreams - Fall
- `"was Special Summoned"` → `"were Special Summoned"`
- **BUG QUAN TRỌNG**: HOPT clause ghi `"Castle of Dreams - Breakout"` → phải là `"Castle of Dreams - Fall"` (lỗi copy-paste)
