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

Hiện tại project có **122** custom cards (bao gồm cả fan-made original archetypes và các thẻ bài support cho các archetype chính thức):

### Archetypes Thiết Kế Riêng (Fan-made Original)

| Archetype / Series | Số card | Mô tả |
| :--- | :---: | :--- |
| **Castle of Dreams** | 14 | Archetype độc quyền xoay quanh các quái thú tiên (Fairy) và cơ chế giấc mơ |
| **Wezaemon the Tombguard** | 12 | Archetype dựa trên boss Wezaemon và cơ chế chiến đấu của Shangri-La Frontier |
| **TTF / Atermis / Cat / Hanako** | 10 | Các thẻ bài linh vật của nhóm TTF, Artemis và biệt đội mèo siêu quậy |
| **Desire HERO / Buckle** | 6 | Lấy cảm hứng từ series Kamen Rider Geats với cơ chế thay đổi Buckle |
| **Hyperdimension CPU** | 2 | Các quái thú CPU Neptune và Chrome Heart từ vũ trụ Hyperdimension Neptunia |

### Thẻ Bài Hỗ Trợ (Support Cards) cho Archetype Chính Thức

| Archetype Hỗ Trợ | Số card | Các card tiêu biểu / Ghi chú |
| :--- | :---: | :--- |
| **Witchcrafter / Magistus** | 14 | Witchcrafter Unit Jeweler, Witchcrafter Hisho - Madame, Verre Magic: Transformation, Witchcrafter Garden... |
| **Branded / Albaz** | 4 | Branded's New Adventure, Branded in Peace, Protection of the Albaz, Fall of the Fallen |
| **Charmer** | 4 | Blessing of the Earth/Fire/Water/Wind Charmer |
| **HERO (Elemental / Xtra / Blue-Eyes)** | 4 | Elemental HERO Draconic Neos, Xtra HERO Wonderkid, Blue-eyes HERO Dragon, Maiden of White – Dragon Blessing |
| **Labrynth** | 3 | Labrynth Party, Farewell Labrynth, Chambermaid of the Silver Castle |
| **Mikanko** | 3 | Ohime the Curious Mikanko, Mikanko Illusion Dance, Mikanko Fire Soul |
| **White Forest** | 3 | Whispers of the White Forest, Memory of the White Forest, Knowledge of the White Forest |
| **Dragonmaid** | 2 | Dragonmaid's Soul!?, Laundry Fusion |
| **Melodious** | 2 | Melodious Fusion, MELODIOUS FAMILY |
| **Maliss** | 2 | The Grand Stage of Maliss, Maliss of the Fallen Game |
| **Traptrix** | 2 | Return of the Red Ant, Seventh Traptrix |
| **Rank-Up-Magic** | 2 | DoomZ Command J.U.P.I.T.E.R, Rank-Up-Magic Rising Force |
| **Exosister** | 1 | Exosister Nunctis |
| **Rikka** | 1 | Teardrop the Rikka Fairy |
| **Umi / Kairyu-Shin** | 1 | Lemuria, the Slumbering Eternal City |
| **Outer Entity** | 1 | Outer Entity Sothoth |
| **Các card khác (Meme / Generic / Support lẻ)** | 29 | Elaina, The Wandering Witch, Drytron Supernova, Toon Shooting Quasar Dragon, Cây Súng Ngàn Năm, Monster Redie, Power of the Dominators... |


---

## Cấu trúc thư mục

```
script/          — Lua script cho mỗi card (tên file = passcode)
pics/            — Artwork (tên file = passcode)
docs/            — Tài liệu nội bộ
script-test/     — Công cụ CLI, linter và templates:
  ├── templates/        — Templates để tạo script mới
  ├── manage_harness.py — Quản lý quy trình (Harness CLI)
  └── manage_db.py      — Quản lý CDB (CDB Compiler)
custom_cards_zesty.cdb  — Database SQLite
strings.conf     — Tên archetype hiển thị trong game
```

---

## Đóng góp

Nếu bạn muốn thêm card mới hoặc sửa bug, đọc [`AGENTS.md`](AGENTS.md) để biết workflow.

---

## License

MIT
