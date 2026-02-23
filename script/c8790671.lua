--Quadratic Equation Cannon
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

function s.extramonsterfilter(c)
	return c:IsType(TYPE_MONSTER) and c:HasLevel()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.extramonsterfilter,tp,LOCATION_EXTRA,0,1,nil)
	end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	-- Reveal Extra Deck
	Duel.ConfirmCards(1-tp,Duel.GetMatchingGroup(Card.IsType,tp,LOCATION_EXTRA,0,nil,TYPE_MONSTER))

	-- Opponent banishes 1 monster from your Extra Deck
	Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_REMOVE)
	local g1=Duel.SelectMatchingCard(1-tp,s.extramonsterfilter,tp,LOCATION_EXTRA,0,1,1,nil)
	if #g1==0 then return end
	Duel.Remove(g1,POS_FACEUP,REASON_EFFECT)
	local L1=g1:GetFirst():GetLevel()

	-- You banish 1 monster from your Extra Deck
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g2=Duel.SelectMatchingCard(tp,s.extramonsterfilter,tp,LOCATION_EXTRA,0,1,1,nil)
	if #g2==0 then return end
	Duel.Remove(g2,POS_FACEUP,REASON_EFFECT)
	local L2=g2:GetFirst():GetLevel()

	-- Declare number x (1~6)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NUMBER)
	local x=Duel.AnnounceNumber(tp,1,2,3,4,5,6)

	-- Calculate result
	local A = x*x*L1
	local B = x*L2

	local fieldCount = Duel.GetFieldGroupCount(tp,LOCATION_ONFIELD+LOCATION_GRAVE,LOCATION_ONFIELD+LOCATION_GRAVE)
	local K = A + B - fieldCount

	-- Apply effect
	if K==0 then
		-- Shuffle opponent field + GY to Deck
		local og=Duel.GetFieldGroup(tp,0,LOCATION_ONFIELD+LOCATION_GRAVE)
		Duel.SendtoDeck(og,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	else
		-- Shuffle your field to Deck
		local tg=Duel.GetFieldGroup(tp,LOCATION_ONFIELD,0)
		Duel.SendtoDeck(tg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
end