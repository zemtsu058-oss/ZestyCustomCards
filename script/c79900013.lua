-- ============================================================
-- Card Name: Green Reboot
-- Passcode : 79900013
-- Type     : Spell / Quick-Play
-- Archetype: Generic (None)
-- ============================================================
-- Effect 1: Negate Spell activation/effect of opponent, they
--           Set it (and can Set other Spells from hand), also
--           Set Spells cannot be activated until the end of the
--           next turn (Your opponent cannot respond).
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Negate Spell and force opponent to Set Spells from hand
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_NEGATE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_CHAINING)
    e1:SetCondition(s.condition)
    e1:SetTarget(s.target)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)
end

-- ============================================================
-- Effect 1: Condition — Opponent activates Spell card/effect
-- ============================================================
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return rp==1-tp and re:IsActiveType(TYPE_SPELL) and Duel.IsChainNegatable(ev)
end

-- ============================================================
-- Effect 1: Target — Chain response limit
-- ============================================================
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    Duel.SetChainLimit(s.chlimit)
end

-- ============================================================
-- Effect 1: Chain Limit — Lock chain response
-- ============================================================
function s.chlimit(e,ep,tp)
    return tp==ep
end

-- ============================================================
-- Effect 1: Filter — SSetable Spells
-- ============================================================
function s.setfilter(c)
    return c:IsType(TYPE_SPELL) and c:IsSSetable()
end

-- ============================================================
-- Effect 1: Operation — Negate Spell and lock Set Spells
-- ============================================================
function s.operation(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if Duel.NegateActivation(ev) then
        local count=Duel.GetLocationCount(1-tp,LOCATION_SZONE)
        local hand_g=Duel.GetMatchingGroup(s.setfilter,1-tp,LOCATION_HAND,0,nil)
        if count>0 and #hand_g>0 then
            local max_set=math.min(count,#hand_g)
            Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_SET)
            local sg=hand_g:Select(1-tp,1,max_set,nil)
            if #sg>0 then
                Duel.SSet(1-tp,sg)
            end
        end
        
        -- Lock Set Spells until the end of the next turn
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_FIELD)
        e1:SetCode(EFFECT_CANNOT_TRIGGER)
        e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
        e1:SetTargetRange(LOCATION_SZONE,LOCATION_SZONE)
        e1:SetTarget(s.locktarget)
        e1:SetReset(RESET_PHASE+PHASE_END,2)
        Duel.RegisterEffect(e1,tp)
    end
end

-- ============================================================
-- Effect 1: Lock Target Filter — Facedown Spells
-- ============================================================
function s.locktarget(e,c)
    return c:IsFacedown() and c:IsType(TYPE_SPELL)
end
