local s,id=GetID()
function s.initial_effect(c)
	-- Effect 1: Search khi Summon/Special Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0)) -- "Khi Summon: Search bài"
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	local e1b=e1:Clone()
	e1b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e1b)

	-- Effect 2: Boost Buckle -> Invitation
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,3)) -- "Gửi Boost Buckle để lấy Invitation"
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.eqcon(927682)) 
	e2:SetTarget(s.eqtg(927681))    
	e2:SetOperation(s.eqop(927681, 927682))
	c:RegisterEffect(e2)

	-- Effect 3: Magnum Buckle -> Burn
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,4)) -- "Gửi Magnum Buckle để gây sát thương"
	e3:SetCategory(CATEGORY_DAMAGE+CATEGORY_TOGRAVE)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+200)
	e3:SetCondition(s.eqcon(927683)) 
	e3:SetTarget(s.damtg)
	e3:SetOperation(s.damop)
	c:RegisterEffect(e3)
end

s.listed_series={0x927, 0x315}
s.listed_names={927681, 927682, 927683}

-- Filters
function s.filter1(c)
	return c:IsSetCard(0x315) and c:IsType(TYPE_SPELL) and c:IsAbleToHand()
end
function s.filter2(c)
	return c:IsSetCard(0x927) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.invfilter(c)
	return c:IsFaceup() and c:IsCode(927681)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local b1=Duel.IsExistingMatchingCard(s.filter1,tp,LOCATION_DECK,0,1,nil)
		local inv=Duel.IsExistingMatchingCard(s.invfilter,tp,LOCATION_ONFIELD,0,1,nil)
		local b2=inv and Duel.IsExistingMatchingCard(s.filter2,tp,LOCATION_DECK,0,1,nil)
		return b1 or b2
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local inv=Duel.IsExistingMatchingCard(s.invfilter,tp,LOCATION_ONFIELD,0,1,nil)
	local b1=Duel.IsExistingMatchingCard(s.filter1,tp,LOCATION_DECK,0,1,nil)
	local b2=inv and Duel.IsExistingMatchingCard(s.filter2,tp,LOCATION_DECK,0,1,nil)
	
	local op=0
	if b1 and b2 then
		-- Dùng Stringid 1 và 2 để hiện text lựa chọn
		op=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))
	elseif b1 then
		op=0
	elseif b2 then
		op=1
	else return end
	
	local g
	if op==0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		g=Duel.SelectMatchingCard(tp,s.filter1,tp,LOCATION_DECK,0,1,1,nil)
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		g=Duel.SelectMatchingCard(tp,s.filter2,tp,LOCATION_DECK,0,1,1,nil)
	end
	
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- Equip Logic
function s.eqcon(eq_code)
	return function(e,tp,eg,ep,ev,re,r,rp)
		local g=e:GetHandler():GetEquipGroup()
		return g and #g>0 and g:IsExists(Card.IsCode,1,nil,eq_code)
	end
end

function s.eqtg(search_code)
	return function(e,tp,eg,ep,ev,re,r,rp,chk)
		if chk==0 then return Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_DECK,0,1,nil,search_code) end
		Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_SZONE)
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	end
end

function s.eqop(search_code, target_eq)
	return function(e,tp,eg,ep,ev,re,r,rp)
		local c=e:GetHandler()
		local g=c:GetEquipGroup():Filter(Card.IsCode,nil,target_eq)
		if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)~=0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local sg=Duel.SelectMatchingCard(tp,Card.IsCode,tp,LOCATION_DECK,0,1,1,nil,search_code)
			if #sg>0 then
				Duel.SendtoHand(sg,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,sg)
			end
		end
	end
end

function s.damtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_SZONE)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,200)
end

function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=c:GetEquipGroup():Filter(Card.IsCode,nil,927683)
	if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)~=0 then
		Duel.Damage(1-tp,200,REASON_EFFECT)
	end
end
