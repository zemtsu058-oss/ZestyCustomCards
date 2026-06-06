-- ============================================================
-- Card Name: Blessing of the Wind Charmer
-- Passcode : 19100004
-- Type     : Spell / Normal
-- Archetype: Charmer (0xbf)
-- ============================================================
-- Effect 1: Send 1 WIND monster from your Deck to the GY;
--           until the end of the next turn, each time a WIND
--           monster(s) you control leaves the field, your
--           opponent must return 1 card they control to the hand.
-- You can only activate 1 "Blessing of the Wind Charmer" per turn.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Normal Spell activation: Send WIND, apply field trigger
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
-- Effect 1: Cost filter — WIND monster in Deck
-- ============================================================
function s.filter_cost(c)
    return c:IsAttribute(ATTRIBUTE_WIND) and c:IsMonster() and c:IsAbleToGraveAsCost()
end

-- ============================================================
-- Effect 1: Cost — Send 1 WIND monster from Deck to GY
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
-- Effect 1: Operation — Register the leaves field trigger
-- ============================================================
function s.op_activate(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    local rflag=Duel.GetTurnPlayer()==tp and RESET_OPPO_TURN or RESET_SELF_TURN
    
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EVENT_LEAVE_FIELD)
    e1:SetCondition(s.con_wind)
    e1:SetOperation(s.op_wind)
    e1:SetReset(RESET_PHASE+PHASE_END+rflag,1)
    Duel.RegisterEffect(e1,tp)
end

-- ============================================================
-- Filter — WIND monster that was controlled by tp on field and left it
-- ============================================================
function s.filter_wind(c,tp)
    return c:IsPreviousControler(tp) and c:IsPreviousLocation(LOCATION_MZONE)
        and c:IsPreviousPosition(POS_FACEUP) and (c:GetPreviousAttributeOnField()&ATTRIBUTE_WIND)~=0
end

-- ============================================================
-- Condition — Check if any WIND monster you control left the field
-- ============================================================
function s.con_wind(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.filter_wind,1,nil,tp)
end

-- ============================================================
-- Operation — Opponent must return 1 card they control to hand
-- ============================================================
function s.op_wind(e,tp,eg,ep,ev,re,r,rp)
    local ot=1-tp
    local g=Duel.GetMatchingGroup(Card.IsAbleToHand,ot,LOCATION_ONFIELD,0,nil)
    if #g>0 then
        Duel.Hint(HINT_SELECTMSG,ot,HINTMSG_RTOHAND)
        local sg=g:Select(ot,1,1,nil)
        if #sg>0 then
            Duel.HintSelection(sg)
            Duel.SendtoHand(sg,nil,REASON_RULE)
        end
    end
end
