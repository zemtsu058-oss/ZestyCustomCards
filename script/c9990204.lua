local s,id=GetID()

function s.initial_effect(c)
    c:EnableReviveLimit()
    -- Fusion Material: 1 Spellcaster + 1 LIGHT/1000/2800 Spellcaster
    -- Đã nới lỏng để nhận diện các lá bài được Profusion biến hình
    Fusion.AddProcMix(c,true,true,s.matfilter1,s.matfilter2)

    -- Quick Effect: Negate & Boost
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DISABLE+CATEGORY_ATKCHANGE+CATEGORY_DEFCHANGE)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_MZONE)
    e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.negcost)
    e1:SetTarget(s.negtg)
    e1:SetOperation(s.negop)
    c:RegisterEffect(e1)

    -- Hiệu ứng kháng rời sân: Chống hủy, trục xuất, dội tay/deck
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EFFECT_DESTROY_REPLACE)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetTarget(s.reptg)
    e2:SetOperation(s.repop)
    c:RegisterEffect(e2)
    
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e3:SetCode(EFFECT_SEND_REPLACE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetTarget(s.reptg)
    e3:SetOperation(s.repop)
    c:RegisterEffect(e3)
end

-- ==============================================
-- LOGIC NGUYÊN LIỆU (ĐÃ FIX TỊT NGÒI)
-- ==============================================
function s.matfilter1(c,fc,sumtype,tp)
    return c:IsRace(RACE_SPELLCASTER,fc,sumtype,tp)
end

function s.matfilter2(c,fc,sumtype,tp)
    -- Kiểm tra nếu là triệu hồi Fusion
    local is_fusion = (sumtype & SUMMON_TYPE_FUSION) == SUMMON_TYPE_FUSION
    
    -- Nếu lá bài có hiệu ứng thay thế nguyên liệu (từ Profusion), Verre sẽ nhận luôn
    if is_fusion and c:IsHasEffect(EFFECT_FUSION_SUBSTITUTE) then return true end
    
    -- Điều kiện gốc
    return c:IsRace(RACE_SPELLCASTER,fc,sumtype,tp) 
        and c:IsAttribute(ATTRIBUTE_LIGHT,fc,sumtype,tp)
        and c:IsAttack(1000) and c:IsDefense(2800)
end

-- ==============================================
-- HIỆU ỨNG NEGATE & BOOST
-- ==============================================
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsType,tp,LOCATION_HAND,0,1,nil,TYPE_SPELL) end
    Duel.DiscardHand(tp,Card.IsType,1,1,REASON_COST+REASON_DISCARD,nil,TYPE_SPELL)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_ONFIELD,1,nil) end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_ONFIELD,nil)
    local count=0
    for tc in aux.Next(g) do
        if tc:IsCanBeDisabledByEffect(e) then
            Duel.NegateRelatedChain(tc,RESET_TURN_SET)
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_DISABLE)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
            tc:RegisterEffect(e1)
            local e2=e1:Clone()
            e2:SetCode(EFFECT_DISABLE_EFFECT)
            tc:RegisterEffect(e2)
            count=count+1
        end
    end
    if count>0 and c:IsRelateToEffect(e) and c:IsFaceup() then
        Duel.BreakEffect()
        local e4=Effect.CreateEffect(c)
        e4:SetType(EFFECT_TYPE_SINGLE)
        e4:SetCode(EFFECT_UPDATE_ATTACK)
        e4:SetValue(count*1000)
        e4:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        c:RegisterEffect(e4)
        local e5=e4:Clone()
        e5:SetCode(EFFECT_UPDATE_DEFENSE)
        c:RegisterEffect(e5)
    end
end

-- ==============================================
-- LOGIC BẢO VỆ (REPLACEMENT)
-- ==============================================
function s.repfilter(c)
    return c:IsRace(RACE_SPELLCASTER) and c:IsAbleToDeck()
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    -- Phải do đối thủ tác động và có Spellcaster trong Banish để trả về Deck
    if chk==0 then return c:IsReason(REASON_EFFECT) and rp~=tp 
        and not c:IsStatus(STATUS_DESTROY_CONFIRMED)
        and Duel.IsExistingMatchingCard(s.repfilter,tp,LOCATION_REMOVED,0,1,nil) end
    return Duel.SelectEffectYesNo(tp,c,aux.Stringid(id,1))
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local g=Duel.SelectMatchingCard(tp,s.repfilter,tp,LOCATION_REMOVED,0,1,1,nil)
    if #g>0 then
        Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
        -- Đánh dấu đã thay thế để engine không đẩy Verre rời sân
        e:GetHandler():SetStatus(STATUS_EFFECT_REPLACED,true)
    end
end
