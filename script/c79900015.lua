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
-- Effect 1: If a card(s) is in either GY or banishment
--           (Quick Effect): You can banish this card from your
--           hand; until the end of the next turn, any card
--           banished, except from the GY, is sent to the GY
--           instead, also your opponent takes 100 damage for
--           each card sent to the GY that way.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
	-- ============================================================
	-- Effect 1 — Quick Effect from hand: Redirect banishment to GY + burn
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
-- Effect 1: Condition — At least 1 card in any GY or banished
-- ============================================================
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetFieldGroupCount(tp,LOCATION_GRAVE+LOCATION_REMOVED,LOCATION_GRAVE+LOCATION_REMOVED)>0
end

-- ============================================================
-- Effect 1: Cost — Banish this card from hand
-- ============================================================
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToRemoveAsCost() end
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end

-- ============================================================
-- Effect 1: Target — Declare damage to opponent
-- ============================================================
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,0)
end

-- ============================================================
-- Effect 1: Redirect filter — Exclude cards banished from GY
--           Also tags redirected cards with a flag for burn tracking
-- ============================================================
function s.redirect_filter(e,c)
	if c:GetPreviousLocation()==LOCATION_GRAVE then return false end
	-- Tag this card so the burn trigger can identify it
	c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
	return true
end

-- ============================================================
-- Effect 1: Operation — Register redirect + burn trigger
-- ============================================================
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- (1) Redirect: any card that would be banished (except from GY)
	--     is sent to GY instead
	--     Pattern mirrors Dimension Shifter's EFFECT_TO_GRAVE_REDIRECT
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE+EFFECT_FLAG_IGNORE_RANGE+EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetCode(EFFECT_REMOVE_REDIRECT)
	e1:SetTargetRange(0xff,0xff)
	e1:SetReset(RESET_PHASE+PHASE_END,2)
	e1:SetValue(LOCATION_GRAVE)
	e1:SetTarget(s.redirect_filter)
	Duel.RegisterEffect(e1,tp)
	-- (2) Burn trigger: when cards are sent to GY by this redirect,
	--     deal 100 damage per card to opponent
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetReset(RESET_PHASE+PHASE_END,2)
	e2:SetCondition(s.burn_condition)
	e2:SetOperation(s.burn_operation)
	Duel.RegisterEffect(e2,tp)
end

-- ============================================================
-- Effect 1: Burn condition — Check if any cards were redirected
-- ============================================================
function s.flagfilter(c)
	return c:GetFlagEffect(id)>0
end

function s.burn_condition(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.flagfilter,1,nil)
end

-- ============================================================
-- Effect 1: Burn operation — Deal 100 damage per redirected card
-- ============================================================
function s.burn_operation(e,tp,eg,ep,ev,re,r,rp)
	local g=eg:Filter(s.flagfilter,nil)
	local ct=#g
	if ct>0 then
		-- Clear flags to prevent double-counting
		for tc in g:Iter() do
			tc:ResetFlagEffect(id)
		end
		Duel.Damage(1-tp,ct*100,REASON_EFFECT)
	end
end
