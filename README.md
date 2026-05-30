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

| Archetype | Số card | Loại |
|-----------|---------|------|
| Castle of Dreams | 14 | Fan-made original |
| TTF / Atermis / Cat | ~10 | Fan-made original |
| Labrynth | 2 | Support card |
| Dragonmaid | 2 | Support card |
| White Forest | 1 | Support card |
| Branded | 1 | Support card |
| Desire HERO / Buckle | ~8 | Fan-made original |

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
