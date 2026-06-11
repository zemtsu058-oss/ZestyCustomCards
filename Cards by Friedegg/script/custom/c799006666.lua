-- Retfihs Noisnemid
local s, id = GetID()
function s.initial_effect(c)
    -- Quick Effect: Redirect banished cards to the GY and inflict damage
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_TOGRAVE + CATEGORY_DAMAGE)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_HAND)
    e1:SetCondition(s.condition)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)
end

function s.condition(e, tp, eg, ep, ev, re, r, rp)
    -- Trigger Condition: "If a card(s) is in either GY or banishment"
    return Duel.GetFieldGroupCount(tp, LOCATION_GRAVE + LOCATION_REMOVED, LOCATION_GRAVE + LOCATION_REMOVED) > 0
end

function s.cost(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    -- Cost: "You can banish this card from your hand"
    if chk == 0 then return c:IsAbleToRemoveAsCost() end
    Duel.Remove(c, POS_FACEUP, REASON_COST)
end

function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
end

function s.operation(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    -- Lingering Effect: "until the end of the next turn"
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EVENT_REMOVE)
    e1:SetCondition(s.repcon)
    e1:SetOperation(s.repop)
    e1:SetReset(RESET_PHASE + PHASE_END, 2)
    Duel.RegisterEffect(e1, tp)
end

function s.repfilter(c)
    -- Filter: "any card banished, except from the GY"
    return c:GetPreviousLocation() ~= LOCATION_GRAVE and c:IsLocation(LOCATION_REMOVED)
end

function s.repcon(e, tp, eg, ep, ev, re, r, rp)
    return eg:IsExists(s.repfilter, 1, nil)
end

function s.repop(e, tp, eg, ep, ev, re, r, rp)
    local tg = eg:Filter(s.repfilter, nil)
    if #tg > 0 then
        -- Send to GY instead. 
        -- REASON_RETURN treats this as a return from banishment, preventing infinite loops with Macro Cosmos.
        Duel.SendtoGrave(tg, REASON_EFFECT + REASON_RETURN)
        
        -- Verify how many cards actually landed in the GY
        local og = Duel.GetOperatedGroup()
        local ct = og:FilterCount(Card.IsLocation, nil, LOCATION_GRAVE)
        if ct > 0 then
            -- "also your opponent take 100 damage for each card sent to the GY that way."
            Duel.Damage(1 - tp, ct * 100, REASON_EFFECT)
        end
    end
end