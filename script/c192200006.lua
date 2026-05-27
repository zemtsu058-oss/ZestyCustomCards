-- ============================================================
-- Card Name: Morpheus, Corruptor of the Castle of Dreams
-- Passcode : 192200006
-- Type     : Monster / Link / Effect
-- Attribute: DARK
-- Link     : 2
-- ATK       : 2600
-- Race     : Spellcaster
-- Archetype: Castle of Dreams (0x782)
-- Materials: 2 monsters, including a "Castle of Dreams" Spellcaster
-- Markers  : Bottom, Bottom-Right
-- ============================================================
-- Effect 1: If this card is Link Summoned: Set 2 "Castle of
--           Dreams" Traps from your Deck, GY and/or banishment
--           to your field.
-- Effect 2: (Quick Effect): You can Tribute this card, then
--           Special Summon 2 non-Link "Castle of Dreams" monsters
--           from your hand, GY and/or banishment.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    c:EnableReviveLimit()

    -- ============================================================
    -- Summon Procedure — Link Summon: 2 monsters, including a Castle of Dreams Spellcaster
    -- ============================================================
    Link.AddProcedure(c,nil,2,2,s.lcheck)

    -- ============================================================
    -- Effect 1 — Trigger on Link Summon: Set 2 Castle of Dreams Traps
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCondition(s.setcon)
    e1:SetTarget(s.tg_set)
    e1:SetOperation(s.op_set)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — Quick Effect: Tribute self, SS 2 non-Link monsters
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_RELEASE)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e2:SetCost(s.cost_ss)
    e2:SetTarget(s.tg_ss)
    e2:SetOperation(s.op_ss)
    c:RegisterEffect(e2)
end

-- ============================================================
-- Material check — At least 1 Castle of Dreams Spellcaster
-- ============================================================
function s.matfilter(c,lc,sumtype,tp)
    return c:IsSetCard(0x782,lc,sumtype,tp) and c:IsRace(RACE_SPELLCASTER,lc,sumtype,tp)
end

function s.lcheck(g,lc,sumtype,tp)
    return g:IsExists(s.matfilter,1,nil,lc,sumtype,tp)
end

-- ============================================================
-- Effect 1: Condition — Must be Link Summoned
-- ============================================================
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

-- ============================================================
-- Effect 1: Filter — Castle of Dreams Traps that can be Set
-- ============================================================
function s.filter_trap(c)
    return c:IsSetCard(0x782) and c:IsTrap() and c:IsSSetable()
end

-- ============================================================
-- Effect 1: Target — Check if a valid Trap exists anywhere
-- ============================================================
function s.tg_set(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_SZONE)>=2
            and Duel.IsExistingMatchingCard(s.filter_trap,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,2,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_SEARCH,nil,2,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED)
end

-- ============================================================
-- Effect 1: Operation — Select 2 Traps, Set them
-- ============================================================
function s.op_set(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_SZONE)<2 then return end
    local g=Duel.GetMatchingGroup(s.filter_trap,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
    if #g<2 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local sg=g:Select(tp,2,2,nil)
    if #sg>0 then
        Duel.SSet(tp,sg)
    end
end

-- ============================================================
-- Effect 2: Cost — Tribute this card
-- ============================================================
function s.cost_ss(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsReleasable() end
    Duel.Release(e:GetHandler(),REASON_COST)
end

-- ============================================================
-- Effect 2: Filter — Non-Link Castle of Dreams monsters that can be SS
-- ============================================================
function s.filter_ss(c,e,tp)
    return c:IsSetCard(0x782) and c:IsMonster() and not c:IsType(TYPE_LINK)
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- ============================================================
-- Effect 2: Target — Check for valid SS targets
-- ============================================================
function s.tg_ss(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetMZoneCount(tp,e:GetHandler())>=2
            and Duel.IsExistingMatchingCard(s.filter_ss,tp,LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED,0,2,nil,e,tp)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED)
end

-- ============================================================
-- Effect 2: Operation — SS 2 non-Link Castle of Dreams monsters
-- ============================================================
function s.op_ss(e,tp,eg,ep,ev,re,r,rp)
    local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
    if ft<2 then return end
    local g=Duel.GetMatchingGroup(s.filter_ss,tp,LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED,0,nil,e,tp)
    if #g<2 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local sg=g:Select(tp,2,2,nil)
    if #sg>0 then
        local ctl=0
        for tc in aux.Next(sg) do
            if Duel.SpecialSummonStep(tc,0,tp,tp,false,false,POS_FACEUP) then
                ctl=ctl+1
            end
        end
        if ctl>0 then
            Duel.SpecialSummonComplete()
        end
    end
end
