-- The Elation Game
local s, id = GetID()

function s.initial_effect(c)
    -- The activation and the effects of this card cannot be negated
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_CANNOT_DISABLE)
    c:RegisterEffect(e1)

    -- If this card would leave the field by a card effect, inflict 1000 damage instead
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_CONTINUOUS)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetCode(EFFECT_SEND_REPLACE)
    e2:SetRange(LOCATION_FZONE)
    e2:SetTarget(s.reptg)
    e2:SetOperation(s.repop)
    c:RegisterEffect(e2)
    local e3 = e2:Clone()
    e3:SetCode(EFFECT_DESTROY_REPLACE)
    c:RegisterEffect(e3)

    -- Activation Effect (Trigger upon activation)
    local e4 = Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id, 0))
    e4:SetCategory(CATEGORY_DICE + CATEGORY_RECOVER + CATEGORY_ATKCHANGE + CATEGORY_DRAW + CATEGORY_SEARCH + CATEGORY_TOHAND + CATEGORY_SUMMON)
    e4:SetType(EFFECT_TYPE_ACTIVATE)
    e4:SetCode(EVENT_FREE_CHAIN)
    e4:SetCountLimit(1, id)
    e4:SetTarget(s.acttg)
    e4:SetOperation(s.rollop)
    c:RegisterEffect(e4)

    -- Standby Phase Trigger
    local e5 = Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id, 0))
    e5:SetCategory(CATEGORY_DICE + CATEGORY_RECOVER + CATEGORY_ATKCHANGE + CATEGORY_DRAW + CATEGORY_SEARCH + CATEGORY_TOHAND + CATEGORY_SUMMON)
    e5:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_F)
    e5:SetCode(EVENT_PHASE + PHASE_STANDBY)
    e5:SetRange(LOCATION_FZONE)
    e5:SetCountLimit(1, id)
    e5:SetTarget(s.sptg)
    e5:SetOperation(s.rollop)
    c:RegisterEffect(e5)
end

-- =========================================================
-- Leave Field Replace Logic
-- =========================================================
function s.reptg(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    -- Check if it is leaving the field by a card effect and prevent loop
    return c:IsReason(REASON_EFFECT) and re and not c:IsReason(REASON_REPLACE)
end

function s.repop(e, tp, eg, ep, ev, re, r, rp)
    -- Inflict damage to the player who activated the effect that would make this card leave the field
    Duel.Damage(rp, 1000, REASON_EFFECT)
end

-- =========================================================
-- Prevent Chaining Logic
-- =========================================================
function s.acttg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    -- Cards and effects cannot be activated in respond to this card's activation
    Duel.SetChainLimit(aux.FALSE)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
end

-- =========================================================
-- Roll & Resolve Logic
-- =========================================================
function s.rollop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    
    local p = Duel.GetTurnPlayer()
    local d = Duel.TossDice(p, 1) -- "the turn player rolls a six-sided die"
    
    if d == 1 then
        Duel.Recover(tp, 1000, REASON_EFFECT)
        local g = Duel.GetMatchingGroup(Card.IsFaceup, tp, LOCATION_MZONE, 0, nil)
        for tc in aux.Next(g) do
            local buff = Effect.CreateEffect(c)
            buff:SetType(EFFECT_TYPE_SINGLE)
            buff:SetCode(EFFECT_UPDATE_ATTACK)
            buff:SetValue(1000)
            buff:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
            tc:RegisterEffect(buff)
        end
        
    elseif d == 2 then
        Duel.Draw(tp, 1, REASON_EFFECT)
        
    elseif d == 3 then
        local sumeff = Effect.CreateEffect(c)
        sumeff:SetType(EFFECT_TYPE_FIELD)
        sumeff:SetCode(EFFECT_SET_SUMMON_COUNT_LIMIT)
        sumeff:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
        sumeff:SetTargetRange(1, 0)
        sumeff:SetValue(2)
        sumeff:SetReset(RESET_PHASE + PHASE_END)
        Duel.RegisterEffect(sumeff, tp)
        
    elseif d == 4 then
        Duel.Draw(tp, 2, REASON_EFFECT)
        
    elseif d == 5 then
        -- Quick Effect Negate Assignment
        local qeff = Effect.CreateEffect(c)
        qeff:SetDescription(aux.Stringid(id, 1)) -- "Negate 1 opponent's effect"
        qeff:SetCategory(CATEGORY_NEGATE)
        qeff:SetType(EFFECT_TYPE_QUICK_O)
        qeff:SetCode(EVENT_CHAINING)
        qeff:SetRange(LOCATION_FZONE)
        qeff:SetCountLimit(1)
        qeff:SetCondition(s.negcon)
        qeff:SetTarget(s.negtg)
        qeff:SetOperation(s.negop)
        qeff:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
        c:RegisterEffect(qeff)
        -- Thêm hint cho player biết Field đang có eff negate
        c:RegisterFlagEffect(id, RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END, EFFECT_FLAG_CLIENT_HINT, 1, 0, aux.Stringid(id, 2))
        
    elseif d == 6 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
        local g = Duel.SelectMatchingCard(tp, nil, tp, LOCATION_DECK, 0, 1, 1, nil)
        if #g > 0 then
            Duel.SendtoHand(g, nil, REASON_EFFECT)
            Duel.ConfirmCards(1 - tp, g)
        end
    end
end

-- =========================================================
-- Quick Effect Negate Logic (Result: 5)
-- =========================================================
function s.negcon(e, tp, eg, ep, ev, re, r, rp)
    -- Trigger nếu đối thủ activate eff và chain đó có thể negate được
    return ep ~= tp and Duel.IsChainNegatable(ev)
end

function s.negtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_NEGATE, eg, 1, 0, 0)
end

function s.negop(e, tp, eg, ep, ev, re, r, rp)
    -- Negate hiệu ứng (Không Destroy)
    Duel.NegateEffect(ev)
end
