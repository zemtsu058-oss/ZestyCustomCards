--Protection of the Albaz
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

-- When your card is targeted
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	if not re:IsHasProperty(EFFECT_FLAG_CARD_TARGET) then return false end
	local g=Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS)
	return g and g:IsExists(Card.IsControler,1,nil,tp)
end

function s.fusfilter(c)
	return c:IsType(TYPE_FUSION) and c:ListsCode(68468459) -- Fallen of Albaz ID
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_DECK,0,1,nil,68468459)
			and Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_MZONE+LOCATION_GRAVE)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	-- Send Albaz to GY
	local albaz=Duel.SelectMatchingCard(tp,Card.IsCode,tp,LOCATION_DECK,0,1,1,nil,68468459)
	if #albaz==0 then return end
	if Duel.SendtoGrave(albaz,REASON_EFFECT)==0 then return end
	
	-- Banish Fusion mentioning Albaz
	local g=Duel.SelectMatchingCard(tp,s.fusfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,1,nil)
	if #g==0 then return end
	if Duel.Remove(g,POS_FACEUP,REASON_EFFECT)==0 then return end
	
	-- Negate opponent cards on field & GY & banished
	local og=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD+LOCATION_GRAVE+LOCATION_REMOVED,nil)
	for oc in aux.Next(og) do
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		oc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		oc:RegisterEffect(e2)
	end
	
	-- Protection for 1500/1500 monsters
	local e3=Effect.CreateEffect(e:GetHandler())
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e3:SetTargetRange(LOCATION_MZONE,0)
	e3:SetTarget(function(e,c) return c:IsAttack(1500) and c:IsDefense(1500) end)
	e3:SetValue(aux.tgoval)
	e3:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e3,tp)
	
	local e4=e3:Clone()
	e4:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e4:SetValue(1)
	Duel.RegisterEffect(e4,tp)
	
	-- Banish this card face-down after resolution
	Duel.Remove(e:GetHandler(),POS_FACEDOWN,REASON_EFFECT)
end