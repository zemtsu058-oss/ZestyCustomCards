-- ============================================================
-- Card Name: Wolff, Servant of the Castle of Dreams
-- Passcode : 192200003
-- Type     : Monster / Effect
-- Attribute: EARTH
-- Level    : 4
-- ATK/DEF  : 1800 / 1600
-- Race     : Illusion
-- Archetype: Castle of Dreams (0x782)
-- ============================================================
-- Effect 1: (Quick Effect): You can Tribute this card; Special
--           Summon 1 "Castle of Dreams" monster from your hand
--           or Deck.
-- Effect 2: If a Field Spell card you control would be destroyed,
--           you can banish this card from your GY, instead.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Quick Effect: Tribute self to SS a Castle of Dreams monster
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCost(s.cost_ss)
    e1:SetTarget(s.tg_ss)
    e1:SetOperation(s.op_ss)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — GY banish: protect Field Spell from destruction
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EFFECT_DESTROY_REPLACE)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,{id,1},EFFECT_COUNT_CODE_OATH)
    e2:SetTarget(s.reptg)
    e2:SetValue(s.repval)
    e2:SetOperation(s.repop)
    c:RegisterEffect(e2)
end

-- ============================================================
-- Effect 1: Cost — Tribute this card
-- ============================================================
function s.cost_ss(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsReleasable() end
    Duel.Release(e:GetHandler(),REASON_COST)
end

-- ============================================================
-- Effect 1: Filter — Castle of Dreams monsters that can be SS
-- ============================================================
function s.filter_ss(c,e,tp)
    return c:IsSetCard(0x782) and c:IsType(TYPE_MONSTER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- ============================================================
-- Effect 1: Target — Check if a valid SS target exists
-- ============================================================
function s.tg_ss(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetMZoneCount(tp,e:GetHandler())>0
            and Duel.IsExistingMatchingCard(s.filter_ss,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end

-- ============================================================
-- Effect 1: Operation — Select and SS 1 Castle of Dreams monster
-- ============================================================
function s.op_ss(e,tp,eg,ep,ev,re,r,rp)
    -- IsRelateToEffect check is not required for tribute-tossed procedure
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.filter_ss,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- ============================================================
-- Effect 2: Filter — face-up Castle of Dreams Field Spell about to be destroyed
-- ============================================================
function s.repfilter(c,tp)
    return c:IsFaceup() and c:IsControler(tp) and c:IsLocation(LOCATION_FZONE)
        and c:IsReason(REASON_EFFECT) and not c:IsReason(REASON_REPLACE)
end

-- ============================================================
-- Effect 2: Target — Ask player if they want to replace
-- ============================================================
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then
        return eg:IsExists(s.repfilter,1,nil,tp)
    end
    return Duel.SelectEffectYesNo(tp,c,96)
end

-- ============================================================
-- Effect 2: Value — Confirm the card qualifies for replacement
-- ============================================================
function s.repval(e,c)
    return s.repfilter(c,e:GetHandlerPlayer())
end

-- ============================================================
-- Effect 2: Operation — Banish this card from GY
-- ============================================================
function s.repop(e,tp,eg,ep,ev,re,r,rp)
    -- IsRelateToEffect check is not required for replacement effect
    local c=e:GetHandler()
    Duel.Remove(c,POS_FACEUP,REASON_EFFECT+REASON_REPLACE)
end
