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
-- Effect 1: Redirect filter — Only redirect cards NOT from GY
-- At redirect check time, the card is still at its current
-- location before being removed. IsLocation(LOCATION_GRAVE)
-- means the card is currently in GY (being banished FROM GY),
-- which we exclude.
-- ============================================================
function s.redirect_filter(e,c)
	return not c:IsLocation(LOCATION_GRAVE)
end

function s.rmlimit(e,re,rp)
	if not re then return false end
	local code=re:GetCode()
	return code==EFFECT_TO_GRAVE_REDIRECT or code==EFFECT_REMOVE_REDIRECT or code==EFFECT_LEAVE_FIELD_REDIRECT
end

-- ============================================================
-- Effect 1: Operation — Register redirect + burn trigger
-- Uses EFFECT_REMOVE_REDIRECT to redirect cards being banished
-- to GY instead. Also registers EFFECT_CANNOT_REMOVE with a
-- custom value function to block redirect-to-banish effects
-- (like Masked HERO Dark Law or Macro Cosmos) so the cards
-- go to the GY instead of being banished.
-- ============================================================
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- (1) Redirect: cards that would be banished (except from GY)
	--     are sent to GY instead
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE+EFFECT_FLAG_IGNORE_RANGE+EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetCode(EFFECT_REMOVE_REDIRECT)
	e1:SetTargetRange(0xff,0xff)
	e1:SetReset(RESET_PHASE+PHASE_END,2)
	e1:SetValue(LOCATION_GRAVE)
	e1:SetTarget(s.redirect_filter)
	Duel.RegisterEffect(e1,tp)
	-- (1b) Block redirect banishment: cards that would be banished by redirect effects (except from GY)
	--      cannot be removed/banished, so they go to GY instead.
	local e1b=Effect.CreateEffect(c)
	e1b:SetType(EFFECT_TYPE_FIELD)
	e1b:SetProperty(EFFECT_FLAG_SET_AVAILABLE+EFFECT_FLAG_IGNORE_RANGE+EFFECT_FLAG_IGNORE_IMMUNE)
	e1b:SetCode(EFFECT_CANNOT_REMOVE)
	e1b:SetTargetRange(0xff,0xff)
	e1b:SetReset(RESET_PHASE+PHASE_END,2)
	e1b:SetTarget(s.redirect_filter)
	e1b:SetValue(s.rmlimit)
	Duel.RegisterEffect(e1b,tp)
	-- (2) Burn trigger: continuous field effect monitors EVENT_TO_GRAVE
	--     Detects redirected cards via REASON_REDIRECT (0x4000000) or check function
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetReset(RESET_PHASE+PHASE_END,2)
	e2:SetCondition(s.burn_condition)
	e2:SetOperation(s.burn_operation)
	Duel.RegisterEffect(e2,tp)
end

-- ============================================================
-- Effect 1: Burn filter — Cards arriving in GY via redirect
-- or saved from redirect banishment (Macro Cosmos, etc.)
-- ============================================================
function s.burn_filter(c)
	if bit.band(c:GetReason(),REASON_REDIRECT)~=0 then return true end
	-- Check player-level redirects (e.g. Macro Cosmos, Dark Law)
	local peff=Duel.IsPlayerAffectedByEffect(c:GetControler(),EFFECT_TO_GRAVE_REDIRECT)
	if peff then
		local val=peff:GetValue()
		if val==LOCATION_REMOVED or (type(val)=="function" and val(peff,c)==LOCATION_REMOVED) then
			return true
		end
	end
	-- Check card-level redirects (e.g. Plaguespreader Zombie, etc.)
	local ceff=c:IsHasEffect(EFFECT_LEAVE_FIELD_REDIRECT)
	if ceff then
		local val=ceff:GetValue()
		if val==LOCATION_REMOVED or (type(val)=="function" and val(ceff,c)==LOCATION_REMOVED) then
			return true
		end
	end
	return false
end

function s.burn_condition(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.burn_filter,1,nil)
end

-- ============================================================
-- Effect 1: Burn operation — Deal 100 damage per redirected card
-- ============================================================
function s.burn_operation(e,tp,eg,ep,ev,re,r,rp)
	local g=eg:Filter(s.burn_filter,nil)
	local ct=#g
	if ct>0 then
		Duel.Damage(1-tp,ct*100,REASON_EFFECT)
	end
end
