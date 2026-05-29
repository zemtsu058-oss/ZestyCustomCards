# Critical Rules — Lua Scripting

> Đọc file này khi: viết hoặc sửa bất kỳ script Lua nào.

---

## Script Rules (BẮT BUỘC — KHÔNG ĐƯỢC VI PHẠM)

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
11. **CRITICAL — NEVER** tham chiếu hay copy code từ bất kỳ script nào trong `script/`. Toàn bộ source hiện tại đang có rất nhiều lỗi (thiếu `EFFECT_COUNT_CODE_OATH`, sai category, sai reset, sai `SetSPSummonOnce`, sai `Stringid` mapping, v.v.). **Chỉ dùng template trong `template-card/` và document trong `docs/` làm reference.**
12. **ALWAYS** dùng template trong `template-card/` làm base

---

## Code Quality

- Hàm filter/target/operation dùng tên có ý nghĩa: `filter_search`, `tg_destroy`, `op_revive`, v.v.
- Mỗi effect block phải có comment `-- Effect N — Mô tả ngắn gọn`
- Giữ text effect gốc trong header comment của file
- Hàm filter đặt trước hàm target, hàm target trước hàm operation

---

## Git & Infrastructure

- **KHÔNG tự động commit** — chỉ commit khi user yêu cầu.
- **KHÔNG tự động push** — chỉ push khi user yêu cầu.
- **Cấu trúc Commit Message bắt buộc:**
  * Format: `[<Git User Name>] [<Type>]: <Mô tả ngắn bằng tiếng Anh>` (Trong đó `<Git User Name>` được lấy động từ cấu hình `git config user.name` của hệ thống)
  * Các `<Type>` hợp lệ:
    * `[Fix]`: Sửa lỗi script, sửa hiệu ứng, sửa DB sai thông tin.
    * `[Feature]`: Thêm card mới, script mới hoặc hiệu ứng mới.
    * `[Chore]`: Cập nhật cấu hình, cập nhật database chung, dọn dẹp file.
    * `[Refactor]`: Tái cấu trúc thư mục, tối ưu hóa code không làm thay đổi tính năng.
- File trong `docs/`, `template-card/`, `script-test/` là infrastructure — giữ sạch.
