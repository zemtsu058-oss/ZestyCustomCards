-- ============================================================
-- Card Name: Knowledge of the White Forest
-- Passcode : 42600003
-- Type     : Spell / Quick-Play
-- Archetype: White Forest (0x1aa)
-- ============================================================
-- Effect 1: Target 1 "White Forest" card you control; its effects cannot be negated for the rest of this turn, then you can add 1 Spell from your GY to your hand.
-- Effect 2: If this card is sent to the GY to activate a monster effect: You can Set this card.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Protection + GY Spell search
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.tg_protect)
    e1:SetOperation(s.op_protect)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — GY recovery
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,2))
    e2:SetCategory(CATEGORY_LEAVE_GRAVE+CATEGORY_SET)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.con_set)
    e2:SetTarget(s.tg_set)
    e2:SetOperation(s.op_set)
    c:RegisterEffect(e2)
end

-- ============================================================
-- Effect 1: Filter — White Forest card on field
-- ============================================================
function s.filter_protect(c)
    return c:IsFaceup() and c:IsSetCard(0x1aa)
end

-- ============================================================
-- Effect 1: Target — Target 1 White Forest card on field
-- ============================================================
function s.tg_protect(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsOnField() and chkc:IsControler(tp) and s.filter_protect(chkc) end
    if chk==0 then return Duel.IsExistingTarget(s.filter_protect,tp,LOCATION_ONFIELD,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    local g=Duel.SelectTarget(tp,s.filter_protect,tp,LOCATION_ONFIELD,0,1,1,nil)
    Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end

-- ============================================================
-- Effect 1: Operation — Protect target, then optionally add Spell from GY
-- ============================================================
function s.op_protect(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
        -- Cannot be negated
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_CANNOT_DISABLE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        tc:RegisterEffect(e1)
        local e2=e1:Clone()
        e2:SetCode(EFFECT_CANNOT_DISEFFECT)
        tc:RegisterEffect(e2)

        -- Optionally add 1 Spell from GY to hand
        if Duel.IsExistingMatchingCard(Card.IsType,tp,LOCATION_GRAVE,0,1,nil,TYPE_SPELL)
            and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
            Duel.BreakEffect()
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
            local g=Duel.SelectMatchingCard(tp,Card.IsType,tp,LOCATION_GRAVE,0,1,1,nil,TYPE_SPELL)
            if #g>0 then
                Duel.SendtoHand(g,nil,REASON_EFFECT)
                Duel.ConfirmCards(1-tp,g)
            end
        end
    end
end

-- ============================================================
-- Effect 2: Condition — Sent to GY as cost for monster effect
-- ============================================================
function s.con_set(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:IsReason(REASON_COST) and re and re:IsActivated() and re:IsMonsterEffect()
end

-- ============================================================
-- Effect 2: Target — Set this card
-- ============================================================
function s.tg_set(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsSSetable() end
    Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,c,1,tp,0)
end

-- ============================================================
-- Effect 2: Operation — SSet this card from GY
-- ============================================================
function s.op_set(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) and c:IsSSetable() then
        Duel.SSet(tp,c)
    end
end
