-- ============================================================
-- Card Name: Tachikaze
-- Passcode : 192300006
-- Type     : Spell / Quick-Play
-- Archetype: Wezaemon (0x783)
-- ============================================================
-- Effect 1: If you control only "Wezaemon the Tombguard": You
--           can pay 800 LP, then target 1 monster your opponent
--           controls; destroy it.
-- Effect 2: You can banish this card from your GY; Set 1
--           "Tachikaze" or "Raisho" directly from your Deck.
--           It can be activated this turn. You can only use
--           this effect of "Tachikaze" once per turn.
-- ============================================================

local s,id=GetID()

s.listed_names={192300001,id,192300007}

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Quick-Play activation: Destroy 1 opponent's monster
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DESTROY)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCost(s.cost_lp)
    e1:SetCondition(s.onlywecon)
    e1:SetTarget(s.tg_destroy)
    e1:SetOperation(s.op_destroy)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — GY: Banish to Set Tachikaze or Raisho from Deck
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
    e2:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e2:SetCost(s.cost_banish)
    e2:SetTarget(s.tg_set_deck)
    e2:SetOperation(s.op_set_deck)
    c:RegisterEffect(e2)
end

-- ============================================================
-- Condition — You control only "Wezaemon the Tombguard"
-- ============================================================
function s.onlywecon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)>0
        and not Duel.IsExistingMatchingCard(s.nonwefilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.nonwefilter(c)
    return not c:IsCode(192300001)
end

-- ============================================================
-- Cost — Pay 800 LP
-- ============================================================
function s.cost_lp(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.CheckLPCost(tp,800) end
    Duel.PayLPCost(tp,800)
end

-- ============================================================
-- Effect 1: Target — Target 1 opponent's monster
-- ============================================================
function s.tg_destroy(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) end
    if chk==0 then
        return Duel.IsExistingTarget(Card.IsDestructable,tp,0,LOCATION_MZONE,1,nil)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g=Duel.SelectTarget(tp,Card.IsDestructable,tp,0,LOCATION_MZONE,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

-- ============================================================
-- Effect 1: Operation — Destroy the targeted monster
-- ============================================================
function s.op_destroy(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.Destroy(tc,REASON_EFFECT)
    end
end

-- ============================================================
-- Effect 2: Cost — Banish from GY
-- ============================================================
function s.cost_banish(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsAbleToRemoveAsCost() end
    Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end

-- ============================================================
-- Effect 2: Filter — "Tachikaze" or "Raisho" in Deck
-- ============================================================
function s.setdeckfilter(c)
    return (c:IsCode(192300006) or c:IsCode(192300007)) and c:IsSSetable()
end

-- ============================================================
-- Effect 2: Target — Check if valid Set target exists
-- ============================================================
function s.tg_set_deck(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.setdeckfilter,tp,LOCATION_DECK,0,1,nil)
    end
end

-- ============================================================
-- Effect 2: Operation — Set from Deck + can activate this turn
-- ============================================================
function s.op_set_deck(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local g=Duel.SelectMatchingCard(tp,s.setdeckfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        local tc=g:GetFirst()
        Duel.SSet(tp,tc)
        -- Allow activation this turn
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
        e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        tc:RegisterEffect(e1)
    end
end
