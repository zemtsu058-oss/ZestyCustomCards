--Blue-Eyes Hero Dragon
local s,id=GetID()
function s.initial_effect(c)
	--Fusion material
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,s.matfilter,aux.FilterBoolFunction(Card.IsRace,RACE_DRAGON))

	--Effect on Fusion Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DRAW+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	e1:SetCountLimit(1,id)
	c:RegisterEffect(e1)
end

--Fusion material: monster added to hand by an effect
function s.matfilter(c,fc,sumtype,tp)
	return c:IsMonster() and c:IsLocation(LOCATION_HAND) and c:IsReason(REASON_EFFECT)
end

--Must be Fusion Summoned
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

--Target
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local ops={}
	local opcodes={}

	--Draw 2
	if Duel.IsPlayerCanDraw(tp,2) then
		table.insert(ops,aux.Stringid(id,1))
		table.insert(opcodes,1)
	end
	--Search Fusion Spell
	if Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) then
		table.insert(ops,aux.Stringid(id,2))
		table.insert(opcodes,2)
	end
	--Special Summon Dragons
	if Duel.IsExistingMatchingCard(aux.FilterBoolFunction(Card.IsRace,RACE_DRAGON),
		tp,LOCATION_GRAVE,0,1,nil)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		table.insert(ops,aux.Stringid(id,3))
		table.insert(opcodes,3)
	end

	local op=Duel.SelectOption(tp,table.unpack(ops))
	e:SetLabel(opcodes[op+1])
end

--Operation
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local op=e:GetLabel()
	if op==1 then
		Duel.Draw(tp,2,REASON_EFFECT)

	elseif op==2 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end

	elseif op==3 then
		local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
		if ft<=0 then return end
		if ft>2 then ft=2 end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,aux.FilterBoolFunction(Card.IsRace,RACE_DRAGON),
			tp,LOCATION_GRAVE,0,1,ft,nil)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_DEFENSE)
		end
	end
end

--Fusion Spell filter
function s.thfilter(c)
	return c:IsSpell() and c:IsSetCard(0x46) and c:IsAbleToHand()
end