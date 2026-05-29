# Bug Fix & Escalation Guide

> Đọc file này khi: (1) user báo bug, hoặc (2) template không đủ cho effect cần làm.

---

## Bug Fix Workflow

Khi user báo bug:

1. **Đọc script** liên quan (`script/c<PASSCODE>.lua`)
2. **Xác định effect** bị lỗi (đọc text card → tìm effect tương ứng)
3. **Check từng phần**: Condition → Cost → Target → Operation
4. **Tìm pattern sai**: xem [`docs/testing-guide.md`](testing-guide.md) mục Common Bugs
5. **Sửa** → chạy `.\script-test\validate_scripts.ps1`
6. **Không sửa file khác** nếu không liên quan

---

## Khi Template Không Đủ

Nếu card cần pattern không có trong template, tìm kiếm theo thứ tự:

### 1. Docs nội bộ
```
docs/card-scripting-guide.md       — API đầy đủ, tất cả pattern
docs/testing-guide.md              — Debug & common bugs
template-card/README.md            — Bảng lookup pattern → source
```

### 2. Constants và Setcode cục bộ
```
docs/archetype_setcode_constants.lua  — Bản đồ setcode toàn bộ archetype official
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

- Xem thư mục chứa các card mẫu: [`docs/official-reference/`](official-reference/)
- Nếu chưa có card mẫu cần thiết, tải về:
  ```powershell
  .\script-test\fetch_official.ps1 <passcode>
  ```
  File tải về sẽ được lưu vào `docs/official-reference/c<passcode>.lua` để dùng lại sau.
