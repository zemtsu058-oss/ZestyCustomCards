-- ============================================================
-- Card Name: Seventh Traptrix
-- Passcode : 13800002
-- Type     : Spell / Normal
-- Archetype: Traptrix (0x8a)
-- ============================================================
-- Effect 1: Reveal 1 "Traptrix" Xyz Monster in Extra Deck,
--           discard 1 Level 4 Insect/Plant or 1 Normal Trap;
--           Special Summon 1 Level 4 EARTH monster with the same
--           Type from Deck, then you can Set 1 "Hole" Normal
--           Trap from Deck if it is a "Traptrix" monster.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Reveal and Discard to SS & Set
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)
end

s.listed_series={0x8a, 0x89}

-- ============================================================
-- Effect 1: Filter — Valid Special Summon targets
-- ============================================================
function s.spfilter(c,e,tp,race)
    return c:IsLevel(4) and c:IsAttribute(ATTRIBUTE_EARTH) and c:IsRace(race)
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- ============================================================
-- Effect 1: Filter — Valid Traptrix Xyz monsters in Extra
-- ============================================================
function s.xyzfilter(c,e,tp)
    return c:IsType(TYPE_XYZ) and c:IsSetCard(0x8a)
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp,c:GetRace())
end

-- ============================================================
-- Effect 1: Filter — Valid discard cards
-- ============================================================
function s.discfilter(c)
    return (c:IsLevel(4) and (c:IsRace(RACE_INSECT) or c:IsRace(RACE_PLANT))) or c:IsNormalTrap()
end

-- ============================================================
-- Effect 1: Cost — Reveal 1 Xyz and discard 1 filter card
-- ============================================================
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
            and Duel.IsExistingMatchingCard(s.discfilter,tp,LOCATION_HAND,0,1,nil)
    end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
    local rc=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp):GetFirst()
    Duel.ConfirmCards(1-tp,rc)
    e:SetLabel(rc:GetRace())
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
    local g=Duel.SelectMatchingCard(tp,s.discfilter,tp,LOCATION_HAND,0,1,1,nil)
    Duel.SendtoGrave(g,REASON_COST+REASON_DISCARD)
end

-- ============================================================
-- Effect 1: Target — Check if Special Summon is possible
-- ============================================================
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

-- ============================================================
-- Effect 1: Filter — Valid "Hole" Normal Traps in Deck
-- ============================================================
function s.setfilter(c)
    return c:IsSetCard(0x89) and c:IsNormalTrap() and c:IsSSetable()
end

-- ============================================================
-- Effect 1: Operation — Special Summon and optionally Set
-- ============================================================
function s.operation(e,tp,eg,ep,ev,re,r,rp)
    -- Locked into Xyz & Link from Extra Deck
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
    e1:SetTargetRange(1,0)
    e1:SetTarget(s.splimit)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
    
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    local race=e:GetLabel()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp,race)
    if #g>0 then
        local tc=g:GetFirst()
        if Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
            if tc:IsSetCard(0x8a) and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil)
                and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
                Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
                local sg=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
                if #sg>0 then
                    Duel.SSet(tp,sg)
                end
            end
        end
    end
end

-- ============================================================
-- Effect 1: Extra Summon Restriction
-- ============================================================
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
    return c:IsLocation(LOCATION_EXTRA) and not (c:IsType(TYPE_XYZ) or c:IsType(TYPE_LINK))
end
