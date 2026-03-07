local s,id=GetID()
function s.initial_effect(c)
    -- Quick effect
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_DUEL)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)
end

s.listed_names={94145021}

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsDiscardable() end
    Duel.SendtoGrave(e:GetHandler(),REASON_COST+REASON_DISCARD)
end

function s.revealfilter(c)
    return c:IsType(TYPE_NORMAL)
        and c:IsRace(RACE_DRAGON)
        and c:IsAttribute(ATTRIBUTE_LIGHT)
        and c:GetAttack()==3000
        and c:GetDefense()==2500
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.revealfilter,tp,0,LOCATION_HAND+LOCATION_DECK,1,nil)
        and Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_DECK,0,1,nil,94145021)
    end

    -- KHÔNG AI CÓ THỂ CHAIN
    Duel.SetChainLimit(aux.FALSE)

    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_CONFIRM)
    local g=Duel.SelectMatchingCard(1-tp,s.revealfilter,1-tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil)
    if #g==0 then return end
    Duel.ConfirmCards(tp,g)

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local dg=Duel.SelectMatchingCard(tp,Card.IsCode,tp,LOCATION_DECK,0,1,1,nil,94145021)
    if #dg==0 then return end
    Duel.SendtoHand(dg,nil,REASON_EFFECT)
    Duel.ConfirmCards(1-tp,dg)

    -- Protect Droll activation
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_CANNOT_INACTIVATE)
    e1:SetTargetRange(1,0)
    e1:SetValue(function(e,ct)
        local te=Duel.GetChainInfo(ct,CHAININFO_TRIGGERING_EFFECT)
        return te and te:GetHandler():IsCode(94145021)
    end)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)

    -- Protect Droll effect
    local e2=Effect.CreateEffect(e:GetHandler())
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_CANNOT_DISEFFECT)
    e2:SetTargetRange(1,0)
    e2:SetValue(function(e,ct)
        local te=Duel.GetChainInfo(ct,CHAININFO_TRIGGERING_EFFECT)
        return te and te:GetHandler():IsCode(94145021)
    end)
    e2:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e2,tp)
end