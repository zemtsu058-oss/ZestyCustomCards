-- ============================================================
-- Card Name: Castle of Dreams - Iris's Necklace
-- Passcode : 192200011
-- Type     : Spell / Normal
-- Archetype: Castle of Dreams (0x782)
-- ============================================================
-- Effect 1: Special Summon 1 "Castle of Dreams" Illusion monster
--           from your Deck or GY, or if your opponent controls a
--           monster that was Special Summoned from their Deck or
--           Extra Deck, you can Special Summon 1 "Castle of Dreams"
--           Spellcaster monster instead.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Normal Spell activation: SS Castle of Dreams monster
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetTarget(s.tg_ss)
    e1:SetOperation(s.op_ss)
    c:RegisterEffect(e1)
end

-- ============================================================
-- Effect 1: Filter — Opponent's monster SS from Deck or Extra Deck
-- ============================================================
function s.filter_opp(c,tp)
    local loc=c:GetSummonLocation()
    return c:IsSummonType(SUMMON_TYPE_SPECIAL)
        and (loc==LOCATION_DECK or loc==LOCATION_EXTRA)
end

-- ============================================================
-- ============================================================
-- Effect 1: Filter — Castle of Dreams Illusion or optionally Spellcaster monster
-- ============================================================
function s.filter_ss(c,e,tp,opp_ss)
    if not (c:IsSetCard(0x782) and c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,false,false)) then return false end
    return c:IsRace(0x2000000) or (opp_ss and c:IsRace(RACE_SPELLCASTER))
end

-- ============================================================
-- Effect 1: Target — Check for valid SS targets based on condition
-- ============================================================
function s.tg_ss(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return false end
        local opp_ss=Duel.IsExistingMatchingCard(s.filter_opp,tp,0,LOCATION_MZONE,1,nil,tp)
        return Duel.IsExistingMatchingCard(s.filter_ss,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp,opp_ss)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

-- ============================================================
-- Effect 1: Operation — SS appropriate monster based on condition
-- ============================================================
function s.op_ss(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    local opp_ss=Duel.IsExistingMatchingCard(s.filter_opp,tp,0,LOCATION_MZONE,1,nil,tp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.filter_ss,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp,opp_ss)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end
