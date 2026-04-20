--Maiden of White - Dragon Blessing
local s,id=GetID()

function s.initial_effect(c)

    --(1) Reveal; search + discard + draw
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND+CATEGORY_HANDES+CATEGORY_DRAW)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.cost1)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)

    --(2) Negate from hand
    local e2=Effect.CreateEffect(c)
    e2:SetCategory(CATEGORY_NEGATE)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_CHAINING)
    e2:SetRange(LOCATION_HAND)
    e2:SetCountLimit(1,id+100)
    e2:SetCondition(s.negcon)
    e2:SetCost(s.cost2)
    e2:SetTarget(s.negtg)
    e2:SetOperation(s.negop)
    c:RegisterEffect(e2)

end

---------------------------------------------------
-- EFFECT 1
---------------------------------------------------

function s.cost1(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.ConfirmCards(1-tp,e:GetHandler())
end

function s.thfilter(c)
    return c:ListsCode(89631139) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
            and Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,e:GetHandler())
    end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
    if #g==0 then return end

    Duel.SendtoHand(g,nil,REASON_EFFECT)
    Duel.ConfirmCards(1-tp,g)

    --discard
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
    local dg=Duel.SelectMatchingCard(tp,Card.IsDiscardable,tp,LOCATION_HAND,0,1,1,nil)

    if #dg>0 then
        Duel.SendtoGrave(dg,REASON_EFFECT+REASON_DISCARD)

        if dg:GetFirst():IsCode(89631139) then
            Duel.Draw(tp,1,REASON_EFFECT)
        end
    end

end

---------------------------------------------------
-- EFFECT 2 (FULL CORRECT)
---------------------------------------------------

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return rp==1-tp
        and Duel.IsChainNegatable(ev)
        and re:GetHandler():IsLocation(LOCATION_HAND)
end

function s.cost2(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.ConfirmCards(1-tp,e:GetHandler())
end

--target filter (Blue-Eyes or mentions it AND not used this turn)
function s.cfilter(c,tp)
    return c:IsFaceup()
        and (c:IsCode(89631139) or c:ListsCode(89631139))
        and not Duel.HasFlagEffect(tp,c:GetCode())
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)

    if chk==0 then
        return Duel.IsExistingTarget(s.cfilter,tp,LOCATION_ONFIELD,0,1,nil,tp)
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    local g=Duel.SelectTarget(tp,s.cfilter,tp,LOCATION_ONFIELD,0,1,1,nil,tp)

    local tc=g:GetFirst()
    if tc then
        e:SetLabel(tc:GetCode()) -- lưu tên để lock
    end

    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)

end

function s.negop(e,tp,eg,ep,ev,re,r,rp)

    local code=e:GetLabel()

    if Duel.NegateActivation(ev) then

        --lock không cho target cùng tên nữa trong turn
        Duel.RegisterFlagEffect(tp,code,RESET_PHASE+PHASE_END,0,1)

    end

end