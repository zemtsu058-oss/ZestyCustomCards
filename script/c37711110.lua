local s,id=GetID()
function s.initial_effect(c)

    -- Link Summon
    c:EnableReviveLimit()
    Link.AddProcedure(c,s.matfilter,1,1)

    -------------------------------------------------
    -- Linked monsters treated as Elemental HERO
    -------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_ADD_SETCODE)
    e1:SetRange(LOCATION_MZONE)
    e1:SetTargetRange(LOCATION_MZONE,0)
    e1:SetTarget(s.herotg)
    e1:SetValue(0x3008)
    c:RegisterEffect(e1)

    -------------------------------------------------
    -- On Link Summon: Search + Discard
    -------------------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_SEARCH+CATEGORY_HANDES)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetCondition(s.thcon)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    e2:SetCountLimit(1,id)
    c:RegisterEffect(e2)

    -------------------------------------------------
    -- GY Effect: Banish 2 HERO → add ≤1000 ATK
    -------------------------------------------------
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_TOHAND)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_GRAVE)
    e3:SetCost(s.retcost)
    e3:SetTarget(s.rettg)
    e3:SetOperation(s.retop)
    e3:SetCountLimit(1,id+100)
    c:RegisterEffect(e3)
end

-------------------------------------------------
-- Link Material (HERO 0x8 or Neo-Spacian 0x1f)
-------------------------------------------------
function s.matfilter(c,lc,sumtype,tp)
    return c:IsSetCard(0x8) or c:IsSetCard(0x1f)
end

-------------------------------------------------
-- Linked monsters treated as Elemental HERO
-------------------------------------------------
function s.herotg(e,c)
    return e:GetHandler():GetLinkedGroup():IsContains(c)
end

-------------------------------------------------
-- Search Condition
-------------------------------------------------
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsLinkSummoned()
end

function s.thfilter(c)
    return (c:IsSetCard(0x8) or c:ListsCode(CARD_POLYMERIZATION))
        and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
            and Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_SEARCH,nil,1,tp,LOCATION_DECK)
    Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,1,tp,LOCATION_HAND)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
        Duel.ConfirmCards(1-tp,g)
        Duel.BreakEffect()
        Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_EFFECT+REASON_DISCARD)
    end
end

-------------------------------------------------
-- GY Cost (cannot ban ≤1000 ATK target)
-------------------------------------------------
function s.costfilter(c)
    return c:IsSetCard(0x8)
        and not c:IsAttackBelow(1000)
        and c:IsAbleToRemoveAsCost()
end

function s.retcost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then
        return c:IsAbleToRemoveAsCost()
            and Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_GRAVE,0,1,c)
            and Duel.IsExistingMatchingCard(s.retfilter,tp,LOCATION_GRAVE,0,1,nil)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_GRAVE,0,1,1,c)
    g:AddCard(c)
    Duel.Remove(g,POS_FACEUP,REASON_COST)
end

-------------------------------------------------
-- Return filter (≤1000 ATK)
-------------------------------------------------
function s.retfilter(c)
    return c:IsAttackBelow(1000)
        and c:IsAbleToHand()
end

function s.rettg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.retfilter,tp,LOCATION_GRAVE,0,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end

function s.retop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.retfilter,tp,LOCATION_GRAVE,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
    end
end