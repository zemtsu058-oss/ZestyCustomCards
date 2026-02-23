--Witchcrafter Wishes
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--==================================================
-- Utility
--==================================================

function s.wcmonster(c)
	return c:IsFaceup() and c:IsSetCard(0x128) and c:IsType(TYPE_MONSTER)
end

function s.wcspellcount(tp)
	return Duel.GetMatchingGroupCount(function(c)
		return c:IsSetCard(0x128) and c:IsType(TYPE_SPELL)
	end,tp,LOCATION_HAND+LOCATION_GRAVE,0,nil)
end

--==================================================
-- Target (FIXED CHECK)
--==================================================

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)

	local b1=Duel.GetMatchingGroupCount(s.wcmonster,tp,LOCATION_MZONE,0,nil)>0
		and Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil)

	local b2=Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)>0

	local b3=s.wcspellcount(tp)>0
		and Duel.IsExistingMatchingCard(Card.IsAbleToDeck,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil)

	if chk==0 then return b1 or b2 or b3 end

	local ops={}
	local opval={}

	if b1 then
		table.insert(ops,aux.Stringid(id,1))
		table.insert(opval,0)
	end
	if b2 then
		table.insert(ops,aux.Stringid(id,2))
		table.insert(opval,1)
	end
	if b3 then
		table.insert(ops,aux.Stringid(id,3))
		table.insert(opval,2)
	end

	local sel=Duel.SelectOption(tp,table.unpack(ops))
	e:SetLabel(opval[sel+1])
end

--==================================================
-- Operation
--==================================================

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local op=e:GetLabel()

	-- (1) Change ATK to 0
	if op==0 then
		local ct=Duel.GetMatchingGroupCount(s.wcmonster,tp,LOCATION_MZONE,0,nil)
		if ct==0 then return end

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
		local g=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,ct,nil)

		for tc in aux.Next(g) do
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_SET_ATTACK_FINAL)
			e1:SetValue(0)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
		end
	end

	-- (2) Mill then return non-Spells
	if op==1 then
		local ct=Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)
		if ct==0 then return end

		Duel.DiscardDeck(tp,ct,REASON_EFFECT)

		local g=Duel.GetMatchingGroup(function(c)
			return c:IsLocation(LOCATION_GRAVE)
				and c:IsPreviousLocation(LOCATION_DECK)
				and not c:IsType(TYPE_SPELL)
		end,tp,LOCATION_GRAVE,0,nil)

		if #g>0 then
			Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		end
	end

	-- (3) Recycle then draw
	if op==2 then
		local max=s.wcspellcount(tp)
		if max==0 then return end

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local g=Duel.SelectMatchingCard(tp,Card.IsAbleToDeck,tp,
			LOCATION_GRAVE+LOCATION_REMOVED,0,1,max,nil)

		if #g>0 then
			local ct=Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
			if ct>=2 then
				Duel.BreakEffect()
				Duel.Draw(tp,math.floor(ct/2),REASON_EFFECT)
			end
		end
	end
end