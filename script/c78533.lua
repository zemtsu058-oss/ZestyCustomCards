local s,id=GetID()
function s.initial_effect(c)
	-- Fusion Summon: 2 Spellcasters including WIND
	c:EnableReviveLimit()
	-- Sử dụng AddProcMix chuẩn để Profusion dễ nhận diện
	Fusion.AddProcMix(c,true,true,aux.FilterBoolFunctionEx(Card.IsRace,RACE_SPELLCASTER),s.ffilter)
	
	-- EFFECT 1: Send 1 "Witchcrafter" Spell from HAND or DECK and copy effect
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.cpcon)
	e1:SetTarget(s.cptg)
	e1:SetOperation(s.cpop)
	c:RegisterEffect(e1)
	
	-- EFFECT 2: Quick Effect return to hand (Giữ nguyên)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e2:SetCountLimit(1,id+100)
	e2:SetTarget(s.rthtg)
	e2:SetOperation(s.rthop)
	c:RegisterEffect(e2)
end

-- Bộ lọc nguyên liệu hệ WIND cho Madame
function s.ffilter(c,fc,sumtype,tp)
	return c:IsAttribute(ATTRIBUTE_WIND,fc,sumtype,tp) and c:IsRace(RACE_SPELLCASTER,fc,sumtype,tp)
end

-- ==========================================
-- LOGIC COPY EFFECT (GỬI TỪ TAY HOẶC DECK)
-- ==========================================

function s.cpcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

function s.cpfilter(c)
	return c:IsSetCard(0x128) and c:IsType(TYPE_SPELL) and c:IsAbleToGrave()
		and c:CheckActivateEffect(false,true,true)~=nil
end

function s.cptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		-- Kiểm tra cả tay (HAND) và bộ bài (DECK)
		return Duel.IsExistingMatchingCard(s.cpfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil) 
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	-- Cho phép chọn từ HAND hoặc DECK
	local g=Duel.SelectMatchingCard(tp,s.cpfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil)
	local tc=g:GetFirst()
	
	local te,ceg,cep,cev,cre,cr,crp=tc:CheckActivateEffect(false,true,true)
	Duel.SendtoGrave(g,REASON_EFFECT)
	
	e:SetProperty(te:GetProperty())
	local tg=te:GetTarget()
	if tg then tg(e,tp,ceg,cep,cev,cre,cr,crp,1) end
	
	e:SetLabelObject(te)
	Duel.ClearOperationInfo(0)
end

function s.cpop(e,tp,eg,ep,ev,re,r,rp)
	local te=e:GetLabelObject()
	if not te then return end
	local op=te:GetOperation()
	if op then op(e,tp,eg,ep,ev,re,r,rp) end
end

-- ==========================================
-- LOGIC RETURN TO HAND (QUICK EFFECT)
-- ==========================================
function s.rthfilter(c)
	return c:IsSetCard(0x128) and c:IsType(TYPE_SPELL+TYPE_TRAP)
end
function s.rthtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if chkc then return chkc:IsOnField() and chkc:IsAbleToHand() and chkc~=c end
	local gy_count=Duel.GetMatchingGroupCount(s.rthfilter,tp,LOCATION_GRAVE,0,nil)
	if chk==0 then 
		return gy_count>0 and c:IsAbleToHand()
			and Duel.IsExistingTarget(Card.IsAbleToHand,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,c) 
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g=Duel.SelectTarget(tp,Card.IsAbleToHand,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,gy_count,c)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,#g+1,tp,LOCATION_ONFIELD)
end
function s.rthop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tg=Duel.GetTargetCards(e)
	if #tg>0 then
		if c:IsRelateToEffect(e) then tg:AddCard(c) end
		Duel.SendtoHand(tg,nil,REASON_EFFECT)
	end
end
