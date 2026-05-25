-- ============================================================
-- Card Name: Farewell Labrynth
-- Passcode : 90178
-- Type     : Trap / Normal
-- Archetype: Labrynth (0x17f)
-- ============================================================
-- While you control a "Labrynth" monster, this turn, each
-- player must send 1 card from their hand to the GY to
-- activate a card or effect. If a player has no cards in
-- their hand, it becomes the End Phase.
-- You can banish this card from your GY; return 1 banished
-- card to the GY.
-- You can only use 1 "Farewell Labrynth" effect per turn,
-- and only once that turn.
-- ============================================================

local s,id=GetID()
s.listed_series={0x17f}

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Normal Trap activation: activation cost for the turn
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOGRAVE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)                       -- Normal Trap: set first, then activate
    e1:SetCode(EVENT_FREE_CHAIN)                           -- No specific timing requirement
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)          -- Hard once per turn (shared with GY effect)
    e1:SetCondition(s.actcon)                              -- Must control a Labrynth monster
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — Ignition from GY: Banish self, send banished to GY
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOGRAVE)
    e2:SetType(EFFECT_TYPE_IGNITION)                       -- Can only activate during your Main Phase
    e2:SetRange(LOCATION_GRAVE)                            -- Must be in the GY
    e2:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)          -- Hard once per turn (shared with activation)
    e2:SetCost(s.gycost)                                   -- Cost: banish this card from GY
    e2:SetTarget(s.gytg)
    e2:SetOperation(s.gyop)
    c:RegisterEffect(e2)
end

-- ============================================================
-- Effect 1: Filter — Labrynth monster on your Monster Zone
-- ============================================================
function s.labmonfilter(c)
    return c:IsSetCard(0x17f) and c:IsType(TYPE_MONSTER)
end

-- ============================================================
-- Effect 1: Condition — You must control at least 1 Labrynth
-- ============================================================
function s.actcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(s.labmonfilter,tp,LOCATION_MZONE,0,1,nil)
end

-- ============================================================
-- Effect 1: Operation — Register an activation cost for the turn
-- ============================================================
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end

    -- Register a field cost: whenever a card or effect is activated,
    -- the activating player must send 1 card from hand to GY to activate it
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_ACTIVATE_COST)                       -- Applies before each card/effect activation
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e1:SetTargetRange(1,1)                                 -- Applies to both players
    e1:SetReset(RESET_PHASE+PHASE_END)                     -- Clears at end of turn
    e1:SetLabel(tp)                                        -- Remember this Trap's controller
    e1:SetCondition(s.actcostcon)                          -- Applies while you control Labrynth
    e1:SetCost(s.actcostchk)
    e1:SetOperation(s.actcostop)
    Duel.RegisterEffect(e1,tp)
end

-- ============================================================
-- Effect 1: Cost condition — The Trap's controller must control Labrynth
-- ============================================================
function s.actcostcon(e)
    return Duel.IsExistingMatchingCard(s.labmonfilter,e:GetLabel(),LOCATION_MZONE,0,1,nil)
end

-- ============================================================
-- Effect 1: Cost check — Always allow activation to resolve the no-hand case
-- ============================================================
function s.actcostchk(e,te_or_c,tp)
    return true
end

-- ============================================================
-- Effect 1: Cost operation — The activating player sends 1 card
-- ============================================================
function s.actcostop(e,tp,eg,ep,ev,re,r,rp)
    local hg=Duel.GetFieldGroup(tp,LOCATION_HAND,0)        -- tp = player activating the card/effect
    if #hg>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
        local sg=hg:Select(tp,1,1,nil)
        Duel.SendtoGrave(sg,REASON_COST)
    else
        local turnp=Duel.GetTurnPlayer()
        Duel.SkipPhase(turnp,PHASE_DRAW,RESET_PHASE+PHASE_END,1)
        Duel.SkipPhase(turnp,PHASE_STANDBY,RESET_PHASE+PHASE_END,1)
        Duel.SkipPhase(turnp,PHASE_MAIN1,RESET_PHASE+PHASE_END,1)
        Duel.SkipPhase(turnp,PHASE_BATTLE,RESET_PHASE+PHASE_END,1)
        Duel.SkipPhase(turnp,PHASE_MAIN2,RESET_PHASE+PHASE_END,1)
    end
end

-- ============================================================
-- Effect 2: Cost — Banish this card from GY face-up
-- ============================================================
function s.gycost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsAbleToRemoveAsCost() end
    Duel.Remove(c,POS_FACEUP,REASON_COST)
end

-- ============================================================
-- Effect 2: Filter — Any banished card that can go to GY
-- ============================================================
function s.removedfilter(c)
    return c:IsAbleToGrave()
end

-- ============================================================
-- Effect 2: Target — Check that a banished card can return to GY
-- ============================================================
function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.removedfilter,tp,LOCATION_REMOVED,LOCATION_REMOVED,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,PLAYER_ALL,LOCATION_REMOVED)
end

-- ============================================================
-- Effect 2: Operation — Choose 1 banished card and send it to GY
-- ============================================================
function s.gyop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.removedfilter,tp,LOCATION_REMOVED,LOCATION_REMOVED,1,1,nil)
    if #g>0 then
        Duel.SendtoGrave(g,REASON_EFFECT)
    end
end
