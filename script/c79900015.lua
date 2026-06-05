-- ============================================================
-- Card Name: Retfihs Noisnemid
-- Passcode : 79900015
-- Type     : Monster / Effect
-- Attribute: LIGHT
-- Level    : 6
-- ATK      : 2200
-- DEF      : 1200
-- Race     : Spellcaster
-- Archetype: Generic (None)
-- ============================================================
-- Effect 1: Quick Effect: If there are cards in GY/banishment:
--           Banish this card from hand; until the end of the next
--           turn, any card sent to banishment (except from GY)
--           is sent to GY instead, and opponent takes 100 damage
--           for each card sent to GY.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Discard to redirect banishment and burn
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DAMAGE)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_HAND)
    e1:SetCondition(s.condition)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)
end

-- ============================================================
-- Effect 1: Condition — Cards exist in GY or banishment
-- ============================================================
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetFieldGroupCount(tp,LOCATION_GRAVE+LOCATION_REMOVED,LOCATION_GRAVE+LOCATION_REMOVED)>0
end

-- ============================================================
-- Effect 1: Cost — Banish this card from hand
-- ============================================================
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsAbleToRemoveAsCost() and c:IsLocation(LOCATION_HAND) end
    Duel.Remove(c,POS_FACEUP,REASON_COST)
end

-- ============================================================
-- Effect 1: Target — Damage setup
-- ============================================================
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,0)
end

-- ============================================================
-- Effect 1: Operation — Register replacement effect
-- ============================================================
function s.operation(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    
    -- Redirect banished cards to GY
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE+EFFECT_FLAG_IGNORE_RANGE+EFFECT_FLAG_IGNORE_IMMUNE)
    e1:SetCode(EFFECT_REMOVE_REDIRECT)
    e1:SetTargetRange(0xff,0xff)
    e1:SetReset(RESET_PHASE+PHASE_END,2)
    e1:SetValue(LOCATION_GRAVE)
    e1:SetTarget(s.reptg)
    Duel.RegisterEffect(e1,tp)
    
    -- Burn damage when redirected
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetReset(RESET_PHASE+PHASE_END,2)
    e2:SetCondition(s.damcon)
    e2:SetOperation(s.damop)
    Duel.RegisterEffect(e2,tp)
end

-- ============================================================
-- Effect 1: Target — Filter cards moving to banish zone not from GY
-- ============================================================
function s.reptg(e,c)
    -- Ignore if card is already in GY (except from GY)
    if not c:IsLocation(LOCATION_GRAVE) then
        c:RegisterFlagEffect(id,RESET_PHASE+PHASE_END,0,1)
        return true
    end
    return false
end

-- ============================================================
-- Effect 1: Burn logic for redirected cards
-- ============================================================
function s.damfilter(c)
    return c:GetFlagEffect(id)>0
end

function s.damcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.damfilter,1,nil)
end

function s.damop(e,tp,eg,ep,ev,re,r,rp)
    local g=eg:Filter(s.damfilter,nil)
    local count=#g
    if count>0 then
        for tc in aux.Next(g) do
            tc:ResetFlagEffect(id)
        end
        Duel.Damage(1-tp,count*100,REASON_EFFECT)
    end
end
