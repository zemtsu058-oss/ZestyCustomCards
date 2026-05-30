-- ============================================================
-- Card Name: Teardrop the Rikka Fairy
-- Passcode : 32100001
-- Type     : Monster / Xyz / Effect
-- Attribute: WATER
-- Rank     : 12
-- ATK/DEF  : 4000 / 3500
-- Race     : Plant
-- Archetype: Rikka (0x141)
-- Materials: 2 Level 12 monsters
-- Alt. Xyz : Also by using "Teardrop the Rikka Queen" (33779875)
--            that has 2 Plant overlay materials
-- ============================================================
-- Effect 0: Unaffected by other card effects except Rikka.
-- Effect 1: Detach 1, return 1 Plant (Banish/GY/Field) to hand;
--           then look at opponent's hand, destroy 2 (hand/field).
--           Quick Effect if Plant material. HOPT.
-- Effect 2: Opponent activates → detach 1, negate + banish.
--           Trigger without Plant material, Quick with Plant.
-- Effect 3: Detach 2, destroy all on opponent's field.
--           Quick Effect if Plant material.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    c:EnableReviveLimit()

    -- ============================================================
    -- Summon Procedure — 2 Level 12 + Alt overlay on Rikka Queen
    -- ============================================================
    Xyz.AddProcedure(c,nil,12,2,s.xyzfilter,aux.Stringid(id,0))

    -- ============================================================
    -- Effect 0 — Continuous: Unaffected except by Rikka effects
    -- ============================================================
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e0:SetCode(EFFECT_IMMUNE_EFFECT)
    e0:SetRange(LOCATION_MZONE)
    e0:SetValue(s.immfilter)
    c:RegisterEffect(e0)

    -- ============================================================
    -- Effect 1a — Ignition: Detach 1, return Plant, look+destroy 2
    -- (activates when NO Plant overlay material)
    -- ============================================================
    local e1a=Effect.CreateEffect(c)
    e1a:SetDescription(aux.Stringid(id,1))
    e1a:SetCategory(CATEGORY_TOHAND+CATEGORY_DESTROY)
    e1a:SetType(EFFECT_TYPE_IGNITION)
    e1a:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1a:SetRange(LOCATION_MZONE)
    e1a:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1a:SetCondition(aux.NOT(s.quickcon))
    e1a:SetCost(Cost.DetachFromSelf(1))
    e1a:SetTarget(s.tg_return)
    e1a:SetOperation(s.op_return)
    c:RegisterEffect(e1a)

    -- Effect 1b — Quick-O clone (has Plant material)
    local e1b=e1a:Clone()
    e1b:SetType(EFFECT_TYPE_QUICK_O)
    e1b:SetCode(EVENT_FREE_CHAIN)
    e1b:SetCondition(s.quickcon)
    e1b:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_END_PHASE)
    c:RegisterEffect(e1b)

    -- ============================================================
    -- Effect 2a — Quick-O: Negate activation + banish (during your turn)
    -- (activates when NO Plant overlay material)
    -- ============================================================
    local e2a=Effect.CreateEffect(c)
    e2a:SetDescription(aux.Stringid(id,2))
    e2a:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE)
    e2a:SetType(EFFECT_TYPE_QUICK_O)
    e2a:SetCode(EVENT_CHAINING)
    e2a:SetRange(LOCATION_MZONE)
    e2a:SetCondition(s.negcon_noq)
    e2a:SetCost(Cost.DetachFromSelf(1))
    e2a:SetTarget(s.negtg)
    e2a:SetOperation(s.negop)
    c:RegisterEffect(e2a)

    -- Effect 2b — Quick-O clone (has Plant material, during either turn)
    local e2b=e2a:Clone()
    e2b:SetCondition(s.negcon_q)
    c:RegisterEffect(e2b)

    -- ============================================================
    -- Effect 3a — Ignition: Detach 2, destroy all opponent's field
    -- (activates when NO Plant overlay material)
    -- ============================================================
    local e3a=Effect.CreateEffect(c)
    e3a:SetDescription(aux.Stringid(id,3))
    e3a:SetCategory(CATEGORY_DESTROY)
    e3a:SetType(EFFECT_TYPE_IGNITION)
    e3a:SetRange(LOCATION_MZONE)
    e3a:SetCondition(aux.NOT(s.quickcon))
    e3a:SetCost(Cost.DetachFromSelf(2))
    e3a:SetTarget(s.tg_wipe)
    e3a:SetOperation(s.op_wipe)
    c:RegisterEffect(e3a)

    -- Effect 3b — Quick-O clone (has Plant material)
    local e3b=e3a:Clone()
    e3b:SetType(EFFECT_TYPE_QUICK_O)
    e3b:SetCode(EVENT_FREE_CHAIN)
    e3b:SetCondition(s.quickcon)
    e3b:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_END_PHASE)
    c:RegisterEffect(e3b)
end

