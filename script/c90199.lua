--Kewl Tune New Era (Complete Version)
local s,id=GetID()

function s.initial_effect(c)

    --Xyz Summon
    Xyz.AddProcedure(c,nil,5,2)
    c:EnableReviveLimit()

    ---------------------------------------------------
    -- Treat as Tuner
    ---------------------------------------------------
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetCode(EFFECT_ADD_TYPE)
    e0:SetValue(TYPE_TUNER)
    c:RegisterEffect(e0)

    ---------------------------------------------------
    -- Rank -> Level (Xiangke style)
    ---------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCode(EFFECT_RANK_LEVEL_S)
    e1:SetValue(s.xyzlv)
    c:RegisterEffect(e1)

    ---------------------------------------------------
    -- Opponent cannot Tribute your Tuners
    ---------------------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_UNRELEASABLE_SUM)
    e2:SetRange(LOCATION_MZONE)
    e2:SetTargetRange(LOCATION_MZONE,0)
    e2:SetTarget(s.relfilter)
    e2:SetValue(1)
    c:RegisterEffect(e2)

    local e3=e2:Clone()
    e3:SetCode(EFFECT_UNRELEASABLE_NONSUM)
    c:RegisterEffect(e3)

    ---------------------------------------------------
    -- Cannot be material except Synchro
    ---------------------------------------------------
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetCode(EFFECT_CANNOT_BE_MATERIAL)
    e4:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e4:SetValue(s.matlimit)
    c:RegisterEffect(e4)

    ---------------------------------------------------
    -- Cannot be cost for Level-related effects
    -- (Sửa lỗi dòng 61: EFFECT_CANNOT_BE_COST -> EFFECT_CANNOT_USE_AS_COST)
    ---------------------------------------------------
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE)
    e5:SetCode(EFFECT_CANNOT_USE_AS_COST) 
    e5:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e5:SetValue(s.costlimit)
    c:RegisterEffect(e5)

    ---------------------------------------------------
    -- Immune to Level-related effects
    ---------------------------------------------------
    local e6=Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_SINGLE)
    e6:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e6:SetRange(LOCATION_MZONE)
    e6:SetCode(EFFECT_IMMUNE_EFFECT)
    e6:SetValue(s.efilter)
    c:RegisterEffect(e6)

    ---------------------------------------------------
    -- Quick Synchro Effect
    ---------------------------------------------------
    local e7=Effect.CreateEffect(c)
    e7:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e7:SetType(EFFECT_TYPE_QUICK_O)
    e7:SetCode(EVENT_FREE_CHAIN)
    e7:SetRange(LOCATION_MZONE)
    e7:SetCountLimit(1,id)
    e7:SetCondition(s.condition)
    e7:SetCost(s.cost)
    e7:SetTarget(s.target)
    e7:SetOperation(s.operation)
    c:RegisterEffect(e7)

end

---------------------------------------------------
-- Rank -> Level
---------------------------------------------------
function s.xyzlv(e,c,rc)
    return c:GetRank()
end

---------------------------------------------------
-- Tribute filter
---------------------------------------------------
function s.relfilter(e,c,tp)
    return c:IsType(TYPE_TUNER)
end

---------------------------------------------------
-- Material limit
---------------------------------------------------
function s.matlimit(e,c,sumtype,tp)
    return not c:IsType(TYPE_SYNCHRO)
end

---------------------------------------------------
-- Cost limit
---------------------------------------------------
function s.costlimit(e,re,tp)
    if not re then return false end
    return re:GetCode()==EFFECT_CHANGE_LEVEL
        or re:GetCode()==EFFECT_UPDATE_LEVEL
        or re:GetCode()==EFFECT_CHANGE_LEVEL_FINAL
end

---------------------------------------------------
-- Immune Level effects
---------------------------------------------------
function s.efilter(e,te)
    return te:GetCode()==EFFECT_CHANGE_LEVEL
        or te:GetCode()==EFFECT_UPDATE_LEVEL
        or te:GetCode()==EFFECT_CHANGE_LEVEL_FINAL
end

---------------------------------------------------
-- Condition
---------------------------------------------------
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsMainPhase()
        or (Duel.GetTurnPlayer()~=tp and Duel.GetCurrentPhase()==PHASE_BATTLE)
end

---------------------------------------------------
-- Cost
---------------------------------------------------
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
    e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

---------------------------------------------------
-- Special Summon filter
---------------------------------------------------
function s.spfilter(c,e,tp)
    return c:IsType(TYPE_TUNER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

---------------------------------------------------
-- Synchro filter
---------------------------------------------------
function s.synfilter(c,e,tp,mg)
    return c:IsType(TYPE_SYNCHRO) and c:IsSynchroSummonable(nil,mg)
end

---------------------------------------------------
-- Target
---------------------------------------------------
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)

    local mg=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_MZONE,0,nil)

    if chk==0 then
        return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
            and Duel.IsExistingMatchingCard(s.synfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg)
    end

    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end

---------------------------------------------------
-- Operation
---------------------------------------------------
function s.operation(e,tp,eg,ep,ev,re,r,rp)

    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end

    ---------------------------------------------------
    -- Increase opponent monsters Level
    ---------------------------------------------------
    local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
    for tc in aux.Next(g) do
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_LEVEL)
        e1:SetValue(1)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        tc:RegisterEffect(e1)
    end

    ---------------------------------------------------
    -- Special Summon Tuner from GY
    ---------------------------------------------------
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local sg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
    local sc1=sg:GetFirst()
    if sc1 and Duel.SpecialSummon(sc1,0,tp,tp,false,false,POS_FACEUP)>0 then

        ---------------------------------------------------
        -- Synchro Summon
        ---------------------------------------------------
        local mg=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_MZONE,0,nil)

        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local sc=Duel.SelectMatchingCard(tp,s.synfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mg):GetFirst()

        if sc then
            Duel.SynchroSummon(tp,sc,nil,mg)
        end
    end

end
