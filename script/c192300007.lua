-- ============================================================
-- Card Name: Raisho
-- Passcode : 192300007
-- Type     : Spell / Quick-Play
-- Archetype: Wezaemon (0x783)
-- ============================================================
-- Effect 1: If you control only "Wezaemon the Tombguard": You
--           can pay 800 LP, then target up to 2 monsters your
--           opponent controls, or target up to 5 monsters your
--           opponent controls if they control 5 or more
--           monsters; place them in your opponent's Spell &
--           Trap Zone as Continuous Spell Cards, and banish
--           them when they leave the field.
-- Effect 2: You can banish this card from your GY; Set 1
--           "Nyudogumo" or "Tachikaze" directly from your
--           Deck. It can be activated this turn. You can only
--           use each effect of "Raisho" once per turn.
-- ============================================================

local s,id=GetID()

s.listed_names={192300001,192300008,192300006}

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Quick-Play: Place opponent's monsters as Cont. Spells
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCost(s.cost_lp)
    e1:SetCondition(s.onlywecon)
    e1:SetTarget(s.tg_place)
    e1:SetOperation(s.op_place)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — GY: Banish to Set Nyudogumo or Tachikaze from Deck
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
    e2:SetCountLimit(1,{id,1},EFFECT_COUNT_CODE_OATH)
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
-- Effect 1: Target — Target up to 2 (or 5 if opponent has 5+)
-- ============================================================
function s.placefilter(c)
    return c:IsFaceup()
end

function s.tg_place(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    local omc=Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)
    local maxc=2
    if omc>=5 then maxc=5 end
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and s.placefilter(chkc) end
    if chk==0 then
        return Duel.IsExistingTarget(s.placefilter,tp,0,LOCATION_MZONE,1,nil)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    local g=Duel.SelectTarget(tp,s.placefilter,tp,0,LOCATION_MZONE,1,maxc,nil)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,0,0)
end

-- ============================================================
-- Effect 1: Operation — Place as Continuous Spells in opponent's S/T Zone
-- ============================================================
function s.op_place(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetTargetCards(e)
    if #g==0 then return end
    for tc in g:Iter() do
        if tc:IsRelateToEffect(e) and tc:IsFaceup() then
            -- Check if opponent has available S/T zones
            if Duel.GetLocationCount(1-tp,LOCATION_SZONE)>0 then
                -- Move to opponent's S/T Zone
                Duel.MoveToField(tc,tp,1-tp,LOCATION_SZONE,POS_FACEUP,true)
                -- Change to Continuous Spell
                local e1=Effect.CreateEffect(e:GetHandler())
                e1:SetType(EFFECT_TYPE_SINGLE)
                e1:SetCode(EFFECT_CHANGE_TYPE)
                e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
                e1:SetValue(TYPE_SPELL+TYPE_CONTINUOUS)
                e1:SetReset(RESET_EVENT+RESETS_STANDARD)
                tc:RegisterEffect(e1)
                -- Banish when leaving the field
                local e2=Effect.CreateEffect(e:GetHandler())
                e2:SetType(EFFECT_TYPE_SINGLE)
                e2:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
                e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
                e2:SetValue(LOCATION_REMOVED)
                e2:SetReset(RESET_EVENT+RESETS_STANDARD)
                tc:RegisterEffect(e2)
            end
        end
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
-- Effect 2: Filter — "Nyudogumo" or "Tachikaze" in Deck
-- ============================================================
function s.setdeckfilter(c)
    return (c:IsCode(192300008) or c:IsCode(192300006)) and c:IsSSetable()
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
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
        e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        tc:RegisterEffect(e1)
    end
end
