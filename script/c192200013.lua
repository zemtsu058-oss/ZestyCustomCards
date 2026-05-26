-- ============================================================
-- Card Name: Castle of Dreams - Breakout
-- Passcode : 192200013
-- Type     : Trap / Normal
-- Archetype: Castle of Dreams (0x782)
-- ============================================================
-- Effect 1: If 3 or more monsters were Special Summoned from your
--           opponent's Deck and/or Extra Deck this turn, while you
--           control a "Castle of Dreams" Field Spell: Destroy any
--           number of cards on the field, then you can Special
--           Summon 1 monster from your GY or banishment.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    s.global_check(c)

    -- ============================================================
    -- Effect 1 — Normal Trap activation: Destroy + optional SS
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCondition(s.condition)
    e1:SetTarget(s.tg_destroy)
    e1:SetOperation(s.op_destroy)
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
-- Effect 1: Filter — Destructible cards on the field
-- ============================================================
function s.filter_destroy(c)
    return c:IsDestructable()
end

-- ============================================================
-- Effect 1: Target — Check for cards to destroy
-- ============================================================
function s.tg_destroy(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.filter_destroy,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,0,LOCATION_ONFIELD)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
end

-- ============================================================
-- Effect 1: Filter — Monsters in GY or banishment that can be SS
-- ============================================================
function s.filter_ss_gy(c,e,tp)
    return c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- ============================================================
-- Effect 1: Operation — Destroy selected cards, then optionally SS
-- ============================================================
function s.op_destroy(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(s.filter_destroy,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
    if #g>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
        local dg=g:Select(tp,1,#g,nil)
        if #dg>0 then
            Duel.Destroy(dg,REASON_EFFECT)
        end
    end
    if Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.filter_ss_gy,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp)
        and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local sg=Duel.SelectMatchingCard(tp,s.filter_ss_gy,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,e,tp)
        if #sg>0 then
            Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
        end
    end
end
