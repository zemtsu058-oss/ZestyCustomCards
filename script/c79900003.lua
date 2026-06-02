-- ============================================================
-- Card Name: First Day Of Witch
-- Passcode : 79900003
-- Type     : Spell / Normal
-- Archetype: None (0x0)
-- ============================================================
-- Effect 1 [Activate]: Send 1 Spellcaster monster from your Deck
--   to the GY, then, if your opponent activated a card or
--   effect this turn, you can send 1 Normal or Quick-Play Spell
--   from your Deck to the GY.
--
-- HOPT Limit: You can only activate 1 "First Day Of Witch" per turn.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- Effect 1: Send 1 Spellcaster, optionally 1 Spell
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOGRAVE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetTarget(s.tg_activate)
    e1:SetOperation(s.op_activate)
    c:RegisterEffect(e1)

    -- Custom activity counter to track any activation by the opponent
    Duel.AddCustomActivityCounter(id,ACTIVITY_CHAIN,s.filter_chain)
end

function s.filter_chain(re,tp,cid)
    return false
end

function s.filter_tg(c)
    return c:IsRace(RACE_SPELLCASTER) and c:IsAbleToGrave()
end

function s.filter_spell(c)
    return (c:IsNormalSpell() or c:IsQuickPlaySpell()) and c:IsAbleToGrave()
end

function s.tg_activate(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.filter_tg,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end

function s.op_activate(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.filter_tg,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)>0 and g:GetFirst():IsLocation(LOCATION_GRAVE) then
        if Duel.GetCustomActivityCount(id,1-tp,ACTIVITY_CHAIN)>0
            and Duel.IsExistingMatchingCard(s.filter_spell,tp,LOCATION_DECK,0,1,nil)
            and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
            Duel.BreakEffect()
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
            local sg=Duel.SelectMatchingCard(tp,s.filter_spell,tp,LOCATION_DECK,0,1,1,nil)
            if #sg>0 then
                Duel.SendtoGrave(sg,REASON_EFFECT)
            end
        end
    end
end
