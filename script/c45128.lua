--[[
===========================================
  DRAGONBONE CITY STYXIA
  ID: 45128 | Field Spell Card
===========================================

  [HU1 - CONTINUOUS] Chuyển hướng Banish sang Mộ
    - Khi bất kỳ lá bài nào bị Banish, thay vào đó lá đó được đưa
      thẳng vào Mộ (không vào vùng Banish).

  [HU2 - CONTINUOUS] Theo dõi LP và tích Styxia Counter (0x1a1)
    - Theo dõi LP người chơi sau mỗi sự kiện ADJUST.
    - Mỗi khi mất 1000 LP, đặt 1 Styxia Counter lên lá này.

  [HU3 - IGNITION / HOPT] Triệu hồi đặc biệt từ Mộ
    - Chọn 1 quái thú trong Mộ của mình, Triệu hồi đặc biệt nó.
    - Sau đó, người chơi mất LP bằng 1/2 ATK của quái vừa được triệu hồi.

  [HU4 - IGNITION / HOPT] Triệu hồi Pollux (ID: 92047)
    - Chi phí: Xóa TẤT CẢ Styxia Counter trên lá này (tối thiểu 4).
    - Triệu hồi đặc biệt Pollux từ Extra Deck.
    - ATK/DEF của Pollux = (số counter đã xóa) x 1000.
    - Hiệu ứng này không thể bị vô hiệu hóa (EFFECT_FLAG_CANNOT_DISABLE).

===========================================
]]

local s,id=GetID()
s.counter_place_list={0x1a1}

---------------------------------------------------
-- ĐĂNG KÝ HIỆU ỨNG
---------------------------------------------------
function s.initial_effect(c)
    c:EnableCounterPermit(0x1a1)

    -- Kích hoạt Field Spell
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_ACTIVATE)
    e0:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e0)

    -- HU1: Bắt sự kiện Banish, chuyển lá bị banish về Mộ thay vì vùng Removed
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EVENT_REMOVE)
    e1:SetRange(LOCATION_FZONE)
    e1:SetOperation(s.pull_to_gy)
    c:RegisterEffect(e1)

    -- HU2: Theo dõi LP sau mỗi EVENT_ADJUST, đặt Styxia Counter khi mất LP
    -- Label = 0 là giá trị sentinel, s.ctop sẽ khởi tạo LP thực tế trong lần chạy đầu
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_ADJUST)
    e2:SetRange(LOCATION_FZONE)
    e2:SetLabel(0)
    e2:SetOperation(s.ctop)
    c:RegisterEffect(e2)

    -- HU3: Triệu hồi đặc biệt 1 quái thú từ Mộ, mất LP bằng 1/2 ATK của nó (HOPT)
    local e3=Effect.CreateEffect(c)
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DAMAGE)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_FZONE)
    e3:SetCountLimit(1,id)
    e3:SetTarget(s.sptg)
    e3:SetOperation(s.spop)
    c:RegisterEffect(e3)

    -- HU4: Xóa counter để triệu hồi Pollux, ATK/DEF = số counter x 1000 (HOPT riêng)
    local e4=Effect.CreateEffect(c)
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetRange(LOCATION_FZONE)
    e4:SetCountLimit(1,{id,1})
    e4:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e4:SetCost(s.cost)
    e4:SetTarget(s.polluxtg)
    e4:SetOperation(s.polluxop)
    c:RegisterEffect(e4)
end

---------------------------------------------------
-- HU1: CHUYỂN LÁ BỊ BANISH VỀ MỘ
---------------------------------------------------

-- Lọc những lá bài đã vào LOCATION_REMOVED trong EVENT_REMOVE rồi gửi hết về Mộ
function s.pull_to_gy(e,tp,eg,ep,ev,re,r,rp)
    local g=eg:Filter(Card.IsLocation,nil,LOCATION_REMOVED)
    if #g>0 then
        -- Dùng REASON_EFFECT thuần túy; REASON_RETURN chỉ dành cho banish tạm thời
        Duel.Hint(HINT_CARD,0,id)
        Duel.SendtoGrave(g,REASON_EFFECT)
    end
