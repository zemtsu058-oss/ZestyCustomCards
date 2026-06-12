--Determination
local s,id=GetID()
function s.initial_effect(c)
	--Always treated as "Undertale"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_SINGLE_RANGE)
	e0:SetRange(LOCATION_ALL)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(0x368)
	c:RegisterEffect(e0)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,500) end
	Duel.PayLPCost(tp,500)
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x367) and c:IsLevelBelow(4) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.fusfilter(c,e,tp,mg)
	return c:IsSetCard(0x366) and c:IsType(TYPE_FUSION) and c:CheckFusionMaterial(mg,nil,tp)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1 = false
	local b2 = false
	
	if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		local sg=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_GRAVE,0,nil,e,tp)
		if #sg>0 then
			b1 = true
		end
	end
	
	local mg1=Duel.GetFusionMaterial(tp):Filter(Card.IsLocation,nil,LOCATION_HAND|LOCATION_MZONE)
	local mg2=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,LOCATION_GRAVE,0,nil)
	local mg=mg1+mg2
	b2 = Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg)
	
	if chk==0 then return b1 or b2 end
	
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))
	elseif b1 then
		op=Duel.SelectOption(tp,aux.Stringid(id,1))
	else
		op=Duel.SelectOption(tp,aux.Stringid(id,2))+1
	end
	e:SetLabel(op)
	if op==0 then
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
	else
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	end
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local op=e:GetLabel()
	if op==0 then
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
		local tc=g:GetFirst()
		if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
			local syng=Duel.GetMatchingGroup(Card.IsSynchroSummonable,tp,LOCATION_EXTRA,0,nil,nil)
			if #syng>0 then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
				local sgc=syng:Select(tp,1,1,nil):GetFirst()
				Duel.SynchroSummon(tp,sgc,nil)
			end
		end
	else
		local chkf=tp
		local mg1=Duel.GetFusionMaterial(tp):Filter(Card.IsLocation,nil,LOCATION_HAND|LOCATION_MZONE)
		local mg2=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,LOCATION_GRAVE,0,nil)
		local mg=mg1+mg2
		local sg=Duel.GetMatchingGroup(s.fusfilter,tp,LOCATION_EXTRA,0,nil,e,tp,mg)
		if #sg>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local tc=sg:Select(tp,1,1,nil):GetFirst()
			if tc then
				local mat=Duel.SelectFusionMaterial(tp,tc,mg,nil,chkf)
				tc:SetMaterial(mat)
				local rmat=mat:Filter(Card.IsLocation,nil,LOCATION_GRAVE)
				local lmat=mat:Filter(Card.IsLocation,nil,LOCATION_HAND|LOCATION_MZONE)
				if #rmat>0 then
					Duel.Remove(rmat,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
				end
				if #lmat>0 then
					Duel.SendtoGrave(lmat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
				end
				Duel.BreakEffect()
				Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
				tc:CompleteProcedure()
			end
		end
	end
end
