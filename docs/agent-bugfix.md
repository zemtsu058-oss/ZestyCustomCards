# Bug Fix & Escalation Guide

> Đọc file này khi: (1) user báo bug, hoặc (2) template không đủ cho effect cần làm.

---

## Bug Fix Workflow (Quy trình sửa lỗi nhanh — KHÔNG CẦN TỰ SUY NGHĨ)

Khi nhận được báo cáo lỗi (ví dụ: hiệu ứng kích hoạt không đúng điều kiện, logic sai hoặc crash game):

### Bước 1: Xác định card bị lỗi và card tham khảo
1. Tìm passcode của card bị lỗi trong `script/` hoặc cơ sở dữ liệu.
2. Tìm 1-2 lá bài **official** có hiệu ứng tương đồng nhất với hiệu ứng đang lỗi (Ví dụ: chặn di chuyển Graveyard -> Ghost Belle `73642296`; chặn add từ Deck -> Ash Blossom `14558127`; chặn Special Summon -> Solemn Strike `40605147`).
3. Tải ngay card official đó về làm mẫu bằng lệnh:
   ```powershell
   .\script-test\fetch_official.ps1 <passcode_official>
   ```
4. Đọc file card mẫu tại `docs/official-reference/c<passcode_official>.lua` để đối chiếu.

### Bước 2: So sánh logic (Mechanical Diff)
So sánh trực tiếp code của card bị lỗi và card mẫu theo cấu trúc:
* **Condition (`con`)**: Card mẫu lọc điều kiện kích hoạt bằng hàm nào? Cần so sánh `tp`, `1-tp` (người chơi/đối thủ), vị trí (`IsLocation`), hay các category check (`re:IsHasCategory` / `Duel.GetOperationInfo`).
* **Target (`tg`) / Cost (`cost`)**: Kiểm tra xem các cờ Category, Target Range, hay các bước check legality (`chk==0`) có khớp với card mẫu không.
* **Operation (`op`)**: Kiểm tra cách xử lý hiệu ứng, các hàm API của EDOPro được gọi như thế nào.

### Bước 3: Sửa đổi và Tối ưu hóa
1. Cập nhật code trong file `script/c<PASSCODE_LỖI>.lua`.
2. **Lưu ý quan trọng**: Đảm bảo không sử dụng các hằng số không có trong whitelist của validator (ví dụ: `CATEGORY_GRAVE_SPSUMMON` và `CATEGORY_GRAVE_ACTION` không thuộc whitelist, thay vào đó hãy check 8 categories di chuyển card tiêu chuẩn).

### Bước 4: Chạy kiểm tra tự động (BẮT BUỘC)
Chạy lần lượt 2 lệnh sau dưới PowerShell:
```powershell
# 1. Validate cú pháp và linter
.\script-test\validate_scripts.ps1

# 2. Kiểm tra đồng bộ cơ sở dữ liệu
python .\script-test\manage_db.py check-sync
```
Nếu có bất kỳ dòng `[!] WARN` hoặc `[X] FAIL` nào xuất hiện cho card vừa sửa, phải sửa cho đến khi file đó hiển thị `[ ] OK`.

### Bước 5: Cập nhật nhật ký
Thêm dòng mô tả sửa đổi vào phần cuối của [`claude-progress.md`](claude-progress.md) theo format của các phiên trước.

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
