-- ============================================================
-- Card Name: Blessing of the Earth Charmer
-- Passcode : 19100001
-- Type     : Spell / Normal
-- Archetype: Charmer (0xbf)
-- ============================================================
-- Effect 1: Send 1 EARTH monster from your Deck to the GY;
--           until the end of the next turn, EARTH monsters you
--           control are unaffected by your opponent's card effects
--           while they are in Defense Position.
-- You can only activate 1 "Blessing of the Earth Charmer" per turn.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Normal Spell activation: Send EARTH, apply immune
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCost(s.cost_activate)
    e1:SetTarget(s.tg_activate)
    e1:SetOperation(s.op_activate)
    c:RegisterEffect(e1)
end

-- ============================================================
-- Effect 1: Cost filter — EARTH monster in Deck
-- ============================================================
function s.filter_cost(c)
    return c:IsAttribute(ATTRIBUTE_EARTH) and c:IsMonster() and c:IsAbleToGraveAsCost()
end

-- ============================================================
-- Effect 1: Cost — Send 1 EARTH monster from Deck to GY
-- ============================================================
function s.cost_activate(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.filter_cost,tp,LOCATION_DECK,0,1,nil)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.filter_cost,tp,LOCATION_DECK,0,1,1,nil)
    Duel.SendtoGrave(g,REASON_COST)
end

-- ============================================================
-- Effect 1: Target — Check legality
-- ============================================================
function s.tg_activate(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
end

-- ============================================================
-- Effect 1: Operation — Apply lingering immunity effect
-- ============================================================
function s.op_activate(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_IMMUNE_EFFECT)
    e1:SetTargetRange(LOCATION_MZONE,0)
    e1:SetTarget(function(e,tc) return tc:IsAttribute(ATTRIBUTE_EARTH) and tc:IsDefensePos() end)
    e1:SetValue(function(e,re) return re:GetOwnerPlayer()~=e:GetHandlerPlayer() end)
    -- Dynamic reset: end of opponent's turn if activated on ours, or end of our turn if activated on opponent's
    local rflag=Duel.GetTurnPlayer()==tp and RESET_OPPO_TURN or RESET_SELF_TURN
    e1:SetReset(RESET_PHASE+PHASE_END+rflag,1)
    Duel.RegisterEffect(e1,tp)
end
