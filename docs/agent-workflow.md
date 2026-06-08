# Hướng Dẫn Quy Trình Vận Hành & Kiểm QA (Card Operations)

Tài liệu này bao gồm toàn bộ quy trình từ lúc khởi tạo card mới, gỡ lỗi, kiểm QA và test trực tiếp trong game EDOPro.

---

## 1. Quy Trình Tạo Card Mới (Harness CLI)

Mọi card mới bắt buộc phải được quản lý thông qua **Harness CLI** để tự động hóa việc rename artwork, đăng ký feature list và kiểm tra cú pháp.

### Bước 1: Nhận yêu cầu và Chọn Template
Đọc effect text của card để chọn loại template tương ứng cho việc sinh mã nguồn:

| Mô tả effect | Loại card / Effect đặc trưng | Tên template |
|-------------|-----------------------------|--------------|
| "If/When ... is Summoned..." | Trigger Monster | `effect_monster` |
| "Once per turn: You can..." (Main Phase) | Ignition Monster | `effect_monster` |
| "(Quick Effect): You can..." | Hand Trap / Quick Effect | `hand_trap` |
| Spell Card kích hoạt thông thường | Normal Spell | `normal_spell` |
| Trap Card kích hoạt thông thường | Normal Trap | `normal_trap` |
| Field Spell (activation + continuous) | Field Spell | `field_spell` |
| Fusion Monster + effect | Fusion | `fusion_monster` |
| Synchro Monster + effect | Synchro | `synchro_monster` |
| Xyz Monster + detach effect | Xyz | `xyz_monster` |
| Link Monster + effect | Link | `link_monster` |
| Pendulum (scale + monster effect) | Pendulum | `pendulum_monster` |

*Xác định Passcode:* Passcode gồm **9 chữ số** (Xem hướng dẫn tại [docs/agent-rules.md](agent-rules.md)).

### Bước 2: Khởi tạo bằng Harness CLI
Chạy lệnh sau để CLI tự động thiết lập khung dự án cho card mới:
```powershell
python .\script-test\manage_harness.py start <passcode> "<tên_card>" <tên_template>
```
*Tác vụ tự động:* Tạo `script/c<passcode>.lua`, tạo `card-data/c<passcode>.json`, đổi tên ảnh queue sang làm việc `w_`, và đăng ký `"working"` trong `feature_list.json`.

### Bước 3: Hoàn thiện logic & điền Specs JSON
1. **Specs JSON (`card-data/c<passcode>.json`):** Mở file specs JSON vừa tạo và điền các thuộc tính thực tế (ATK, DEF, Level, Race, Attribute, Type, Category). *Tra cứu bitmask thập phân tại [docs/agent-rules.md](agent-rules.md).*
2. **Logic Lua (`script/c<passcode>.lua`):** Viết logic hiệu ứng trong tệp Lua.

### Bước 4: Xác thực và Hoàn thành bằng Harness CLI
Khi viết xong code, chạy lệnh verify để chạy đường ống kiểm tra tự động:
```powershell
python .\script-test\manage_harness.py verify <passcode>
```
*Tác vụ tự động:* Biên dịch CDB, validate cú pháp/cấu trúc Lua, kiểm tra linter style, check-sync toàn project.
Nếu verify đạt `SUCCESS`, trạng thái card tự động đổi sang `done` và ảnh queue đổi sang `d_`.

---

## 2. Quy Trình Sửa Lỗi Nhanh (Bug Fix Workflow)

Khi nhận báo cáo lỗi hiệu ứng, hãy thực hiện theo quy trình cơ học sau:

1. **Xác định card lỗi và card tham khảo:** Tìm 1-2 lá bài **official** có hiệu ứng tương đồng nhất với hiệu ứng đang bị lỗi.
2. **Tải script official:** Sử dụng công cụ tải script mẫu về tham khảo:
   ```powershell
   .\script-test\fetch_official.ps1 <passcode_official>
   ```
   *Vị trí file tải về:* `docs/official-reference/c<passcode_official>.lua`
3. **So sánh logic (Mechanical Diff):** Đối chiếu cấu trúc:
   - **Condition (`con`):** Cách lọc điều kiện, kiểm tra vị trí.
   - **Target (`tg`):** Cách check legality (`chk==0`), gán Category.
   - **Operation (`op`):** Cách gọi các hàm API của EDOPro.
4. **Sửa đổi và Chạy CLI Verify:** Sau khi sửa xong script, chạy lệnh xác thực:
   ```powershell
   python .\script-test\manage_harness.py verify <passcode>
   ```
   Bắt buộc sửa cho đến khi verify báo `SUCCESS` mới được báo hoàn thành.

---

## 3. Checklist QA của Agent (Bắt buộc trước khi báo DONE)

CLI verify tự động kiểm tra cú pháp và cấu trúc, nhưng bạn bắt buộc phải tự review bằng mắt các điểm logic sau:
* [ ] **ATK/DEF, Level/Rank/Link/Pendulum Scale** trong Specs JSON đã khớp chính xác với effect text gốc.
* [ ] **HOPT vs SOPT:** Đã sử dụng đúng `EFFECT_COUNT_CODE_OATH` kèm ID của card (`{id, N}`) cho Hard Once Per Turn (HOPT)?
* [ ] **Legality check:** Target function bắt buộc phải có `if chk==0 then return ... end`.
* [ ] **Operation Info:** Đã khai báo đúng `Duel.SetOperationInfo` trong target.
* [ ] **Handler Safety:** Đã dùng `Card.GetRelatedHandler(c, e)` trong các operation của trigger/continuous effect.
* [ ] **Zone Safety:** Đã kiểm tra `Duel.GetLocationCount` (hoặc `GetMZoneCount`) > 0 trước khi Special Summon.
* [ ] **Effect Description:** Đã gán đúng `aux.Stringid(id, N)` tương ứng trong `strings` của Specs JSON.

---

## 4. Kiểm Thử Trong Game (EDOPro Test Setup)

### 4.1 Setup Deck Test
1. Mở EDOPro client → Chọn **Deck Edit**.
2. Tạo deck mới, thêm card custom cần test (Tích chọn ô **"Alternate format"** ở bộ lọc tìm kiếm để game hiển thị các custom card).
3. Vào **AI mode** hoặc mở phòng **LAN mode** (Local) để bắt đầu duel thử nghiệm.

### 4.2 Sử dụng Debug Console trong game
Nhấn phím backtick `` ` `` (nằm dưới phím ESC) trong trận đấu để mở debug console của EDOPro và gõ các lệnh Lua trực tiếp để kiểm tra trạng thái:
```lua
-- In ra danh sách card đang có trên Monster Zone của bạn (tp)
=Duel.GetFieldGroup(tp,LOCATION_MZONE,0)

-- Kiểm tra xem trong Deck của bạn có tồn tại card có ID cụ thể hay không
=Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_DECK,0,1,nil,12345678)
```
