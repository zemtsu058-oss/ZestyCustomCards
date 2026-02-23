-- BƯỚC 1: TỰ TẠO CONSTANT CỦA RIÊNG BẠN (Đặt ngay đầu file)
-- Bạn thích đặt tên gì cũng được, mình đặt là MY_REPLACE_COST
local MY_REPLACE_COST = 83289866 

local s,id=GetID()
function s.initial_effect(c)
	-- Link Summon
	c:EnableReviveLimit()
	Link.AddProcedure(c,s.mat_filter,2,2,s.lcheck)
	
	-- EFFECT 1: Thay thế Cost (Dùng Constant tự tạo)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(MY_REPLACE_COST) -- <== Dùng tên bạn vừa đặt ở trên
	e1:SetRange(LOCATION_MZONE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(1,0)
	e1:SetCondition(s.repcon) -- <== Quan trọng nhất là sửa cái hàm này
	e1:SetTarget(s.reptg)
	e1:SetOperation(s.repop)
	e1:SetValue(s.repval)
	c:RegisterEffect(e1)

	-- EFFECT 2: Special Summon
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetCost(s.spcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

-- Bộ lọc Link
function s.mat_filter(c,lc,sumtype,tp)
	return c:IsRace(RACE_SPELLCASTER,lc,sumtype,tp)
end
function s.lcheck(g,lc,sumtype,tp)
	return g:GetClassCount(Card.GetAttribute,lc,sumtype,tp)==#g
end

-- ==================================================================
-- KHU VỰC SỬA LỖI CRASH (Đọc kỹ phần này)
-- ==================================================================

function s.repfilter(c)
	return c:IsSetCard(0x128) and c:IsType(TYPE_SPELL) and c:IsAbleToGrave()
end

-- Hàm check điều kiện (Nguyên nhân gây lỗi "Parameter 2 is nil")
function s.repcon(e,tp,eg,ep,ev,re,r,rp)
	-- MẸO: Đừng tin biến 'tp' do game đưa vào (vì nó đang bị lỗi nil trên máy bạn)
	-- Hãy tự lấy ID người chơi bằng lệnh này:
	local my_player = e:GetHandlerPlayer()
	
	-- Thay thế 'tp' bằng 'my_player'
	return Duel.IsExistingMatchingCard(s.repfilter,my_player,LOCATION_DECK,0,1,nil)
end

function s.repval(e,re,tp)
	local rc=re:GetHandler()
	local my_player = e:GetHandlerPlayer()
	return rc:IsSetCard(0x128) and rc:IsType(TYPE_MONSTER) and rc:IsControler(my_player)
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local my_player = e:GetHandlerPlayer()
	return Duel.SelectYesNo(my_player,aux.Stringid(id,1))
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	local my_player = e:GetHandlerPlayer() -- Luôn dùng cái này cho chắc ăn
	Duel.Hint(HINT_CARD,0,id)
	Duel.Hint(HINT_SELECTMSG,my_player,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(my_player,s.repfilter,my_player,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoGrave(g,REASON_EFFECT)
	end
end

-- ==================================================================

-- Logic Effect 2 (Không đổi vì đã ổn)
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsType,tp,LOCATION_HAND,0,1,nil,TYPE_SPELL) end
	Duel.DiscardHand(tp,Card.IsType,1,1,REASON_COST+REASON_DISCARD,nil,TYPE_SPELL)
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x128) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetValue(1)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
end
