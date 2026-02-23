local s,id=GetID()
function s.initial_effect(c)
	-- Kích hoạt: Search 1 "Buckle" hoặc 1 "Desire Driver"
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- Hiệu ứng Fusion (Một lần mỗi lượt)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1)
	e2:SetTarget(s.fustg)
	e2:SetOperation(s.fusop)
	c:RegisterEffect(e2)

	-- Bảo vệ: "Desire Hero" có trang bị "Buckle" không bị chỉ định
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e3:SetRange(LOCATION_SZONE)
	e3:SetTargetRange(LOCATION_MZONE,0)
	e3:SetTarget(s.tgtg)
	e3:SetValue(aux.tgoval)
	c:RegisterEffect(e3)
end

s.listed_series={0x315, 0x927} 
s.listed_names={927684} 

-- LOGIC SEARCH & FLAG CHO DRIVER
function s.thfilter(c)
	return (c:IsSetCard(0x315) or c:IsCode(927684)) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	-- Đăng ký FLAG để Desire Driver (927684) nhận diện đã kích hoạt
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- LOGIC FUSION LÊN LEVEL 6
function s.costfilter1(c)
	return c:IsSetCard(0x315) and c:IsType(TYPE_SPELL) and c:IsDiscardable()
end
function s.costfilter2(c)
	return c:IsSetCard(0x927) and c:IsType(TYPE_MONSTER) and (c:IsLocation(LOCATION_DECK) or c:IsFaceup()) and c:IsAbleToGrave()
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x927) and c:IsType(TYPE_FUSION) and c:IsLevel(6)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.costfilter1,tp,LOCATION_HAND,0,1,nil)
			and Duel.IsExistingMatchingCard(s.costfilter2,tp,LOCATION_DECK+LOCATION_MZONE,0,1,nil)
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	
	-- 1. Chia đôi LP
	Duel.PayLPCost(tp,math.floor(Duel.GetLP(tp)/2))
	
	-- 2. Discard 1 Buckle từ tay
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
	local g1=Duel.SelectMatchingCard(tp,s.costfilter1,tp,LOCATION_HAND,0,1,1,nil)
	if #g1>0 and Duel.SendtoGrave(g1,REASON_EFFECT+REASON_DISCARD)~=0 then
		
		-- 3. Gửi 1 Desire Hero từ Deck/Field xuống mộ
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local g2=Duel.SelectMatchingCard(tp,s.costfilter2,tp,LOCATION_DECK+LOCATION_MZONE,0,1,1,nil)
		if #g2>0 and Duel.SendtoGrave(g2,REASON_EFFECT)~=0 then
			
			-- 4. Triệu hồi đặc biệt từ Extra Deck
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local sg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
			if #sg>0 then
				Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
			end
		end
	end
end

-- LOGIC BẢO VỆ
function s.tgtg(e,c)
	if not (c:IsSetCard(0x927) and c:IsType(TYPE_MONSTER)) then return false end
	return c:GetEquipGroup():IsExists(Card.IsSetCard,1,nil,0x315)
end
