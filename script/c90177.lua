--Labrynth Party
local s,id=GetID()

function s.initial_effect(c)

    --OPT chung
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_CANNOT_DISABLE)
    c:RegisterEffect(e0)

    --Activate
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_TODECK)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCondition(s.actcon)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)

    --GY effect
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e2:SetCost(s.gycost)
    e2:SetTarget(s.settg)
    e2:SetOperation(s.setop)
    c:RegisterEffect(e2)

end

---------------------------------------------------
-- CONDITION
---------------------------------------------------

function s.cfilter(c)
    return c:IsType(TYPE_TRAP) and c:IsNormalTrap()
end

function s.labfilter(c)
    return c:IsSetCard(0x17f) and c:IsType(TYPE_TRAP)
end

function s.actcon(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(s.cfilter,tp,LOCATION_GRAVE,0,nil)
    return #g>=2 and Duel.IsExistingMatchingCard(s.labfilter,tp,LOCATION_GRAVE,0,1,nil)
end

---------------------------------------------------
-- COST (TRIBUTE)
---------------------------------------------------

function s.costfilter(c)
    return c:IsLevel(8) and c:IsRace(RACE_FIEND) and c:IsReleasable()
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.CheckReleaseGroup(tp,s.costfilter,1,nil) end
    local g=Duel.SelectReleaseGroup(tp,s.costfilter,1,1,nil)
    Duel.Release(g,REASON_COST)
end

---------------------------------------------------
-- SET FROM DECK
---------------------------------------------------

function s.setfilter(c,g)
    return c:IsNormalTrap() and c:IsSSetable()
        and not g:IsExists(Card.IsCode,1,nil,c:GetCode())
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)

    local gy=Duel.GetMatchingGroup(Card.IsType,tp,LOCATION_GRAVE,0,nil,TYPE_TRAP)
    local labct=Duel.GetMatchingGroupCount(s.labfilter,tp,LOCATION_GRAVE,0,nil)

    if labct<=0 then return end

    local g=Duel.GetMatchingGroup(s.setfilter,tp,LOCATION_DECK,0,nil,gy)
    if #g==0 then return end

    local ct=math.min(labct,#g)

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local sg=g:Select(tp,1,ct,nil)

    for tc in aux.Next(sg) do
        if Duel.SSet(tp,tc)>0 then

            --activate this turn
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD)
            tc:RegisterEffect(e1)

        end
    end

end

---------------------------------------------------
-- GY EFFECT
---------------------------------------------------

function s.gycost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsAbleToRemoveAsCost() end
    Duel.Remove(c,POS_FACEUP,REASON_COST)
end

function s.setfilter2(c)
    return c:IsType(TYPE_TRAP) and c:IsSSetable()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter2,tp,LOCATION_GRAVE,0,1,nil) end
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)

    local g=Duel.GetMatchingGroup(s.setfilter2,tp,LOCATION_GRAVE,0,nil)
    if #g==0 then return end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local sg=g:Select(tp,1,1,nil)
    local tc=sg:GetFirst()

    if Duel.SSet(tp,tc)>0 then

        --activate this turn
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e1)

        --banish when leaves field
        local e2=Effect.CreateEffect(e:GetHandler())
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
        e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
        e2:SetReset(RESET_EVENT+RESETS_REDIRECT)
        e2:SetValue(LOCATION_REMOVED)
        tc:RegisterEffect(e2)

    end

end