end

---------------------------------------------------
-- HU2: THEO DÕI LP VÀ TÍCH STYXIA COUNTER
---------------------------------------------------

-- Chạy sau mỗi EVENT_ADJUST; tính số LP đã mất và đặt counter tương ứng
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local lp=Duel.GetLP(tp)
    local prev=e:GetLabel()

    -- Lần đầu khởi chạy (sentinel = 0): ghi nhận LP thực tế, không tính counter
    -- Tránh đặt counter nhầm khi LP hiện tại < 8000 lúc Field Spell được kích hoạt
    if prev==0 then
        e:SetLabel(lp)
        return
    end

    -- Mỗi khi mất >= 1000 LP, đặt thêm counter tương ứng
    if lp<prev then
        local lost=prev-lp
        local ct=math.floor(lost/1000)
        if ct>0 then
            c:AddCounter(0x1a1,ct)
        end
    end
    e:SetLabel(lp)
end

---------------------------------------------------
-- HU3: TRIỆU HỒI ĐẶC BIỆT TỪ MỘ
---------------------------------------------------

-- Filter: quái thú trong Mộ có thể được triệu hồi đặc biệt
function s.spfilter(c,e,tp)
    return c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- Kiểm tra điều kiện: có ô MZone trống và có quái thú hợp lệ trong Mộ
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end

-- Triệu hồi quái thú được chọn, sau đó gây sát thương LP bằng 1/2 ATK của nó
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local tc=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp):GetFirst()
    if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
        local atk=tc:GetAttack()
        if atk>0 then
            -- Dùng Duel.Damage để kích hoạt EVENT_DAMAGE và tương tác với hiệu ứng chặn sát thương
            -- (Duel.SetLP ghi đè LP trực tiếp, bỏ qua tất cả damage modifier)
            Duel.Damage(tp,math.floor(atk/2),REASON_EFFECT)
        end
    end
end

---------------------------------------------------
-- HU4: TRIỆU HỒI POLLUX TỪ EXTRA DECK
---------------------------------------------------

-- Chi phí: xóa tất cả Styxia Counter (tối thiểu 4), lưu số lượng vào label để dùng sau
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    local ct=c:GetCounter(0x1a1)
    if chk==0 then return ct>=4 end
    e:SetLabel(ct)
    c:RemoveCounter(tp,0x1a1,ct,REASON_COST)
end

-- Filter: là Pollux (ID 92047) và có thể được triệu hồi đặc biệt
function s.polluxfilter(c,e,tp)
    return c:IsCode(92047) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SPECIAL,tp,false,false)
end

-- Kiểm tra điều kiện: có ô trong Extra Deck zone và Pollux tồn tại trong Extra Deck
function s.polluxtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCountFromEx(tp)>0
            and Duel.IsExistingMatchingCard(s.polluxfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

-- Triệu hồi Pollux và gán ATK/DEF = số counter đã xóa x 1000
function s.polluxop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local ct=e:GetLabel()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local tc=Duel.SelectMatchingCard(tp,s.polluxfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp):GetFirst()
    if tc and Duel.SpecialSummon(tc,SUMMON_TYPE_SPECIAL,tp,tp,false,false,POS_FACEUP)>0 then
        local val=ct*1000
        -- Gán ATK gốc cho Pollux bằng giá trị tính từ counter
        -- Tạo effect từ tc (Pollux) để lifecycle theo Pollux, không theo Field Spell
        local e2=Effect.CreateEffect(tc)
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_SET_BASE_ATTACK)
        e2:SetValue(val)
        e2:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e2)
        -- Gán DEF gốc tương tự (tạo riêng từ tc, không clone)
        local e3=Effect.CreateEffect(tc)
        e3:SetType(EFFECT_TYPE_SINGLE)
        e3:SetCode(EFFECT_SET_BASE_DEFENSE)
        e3:SetValue(val)
        e3:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e3)
    end
end
