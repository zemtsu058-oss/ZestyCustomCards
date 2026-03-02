--Triune Paradox – Axiarch of the End Code
local s,id=GetID()

function s.initial_effect(c)

    -- Link Summon
    c:EnableReviveLimit()
    Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsType,TYPE_EFFECT),3,99,s.lcheck)

    -------------------------------------------------
    -- On Link Summon
    -------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_TODECK+CATEGORY_REMOVE)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCondition(s.lkcon)
    e1:SetTarget(s.lktg)
    e1:SetOperation(s.lkop)
    c:RegisterEffect(e1)

    -------------------------------------------------
    -- Ignition effect
    -------------------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetCategory(CATEGORY_TODECK+CATEGORY_REMOVE)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,id)
    e2:SetTarget(s.qtg)
    e2:SetOperation(s.qop)
    c:RegisterEffect(e2)

    -------------------------------------------------
    -- Quick effect when truly co-linked
    -------------------------------------------------
    local e3=e2:Clone()
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetCondition(s.quickcon)
    c:RegisterEffect(e3)
end

-------------------------------------------------
-- 3 monsters with different original names
-------------------------------------------------
function s.lcheck(g,lc,sumtype,tp)
    return g:GetClassCount(Card.GetOriginalCode)>=3
end

-------------------------------------------------
-- Must be Link Summoned
-------------------------------------------------
function s.lkcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

-------------------------------------------------
-- Target for summon effect
-------------------------------------------------
function s.lktg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLP(tp)>1 end
    Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,0,PLAYER_ALL,LOCATION_GRAVE)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,0,PLAYER_ALL,LOCATION_EXTRA)
end

-------------------------------------------------
-- Operation for summon effect
-------------------------------------------------
function s.lkop(e,tp,eg,ep,ev,re,r,rp)
    local tp=e:GetHandlerPlayer()

    -- Pay half LP
    Duel.PayLPCost(tp,math.floor(Duel.GetLP(tp)/2))

    -- Shuffle both GY into Deck
    local g=Duel.GetMatchingGroup(Card.IsAbleToDeck,tp,LOCATION_GRAVE,LOCATION_GRAVE,nil)
    if #g>0 then
        Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
    end

    -- Banish both Extra face-down
    local ex=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,LOCATION_EXTRA,LOCATION_EXTRA,nil)
    if #ex>0 then
        Duel.Remove(ex,POS_FACEDOWN,REASON_EFFECT)
    end
end

-------------------------------------------------
-- TRUE co-link check (no IsCoLinked)
-------------------------------------------------
function s.quickcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local lg=c:GetLinkedGroup()
    return lg and lg:IsExists(function(tc)
        return tc:GetLinkedGroup():IsContains(c)
    end,1,nil)
end

-------------------------------------------------
-- Target for banish effect
-------------------------------------------------
function s.qtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(Card.IsAbleToDeck,tp,LOCATION_REMOVED,LOCATION_REMOVED,1,nil)
        and Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)>0
    end
    Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,PLAYER_ALL,LOCATION_REMOVED)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_HAND)
end

-------------------------------------------------
-- Operation
-------------------------------------------------
function s.qop(e,tp,eg,ep,ev,re,r,rp)

    -- Return 1 banished card
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local g=Duel.SelectMatchingCard(tp,Card.IsAbleToDeck,tp,LOCATION_REMOVED,LOCATION_REMOVED,1,1,nil)
    if #g==0 then return end
    Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)

    -- Opponent hand
    local hg=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
    if #hg==0 then return end

    Duel.ConfirmCards(tp,hg)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local sg=hg:Select(tp,1,1,nil)
    Duel.ShuffleHand(1-tp)

    local tc=sg:GetFirst()
    if Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)~=0 then

        -- End Phase return (SAFE VERSION)
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        e1:SetCode(EVENT_PHASE+PHASE_END)
        e1:SetCountLimit(1)
        e1:SetReset(RESET_PHASE+PHASE_END+RESET_SELF_TURN)
        e1:SetLabelObject(tc)
        e1:SetOperation(s.retop)
        Duel.RegisterEffect(e1,tp)
    end
end

-------------------------------------------------
-- End Phase return (no freeze)
-------------------------------------------------
function s.retop(e,tp)
    local tc=e:GetLabelObject()
    if not tc then return end
    if tc:IsLocation(LOCATION_REMOVED) and tc:IsAbleToHand() then
        Duel.SendtoHand(tc,nil,REASON_EFFECT)
    end
end