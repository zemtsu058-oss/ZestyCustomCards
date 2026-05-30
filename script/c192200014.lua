-- ============================================================
-- Card Name: Castle of Dreams - Fall
-- Passcode : 192200014
-- Type     : Trap / Normal
-- Archetype: Castle of Dreams (0x782)
-- ============================================================
-- Effect 1: If 3 or more monsters were Special Summoned from your
--           opponent's Deck and/or Extra Deck this turn, while you
--           control a "Castle of Dreams" Field Spell: Your opponent
--           sends cards from their hand or Extra Deck to the GY
--           equal to the number of cards in their GY, then you can
--           place 1 Field Spell from your Deck, GY, or banishment
--           face-up on your field.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    s.global_check(c)

    -- ============================================================
    -- Effect 1 — Normal Trap activation: Opponent mills, then place Field Spell
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_LEAVE_GRAVE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCondition(s.condition)
    e1:SetTarget(s.tg_mill)
    e1:SetOperation(s.op_mill)
    c:RegisterEffect(e1)
end

-- ============================================================
-- Effect 1: Filter — Castle of Dreams Field Spell
-- ============================================================
function s.filter_fspell(c)
    return c:IsFaceup() and c:IsSetCard(0x782) and c:IsType(TYPE_FIELD)
end

-- ============================================================
-- Global tracker: Count monsters each player Special Summons from Deck/ED this turn
-- ============================================================
function s.global_check(c)
    if s.global_checked then return end
    s.global_checked=true
    local ge=Effect.CreateEffect(c)
    ge:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    ge:SetCode(EVENT_SPSUMMON_SUCCESS)
    ge:SetOperation(s.regop)
    Duel.RegisterEffect(ge,0)
end

function s.regfilter(c)
    local loc=c:GetSummonLocation()
    return c:IsSummonType(SUMMON_TYPE_SPECIAL)
        and (loc==LOCATION_DECK or loc==LOCATION_EXTRA)
end

function s.regop(e,tp,eg,ep,ev,re,r,rp)
    for tc in aux.Next(eg) do
        if s.regfilter(tc) then
            Duel.RegisterFlagEffect(tc:GetSummonPlayer(),id,RESET_PHASE+PHASE_END,0,1)
        end
    end
end

-- ============================================================
-- Effect 1: Condition — You control a Field Spell + 3+ opponent SS from Deck/ED
-- ============================================================
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(s.filter_fspell,tp,LOCATION_FZONE,0,1,nil)
        and Duel.GetFlagEffect(1-tp,id)>=3
end

-- ============================================================
-- Effect 1: Target — Calculate how many cards opponent will send
-- ============================================================
function s.tg_mill(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    local ct=Duel.GetFieldGroupCount(tp,0,LOCATION_GRAVE)
    local sent_ct=math.min(ct,Duel.GetFieldGroupCount(tp,0,LOCATION_HAND+LOCATION_EXTRA))
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,sent_ct,1-tp,LOCATION_HAND+LOCATION_EXTRA)
end

-- ============================================================
-- Effect 1: Filter — Any Field Spell that can be placed
-- ============================================================
function s.filter_fspell_any(c)
    return c:IsFieldSpell() and not c:IsForbidden()
end

-- ============================================================
-- Effect 1: Operation — Opponent mills, then optionally place a Field Spell
-- ============================================================
function s.op_mill(e,tp,eg,ep,ev,re,r,rp)
    local ct=Duel.GetFieldGroupCount(tp,0,LOCATION_GRAVE)
    if ct>0 then
        local g_h=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
        local g_ed=Duel.GetFieldGroup(tp,0,LOCATION_EXTRA)
        local avail=#g_h+#g_ed
        if avail>0 then
            ct=math.min(ct,avail)
            Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_TOGRAVE)
            local sg=Duel.SelectMatchingCard(1-tp,nil,1-tp,LOCATION_HAND+LOCATION_EXTRA,0,ct,ct,nil)
            if #sg>0 then
                Duel.SendtoGrave(sg,REASON_EFFECT)
            end
        end
    end
    if Duel.IsExistingMatchingCard(s.filter_fspell_any,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil)
        and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
        local sg=Duel.SelectMatchingCard(tp,s.filter_fspell_any,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
        if #sg>0 then
            local tc=sg:GetFirst()
            local fc=Duel.GetFieldCard(tp,LOCATION_FZONE,0)
            if fc then
                Duel.SendtoGrave(fc,REASON_RULE)
                Duel.BreakEffect()
            end
            Duel.MoveToField(tc,tp,tp,LOCATION_FZONE,POS_FACEUP,true)
        end
    end
end
