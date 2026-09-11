-- Magica: SYMPHONIC CADENZA THE SONG OF WAVE
-- ID: 999900011
local s,id=GetID()

local SET_MAGICA		  = 0x654
local SET_SOULGEM		 = 0xc7d
local CARD_SAYAKA_STUDENT = 999900008
local COUNTER_NOTE		= 0x1655

s.listed_series={SET_MAGICA, SET_SOULGEM}
s.listed_names={CARD_SAYAKA_STUDENT}

function s.initial_effect(c)
	-- HOPT Activation
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_COUNTER+CATEGORY_SPECIAL_SUMMON+CATEGORY_RECOVER)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.sayakafilter(c)
	return c:IsFaceup() and c:IsCode(CARD_SAYAKA_STUDENT)
end

function s.magicafilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_MAGICA)
end

function s.setfilter(c,e,tp)
	if not (c:IsSetCard(SET_MAGICA) or c:IsSetCard(SET_SOULGEM)) then return false end
	if c:IsType(TYPE_MONSTER) then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEDOWN_DEFENSE)
	elseif c:IsType(TYPE_SPELL+TYPE_TRAP) then
		return (c:IsType(TYPE_FIELD) or Duel.GetLocationCount(tp,LOCATION_SZONE)>0) and c:IsSSetable()
	end
	return false
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local magica_ct=Duel.GetMatchingGroupCount(s.magicafilter,tp,LOCATION_ONFIELD,0,nil)
	local b1=magica_ct>0 and Duel.IsExistingMatchingCard(Card.IsFaceup,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
	
	local note_ct=Duel.GetCounter(tp,LOCATION_ONFIELD,LOCATION_ONFIELD,COUNTER_NOTE)
	local b2=note_ct>=2 and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp)

	if chk==0 then return b1 or b2 end

	-- Khóa Chain & Không thể bị Negate nếu có Sayaka Student trên sân
	if Duel.IsExistingMatchingCard(s.sayakafilter,tp,LOCATION_MZONE,0,1,nil) then
		e:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CANNOT_NEGATE)
		Duel.SetChainLimit(s.chainlm)
	else
		e:SetProperty(0)
	end

	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,0),aux.Stringid(id,1))
	elseif b1 then
		op=Duel.SelectOption(tp,aux.Stringid(id,0))
	else
		op=Duel.SelectOption(tp,aux.Stringid(id,1))+1
	end
	e:SetLabel(op)

	if op==0 then
		e:SetCategory(CATEGORY_COUNTER)
	else
		e:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_RECOVER)
	end
end

function s.chainlm(e,rp,tp)
	return false
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local op=e:GetLabel()

	if op==0 then
		-- Hiệu ứng 1: Đặt Note Counter = số lá "Magica" đang điều khiển
		local ct=Duel.GetMatchingGroupCount(s.magicafilter,tp,LOCATION_ONFIELD,0,nil)
		if ct<=0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
		local g=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
		if #g>0 then
			g:GetFirst():AddCounter(COUNTER_NOTE,ct)
		end
	else
		-- Hiệu ứng 2: Trừ Note Counter -> Set bài -> Hồi LP -> Chống sát thương
		local note_ct=Duel.GetCounter(tp,LOCATION_ONFIELD,LOCATION_ONFIELD,COUNTER_NOTE)
		if note_ct<2 then return end

		local max_remove=math.min(6, math.floor(note_ct/2)*2)
		local options={}
		for i=2, max_remove, 2 do
			table.insert(options, i)
		end

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local remove_ct=Duel.AnnounceNumber(tp,table.unpack(options))

		if Duel.RemoveCounter(tp,LOCATION_ONFIELD,LOCATION_ONFIELD,COUNTER_NOTE,remove_ct,REASON_EFFECT) then
			local set_count=remove_ct/2

			for i=1, set_count do
				local sg=Duel.GetMatchingGroup(s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,nil,e,tp)
				if #sg==0 then break end
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
				local tc=sg:Select(tp,1,1,nil):GetFirst()
				if tc then
					if tc:IsType(TYPE_MONSTER) then
						Duel.SpecialSummonStep(tc,0,tp,tp,false,false,POS_FACEDOWN_DEFENSE)
						Duel.ConfirmCards(1-tp,tc)
					else
						Duel.SSet(tp,tc)
					end
				end
			end
			Duel.SpecialSummonComplete()

			-- Hồi 200 LP cho mỗi 2 Note Counter còn lại trên sân
			local rem_ct=Duel.GetCounter(tp,LOCATION_ONFIELD,LOCATION_ONFIELD,COUNTER_NOTE)
			local gain_lp=math.floor(rem_ct/2)*200
			if gain_lp>0 then
				Duel.BreakEffect()
				Duel.Recover(tp,gain_lp,REASON_EFFECT)
			end

			-- Trừ đủ 6 Counter: Không chịu sát thương cho đến hết lượt tiếp theo
			if remove_ct==6 then
				local e1=Effect.CreateEffect(e:GetHandler())
				e1:SetType(EFFECT_TYPE_FIELD)
				e1:SetCode(EFFECT_CHANGE_DAMAGE)
				e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
				e1:SetTargetRange(1,0)
				e1:SetValue(0)
				e1:SetReset(RESET_PHASE+PHASE_END,2)
				Duel.RegisterEffect(e1,tp)

				local e2=e1:Clone()
				e2:SetCode(EFFECT_NO_EFFECT_DAMAGE)
				Duel.RegisterEffect(e2,tp)
			end
		end
	end
end
