--Void Invasion
local s,id=GetID()

function s.initial_effect(c)

    --Activate
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_ACTIVATE)
    e0:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e0)

    --Send up to 2 cards; Set that many Void S/T
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SET)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_SZONE)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)

    --GY effect
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,id+100)
    e2:SetCondition(s.spcon)
    e2:SetCost(aux.bfgcost)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)

end

--Void S/T filter
function s.setfilter(c)
    return c:IsSetCard(0xc5) and c:IsSpellTrap() and c:IsSSetable()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)

    if chk==0 then
        return Duel.IsExistingMatchingCard(Card.IsAbleToGrave,tp,LOCATION_HAND,0,1,nil)
            and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil)
    end

end

function s.activate(e,tp,eg,ep,ev,re,r,rp)

    local g=Duel.GetMatchingGroup(Card.IsAbleToGrave,tp,LOCATION_HAND,0,nil)

    if #g==0 then return end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local sg=g:Select(tp,1,2,nil)

    local ct=Duel.SendtoGrave(sg,REASON_EFFECT)

    if ct==0 then return end

    local dg=Duel.GetMatchingGroup(s.setfilter,tp,LOCATION_DECK,0,nil)

    if #dg==0 then return end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local sc=dg:Select(tp,ct,ct,nil)

    for tc in aux.Next(sc) do
        Duel.SSet(tp,tc)
    end

end

--Main Phase check
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsMainPhase()
end

--Void Continuous Spell filter
function s.cfilter(c)
    return c:IsSetCard(0xc5)
        and c:IsType(TYPE_SPELL)
        and c:IsType(TYPE_CONTINUOUS)
        and not c:IsForbidden()
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)

    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
            and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_DECK,0,1,nil)
    end

end

function s.spop(e,tp,eg,ep,ev,re,r,rp)

    if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)

    local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_DECK,0,1,1,nil)
    local tc=g:GetFirst()

    if tc then
        Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
    end

end