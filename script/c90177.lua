-- ============================================================
-- Card Name: Labrynth Party
-- Passcode : 90177
-- Type     : Trap / Normal
-- Archetype: Labrynth (0x17f)
-- ============================================================
-- Effect 1: You can only activate this card if you have 2 or
--           more Normal Traps in your GY, including a "Labrynth"
--           Trap. Tribute 1 Level 8 Fiend monster; Set Normal Traps
--           from your Deck, up to the number of "Labrynth" cards
--           in your GY, with different names from the Traps in
--           your GY.
-- Effect 2: During your Main Phase: You can banish this card
--           from your GY; Set 1 "Labrynth" Trap from your GY.
--           It can be activated this turn, but banish it when
--           it leaves the field.
-- You can only use 1 "Labrynth Party" effect per turn, and only
-- once that turn.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
	-- ============================================================
	-- Effect 1 — Activation: Set Traps from Deck
	-- ============================================================
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(0)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.actcon)
	e1:SetCost(s.cost_tribute)
	e1:SetTarget(s.tg_setdeck)
	e1:SetOperation(s.op_setdeck)
	c:RegisterEffect(e1)

	-- ============================================================
	-- Effect 2 — GY: Banish self, Set 1 Labrynth Trap from GY
	-- ============================================================
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(0)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetCode(0)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e2:SetCondition(s.setcon2)
	e2:SetCost(s.cost_banish)
	e2:SetTarget(s.tg_setgy)
	e2:SetOperation(s.op_setgy)
	c:RegisterEffect(e2)
end

-- ============================================================
-- Effect 1: Condition — 2+ Normal Traps in GY including a Labrynth Trap
-- ============================================================
function s.filter_normaltrap(c)
	return c:IsType(TYPE_TRAP) and c:IsNormalTrap()
end

function s.filter_labtrap(c)
	return c:IsSetCard(0x17f) and c:IsNormalTrap()
end

function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.filter_normaltrap,tp,LOCATION_GRAVE,0,2,nil)
		and Duel.IsExistingMatchingCard(s.filter_labtrap,tp,LOCATION_GRAVE,0,1,nil)
end

-- ============================================================
-- Effect 1: Cost — Tribute 1 Level 8 Fiend monster
-- ============================================================
function s.filter_tribute(c)
	return c:IsLevel(8) and c:IsRace(RACE_FIEND) and c:IsReleasable()
end

function s.cost_tribute(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckReleaseGroup(tp,s.filter_tribute,1,nil) end
	local g=Duel.SelectReleaseGroup(tp,s.filter_tribute,1,1,nil)
	Duel.Release(g,REASON_COST)
end

-- ============================================================
-- Effect 1: Filter — Normal Traps in Deck with different names from GY Traps
-- ============================================================
function s.filter_setdeck(c,gy)
	return c:IsNormalTrap() and c:IsSSetable()
		and not gy:IsExists(Card.IsCode,1,nil,c:GetCode())
end

-- ============================================================
-- Effect 1: Filter — Count Labrynth cards in GY
-- ============================================================
function s.filter_labcard(c)
	return c:IsSetCard(0x17f)
end

-- ============================================================
-- Effect 1: Target — Check if valid targets exist
-- ============================================================
function s.tg_setdeck(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local gy=Duel.GetMatchingGroup(Card.IsType,tp,LOCATION_GRAVE,0,nil,TYPE_TRAP)
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingMatchingCard(s.filter_setdeck,tp,LOCATION_DECK,0,1,nil,gy)
	end
end

-- ============================================================
-- Effect 1: Operation — Set Traps from Deck
-- ============================================================
function s.op_setdeck(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,LOCATION_SZONE)
	if ft<=0 then return end
	local gy=Duel.GetMatchingGroup(Card.IsType,tp,LOCATION_GRAVE,0,nil,TYPE_TRAP)
	local labct=Duel.GetMatchingGroupCount(s.filter_labcard,tp,LOCATION_GRAVE,0,nil)
	if labct<=0 then return end
	local g=Duel.GetMatchingGroup(s.filter_setdeck,tp,LOCATION_DECK,0,nil,gy)
	if #g==0 then return end
	local ct=math.min(labct,#g,ft)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local sg=g:Select(tp,1,ct,nil)
	if #sg>0 then
		Duel.SSet(tp,sg)
	end
end

-- ============================================================
-- Effect 2: Condition — During your Main Phase
-- ============================================================
function s.setcon2(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return Duel.GetTurnPlayer()==tp and (ph==PHASE_MAIN1 or ph==PHASE_MAIN2)
end

-- ============================================================
-- Effect 2: Cost — Banish this card from GY
-- ============================================================
function s.cost_banish(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToRemoveAsCost() end
	Duel.Remove(c,POS_FACEUP,REASON_COST)
end

-- ============================================================
-- Effect 2: Filter — Labrynth Trap in GY that can be Set
-- ============================================================
function s.filter_setgy(c)
	return c:IsSetCard(0x17f) and c:IsType(TYPE_TRAP) and c:IsSSetable()
end

-- ============================================================
-- Effect 2: Target — Check if a valid Labrynth Trap exists in GY
-- ============================================================
function s.tg_setgy(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingMatchingCard(s.filter_setgy,tp,LOCATION_GRAVE,0,1,e:GetHandler())
	end
end

-- ============================================================
-- Effect 2: Operation — Set 1 Labrynth Trap from GY
-- ============================================================
function s.op_setgy(e,tp,eg,ep,ev,re,r,rp)
	-- IsRelateToEffect not checked because handler is banished as cost
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.filter_setgy,tp,LOCATION_GRAVE,0,1,1,e:GetHandler())
	local tc=g:GetFirst()
	if tc and Duel.SSet(tp,tc)>0 then
		-- Can be activated this turn
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		-- Banish when it leaves the field
		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
		e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e2:SetReset(RESET_EVENT+RESETS_REDIRECT)
		e2:SetValue(LOCATION_REMOVED)
		tc:RegisterEffect(e2)
	end
end