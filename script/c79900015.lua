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
    
    -- Register field replacement effect: banish -> GY
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EFFECT_SEND_REPLACE)
    e1:SetTarget(s.reptg)
    e1:SetOperation(s.repop)
    e1:SetReset(RESET_PHASE+PHASE_END,2)
    Duel.RegisterEffect(e1,tp)
end

-- ============================================================
-- Effect 1: Filter — Cards moving to banish zone not from GY
-- ============================================================
function s.repfilter(c)
    return c:GetDestination()==LOCATION_REMOVED and not c:IsLocation(LOCATION_GRAVE)
end

-- ============================================================
-- Effect 1: Replacement Target — Divert to GY instead
-- ============================================================
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return eg:IsExists(s.repfilter,1,nil)
    end
    
    local g=eg:Filter(s.repfilter,nil)
    for tc in g:Iter() do
        tc:SetDestination(LOCATION_GRAVE)
    end
    
    e:SetLabel(#g)
    return true
end

-- ============================================================
-- Effect 1: Replacement Operation — Deal damage based on diverted count
-- ============================================================
function s.repop(e,tp,eg,ep,ev,re,r,rp)
    local count=e:GetLabel()
    if count>0 then
        Duel.Damage(1-tp,count*100,REASON_EFFECT)
    end
end
