-- ============================================================
-- Card Name: Castle of Dreams - Stage
-- Passcode : 192200009
-- Type     : Spell / Field
-- Archetype: Castle of Dreams (0x782)
-- ============================================================
-- Effect 1: During the Main Phase, if a monster(s) is Special
--           Summoned from the Deck and/or Extra Deck: You can
--           Special Summon 1 "Castle of Dreams" monster from
--           your hand, GY, or banishment.
-- Effect 2: Each turn, when your opponent activates a card or
--           effect that would negate the effect of another card
--           (Quick Effect): You can negate that effect, and if
--           you do, your opponent chooses
--           1 of these effects for you to apply.
--           (1) Both players draw 1 card, then discard 1 card.
--           (2) All monsters on the field gain 500 ATK, but change
--               them to Defense Position.
--           (3) Both players gain 1000 LP, but take 2500 damage
--               during the End Phase of this turn.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Activation — Field Spell placeholder (no on-activation effect)
    -- ============================================================
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_ACTIVATE)
    e0:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e0)

    -- ============================================================
    -- Effect 1 — Trigger during Main Phase: SS a Castle of Dreams monster
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetRange(LOCATION_FZONE)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCondition(s.cond_ss)
    e1:SetTarget(s.tg_ss)
    e1:SetOperation(s.op_ss)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — Quick Effect: Negate opponent's effect negate, opponent chooses replacement
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_NEGATE+CATEGORY_DRAW+CATEGORY_ATKCHANGE+CATEGORY_RECOVER+CATEGORY_DAMAGE)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_CHAINING)
    e2:SetRange(LOCATION_FZONE)
    e2:SetCountLimit(1,id+1,EFFECT_COUNT_CODE_OATH)
    e2:SetCondition(s.cond_negate)
    e2:SetTarget(s.tg_negate)
    e2:SetOperation(s.op_negate)
    c:RegisterEffect(e2)
end

-- ============================================================
-- Effect 1: Filter — Was the SS from Deck or Extra Deck
-- ============================================================
function s.filter_trigger_ss(c)
    local loc=c:GetSummonLocation()
    return c:IsSummonType(SUMMON_TYPE_SPECIAL)
        and (loc==LOCATION_DECK or loc==LOCATION_EXTRA)
end

-- ============================================================
-- Effect 1: Condition — Main Phase + monster SS from Deck/ED
-- ============================================================
function s.cond_ss(e,tp,eg,ep,ev,re,r,rp)
    local ph=Duel.GetCurrentPhase()
    return (ph==PHASE_MAIN1 or ph==PHASE_MAIN2)
        and eg:IsExists(s.filter_trigger_ss,1,nil)
end

-- ============================================================
-- Effect 1: Filter — Castle of Dreams monsters that can be SS
-- ============================================================
function s.filter_ss(c,e,tp)
    return c:IsSetCard(0x782) and c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- ============================================================
-- Effect 1: Target — Check for valid SS targets
-- ============================================================
function s.tg_ss(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        local loc=LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(s.filter_ss,tp,loc,0,1,nil,e,tp)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED)
end

-- ============================================================
-- Effect 1: Operation — Select and SS 1 Castle of Dreams monster
-- ============================================================
function s.op_ss(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.filter_ss,tp,LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- ============================================================
-- Effect 2: Condition — Opponent activated an effect-negate effect
-- ============================================================
function s.cond_negate(e,tp,eg,ep,ev,re,r,rp)
    return rp==1-tp and (re:IsHasCategory(CATEGORY_DISABLE) or re:IsHasCategory(CATEGORY_NEGATE))
        and Duel.IsChainNegatable(ev)
end

-- ============================================================
-- Effect 2: Target — Always true (instant chain response)
-- ============================================================
function s.tg_negate(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,nil,0,0,0)
end

-- ============================================================
-- Effect 2: Operation — Negate opponent's effect, opponent chooses replacement
-- ============================================================
function s.op_negate(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    Duel.NegateActivation(ev)
    Duel.Hint(HINT_SELECTMSG,1-tp,aux.Stringid(id,2))
    local op=Duel.SelectOption(1-tp,aux.Stringid(id,2),aux.Stringid(id,3),aux.Stringid(id,4))
    if op==0 then
        if Duel.IsPlayerCanDraw(tp,1) and Duel.IsPlayerCanDraw(1-tp,1) then
            Duel.Draw(tp,1,REASON_EFFECT)
            Duel.Draw(1-tp,1,REASON_EFFECT)
            Duel.BreakEffect()
            Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_EFFECT+REASON_DISCARD)
            Duel.DiscardHand(1-tp,Card.IsDiscardable,1,1,REASON_EFFECT+REASON_DISCARD)
        end
    elseif op==1 then
        local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
        for tc in aux.Next(g) do
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_UPDATE_ATTACK)
            e1:SetValue(500)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD)
            tc:RegisterEffect(e1)
            if tc:IsAttackPos() then
                Duel.ChangePosition(tc,POS_FACEUP_DEFENSE)
            end
        end
    elseif op==2 then
        Duel.Recover(tp,1000,REASON_EFFECT)
        Duel.Recover(1-tp,1000,REASON_EFFECT)
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
        e1:SetCode(EVENT_PHASE+PHASE_END)
        e1:SetCountLimit(1)
        e1:SetOperation(s.dmgop_end)
        e1:SetReset(RESET_PHASE+PHASE_END)
        Duel.RegisterEffect(e1,tp)
    end
end

-- ============================================================
-- Effect 2 — End Phase damage operation
-- ============================================================
function s.dmgop_end(e,tp,eg,ep,ev,re,r,rp)
    Duel.Damage(tp,2500,REASON_EFFECT)
    Duel.Damage(1-tp,2500,REASON_EFFECT)
end
