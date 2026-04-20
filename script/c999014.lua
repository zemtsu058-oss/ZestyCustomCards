-- Melodious Family
local s,id = GetID()
function s.initial_effect(c)
	-- Must be Fusion Summoned
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,90276649,64881644,83793721,56208713)

	-- Only by "Melodious" effect
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_CONDITION)
	e1:SetValue(s.splimit)
	c:RegisterEffect(e1)

	---------------------------------------------------
	-- PROTECTION
	---------------------------------------------------

	-- Cannot be negated
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_DISABLE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0x9b))
	c:RegisterEffect(e2)

	-- Cannot return to hand
	local e3=e2:Clone()
	e3:SetCode(EFFECT_CANNOT_TO_HAND)
	c:RegisterEffect(e3)

	-- Cannot return to Deck
	local e4=e2:Clone()
	e4:SetCode(EFFECT_CANNOT_TO_DECK)
	c:RegisterEffect(e4)

	-- Cannot be tributed
	local e5=e2:Clone()
	e5:SetCode(EFFECT_UNRELEASABLE_NONSUM)
	e5:SetValue(1)
	c:RegisterEffect(e5)

	local e6=e2:Clone()
	e6:SetCode(EFFECT_UNRELEASABLE_EFFECT)
	e6:SetValue(1)
	c:RegisterEffect(e6)

	-- Cannot be turned face-down
	local e7=e2:Clone()
	e7:SetCode(EFFECT_CANNOT_TURN_SET)
	e7:SetValue(s.nosetval)
	c:RegisterEffect(e7)

	---------------------------------------------------
	-- EFFECT 1: Special 3 (GY/Banish)
	---------------------------------------------------
	local e8=Effect.CreateEffect(c)
	e8:SetDescription(aux.Stringid(id,0))
	e8:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e8:SetType(EFFECT_TYPE_QUICK_O)
	e8:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e8:SetCode(EVENT_FREE_CHAIN)
	e8:SetRange(LOCATION_MZONE)
	e8:SetCountLimit(1,id)
	e8:SetTarget(s.sp1tg)
	e8:SetOperation(s.sp1op)
	c:RegisterEffect(e8)

	---------------------------------------------------
	-- EFFECT 2: Special 2 + delayed banish
	---------------------------------------------------
	local e9=Effect.CreateEffect(c)
	e9:SetDescription(aux.Stringid(id,1))
	e9:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e9:SetType(EFFECT_TYPE_QUICK_O)
	e9:SetCode(EVENT_FREE_CHAIN)
	e9:SetRange(LOCATION_MZONE)
	e9:SetCountLimit(1,id+1)
	e9:SetTarget(s.sp2tg)
	e9:SetOperation(s.sp2op)
	c:RegisterEffect(e9)

	---------------------------------------------------
	-- EFFECT 3: Shuffle + Draw
	---------------------------------------------------
	local e10=Effect.CreateEffect(c)
	e10:SetDescription(aux.Stringid(id,2))
	e10:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
	e10:SetType(EFFECT_TYPE_IGNITION)
	e10:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e10:SetRange(LOCATION_MZONE)
	e10:SetCountLimit(1,id+2)
	e10:SetTarget(s.tdtg)
	e10:SetOperation(s.tdop)
	c:RegisterEffect(e10)
end

---------------------------------------------------
-- Summon limit
---------------------------------------------------
function s.splimit(e,se,sp,st)
	if (st&SUMMON_TYPE_FUSION)~=SUMMON_TYPE_FUSION then return true end
	return se and se:GetHandler():IsSetCard(0x9b)
end

---------------------------------------------------
-- Cannot be set face-down
---------------------------------------------------
function s.nosetval(e,re,rp)
	return rp~=e:GetHandlerPlayer()
end

---------------------------------------------------
-- EFFECT 1
---------------------------------------------------
function s.sp1filter(c,e,tp)
	return c:IsSetCard(0x9b) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup())
end

function s.sp1tg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED)
		and chkc:IsControler(tp) and s.sp1filter(chkc,e,tp) end

	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingTarget(s.sp1filter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp) end

	local ft=math.min(3,Duel.GetLocationCount(tp,LOCATION_MZONE))
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then ft=1 end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.sp1filter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,ft,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,#g,0,0)
end

function s.sp1op(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end

---------------------------------------------------
-- EFFECT 2
---------------------------------------------------
function s.sp2filter(c,e,tp)
	return c:IsSetCard(0x9b) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sp2tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.sp2filter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp) end
end

function s.sp2op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 then return end
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then ft=1 end
	ft=math.min(ft,2)

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.sp2filter),
		tp,LOCATION_DECK+LOCATION_GRAVE,0,1,ft,nil,e,tp)

	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end

	-- Register flag
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)

	-- Delayed trigger (NEXT chain)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCondition(s.bancon)
	e1:SetOperation(s.banop)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

function s.bancon(e,tp,eg,ep,ev,re,r,rp)
	return rp==tp
		and Duel.GetFlagEffect(tp,id)>0
		and re:IsActiveType(TYPE_MONSTER)
		and re:GetHandler():IsSetCard(0x9b)
end

function s.banop(e,tp,eg,ep,ev,re,r,rp)
	Duel.ResetFlagEffect(tp,id)

	Duel.Hint(HINT_CARD,0,id)

	local g=Duel.GetMatchingGroup(Card.IsAbleToRemove,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
	local ct=math.min(3,#g)

	if ct>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local sg=g:Select(tp,ct,ct,nil)
		Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)
	end

	e:Reset()
end

---------------------------------------------------
-- EFFECT 3 (FIXED)
---------------------------------------------------
function s.tdfilter(c)
	return c:IsSetCard(0x9b) and c:IsAbleToDeck()
end

function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED)
		and chkc:IsControler(tp) and s.tdfilter(chkc) end

	if chk==0 then
		return Duel.IsPlayerCanDraw(tp,1)
			and Duel.IsExistingTarget(s.tdfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,s.tdfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)

	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

function s.tdop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e)
		and Duel.SendtoDeck(tc,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
		Duel.Draw(tp,1,REASON_EFFECT)
	end
end