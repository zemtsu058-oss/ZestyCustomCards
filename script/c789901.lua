-- Hanako - The Loving Defender Forever
local s,id=GetID()

function s.initial_effect(c)
    -- Fusion procedure
    c:EnableReviveLimit()
    -- Material: 1 "Artemis" + 1 "Hanako" + 1+ Effect Monsters
    Fusion.AddProcMixRep(c,true,true,s.mat_effect,1,99,s.mat_artemis,s.mat_hanako)

    -- E1: Immunity (Kháng tất cả trừ Artemis hoặc archetype 0x789)
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCode(EFFECT_IMMUNE_EFFECT)
    e1:SetValue(s.immuneval)
    c:RegisterEffect(e1)

    -- E2: Quick Effect - Cho 1 quái thú khác khả năng kháng hiệu ứng (trừ chính nó)
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,id)
    e2:SetCost(s.immcost)
    e2:SetTarget(s.immtg)
    e2:SetOperation(s.immop)
    c:RegisterEffect(e2)

    -- E3: Leave field -> Special Summon "Artemis" (Chắc chắn là Quái thú)
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_LEAVE_FIELD)
    e3:SetCondition(s.spcon)
    e3:SetTarget(s.sptg)
    e3:SetOperation(s.spop)
    c:RegisterEffect(e3)
end

-- Material filters
function s.mat_artemis(c) return c:IsCode(79900008) end
function s.mat_hanako(c) return c:IsCode(76900007) end
function s.mat_effect(c) return c:IsType(TYPE_EFFECT) end

-- E1: Immunity logic
function s.immuneval(e,te)
    local tc=te:GetOwner()
    -- Không kháng hiệu ứng từ card có ID 79900008 hoặc thuộc set 0x789
    if tc:IsCode(79900008) or tc:IsSetCard(0x789) then return false end
    
    -- Kiểm tra tên Artemis bằng chuỗi (string search)
    local name = nil
    if tc.GetTextName then name = tc:GetTextName()
    elseif tc.GetName then name = tc:GetName() end
    
    if name and type(name)=="string" then
        if string.find(string.lower(name), "artemis") then return false end
    end
    
    return true
end

-- E2: Quick Effect logic
function s.immcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
    Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end
function s.immtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and chkc:IsFaceup() and chkc~=e:GetHandler() end
    if chk==0 then return Duel.IsExistingTarget(aux.FaceupFilter(Card.IsMonster),tp,LOCATION_MZONE,0,1,e:GetHandler()) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
    Duel.SelectTarget(tp,aux.FaceupFilter(Card.IsMonster),tp,LOCATION_MZONE,0,1,1,e:GetHandler())
end
function s.immop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsFaceup() and tc:IsRelateToEffect(e) then
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_IMMUNE_EFFECT)
        -- Miễn nhiễm hiệu ứng trừ hiệu ứng của chính nó (tc)
        e1:SetValue(function(e,te) return te:GetOwner()~=tc end)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        tc:RegisterEffect(e1)
    end
end

-- E3: Special Summon logic (Xác định chắc chắn là quái thú Artemis)
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsPreviousLocation(LOCATION_MZONE)
end
function s.spfilter(c,e,tp)
    -- Phải là Quái thú và có thể Đặc triệu hồi
    if not (c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,false,false)) then return false end
    
    -- Check mã ID trực tiếp
    if c:IsCode(79900008) then return true end
    
    -- Check chuỗi tên "artemis" (không phân biệt hoa thường)
    local name = nil
    if c.GetTextName then name = c:GetTextName()
    elseif c.GetName then name = c:GetName() end
    
    if name and type(name)=="string" then
        return string.find(string.lower(name), "artemis") ~= nil
    end
    return false
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp)
    if #g>0 then 
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP) 
    end
end
