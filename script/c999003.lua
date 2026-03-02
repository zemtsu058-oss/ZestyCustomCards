--Fall of the Fallen
local s,id=GetID()

function s.initial_effect(c)
	--Activate (Negate)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

---------------------------------------------------
-- CONDITION
---------------------------------------------------

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and Duel.IsChainNegatable(ev)
end

---------------------------------------------------
-- COST (Tribute 1 Fusion that used Fallen of Albaz)
---------------------------------------------------

function s.cfilter(c)
	return c:IsFaceup()
		and c:IsType(TYPE_FUSION)
		and c:GetMaterial()
		and c:GetMaterial():IsExists(Card.IsCode,1,nil,68468459)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.CheckReleaseGroup(tp,s.cfilter,1,nil)
	end
	local g=Duel.SelectReleaseGroup(tp,s.cfilter,1,1,nil)
	Duel.Release(g,REASON_COST)
end

---------------------------------------------------
-- TARGET
---------------------------------------------------

function s.rmfilter(c)
	return c:IsType(TYPE_FUSION)
		and c:IsRace(RACE_DRAGON)
		and c:IsAbleToRemove()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end

	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)

	local g=Duel.GetMatchingGroup(s.rmfilter,tp,LOCATION_GRAVE,0,nil)
	local ct=math.min(2,#g)
	if ct>0 then
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,ct,tp,LOCATION_GRAVE)
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,ct,1-tp,LOCATION_ONFIELD)
	end
end

---------------------------------------------------
-- OPERATION
---------------------------------------------------

function s.operation(e,tp,eg,ep,ev,re,r,rp)

	-- Negate
	if not Duel.NegateActivation(ev) then return end

	-- Destroy negated card
	local rc=re:GetHandler()
	if rc:IsRelateToEffect(re) then
		Duel.Destroy(rc,REASON_EFFECT)
	end

	-- Nếu đối thủ không có card → không được banish
	if Duel.GetFieldGroupCount(tp,0,LOCATION_ONFIELD)==0 then
		return
	end

	local g=Duel.GetMatchingGroup(s.rmfilter,tp,LOCATION_GRAVE,0,nil)
	if #g==0 then return end

	-- Hỏi có muốn banish không
	if not Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local rg=Duel.SelectMatchingCard(tp,s.rmfilter,tp,LOCATION_GRAVE,0,1,2,nil)
	local ct=Duel.Remove(rg,POS_FACEUP,REASON_EFFECT)

	if ct>0 then
		local dg=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_ONFIELD,nil)
		if #dg==0 then return end

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local sg=dg:Select(tp,ct,ct,nil)
		Duel.Destroy(sg,REASON_EFFECT)
	end
end