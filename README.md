# TTF Custom Cards

Custom card fan-made cho [EDOPro](https://github.com/ProjectIgnis/edopro) — simulator Yu-Gi-Oh! miễn phí.

Project này chứa các card do nhóm TTF tự thiết kế: script Lua, database, artwork.

---

## Cài đặt

1. Clone repo này về máy
2. Copy toàn bộ vào thư mục `expansions/` của EDOPro:
   ```
   expansions/
   ├── custom_cards_zesty.cdb   ← database card
   ├── script/                  ← Lua scripts
   ├── pics/                    ← artwork
   └── strings.conf             ← tên archetype
   ```
3. Mở EDOPro → bật "Alternate format" để thấy card tùy chỉnh

---

## Card có trong project

Hiện tại project có **76** custom cards (bao gồm cả fan-made original archetypes và các thẻ bài support cho các archetype chính thức):

### Archetypes Thiết Kế Riêng (Fan-made Original)

| Archetype / Series | Số card | Mô tả |
| :--- | :---: | :--- |
| **Castle of Dreams** | 14 | Archetype độc quyền xoay quanh các quái thú tiên (Fairy) và cơ chế giấc mơ |
| **TTF / Atermis / Cat / Hanako** | 10 | Các thẻ bài linh vật của nhóm TTF, Artemis và biệt đội mèo siêu quậy |
| **Desire HERO / Buckle** | 6 | Lấy cảm hứng từ series Kamen Rider Geats với cơ chế thay đổi Buckle |
| **Hyperdimension CPU** | 2 | Các quái thú CPU Neptune và Chrome Heart từ vũ trụ Hyperdimension Neptunia |

### Thẻ Bài Hỗ Trợ (Support Cards) cho Archetype Chính Thức

| Archetype Hỗ Trợ | Số card | Các card tiêu biểu / Ghi chú |
| :--- | :---: | :--- |
| **Witchcrafter / Magistus** | 9 | Witchcrafter Unit Jeweler, Witchcrafter Hisho - Madame, Verre Magic: Transformation... |
| **Branded / Albaz** | 4 | Branded's New Adventure, Branded in Peace, Protection of the Albaz, Fall of the Fallen |
| **HERO (Elemental / Xtra / Blue-Eyes)** | 3 | Elemental HERO Draconic Neos, Xtra HERO Wonderkid, Blue-eyes HERO Dragon |
| **Labrynth** | 3 | Labrynth Party, Farewell Labrynth, Chambermaid of the Silver Castle |
| **Dragonmaid** | 2 | Dragonmaid's Soul!?, Laundry Fusion |
| **Melodious** | 2 | Melodious Fusion, MELODIOUS FAMILY |
| **White Forest** | 1 | Whispers of the White Forest |
| **Maliss** | 1 | The Grand Stage of Maliss |
| **Rikka** | 1 | Teardrop the Rikka Fairy |
| **Các card khác (Meme / Generic / Support lẻ)** | 18 | DoomZ Command, Majestic Quasar, Toon Quasar, Void Invasion, Drytron Supernova, Cây Súng Ngàn Năm, Monster Redie... |


---

## Cấu trúc thư mục

```
script/          — Lua script cho mỗi card (tên file = passcode)
pics/            — Artwork (tên file = passcode)
template-card/   — Template để tạo script mới
docs/            — Tài liệu nội bộ
script-test/     — Công cụ validate và quản lý database
custom_cards_zesty.cdb  — Database SQLite
strings.conf     — Tên archetype hiển thị trong game
```

---

## Đóng góp

Nếu bạn muốn thêm card mới hoặc sửa bug, đọc [`AGENTS.md`](AGENTS.md) để biết workflow.

---

## License

MIT
