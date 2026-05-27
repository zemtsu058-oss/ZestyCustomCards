-- ============================================================
-- Card Name: Castle of Dreams - Dream Show
-- Passcode : 192200010
-- Type     : Spell / Normal
-- Archetype: Castle of Dreams (0x782)
-- ============================================================
-- Effect 1: Add 1 "Castle of Dreams" card from your Deck to your
--           hand, except "Castle of Dreams - Dream Show", then if
--           your opponent controls a monster that was Special
--           Summoned from their Deck or Extra Deck, you can draw
--           1 card.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Normal Spell activation: Search + optional draw
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND+CATEGORY_DRAW)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetTarget(s.tg_search)
    e1:SetOperation(s.op_search)
    c:RegisterEffect(e1)
end

-- ============================================================
-- Effect 1: Filter — Castle of Dreams cards except this card
-- ============================================================
function s.filter_search(c)
    return c:IsSetCard(0x782) and not c:IsCode(192200010) and c:IsAbleToHand()
end

-- ============================================================
-- Effect 1: Filter — Opponent's monster SS from Deck or Extra Deck
-- ============================================================
function s.filter_opp(c,tp)
    local loc=c:GetSummonLocation()
    return c:IsSummonType(SUMMON_TYPE_SPECIAL)
        and (loc==LOCATION_DECK or loc==LOCATION_EXTRA)
end

-- ============================================================
-- Effect 1: Target — Check if a valid search target exists
-- ============================================================
function s.tg_search(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.filter_search,tp,LOCATION_DECK,0,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

-- ============================================================
-- Effect 1: Operation — Search, then optionally draw
-- ============================================================
function s.op_search(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.filter_search,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
    if Duel.IsExistingMatchingCard(s.filter_opp,tp,0,LOCATION_MZONE,1,nil,tp)
        and Duel.IsPlayerCanDraw(tp,1)
        and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
        Duel.BreakEffect()
        Duel.Draw(tp,1,REASON_EFFECT)
    end
end
