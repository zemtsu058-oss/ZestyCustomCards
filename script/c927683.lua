local s,id=GetID()
function s.initial_effect(c)

    -- Equip (face-up monster)
    aux.AddEquipProcedure(c,nil,aux.FilterBoolFunction(Card.IsFaceup))

    -- Extra attack
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_EQUIP)
    e1:SetCode(EFFECT_EXTRA_ATTACK)
    e1:SetValue(1)
    c:RegisterEffect(e1)

    -- GY effect
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_TOGRAVE+CATEGORY_TOHAND)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetCountLimit(1,id)
    e2:SetCondition(s.thcon)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
end

-------------------------------------------------
-- CONDITION (2 NHÁNH RIÊNG)
-------------------------------------------------
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()

    -- 🔹 Nhánh 1: discard từ tay (bất kỳ effect nào)
    if c:IsPreviousLocation(LOCATION_HAND)
        and (r&(REASON_EFFECT|REASON_COST|REASON_DISCARD))~=0 then
        return true
    end

    -- 🔹 Nhánh 2: đang equip và bị Desire Hero gửi
    if c:IsPreviousLocation(LOCATION_SZONE)
        and re and re:GetHandler()
        and re:GetHandler():IsSetCard(0x927)
        and (r&(REASON_EFFECT|REASON_COST))~=0 then
        return true
    end

    return false
end

-------------------------------------------------
-- FILTER EXTRA
-------------------------------------------------
function s.exfilter(c)
    return c:IsSetCard(0x927)
        and c:IsType(TYPE_MONSTER)
        and c:IsAbleToGrave()
end

-------------------------------------------------
-- TARGET
-------------------------------------------------
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return e:GetHandler():IsAbleToHand()
            and Duel.IsExistingMatchingCard(s.exfilter,tp,LOCATION_EXTRA,0,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_EXTRA)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end

-------------------------------------------------
-- OPERATION
-------------------------------------------------
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.exfilter,tp,LOCATION_EXTRA,0,1,1,nil)

    if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)>0 then
        if c:IsRelateToEffect(e) then
            Duel.BreakEffect()
            Duel.SendtoHand(c,nil,REASON_EFFECT)
        end
    end
end