-- ============================================================
-- Card Name: Rank-Up-Magic Rising Force
-- Passcode : 14900001
-- Type     : Spell / Normal
-- Archetype: Rank-Up-Magic (SET_RANK_UP_MAGIC)
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
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCondition(s.condition)
    e1:SetTarget(s.target)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)
end

s.listed_series={SET_RANK_UP_MAGIC}

-- ============================================================
-- Effect 1: Condition — Control no monsters
-- ============================================================
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
end

-- ============================================================
-- Effect 1: Filter — Valid Extra Deck Xyz targets
-- ============================================================
function s.filter2(c,e,tp,mc,pg)
    if c.rum_limit and not c.rum_limit(mc,e) then return false end
    return c:IsType(TYPE_XYZ) and mc:IsType(TYPE_XYZ,c,SUMMON_TYPE_XYZ,tp)
        and c:IsRace(mc:GetRace(),c,SUMMON_TYPE_XYZ,tp)
        and c:IsAttribute(mc:GetAttribute(),c,SUMMON_TYPE_XYZ,tp)
        and c:GetRank() > mc:GetRank()
        and mc:IsCanBeXyzMaterial(c,tp)
        and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
        and (#pg<=0 or pg:IsContains(mc))
        and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end

-- ============================================================
-- Effect 1: Filter — Valid GY targets
-- ============================================================
function s.filter1(c,e,tp)
    local pg=aux.GetMustBeMaterialGroup(tp,Group.FromCards(c),tp,nil,nil,REASON_XYZ)
    return #pg<=1 and c:IsType(TYPE_XYZ) and (c:GetRank()>0 or c:IsStatus(STATUS_NO_LEVEL))
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
        and Duel.IsExistingMatchingCard(s.filter2,tp,LOCATION_EXTRA,0,1,nil,e,tp,c,pg)
end

-- ============================================================
-- Effect 1: Target — Check if Special Summon & target are valid
-- ============================================================
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.filter1(chkc,e,tp) end
    if chk==0 then
        return Duel.IsPlayerCanSpecialSummonCount(tp,2)
            and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingTarget(s.filter1,tp,LOCATION_GRAVE,0,1,nil,e,tp)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectTarget(tp,s.filter1,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,2,tp,LOCATION_GRAVE+LOCATION_EXTRA)
end

-- ============================================================
-- Effect 1: Operation — Perform Rank-up Xyz Summon & take damage
-- ============================================================
function s.operation(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()
    if not tc or not tc:IsRelateToEffect(e) or tc:IsImmuneToEffect(e) then return end
    
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    
    local pg=aux.GetMustBeMaterialGroup(tp,Group.FromCards(tc),tp,nil,nil,REASON_XYZ)
    if #pg>1 or (#pg==1 and not pg:IsContains(tc)) then return end
    
    if Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)==0 then return end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.filter2,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,tc,pg)
    local sc=g:GetFirst()
    if sc then
        Duel.BreakEffect()
        sc:SetMaterial(Group.FromCards(tc))
        Duel.Overlay(sc,tc)
        if Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)>0 then
            sc:CompleteProcedure()
            if c:IsRelateToEffect(e) then
                c:CancelToGrave()
                Duel.Overlay(sc,c)
            end
            local diff=sc:GetRank()-tc:GetRank()
            if diff>0 then
                Duel.Damage(tp,diff*1000,REASON_EFFECT)
            end
        end
    end
end
