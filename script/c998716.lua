-- ============================================================
-- Card Name: The Grand Stage of Maliss
-- Passcode : 998716
-- Type     : Spell / Continuous
-- Archetype: Maliss (0x1b9)
-- ============================================================
-- Effect 1: When this card is activated, add 1 "Maliss" monster
--           from your Deck to your hand, or if your opponent has
--           3 or more monsters in their banishment, you can
--           Special Summon it instead. For the rest of this turn,
--           you cannot Special Summon monsters from the Extra
--           Deck, except Link Monsters.
-- Effect 2: Your "Maliss" Link monsters gain this effect:
--           ● Once per turn, when your opponent activates a card
--           or effect: You can banish 1 card from your hand
--           (face-down); negate that effect, then banish that card.
-- You can only activate 1 "The Grand Stage of Maliss" per turn.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
	-- ============================================================
	-- Effect 1 — Activation: Search a Maliss monster or SS it
	-- ============================================================
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.tg_activate)
	e1:SetOperation(s.op_activate)
	c:RegisterEffect(e1)

	-- ============================================================
	-- Effect 2 — Grant negate effect to Maliss Link monsters
	-- ============================================================
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_GRANT)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.filter_grant)
	e2:SetLabelObject(s.create_negeff(c))
	c:RegisterEffect(e2)
end

-- ============================================================
-- Effect 1: Filter — Maliss monsters in Deck
-- ============================================================
function s.filter_search(c)
	return c:IsSetCard(0x1b9) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

function s.filter_search_ss(c,e,tp)
	return c:IsSetCard(0x1b9) and c:IsType(TYPE_MONSTER)
		and (c:IsAbleToHand() or (Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)))
end

-- ============================================================
-- Effect 1: Target — Check for valid search targets in Deck
-- ============================================================
function s.tg_activate(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.filter_search,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

-- ============================================================
-- Effect 1: Condition — Check if opponent has 3+ banished monsters
-- ============================================================
function s.check_banish_monster(c)
	return c:IsType(TYPE_MONSTER)
end

-- ============================================================
-- Effect 1: Operation — Search or Special Summon a Maliss monster
-- ============================================================
function s.op_activate(e,tp,eg,ep,ev,re,r,rp)
	local ss=Duel.IsExistingMatchingCard(s.check_banish_monster,tp,0,LOCATION_REMOVED,3,nil)
	local g
	if ss then
		g=Duel.GetMatchingGroup(s.filter_search_ss,tp,LOCATION_DECK,0,nil,e,tp)
	else
		g=Duel.GetMatchingGroup(s.filter_search,tp,LOCATION_DECK,0,nil)
	end
	if #g>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local tc=g:Select(tp,1,1,nil):GetFirst()
		if ss and tc:IsCanBeSpecialSummoned(e,0,tp,false,false)
			and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and (not tc:IsAbleToHand() or Duel.SelectOption(tp,1190,1152)==1) then
			Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
		else
			Duel.SendtoHand(tc,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,tc)
		end
	end
	-- Restriction: Cannot SS from Extra Deck except Link Monsters
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

function s.splimit(e,c)
	return c:IsLocation(LOCATION_EXTRA) and not c:IsType(TYPE_LINK)
end

-- ============================================================
-- Effect 2: Filter — Maliss Link monsters you control
-- ============================================================
function s.filter_grant(e,c)
	return c:IsSetCard(0x1b9) and c:IsType(TYPE_LINK)
end

-- ============================================================
-- Effect 2: Create — Negate effect granted to Maliss Link monsters
-- ============================================================
function s.create_negeff(c)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_CHAINING)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetCondition(s.negcon)
	e1:SetCost(s.negcost)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	return e1
end

-- ============================================================
-- Effect 2: Condition — Opponent activated a card/effect
-- ============================================================
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp~=tp and Duel.IsChainNegatable(ev)
end

-- ============================================================
-- Effect 2: Cost — Banish 1 card from hand face-down
-- ============================================================
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,LOCATION_HAND,0,1,nil,tp,POS_FACEDOWN)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,Card.IsAbleToRemove,tp,LOCATION_HAND,0,1,1,nil,tp,POS_FACEDOWN)
	Duel.Remove(g,POS_FACEDOWN,REASON_COST)
end

-- ============================================================
-- Effect 2: Target — Negate the activation
-- ============================================================
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,eg,1,0,0)
	end
end

-- ============================================================
-- Effect 2: Operation — Negate effect, then banish that card
-- ============================================================
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Remove(eg,POS_FACEUP,REASON_EFFECT)
	end
end
