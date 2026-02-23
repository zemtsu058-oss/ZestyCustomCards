local s,id=GetID()
function s.initial_effect(c)
	-- Fusion Material: Thiết lập giới hạn hồi sinh (Must first be Special Summoned)
	c:EnableReviveLimit()
	
	-- ĐÃ LOẠI BỎ e0 (EFFECT_SPSUMMON_CONDITION) ĐỂ CHO PHÉP INVITATION TRIỆU HỒI

	-- Triệu hồi bằng cách gửi Geats Entry Form (với 2 Buckle) từ sân xuống GY
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Effect 1: Khi triệu hồi thành công - Trang bị lại từ GY và Search
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_EQUIP+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetTarget(s.eqtg)
	e2:SetOperation(s.eqop)
	c:RegisterEffect(e2)

	-- Effect 2: Boost Buckle - Bảo vệ Spell/Trap (Quick Effect)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.boostcon)
	e3:SetCost(s.boostcost)
	e3:SetOperation(s.boostop)
	c:RegisterEffect(e3)

	-- Effect 3: Magnum Buckle - Tăng ATK (Quick Effect)
	local e4=e3:Clone()
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_ATKCHANGE)
	e4:SetCountLimit(1,id+100)
	e4:SetCondition(s.magnumcon)
	e4:SetCost(s.magnumcost)
	e4:SetOperation(s.magnumop)
	c:RegisterEffect(e4)

	-- Effect 4: Cả 2 Buckle - Phủ nhận kích hoạt (Quick Effect)
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,3))
	e5:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_CHAINING)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1,id+200)
	e5:SetCondition(s.negcon)
	e5:SetCost(s.negcost)
	e5:SetTarget(s.negtg)
	e5:SetOperation(s.negop)
	c:RegisterEffect(e5)
end

s.listed_names={927680, 927681, 927682, 927683}
s.listed_series={0x927, 0x315}

-- ==========================================
-- THỦ TỤC TRIỆU HỒI ĐẶC BIỆT (MANUAL)
-- ==========================================
function s.spfilter(c)
	local g=c:GetEquipGroup()
	return c:IsFaceup() and c:IsCode(927680) 
		and g:IsExists(Card.IsCode,1,nil,927682) 
		and g:IsExists(Card.IsCode,1,nil,927683)
		and c:IsAbleToGraveAsCost()
end

function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_MZONE,0,nil)
	if #g>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local sg=g:Select(tp,1,1,nil)
		if sg then
			sg:KeepAlive()
			e:SetLabelObject(sg)
			return true
		end
	end
	return false
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	local tc=g:GetFirst()
	-- Lọc an toàn các trang bị
	local matg=tc:GetEquipGroup():Filter(Card.IsCode,nil,927682,927683)
	matg:AddCard(tc)
	Duel.SendtoGrave(matg,REASON_COST)
end

-- ==========================================
-- TRANG BỊ & SEARCH (ON SUMMON)
-- ==========================================
function s.eqfilter(c)
	return c:IsSetCard(0x315) and c:IsType(TYPE_SPELL) and not c:IsForbidden()
end
function s.thfilter(c)
	return c:IsSetCard(0x927) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingMatchingCard(s.eqfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,nil,1,tp,LOCATION_GRAVE)
end
function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ft=Duel.GetLocationCount(tp,LOCATION_SZONE)
	if ft<=0 or c:IsFacedown() or not c:IsRelateToEffect(e) then return end
	local g=Duel.SelectMatchingCard(tp,s.eqfilter,tp,LOCATION_GRAVE,0,1,math.min(ft,2),nil)
	if #g>0 then
		local tc=g:GetFirst()
		while tc do
			Duel.Equip(tp,tc,c)
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_EQUIP_LIMIT)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetValue(function(e,c) return e:GetOwner()==c end)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
			tc=g:GetNext()
		end
		-- Search quái Desire Hero
		local sg=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,nil)
		if #sg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,4)) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local hg=sg:Select(tp,1,1,nil)
			Duel.SendtoHand(hg,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,hg)
		end
	end
end

-- ==========================================
-- QUICK EFFECTS (BUCKLE LOGIC)
-- ==========================================
function s.boostcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetEquipGroup():IsExists(Card.IsCode,1,nil,927682)
end
function s.boostcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():GetEquipGroup():IsExists(Card.IsCode,1,nil,927682) end
	local g=e:GetHandler():GetEquipGroup():Filter(Card.IsCode,nil,927682)
	Duel.SendtoGrave(g,REASON_COST)
end
function s.boostop(e,tp,eg,ep,ev,re,r,rp)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetTargetRange(LOCATION_SZONE,0)
	e1:SetTarget(aux.TargetBoolFunction(Card.IsType,TYPE_SPELL+TYPE_TRAP))
	e1:SetValue(1)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

function s.magnumcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetEquipGroup():IsExists(Card.IsCode,1,nil,927683)
end
function s.magnumcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():GetEquipGroup():IsExists(Card.IsCode,1,nil,927683) end
	local g=e:GetHandler():GetEquipGroup():Filter(Card.IsCode,nil,927683)
	Duel.SendtoGrave(g,REASON_COST)
end
function s.magnumop(e,tp,eg,ep,ev,re,r,rp)
	local ct=Duel.GetMatchingGroupCount(Card.IsSetCard,tp,LOCATION_SZONE+LOCATION_GRAVE,0,nil,0x315)
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
	for tc in aux.Next(g) do
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(ct*300)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
	end
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	local g=e:GetHandler():GetEquipGroup()
	return g:IsExists(Card.IsCode,1,nil,927682) and g:IsExists(Card.IsCode,1,nil,927683)
		and not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED) and Duel.IsChainNegatable(ev)
end
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=e:GetHandler():GetEquipGroup():Filter(Card.IsCode,nil,927682,927683)
	if chk==0 then return #g>=2 end
	Duel.SendtoGrave(g,REASON_COST)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end
