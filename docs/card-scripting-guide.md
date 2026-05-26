# EDOPro Card Scripting Guide — TTF Custom Cards

Tài liệu tham khảo đầy đủ để lập trình card cho EDOPro, dựa trên ProjectIgnis CardScripts API v41+.

## Mục lục

1. [Kiến trúc tổng quan](#1-kiến-trúc-tổng-quan)
2. [Cấu trúc script cơ bản](#2-cấu-trúc-script-cơ-bản)
3. [Các loại Effect](#3-các-loại-effect)
4. [Filter Function (Bộ lọc)](#4-filter-function-bộ-lọc)
5. [Summon Procedure](#5-summon-procedure)
6. [Cost Patterns](#6-cost-patterns)
7. [Common Pitfalls (Lỗi thường gặp)](#7-common-pitfalls-lỗi-thường-gặp)
8. [Auto-Code Workflow](#8-auto-code-workflow)
9. [Tham khảo API](#9-tham-khảo-api)

---

## 1. Kiến trúc tổng quan

### Các thành phần

| Thành phần | Định dạng | Vị trí |
|-----------|----------|--------|
| Database | `.cdb` (SQLite) | `expansions/` hoặc root repo |
| Script | `cXXXXXXXXX.lua` (Lua 5.3) | `script/` |
| Ảnh | `.png` / `.jpg` | `pics/` |
| Strings | `strings.conf` | root repo |
| Constants | `constants.lua` | `script/` |

### Nguyên lý hoạt động

```
Card Database (.cdb) → passcode/ID → tìm script cXXXXXXXXX.lua → gọi initial_effect(c)
```

Mỗi card có một **passcode** duy nhất (8-9 chữ số). Script được đặt tên `c` + passcode + `.lua`.

### ID Ranges cần tránh (đã dùng bởi EDOPro chính thức)

| Range | Mục đích |
|-------|---------|
| 1–99999999 | Official TCG/OCG cards |
| 10ZXXXXXX | Pre-release cards |
| 100XXXXXX | Video Game cards |
| 160XXXXXX | Rush cards |
| 300XXXXXX | Skill cards |
| 5XXXXXXXX, 200XXXXXX, 800XXXXXX, 810XXXXXX | Anime/Manga |

**Khuyến nghị**: Dùng 9 chữ số bắt đầu bằng range riêng (ví dụ: `7XXXXXXXX`).

---

## 2. Cấu trúc script cơ bản

### Template tối thiểu

```lua
-- Tên Card
local s,id=GetID()
function s.initial_effect(c)
end
```

- `s` — table riêng của card này, chứa tất cả helper functions
- `id` — passcode của card (integer)
- `initial_effect(c)` — hàm bắt buộc, engine gọi khi bắt đầu duel

### Cấu trúc effect cơ bản

Mỗi effect đều có 4 phần:

```lua
function s.initial_effect(c)
    local e1=Effect.CreateEffect(c)              -- 1. Tạo effect
    e1:SetDescription(aux.Stringid(id,0))         -- 2. Mô tả (dùng string từ database)
    e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND) -- 3. Category
    e1:SetType(EFFECT_TYPE_...)                    -- 4. Loại effect
    e1:SetCode(EVENT_...)                          -- 5. Event trigger
    e1:SetRange(LOCATION_...)                      -- 6. Vị trí hoạt động
    e1:SetCountLimit(1,id)                         -- 7. Giới hạn số lần
    e1:SetTarget(s.target)                         -- 8. Điều kiện kích hoạt
    e1:SetOperation(s.activate)                    -- 9. Hành động khi resolve
    c:RegisterEffect(e1)                           -- 10. Đăng ký effect
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return ... end     -- Kiểm tra có thể kích hoạt không
    Duel.SetOperationInfo(0,...)       -- Khai báo sẽ làm gì
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    -- Thực thi effect
end
```

### Tham số của callback functions

| Tham số | Ý nghĩa |
|---------|---------|
| `e` | Effect đang xử lý |
| `tp` | Turn player (hoặc controller của effect) |
| `eg` | Event group (các card liên quan đến event) |
| `ep` | Event player |
| `ev` | Event value |
| `re` | Reason effect |
| `r` | Reason |
| `rp` | Reason player |
| `chk` | `0` = check legality, `1` = thực thi activation |

---

## 3. Các loại Effect

### 3.1 Trigger Effect (Kích hoạt khi sự kiện xảy ra)

```lua
-- "If this card is Normal Summoned: You can..."
e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)  -- O = Optional
e1:SetCode(EVENT_SUMMON_SUCCESS)
e1:SetTarget(s.tgtg)
e1:SetOperation(s.tgop)
```

Các EVENT phổ biến:

| EVENT | Mô tả |
|-------|-------|
| `EVENT_SUMMON_SUCCESS` | Triệu hồi thành công |
| `EVENT_SPSUMMON_SUCCESS` | Special Summon thành công |
| `EVENT_TO_GRAVE` | Vào mộ |
| `EVENT_TO_HAND` | Vào tay |
| `EVENT_BATTLE_DESTROYING` | Tiêu diệt trong battle |
| `EVENT_BATTLE_DESTROYED` | Bị tiêu diệt trong battle |
| `EVENT_DESTROYED` | Bị destroy |
| `EVENT_PHASE+PHASE_STANDBY` | Standby Phase |
| `EVENT_PHASE+PHASE_END` | End Phase |
| `EVENT_CHAINING` | Chain link đang được kích hoạt |
| `EVENT_CHAIN_END` | Chain kết thúc |
| `EVENT_DAMAGE_STEP_END` | Kết thúc Damage Step |
| `EVENT_DRAW` | Rút bài |

Trigger Effect trên field của đối thủ (FIELD):

```lua
-- "If your opponent Normal Summons a monster..."
e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
e1:SetCode(EVENT_SUMMON_SUCCESS)
e1:SetRange(LOCATION_MZONE)  -- card này phải ở Monster Zone
e1:SetCondition(s.condition) -- lọc thêm điều kiện
```

### 3.2 Ignition Effect (Kích hoạt trong Main Phase)

```lua
-- "Once per turn: You can..."
e1:SetType(EFFECT_TYPE_IGNITION)
e1:SetRange(LOCATION_MZONE)
e1:SetCountLimit(1)
e1:SetTarget(s.igtg)
e1:SetOperation(s.igop)
```

### 3.3 Quick Effect (Kích hoạt bất cứ lúc nào)

```lua
-- "During either player's turn: You can..."
e1:SetType(EFFECT_TYPE_QUICK_O)
e1:SetCode(EVENT_FREE_CHAIN)
e1:SetRange(LOCATION_MZONE)
e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER)
e1:SetTarget(s.qtg)
e1:SetOperation(s.qop)
```

Quick Effect để negate:

```lua
-- "When your opponent activates a card or effect: You can negate..."
e1:SetType(EFFECT_TYPE_QUICK_O)
e1:SetCode(EVENT_CHAINING)
e1:SetRange(LOCATION_MZONE)
e1:SetCondition(s.negcon)  -- ep~=tp and Duel.IsChainNegatable(ev)
e1:SetTarget(s.negtg)
e1:SetOperation(s.negop)
```

### 3.4 Continuous Effect (Luôn hoạt động)

```lua
-- "All monsters you control gain 500 ATK"
e1:SetType(EFFECT_TYPE_FIELD)
e1:SetCode(EFFECT_UPDATE_ATTACK)
e1:SetRange(LOCATION_MZONE)
e1:SetTargetRange(LOCATION_MZONE,0)  -- của mình
e1:SetTarget(s.atktg)
e1:SetValue(500)
```

### 3.5 Spell/Trap Activation (Lá Spell/Trap)

```lua
-- Normal Spell
e1:SetType(EFFECT_TYPE_ACTIVATE)
e1:SetCode(EVENT_FREE_CHAIN)
e1:SetTarget(s.target)
e1:SetOperation(s.activate)

-- Field Spell
e1:SetType(EFFECT_TYPE_ACTIVATE)
e1:SetCode(EVENT_FREE_CHAIN)
-- Field cần thêm vị trí:
e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
e2:SetRange(LOCATION_FZONE)
e2:SetCode(EVENT_PHASE+PHASE_STANDBY)
```

### 3.6 Pendulum Effect

```lua
function s.initial_effect(c)
    -- Monster effect
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e1)

    -- Pendulum effect (dùng SetRange khác)
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_PZONE)
    e2:SetCountLimit(1)
    c:RegisterEffect(e2)
end
```

---

## 4. Filter Function (Bộ lọc)

Filter functions được dùng trong `IsExistingMatchingCard`, `SelectMatchingCard`, etc.

### Pattern cơ bản

```lua
function s.filter(c)
    return c:IsFaceup() and c:IsSetCard(0x128) and c:IsAbleToHand()
end
```

### Filter có tham số phụ

```lua
function s.filter(c,e,tp)
    return c:IsLevel(4) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- Gọi:
Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK,0,1,nil,e,tp)
```

### aux.FilterBoolFunction — Filter inline

```lua
-- Thay vì tạo function riêng:
local g=Duel.GetMatchingGroup(aux.FilterBoolFunction(Card.IsRace,RACE_SPELLCASTER),tp,LOCATION_MZONE,0,nil)
```

### Các hàm filter phổ biến

```lua
aux.FilterBoolFunction(Card.IsFaceup)
aux.FilterBoolFunction(Card.IsType,TYPE_MONSTER)
aux.FilterBoolFunction(Card.IsSetCard,0x128)
aux.FilterBoolFunction(Card.IsRace,RACE_SPELLCASTER)
aux.FilterBoolFunction(Card.IsAttribute,ATTRIBUTE_DARK)
aux.FilterBoolFunction(Card.IsLevel,4)
aux.FilterBoolFunctionEx(Card.IsCanBeSpecialSummoned)
aux.FaceupFilter(Card.IsCode,12345678)
aux.NecroValleyFilter(...)

-- Kết hợp filter với AND/OR:
local filter=aux.AND(aux.FilterBoolFunction(Card.IsFaceup),aux.FilterBoolFunction(Card.IsRace,RACE_SPELLCASTER))
```

### Target function pattern

```lua
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK,0,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
```

---

## 5. Summon Procedure

### Fusion Summon

```lua
function s.initial_effect(c)
    c:EnableReviveLimit()
    -- Must be Fusion Summoned
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_SPSUMMON_CONDITION)
    e1:SetValue(aux.fuslimit)
    c:RegisterEffect(e1)
end
```

Hoặc dùng shortcut:

```lua
c:EnableReviveLimit()
Card.AddMustBeFusionSummoned(c)
```

### Synchro Summon

```lua
-- Tuner monster tự summon:
-- Không cần code thêm, engine tự xử lý Synchro summon
-- Chỉ cần set TYPE_TUNER trong database
```

### Xyz Summon

```lua
-- Dùng proc_xyz.lua:
-- Thêm dòng sau initial_effect:
aux.AddXyzProcedure(c,nil,4,2)  -- nil filter, Rank 4, 2 materials
```

### Link Summon

```lua
-- Dùng proc_link.lua:
Link.AddProcedure(c,nil,2,2)  -- nil filter, Link-2, min 2 materials
```

### Special Summon từ tay (built-in)

```lua
function s.spcondition(e,c)
    if c==nil then return true end
    return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
end
function s.spoperation(e,tp,eg,ep,ev,re,r,rp,c)
    -- Không cần code, engine tự xử lý
end

-- Trong initial_effect:
local e1=Effect.CreateEffect(c)
e1:SetType(EFFECT_TYPE_SINGLE)
e1:SetCode(EFFECT_SPSUMMON_CONDITION)
e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
c:RegisterEffect(e1)
```

### Special Summon bằng effect riêng (trigger trong tay)

```lua
-- "You can Special Summon this card (from your hand) by..."
local e1=Effect.CreateEffect(c)
e1:SetType(EFFECT_TYPE_FIELD)
e1:SetCode(EFFECT_SPSUMMON_PROC)
e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
e1:SetRange(LOCATION_HAND)
e1:SetCondition(s.spcon)
e1:SetOperation(s.spop)
c:RegisterEffect(e1)
```

---

## 6. Cost Patterns

### Discard self (hand trap)

```lua
e1:SetCost(aux.DiscardCost(Card.IsDiscardable))  -- discard chính nó
e1:SetCost(Cost.SelfDiscard)                       -- shortcut
```

### Tribute self

```lua
e1:SetCost(Cost.SelfTribute)
```

### Send self to GY

```lua
e1:SetCost(Cost.SelfToGrave)
```

### Banish self

```lua
e1:SetCost(Cost.SelfBanish)
```

### Detach Xyz material

```lua
e1:SetCost(Cost.DetachFromSelf(1))
```

### Pay LP

```lua
e1:SetCost(Cost.PayLP(1000))        -- Pay exactly 1000
e1:SetCost(Cost.PayLP(0.5))         -- Pay half
```

### Discard từ tay (không phải chính nó)

```lua
e1:SetCost(Cost.Discard(aux.FilterBoolFunction(Card.IsSetCard,0x128),false,1,1))
-- filter, other (có bao gồm chính nó?), min, max
```

---

## 7. Common Pitfalls (Lỗi thường gặp)

### 7.1 Thiếu `chk==0` check

```lua
-- SAI:
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    Duel.SetOperationInfo(0,...)  -- Không check chk==0 trước!
end

-- ĐÚNG:
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(...) end
    Duel.SetOperationInfo(0,...)
end
```

### 7.2 Quên `Duel.SetOperationInfo`

Effect cần target hoặc destroy/search phải khai báo trong target function:

```lua
Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
```

### 7.3 Dùng sai EVENT cho Trigger Effect

```lua
-- "If this card is Summoned": dùng EVENT_SUMMON_SUCCESS
-- "If this card is Special Summoned": dùng EVENT_SPSUMMON_SUCCESS
-- Không dùng EVENT_SUMMON_SUCCESS cho SPSUMMON
```

### 7.4 `IsRelateToEffect` và `IsRelateToBattle`

Luôn kiểm tra card còn tồn tại trước khi thực thi operation:

```lua
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end  -- BẮT BUỘC
    -- ... thực thi effect
end
```

### 7.5 SetCountLimit sai pattern

```lua
-- Mỗi card 1 lần/turn (soft once per turn):
e1:SetCountLimit(1)

-- Mỗi card 1 lần/turn với ID riêng:
e1:SetCountLimit(1,id)

-- Tất cả card cùng tên 1 lần/turn (hard once per turn):
e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
```

### 7.6 Reset flag sai

```lua
-- Reset đến cuối turn:
e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)

-- Reset đến cuối turn này (kể cả standby/end):
e1:SetReset(RESET_PHASE+PHASE_END)

-- Reset 1 lần (dùng trong operation):
e1:SetReset(RESET_EVENT+RESETS_STANDARD)
```

### 7.7 Quên `c:IsFaceup()` trong condition

```lua
-- Effect cần card face-up trên field mới hoạt động:
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsFaceup()  -- BẮT BUỘC
end
```

### 7.8 Không kiểm tra zone trống khi Special Summon

```lua
if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
-- Hoặc trong chk==0:
if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
    and Duel.IsExistingMatchingCard(...) end
```

---

## 8. Auto-Code Workflow

### Quy trình tạo card mới

```
1. Thiết kế text effect → phân tích thành các effect con
2. Tạo database entry (.cdb) với DataEditorX
3. Chọn template phù hợp → sinh script
4. Validate script (chạy tests)
5. Test trong EDOPro
```

### Phân tích effect thành code

| Text Pattern | Loại Effect | Template |
|-------------|-------------|----------|
| "If/When ... is Normal/Special Summoned: You can..." | Trigger O | 3.1 |
| "Once per turn: You can..." | Ignition | 3.2 |
| "(Quick Effect): You can..." | Quick | 3.3 |
| "All ... gain/lose ..." | Continuous | 3.4 |
| "Target 1 ...; destroy it" | Target + Destroy | 4 + CATEGORY_DESTROY |
| "Add 1 ... from your Deck to your hand" | Search | CATEGORY_SEARCH+TOHAND |
| "Special Summon 1 ... from your ..." | SS | CATEGORY_SPECIAL_SUMMON |
| "Negate the activation, and if you do, destroy it" | Negate | CATEGORY_NEGATE+DISABLE |

### Sinh code tự động với AI

Khi dùng AI để sinh code, cung cấp prompt theo format:

```
Tạo card script EDOPro (Lua 5.3) cho card sau:

Name: [tên card]
Type: [Monster/Spell/Trap] / [Effect/Normal/Fusion/...]
Attribute: [DARK/LIGHT/...]
Level/Rank/Link: [số]
ATK/DEF: [số/số]
Race: [Spellcaster/Dragon/...]
Archetype: [0xXXX nếu có]

Effect text:
[Full effect text tiếng Anh, mỗi effect 1 dòng]

Yêu cầu:
- Dùng GetID() cho table/ID
- SetCategory đầy đủ
- SetCountLimit đúng (hard/soft once per turn)
- Kiểm tra IsRelateToEffect trong operation
- Dùng aux.FilterBoolFunction cho filter đơn giản
```

---

## 9. Tham khảo API

### Card.* methods thường dùng

```lua
c:IsFaceup()           c:IsLocation(loc)
c:IsSetCard(setcode)   c:IsCode(code)
c:IsType(type)         c:IsRace(race)
c:IsAttribute(att)     c:IsLevel(lv)
c:GetAttack()          c:GetDefense()
c:IsAbleToHand()       c:IsAbleToGrave()
c:IsAbleToRemove()     c:IsReleasable()
c:IsCanBeSpecialSummoned(e,sumtype,tp,...)
c:IsRelateToEffect(e)  c:IsRelateToBattle()
c:IsHasEffect(code)    c:GetCounter(ctype)
c:AddCounter(tp,ctype,count)
c:RemoveCounter(tp,ctype,count,reason)
c:RegisterEffect(e)    c:GetControler()
c:GetOwner()           c:IsOriginalType(type)
```

### Duel.* methods thường dùng

```lua
Duel.GetLocationCount(tp,loc)
Duel.IsExistingMatchingCard(filter,tp,loc1,loc2,min,exclude,...)
Duel.SelectMatchingCard(tp,filter,...)
Duel.GetMatchingGroup(filter,tp,loc1,loc2,exclude,...)
Duel.SendtoGrave(g,reason)
Duel.SendtoHand(g,p,reason)
Duel.Remove(g,pos,reason)
Duel.Destroy(g,reason)
Duel.Release(g,reason)
Duel.SpecialSummon(g,sumtype,tp,tp,ignore,...)
Duel.SetOperationInfo(0,category,g,count,player,location)
Duel.NegateEffect(ev)
Duel.NegateActivation(ev)
Duel.Damage(player,amount,reason)
Duel.Recover(player,amount,reason)
Duel.Draw(player,count,reason)
Duel.ShuffleDeck(player)
Duel.GetTurnPlayer()
Duel.IsMainPhase()
Duel.IsBattlePhase()
```

### Hằng số (từ constant.lua)

```lua
-- Card Types
TYPE_MONSTER    TYPE_SPELL     TYPE_TRAP
TYPE_NORMAL     TYPE_EFFECT    TYPE_FUSION
TYPE_RITUAL     TYPE_SYNCHRO   TYPE_XYZ
TYPE_PENDULUM   TYPE_LINK      TYPE_TOKEN
TYPE_QUICKPLAY  TYPE_CONTINUOUS TYPE_EQUIP
TYPE_FIELD      TYPE_COUNTER

-- Locations
LOCATION_DECK   LOCATION_HAND   LOCATION_MZONE
LOCATION_SZONE  LOCATION_GRAVE  LOCATION_REMOVED
LOCATION_EXTRA  LOCATION_OVERLAY LOCATION_FZONE
LOCATION_PZONE  LOCATION_ONFIELD

-- Attributes
ATTRIBUTE_DARK  ATTRIBUTE_LIGHT ATTRIBUTE_EARTH
ATTRIBUTE_WATER ATTRIBUTE_FIRE  ATTRIBUTE_WIND
ATTRIBUTE_DIVINE

-- Phases
PHASE_DRAW      PHASE_STANDBY   PHASE_MAIN1
PHASE_BATTLE    PHASE_MAIN2     PHASE_END

-- Reset flags
RESET_EVENT     RESETS_STANDARD  RESET_PHASE
RESET_TURN_SET  RESET_TOFIELD   RESET_TOGRAVE
RESET_LEAVE     RESET_TOHAND

-- Categories (cho SetCategory)
CATEGORY_DESTROY   CATEGORY_TOHAND    CATEGORY_TODECK
CATEGORY_REMOVE    CATEGORY_TOGRAVE   CATEGORY_SPECIAL_SUMMON
CATEGORY_SEARCH    CATEGORY_DRAW     CATEGORY_RECOVER
CATEGORY_ATKCHANGE CATEGORY_DEFCHANGE CATEGORY_NEGATE
CATEGORY_DISABLE   CATEGORY_DICE     CATEGORY_COIN
CATEGORY_CONTROL   CATEGORY_EQUIP    CATEGORY_DAMAGE
CATEGORY_RELEASE   CATEGORY_SUMMON   CATEGORY_TOKEN
CATEGORY_COUNTER   CATEGORY_POSITION
```

### External Links

- **CardScripts Wiki**: https://github.com/ProjectIgnis/CardScripts/wiki
- **Scrapi-book (API docs mới)**: https://projectignis.github.io/scrapi-book/
- **utility.lua (mã nguồn aux functions)**: https://github.com/ProjectIgnis/CardScripts/blob/master/utility.lua
- **constant.lua (tất cả constants)**: https://github.com/ProjectIgnis/CardScripts/blob/master/constant.lua
- **Official Card Scripts (tham khảo)**: https://github.com/ProjectIgnis/CardScripts/tree/master/official
- **EDOPro Client**: https://github.com/edo9300/edopro
- **Discord hỗ trợ**: `#card-scripting-101` trên Project Ignis Discord
