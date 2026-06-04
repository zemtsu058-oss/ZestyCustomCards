-- ============================================================
-- Card Name: Return of the Red Ant
-- Passcode : 13800001
-- Type     : Spell / Normal
-- Archetype: Traptrix (0x8a)
-- ============================================================
-- Effect 1: Special Summon 1 EARTH Insect or Plant monster from
--           your hand, GY, or banishment.
-- Effect 2: Banish this card from your GY when a "Hole" Normal
--           Trap is destroyed; Set any number of "Hole" Normal
--           Traps from your GY (can activate this turn, banish
--           when they leave).
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Special Summon 1 EARTH Insect or Plant
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — Banish from GY to Set destroyed Hole traps
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
    e2:SetCode(EVENT_DESTROYED)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,id+1)
    e2:SetCost(aux.bfgcost)
    e2:SetCondition(s.setcon)
    e2:SetTarget(s.settg)
    e2:SetOperation(s.setop)
    c:RegisterEffect(e2)
end

s.listed_series={0x89}

-- ============================================================
-- Effect 1: Filter — Valid Special Summon targets
-- ============================================================
function s.spfilter(c,e,tp)
    return c:IsAttribute(ATTRIBUTE_EARTH) and (c:IsRace(RACE_INSECT) or c:IsRace(RACE_PLANT))
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- ============================================================
-- Effect 1: Target — Check if Special Summon is possible
-- ============================================================
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED)
end

-- ============================================================
-- Effect 1: Operation — Select 1 monster, Special Summon it
-- ============================================================
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- ============================================================
-- Effect 2: Filter — Valid "Hole" Normal Traps in GY
-- ============================================================
function s.holefilter(c)
    return c:IsNormalTrap() and c:IsSetCard(0x89)
end

-- ============================================================
-- Effect 2: Filter — Check if a "Hole" Trap was destroyed
-- ============================================================
function s.cfilter(c,tp)
    return c:IsPreviousControler(tp) and c:IsPreviousLocation(LOCATION_ONFIELD)
        and s.holefilter(c)
end

-- ============================================================
-- Effect 2: Condition — Trigger on "Hole" Trap destruction
-- ============================================================
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.cfilter,1,nil,tp)
end

-- ============================================================
-- Effect 2: Target — Check if Set is possible
-- ============================================================
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        local count=Duel.GetLocationCount(tp,LOCATION_SZONE)
        return count>0 and Duel.IsExistingMatchingCard(s.holefilter,tp,LOCATION_GRAVE,0,1,nil)
    end
end

-- ============================================================
-- Effect 2: Operation — Set destroyed Hole traps from GY
-- ============================================================
function s.setop(e,tp,eg,ep,ev,re,r,rp)
    local count=Duel.GetLocationCount(tp,LOCATION_SZONE)
    if count<=0 then return end
    local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.holefilter),tp,LOCATION_GRAVE,0,nil)
    if #g==0 then return end
    local maxc=math.min(count, #g)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local sg=g:Select(tp,1,maxc,nil)
    if #sg>0 then
        for tc in sg:Iter() do
            if Duel.SSet(tp,tc)>0 then
                local e1=Effect.CreateEffect(e:GetHandler())
                e1:SetType(EFFECT_TYPE_SINGLE)
                e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
                e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
                e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
                tc:RegisterEffect(e1)
                
                local e2=Effect.CreateEffect(e:GetHandler())
                e2:SetType(EFFECT_TYPE_SINGLE)
                e2:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
                e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
                e2:SetValue(LOCATION_REMOVED)
                e2:SetReset(RESET_EVENT+RESETS_REDIRECT)
                tc:RegisterEffect(e2)
            end
        end
    end
end
