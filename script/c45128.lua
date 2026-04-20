--Dragonbone City Styxia
local s,id=GetID()

s.counter_place_list={0x1a1}

function s.initial_effect(c)
    c:EnableCounterPermit(0x1a1)

    -- Activate
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_ACTIVATE)
    e0:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e0)

    ---------------------------------------------------
    -- 🔥 FIX: LÔI CỔ BÀI TỪ VÙNG BANISH VỀ MỘ
    ---------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EVENT_REMOVE) -- Bắt sự kiện NGAY SAU KHI bài đã bị Banish
    e1:SetRange(LOCATION_FZONE)
    e1:SetOperation(s.pull_to_gy)
    c:RegisterEffect(e1)

    ---------------------------------------------------
    -- HIỆU ỨNG 2: LP TRACK SYSTEM
    ---------------------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_ADJUST)
    e2:SetRange(LOCATION_FZONE)
    e2:SetLabel(8000) 
    e2:SetOperation(s.ctop)
    c:RegisterEffect(e2)

    ---------------------------------------------------
    -- HIỆU ỨNG 3: TRIỆU HỒI TỪ MỘ
    ---------------------------------------------------
    local e3=Effect.CreateEffect(c)
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_FZONE)
    e3:SetCountLimit(1,id)
    e3:SetTarget(s.sptg)
    e3:SetOperation(s.spop)
    c:RegisterEffect(e3)

    ---------------------------------------------------
    -- HIỆU ỨNG 4: TRIỆU HỒI POLLUX
    ---------------------------------------------------
    local e4=Effect.CreateEffect(c)
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetRange(LOCATION_FZONE)
    e4:SetCountLimit(1,{id,1})
    e4:SetCost(s.cost)
    e4:SetTarget(s.polluxtg)
    e4:SetOperation(s.polluxop)
    c:RegisterEffect(e4)
end

---------------------------------------------------
-- Logic Kéo Bài Vào Mộ (Mấu chốt)
---------------------------------------------------
function s.pull_to_gy(e,tp,eg,ep,ev,re,r,rp)
    -- Tìm trong nhóm bài vừa bị Banish những lá đang nằm ở LOCATION_REMOVED
    local g = eg:Filter(Card.IsLocation, nil, LOCATION_REMOVED)
    
    if #g > 0 then
        -- Kéo toàn bộ chúng ném thẳng vào Mộ
        Duel.Hint(HINT_CARD, 0, id) -- Chớp sáng Field Spell báo hiệu đang can thiệp
        Duel.SendtoGrave(g, REASON_EFFECT+REASON_RETURN)
    end
end

---------------------------------------------------
-- Logic LP 
---------------------------------------------------
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local lp=Duel.GetLP(tp)
    local prev=e:GetLabel()

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
-- Logic Revive
---------------------------------------------------
function s.spfilter(c,e,tp)
    return c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local tc=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp):GetFirst()
    if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
        local atk=tc:GetAttack()
        if atk>0 then
            Duel.SetLP(tp,Duel.GetLP(tp)-math.floor(atk/2))
        end
    end
end

---------------------------------------------------
-- Logic Pollux
---------------------------------------------------
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    local ct=c:GetCounter(0x1a1)
    if chk==0 then return ct>=4 end
    e:SetLabel(ct)
    c:RemoveCounter(tp,0x1a1,ct,REASON_COST)
end

function s.polluxfilter(c,e,tp)
    return c:IsCode(92047) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SPECIAL,tp,false,false)
end

function s.polluxtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCountFromEx(tp)>0
        and Duel.IsExistingMatchingCard(s.polluxfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.polluxop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local ct=e:GetLabel()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local tc=Duel.SelectMatchingCard(tp,s.polluxfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp):GetFirst()
    if tc and Duel.SpecialSummon(tc,SUMMON_TYPE_SPECIAL,tp,tp,false,false,POS_FACEUP)>0 then
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_CANNOT_DISABLE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e1)
        
        local val=ct*1000
        local e2=Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_SET_BASE_ATTACK)
        e2:SetValue(val)
        e2:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e2)
        local e3=e2:Clone()
        e3:SetCode(EFFECT_SET_BASE_DEFENSE)
        tc:RegisterEffect(e3)
    end
end
