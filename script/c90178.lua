-- ============================================================
-- Card Name: Farewell Labrynth
-- Passcode : 90178
-- Type     : Trap / Normal
-- Archetype: Labrynth (0x17f)
-- ============================================================
-- While you control a "Labrynth" monster, this turn, each
-- player must send 1 card from their hand to the GY to
-- activate a card or effect. If a player has no cards in
-- their hand during the Main Phase, it becomes the End Phase.
-- You can banish this card from your GY; return 1 banished card to the GY.
-- You can only use 1 "Farewell Labrynth" effect per turn,
-- and only once that turn.
-- ============================================================

local s,id=GetID()
s.listed_series={0x17f}

function s.initial_effect(c)
	-- ============================================================
	-- Effect 1 — Normal Trap activation: impose activation cost
	-- ============================================================
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.actcon)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- ============================================================
	-- Effect 2 — GY Ignition: Banish self, return 1 banished to GY
	-- ============================================================
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e2:SetCost(s.gycost)
	e2:SetTarget(s.gytg)
	e2:SetOperation(s.gyop)
	c:RegisterEffect(e2)
end

-- ============================================================
-- Effect 1: Filter — Labrynth monster on the field
-- ============================================================
function s.filter_labrynth(c)
	return c:IsSetCard(0x17f) and c:IsType(TYPE_MONSTER)
end

-- ============================================================
-- Effect 1: Condition — Must control a Labrynth monster
-- ============================================================
function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.filter_labrynth,tp,LOCATION_MZONE,0,1,nil)
end

-- ============================================================
-- Effect 1: Operation — Register activation cost + end phase
-- ============================================================
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	-- Register EFFECT_ACTIVATE_COST: both players must send 1
	-- card from hand to GY to activate any card or effect
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_ACTIVATE_COST)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(1,1)
	e1:SetReset(RESET_PHASE|PHASE_END)
	e1:SetCost(s.costchk)
	e1:SetOperation(s.costop)
	Duel.RegisterEffect(e1,tp)

	-- Register continuous field checks: when any player's hand
	-- becomes empty, immediately move to the End Phase.
	local e2=Effect.CreateEffect(e:GetHandler())
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_CHAIN_SOLVED)
	e2:SetReset(RESET_PHASE|PHASE_END)
	e2:SetOperation(s.ep_check)
	Duel.RegisterEffect(e2,tp)

	local e3=Effect.CreateEffect(e:GetHandler())
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_CHAIN_END)
	e3:SetReset(RESET_PHASE|PHASE_END)
	e3:SetOperation(s.ep_check)
	Duel.RegisterEffect(e3,tp)
end

-- ============================================================
-- Effect 1: Cost check — Player must have at least 1 hand card
-- ============================================================
function s.costchk(e,te_or_c,tp)
	return Duel.IsExistingMatchingCard(Card.IsAbleToGraveAsCost,tp,LOCATION_HAND,0,1,nil)
end

-- ============================================================
-- Effect 1: Cost operation — Send 1 card from hand to GY
-- ============================================================
function s.costop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_CARD,0,id)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,Card.IsAbleToGraveAsCost,tp,LOCATION_HAND,0,1,1,nil)
	if #g>0 then
		Duel.SendtoGrave(g,REASON_COST)
	end
end

-- ============================================================
-- Effect 1: End Phase check — If any player has no hand, end
-- ============================================================
function s.ep_check(e,tp,eg,ep,ev,re,r,rp)
	local phase=Duel.GetCurrentPhase()
	if phase~=PHASE_MAIN1 and phase~=PHASE_MAIN2 then return end
	local tp_hand=Duel.GetFieldGroupCount(tp,LOCATION_HAND,0)
	local opp_hand=Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)
	if tp_hand==0 or opp_hand==0 then
		local turnp=Duel.GetTurnPlayer()
		-- Prevent entering the Battle Phase to bypass phase selection prompt
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_CANNOT_BP)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e1:SetTargetRange(1,0)
		e1:SetReset(RESET_PHASE|PHASE_END)
		Duel.RegisterEffect(e1,turnp)
		Duel.SkipPhase(turnp,PHASE_MAIN1,RESET_PHASE|PHASE_END,1)
		Duel.SkipPhase(turnp,PHASE_BATTLE,RESET_PHASE|PHASE_END,1)
		Duel.SkipPhase(turnp,PHASE_MAIN2,RESET_PHASE|PHASE_END,1)
		e:Reset()
	end
end

-- ============================================================
-- Effect 2: Cost — Banish this card from GY
-- ============================================================
function s.gycost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToRemoveAsCost() end
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end

-- ============================================================
-- Effect 2: Filter — Banished card that can return to GY
-- ============================================================
function s.filter_tograve(c)
	return c:IsAbleToGrave()
end

-- ============================================================
-- Effect 2: Target — Select 1 banished card to return to GY
-- ============================================================
function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.filter_tograve,tp,LOCATION_REMOVED,LOCATION_REMOVED,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,PLAYER_ALL,LOCATION_REMOVED)
end

-- ============================================================
-- Effect 2: Operation — Send 1 banished card to the GY
-- ============================================================
function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.filter_tograve,tp,LOCATION_REMOVED,LOCATION_REMOVED,1,1,nil)
	if #g>0 then
		Duel.SendtoGrave(g,REASON_EFFECT)
	end
end
