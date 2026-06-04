-- ============================================================
-- Card Name: Rank-Up-Magic Rising Force
-- Passcode : 14900001
-- Type     : Spell / Normal
-- Archetype: Rank-Up-Magic (0x95)
-- ============================================================
-- Effect 1: Special Summon 1 Xyz Monster from your GY, then
--           Special Summon from your Extra Deck 1 Xyz Monster
--           with the same Type and Attribute but higher Rank
--           (treated as Xyz Summon, attach the GY monster and
--           this card as materials, take damage equal to the
--           difference in Ranks * 1000).
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Special Summon from GY and Rank-Up Xyz Summon
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.condition)
    e1:SetTarget(s.target)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)
end

s.listed_series={0x95}

-- ============================================================
-- Effect 1: Condition — Control no monsters
-- ============================================================
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
end

-- ============================================================
-- Effect 1: Filter — Valid Extra Deck Xyz targets
-- ============================================================
function s.spfilter(c,e,tp,race,attr,rank)
    return c:IsType(TYPE_XYZ) and c:IsRace(race) and c:IsAttribute(attr)
        and c:GetRank() > rank
        and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end

-- ============================================================
-- Effect 1: Filter — Valid GY targets
-- ============================================================
function s.gyfilter(c,e,tp)
    if not (c:IsType(TYPE_XYZ) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)) then return false end
    return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,c:GetRace(),c:GetAttribute(),c:GetRank())
end

-- ============================================================
-- Effect 1: Target — Check if Special Summon & target are valid
-- ============================================================
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.gyfilter(chkc,e,tp) end
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingTarget(s.gyfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectTarget(tp,s.gyfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,2,tp,LOCATION_GRAVE+LOCATION_EXTRA)
end

-- ============================================================
-- Effect 1: Operation — Perform Rank-up Xyz Summon & take damage
-- ============================================================
function s.operation(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()
    if not tc or not tc:IsRelateToEffect(e) then return end
    
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    if Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)==0 then return end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,tc:GetRace(),tc:GetAttribute(),tc:GetRank())
    local sc=g:GetFirst()
    if sc then
        sc:SetMaterial(Group.FromCards(tc))
        if Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)>0 then
            local og=Group.CreateGroup()
            og:AddCard(tc)
            if c:IsRelateToEffect(e) then
                og:AddCard(c)
            end
            Duel.Overlay(sc,og)
            sc:CompleteProcedure()
            
            local diff=math.abs(sc:GetRank()-tc:GetRank())
            Duel.Damage(tp,diff*1000,REASON_EFFECT)
        end
    end
end
