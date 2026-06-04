-- ============================================================
-- Card Name: Ghost Twin & Spring Rabbit
-- Passcode : 79900012
-- Type     : Monster / Tuner / Effect
-- Attribute: LIGHT
-- Level    : 3
-- ATK      : 0
-- DEF      : 1800
-- Race     : Zombie
-- Archetype: Generic (None)
-- ============================================================
-- Effect 1: Quick Effect: Discard from hand; destroy 1 monster or
--           face-up Spell/Trap on field. Then, optionally discard
--           1 card to banish the destroyed card and all copies
--           of it from Decks and Extra Decks.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Discard to destroy and optionally banish all copies
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DESTROY+CATEGORY_REMOVE+CATEGORY_HANDES)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_CHAINING)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.condition)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)
end

-- ============================================================
-- Effect 1: Condition — Opponent activates monster or S/T effect on field
-- ============================================================
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    local rc=re:GetHandler()
    if not rc:IsOnField() then return false end
    if re:IsActiveType(TYPE_MONSTER) then
        return true
    elseif re:IsActiveType(TYPE_SPELL+TYPE_TRAP) then
        return not re:IsHasType(EFFECT_TYPE_ACTIVATE)
    end
    return false
end

-- ============================================================
-- Effect 1: Cost — Discard this card
-- ============================================================
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsDiscardable() end
    Duel.SendtoGrave(c,REASON_COST+REASON_DISCARD)
end

-- ============================================================
-- Effect 1: Target — Check if target can be destroyed
-- ============================================================
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return re:GetHandler():IsRelateToEffect(re) and re:GetHandler():IsDestructable() end
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
end

-- ============================================================
-- Effect 1: Operation — Destroy and optionally discard to banish all copies
-- ============================================================
function s.operation(e,tp,eg,ep,ev,re,r,rp)
    local tc=re:GetHandler()
    if tc and tc:IsRelateToEffect(re) and tc:IsOnField() then
        if Duel.Destroy(tc,REASON_EFFECT)>0 then
            if Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil)
                and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
                Duel.BreakEffect()
                if Duel.DiscardHand(tp,nil,1,1,REASON_EFFECT+REASON_DISCARD,nil)>0 then
                    local code=tc:GetCode()
                    local g=Group.CreateGroup()
                    
                    if tc:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED) then
                        g:AddCard(tc)
                    end
                    
                    local deck_g=Duel.GetMatchingGroup(Card.IsCode,tp,LOCATION_DECK+LOCATION_EXTRA,LOCATION_DECK+LOCATION_EXTRA,nil,code)
                    g:Merge(deck_g)
                    
                    if #g>0 then
                        Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
                    end
                end
            end
        end
    end
end