-- ============================================================
-- Alt Xyz Filter — "Teardrop the Rikka Queen" with 2 Plant mats
-- ============================================================
function s.xyzfilter(c,tp,xyzc)
    return c:IsFaceup() and c:IsCode(33779875)
        and c:GetOverlayGroup():FilterCount(Card.IsRace,nil,RACE_PLANT)>=2
end

-- ============================================================
-- Shared Condition: Has Plant monster as Xyz material
-- ============================================================
function s.quickcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():GetOverlayGroup():IsExists(Card.IsRace,1,nil,RACE_PLANT)
end

-- ============================================================
-- Effect 0: Immune filter — immune to non-Rikka card effects
-- ============================================================
function s.immfilter(e,re)
    local rc=re:GetHandler()
    return rc and not rc:IsSetCard(0x141)
end

-- ============================================================
-- Effect 1: Filter — Plant monster returnable to hand
-- ============================================================
function s.retfilter(c)
    return c:IsRace(RACE_PLANT) and c:IsAbleToHand()
end

-- ============================================================
-- Effect 1: Filter — Destructible card (for hand/field destroy)
-- ============================================================
function s.desfilter(c)
    return c:IsDestructable()
end

-- ============================================================
-- Effect 1: Target — Select 1 Plant from Banish/GY/Field
-- ============================================================
function s.tg_return(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then
        return chkc:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_ONFIELD)
            and s.retfilter(chkc)
    end
    if chk==0 then
        return Duel.IsExistingTarget(s.retfilter,tp,
            LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_ONFIELD,LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_ONFIELD,1,nil)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
    local g=Duel.SelectTarget(tp,s.retfilter,tp,
        LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_ONFIELD,LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_ONFIELD,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,2,1-tp,LOCATION_HAND+LOCATION_ONFIELD)
end

-- ============================================================
-- Effect 1: Operation — Return Plant, look at hand, destroy 2
-- ============================================================
function s.op_return(e,tp,eg,ep,ev,re,r,rp)
    -- Part 1: Return targeted Plant to hand
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and tc:IsAbleToHand() then
        if Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 and tc:IsLocation(LOCATION_HAND+LOCATION_EXTRA) then
            -- Part 2: Look at opponent's hand
            local hg=Duel.GetFieldGroup(1-tp,LOCATION_HAND,0)
            if #hg>0 then
                Duel.ConfirmCards(tp,hg)
            end
            -- Part 3: Destroy 2 cards in opponent's hand or field
            local dg=Duel.GetMatchingGroup(s.desfilter,tp,0,LOCATION_HAND+LOCATION_ONFIELD,nil)
            if #dg>=2 then
                Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
                local sg=dg:Select(tp,2,2,nil)
                Duel.Destroy(sg,REASON_EFFECT)
            elseif #dg>0 then
                Duel.Destroy(dg,REASON_EFFECT)
            end
            -- Shuffle hand to hide remaining cards
            Duel.ShuffleHand(1-tp)
        end
    end
end

-- ============================================================
-- Effect 2: Condition — Negate (no Plant material, during your turn)
-- ============================================================
function s.negcon_noq(e,tp,eg,ep,ev,re,r,rp)
    return ep==1-tp and Duel.IsChainNegatable(ev) and Duel.GetTurnPlayer()==tp
        and not e:GetHandler():GetOverlayGroup():IsExists(Card.IsRace,1,nil,RACE_PLANT)
end

-- ============================================================
-- Effect 2: Condition — Negate (has Plant material = Quick, during either turn)
-- ============================================================
function s.negcon_q(e,tp,eg,ep,ev,re,r,rp)
    return ep==1-tp and Duel.IsChainNegatable(ev)
        and e:GetHandler():GetOverlayGroup():IsExists(Card.IsRace,1,nil,RACE_PLANT)
end

-- ============================================================
-- Effect 2: Target — Negate activation
-- ============================================================
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    if re:GetHandler():IsRelateToEffect(re) then
        Duel.SetOperationInfo(0,CATEGORY_REMOVE,eg,1,0,0)
    end
end

-- ============================================================
-- Effect 2: Operation — Negate + banish
-- ============================================================
function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) then
        local rc=re:GetHandler()
        if rc:IsRelateToEffect(re) then
            Duel.Remove(rc,POS_FACEUP,REASON_EFFECT)
        end
    end
end

-- ============================================================
-- Effect 3: Filter — Destructible card on field
-- ============================================================
function s.wipefilter(c)
    return c:IsDestructable()
end

-- ============================================================
-- Effect 3: Target — Check opponent has cards on field
-- ============================================================
function s.tg_wipe(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.wipefilter,tp,0,LOCATION_ONFIELD,1,nil)
    end
    local g=Duel.GetMatchingGroup(s.wipefilter,tp,0,LOCATION_ONFIELD,nil)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end

-- ============================================================
-- Effect 3: Operation — Destroy all on opponent's field
-- ============================================================
function s.op_wipe(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(s.wipefilter,tp,0,LOCATION_ONFIELD,nil)
    if #g>0 then
        Duel.Destroy(g,REASON_EFFECT)
    end
end
