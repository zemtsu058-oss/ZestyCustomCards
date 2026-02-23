--Ttf Cat Squad (leave-field revive version)
local s,id=GetID()
function s.initial_effect(c)
	-- Fusion
	c:EnableReviveLimit()
	Fusion.AddProcMixRep(c,true,true,s.matfilter,3,3)

	-- (1) Negate & destroy (as before)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_CHAINING)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.negcon)
	e1:SetCost(s.negcost)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)

	-- (2a) Revive when sent to GY from field
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.leavecon)
	e2:SetCost(s.spcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
	-- (2b) Revive when banished from field
	local e3=e2:Clone()
	e3:SetCode(EVENT_REMOVE)
	c:RegisterEffect(e3)
end

-- materials: Ttf Beast
function s.matfilter(c,fc,sumtype,tp)
	return c:IsSetCard(0x789) and c:IsRace(RACE_BEAST)
end

-- (1) negate
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and Duel.IsChainNegatable(ev)
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsReleasable() end
	Duel.Release(e:GetHandler(),REASON_COST)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsDestructable() then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end

-- Helper: check Holy Sanctuary face-up (by setcode + Field Spell type) 
function s.has_sanctuary(tp)
	return Duel.IsExistingMatchingCard(function(c) return c:IsFaceup() and c:IsSetCard(0x789) and c:IsType(TYPE_SPELL+TYPE_FIELD) end,
		tp,LOCATION_ONFIELD,0,1,nil)
end

-- (2) conditions & cost/ops for revive when leaves field
-- only trigger if it actually *was on the field* before moving
function s.leavecon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- only if it was previously on the field
	if not c:IsPreviousLocation(LOCATION_ONFIELD) then return false end
	-- require Holy Sanctuary face-up
	return s.has_sanctuary(tp)
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		-- can special summon from current location (GY or REMOVED)
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- attempt to special summon from its current location (works from GY or REMOVED)
	if not c:IsRelateToEffect(e) then
		-- in some cores when leaving field the relation may be lost; try to locate by cardid in GY/REM
		-- but simplest is to attempt anyway:
	end
	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)==0 then return end
	-- double its current ATK
	local atk = c:GetAttack()
	if atk<0 then atk = 0 end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SET_ATTACK_FINAL)
	e1:SetValue(atk*2)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	c:RegisterEffect(e1)
end