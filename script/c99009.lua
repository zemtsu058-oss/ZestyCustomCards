--Cây Súng Ngàn Năm
local s,id=GetID()

WIN_REASON_FIVEGUN=0x55

function s.initial_effect(c)

    --Quick negate from hand
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY+CATEGORY_HANDES)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_CHAINING)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.negcon)
    e1:SetCost(s.negcost)
    e1:SetTarget(s.negtg)
    e1:SetOperation(s.negop)
    c:RegisterEffect(e1)

    --Register chain info
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_CHAINING)
    e2:SetOperation(s.regop)
    Duel.RegisterEffect(e2,0)

    --Win condition if negated
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e3:SetCode(EVENT_CHAIN_NEGATED)
    e3:SetOperation(s.winop)
    Duel.RegisterEffect(e3,0)

end

--Opponent activates effect
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return rp==1-tp and Duel.IsChainNegatable(ev)
end

--Pay 1000 LP
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.CheckLPCost(tp,1000) end
    Duel.PayLPCost(tp,1000)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    if re:GetHandler():IsRelateToEffect(re) then
        Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
    end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)

    if Duel.NegateActivation(ev) then

        local rc=re:GetHandler()

        if rc and rc:IsRelateToEffect(re) then
            Duel.Destroy(rc,REASON_EFFECT)
        end

        --Look opponent hand
        local g=Duel.GetFieldGroup(tp,0,LOCATION_HAND)

        if #g>0 then
            Duel.ConfirmCards(tp,g)
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
            local sg=g:Select(tp,1,1,nil)
            Duel.SendtoGrave(sg,REASON_EFFECT+REASON_DISCARD)
            Duel.ShuffleHand(1-tp)
        end

    end

end

--Mark chain if this card effect
function s.regop(e,tp,eg,ep,ev,re,r,rp)
    if re:GetHandler():IsCode(id) then
        s.chain_player=rp
    end
end

--Win if opponent negates this effect
function s.winop(e,tp,eg,ep,ev,re,r,rp)

    if re and re:GetHandler():IsCode(id) then
        local owner=s.chain_player
        if owner then
            Duel.Win(owner,WIN_REASON_FIVEGUN)
        end
    end

end