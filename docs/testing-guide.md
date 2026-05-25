# EDOPro Card Testing Guide — TTF Custom Cards

Hướng dẫn kiểm tra và phát hiện lỗi cho card script EDOPro.

## Mục lục

1. [Kiểm tra nhanh](#1-kiểm-tra-nhanh)
2. [Validation tự động (PowerShell)](#2-validation-tự-động-powershell)
3. [Luacheck (Lua Linter)](#3-luacheck-lua-linter)
4. [Test trong EDOPro](#4-test-trong-edopro)
5. [Checklist kiểm tra card](#5-checklist-kiểm-tra-card)
6. [Common bug patterns và cách fix](#6-common-bug-patterns-và-cách-fix)

---

## 1. Kiểm tra nhanh

Trước khi test trong game, chạy các lệnh sau từ terminal:

```powershell
# Kiểm tra syntax tất cả script .lua
Get-ChildItem script\*.lua | ForEach-Object {
    $file = $_.Name
    $path = $_.FullName
    Write-Host -NoNewline "$file ... "
    $result = & lua -e "local f,e=loadfile('$path'); if f then return 'OK' else return e end" 2>&1
    if ($LASTEXITCODE -eq 0) { Write-Host "OK" -ForegroundColor Green }
    else { Write-Host "ERROR: $result" -ForegroundColor Red }
}

# Hoặc dùng script đã tạo sẵn:
.\script-test\validate_scripts.ps1
```

## 2. Validation tự động (PowerShell)

Script `script-test/validate_scripts.ps1` kiểm tra:

| Check | Mô tả |
|-------|-------|
| `SYNTAX` | Cú pháp Lua hợp lệ |
| `INIT_EFFECT` | Có function `initial_effect` |
| `GETID` | Có gọi `GetID()` |
| `REGISTER_EFFECT` | Có ít nhất 1 `RegisterEffect` |
| `SETCODE` | Có SetCode cho mỗi Effect.CreateEffect |
| `SETTYPE` | Có SetType cho mỗi Effect.CreateEffect |
| `TARGET_CHK` | Có `if chk==0 then return` trong SetTarget |

### Cách dùng

```powershell
# Validate tất cả scripts
.\script-test\validate_scripts.ps1

# Validate 1 file cụ thể
.\script-test\validate_scripts.ps1 -Path script\c22121392.lua
```

### Yêu cầu

- **Lua 5.3+** đã cài đặt (tải từ https://luabinaries.sourceforge.net/)
- Đã thêm `lua.exe` vào PATH

### Output mẫu

```
=== TTF Card Script Validator ===
Scanning: script/

✓ OK  c10472.lua
✗ WARN c22121392.lua
     L122: Thiếu IsRelateToEffect check trong operation
✓ OK  c33816.lua
✗ FAIL c9990204.lua
     Missing: initial_effect function

Results: 55 OK, 2 WARN, 1 FAIL
```

---

## 3. Luacheck (Lua Linter)

### Cài đặt

Luacheck là Lua linter mạnh hơn, phát hiện unused variables, undefined globals, etc.

```powershell
# Cài LuaRocks trước (https://luarocks.org/)
# Sau đó:
luarocks install luacheck
```

### Cấu hình `.luacheckrc`

```lua
-- .luacheckrc (đặt ở root project)
std = "lua53"
globals = {
    "aux", "Card", "Duel", "Effect", "Group",
    "GetID", "Debug", "c946",
    -- Constants từ constant.lua
    "TYPE_MONSTER", "TYPE_SPELL", "TYPE_TRAP",
    "LOCATION_DECK", "LOCATION_HAND", "LOCATION_MZONE",
    "EVENT_SUMMON_SUCCESS", "EVENT_FREE_CHAIN",
    "CATEGORY_SEARCH", "CATEGORY_TOHAND",
    -- Thêm tất cả constants khác...
}
ignore = {
    "211", -- unused variable (thường là tham số callback)
    "212", -- unused argument
}
```

### Chạy

```powershell
luacheck script/ --config .luacheckrc
```

---

## 4. Test trong EDOPro

### Setup test deck

1. Mở EDOPro → Deck Edit
2. Tạo deck mới, thêm card cần test (tích "Alternate format" để thấy custom cards)
3. Vào AI mode hoặc LAN mode để test

### Test từng effect

| Effect type | Cách test |
|-------------|-----------|
| Search/Add | Kiểm tra card có được thêm vào tay đúng không |
| Special Summon | Kiểm tra vị trí summon, điều kiện, giới hạn |
| ATK/DEF change | Dùng `F1` để xem ATK/DEF hiện tại |
| Negate | Test chain với card khác |
| Destroy/Remove | Kiểm tra card đích có về đúng location không |
| Continuous | Kiểm tra stat thay đổi khi card rời field |
| Phase trigger | Chờ đúng phase để kiểm tra |

### Debug console

Nhấn `` ` `` (backtick) trong duel để mở debug console, gõ:

```lua
-- Xem card đang chọn
=Duel.GetFieldGroup(tp,LOCATION_MZONE,0)

-- Kiểm tra card tồn tại
=Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_DECK,0,1,nil,12345678)
```

---

## 5. Checklist kiểm tra card

Trước khi commit, kiểm tra từng mục:

### Database (.cdb)

- [ ] Passcode/ID không trùng card khác
- [ ] Đúng card type (Monster/Spell/Trap + sub-type)
- [ ] Đúng ATK/DEF/Level/Rank/Link/Scale
- [ ] Đúng Attribute, Race
- [ ] Đúng Archetype (setcode)
- [ ] OT = Custom (cho custom card)
- [ ] Có đầy đủ card text

### Script (.lua)

- [ ] File đặt tên đúng `cXXXXXXXXX.lua`
- [ ] Có `local s,id=GetID()`
- [ ] Có `function s.initial_effect(c) ... end`
- [ ] Mỗi `Effect.CreateEffect` có đủ `SetType`, `SetCode`
- [ ] Trigger effect có SetCode đúng EVENT
- [ ] Ignition/Quick effect có SetRange
- [ ] `SetCountLimit` đúng (soft/hard once per turn)
- [ ] Target function có `if chk==0 then return ... end`
- [ ] Target function có `Duel.SetOperationInfo` (nếu destroy/search/SS)
- [ ] Operation function có `IsRelateToEffect` check (nếu cần)
- [ ] Dùng `aux.Stringid(id,N)` cho mô tả effect
- [ ] Reset flag đúng
- [ ] Không có biến undefined
- [ ] Không dùng tên function trùng với card khác

### Ảnh (nếu có)

- [ ] Định dạng PNG hoặc JPG
- [ ] Tên file = passcode (VD: `12345678.png`)
- [ ] Đặt trong `pics/`

---

## 6. Common bug patterns và cách fix

### Bug 1: Effect không kích hoạt được

**Triệu chứng**: Card vào game nhưng không prompt kích hoạt effect.

**Nguyên nhân thường gặp**:
- Sai EVENT code
- Thiếu SetRange (effect cần LOCATION)
- Condition function trả về false
- SetCountLimit hết lượt

**Fix**:
```lua
-- Thêm debug print để kiểm tra:
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    local result = ...  -- logic của bạn
    -- Debug: in ra để kiểm tra
    Debug.Message("Condition check: "..tostring(result))
    return result
end
```

### Bug 2: Game crash khi resolve effect

**Triệu chứng**: EDOPro crash hoặc báo lỗi khi effect resolve.

**Nguyên nhân thường gặp**:
- Truy cập card đã bị destroy/remove trước đó
- Group operation trên group rỗng
- Sai tham số cho SpecialSummon

**Fix**:
```lua
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end  -- LUÔN check
    
    local g=Duel.GetMatchingGroup(s.filter,tp,LOCATION_DECK,0,nil)
    if #g==0 then return end  -- LUÔN check group không rỗng
    
    -- SpecialSummon:
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
end
```

### Bug 3: Search/add sai card

**Triệu chứng**: Search không tìm thấy card dù có trong deck.

**Nguyên nhân**:
- Filter function quá chặt
- `IsExistingMatchingCard` thiếu tham số exclude
- Nhầm LOCATION (deck vs hand vs extra)

### Bug 4: Effect chain sai thứ tự

**Triệu chứng**: Effect bắt buộc kích hoạt sai timing.

**Nguyên nhân**:
- Dùng `TRIGGER_O` thay vì `TRIGGER_F` cho mandatory effect
- Thiếu `HINTMSG` trong selection

### Bug 5: Once per turn không reset

**Triệu chứng**: Card chỉ dùng được 1 lần trong cả duel.

**Nguyên nhân**:
```lua
-- SAI: Không có reset flag
e1:SetCountLimit(1)

-- ĐÚNG: Reset mỗi turn
e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_SINGLE)
```

### Bug 6: Continuous effect vẫn hoạt động sau khi rời field

**Triệu chứng**: Monster bị destroy nhưng ATK boost vẫn còn.

**Nguyên nhân**:
```lua
-- SAI: Thiếu SetRange
e1:SetType(EFFECT_TYPE_FIELD)
e1:SetCode(EFFECT_UPDATE_ATTACK)

-- ĐÚNG: Thêm SetRange
e1:SetType(EFFECT_TYPE_FIELD)
e1:SetCode(EFFECT_UPDATE_ATTACK)
e1:SetRange(LOCATION_MZONE)  -- Chỉ hoạt động khi card ở MZONE
```

---

## Fix workflow

Khi phát hiện bug:

```
1. Xác định effect nào bị lỗi (đọc text card → tìm effect tương ứng trong script)
2. Check từng phần: Condition → Cost → Target → Operation
3. Thêm Debug.Message() để in giá trị trung gian
4. Test trong EDOPro debug console
5. Fix → chạy validate_scripts.ps1 → test lại
```

### Ví dụ debug script

```lua
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        local count=Duel.GetMatchingGroupCount(s.filter,tp,LOCATION_DECK,0,nil)
        Debug.Message("Filter found "..count.." cards in deck")
        return count>0
    end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
```
