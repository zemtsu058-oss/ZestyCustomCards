-- ============================================================
-- Card Name: WANTED: A Lazy Trouble Witch
-- Passcode : 79900007
-- Type     : Spell / Quick-Play
-- Archetype: None (0x0)
-- ============================================================
-- Effect 1 [Activate]: Target 1 Spellcaster monster you control;
--   add 1 level 6 or higher Spellcaster monster with different
--   Attribute from your Deck to your hand, or if you targeted a
--   level 6 or higher Spellcaster monster, you can add 1 level 5
--   or lower Spellcaster monster with different Attribute from
--   your Deck to your hand instead.
--
-- Effect 2 [GY]: During your Main Phase: You can banish this card
--   from your GY and target 1 Spellcaster monster in your
--   banishment; return that targeted card to the GY.
--
-- HOPT Limit: You can only use each effect of "WANTED: A Lazy
--   Trouble Witch" once per turn.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- Effect 1: Search Spellcaster monster
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.tg_activate)
    e1:SetOperation(s.op_activate)
    c:RegisterEffect(e1)

    -- Effect 2: GY return banished to GY
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOGRAVE)
    e2:SetType(EFFECT_TYPE_IGNITION) -- SetCode is implicit
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.con_gy)
    e2:SetCost(s.cost_gy)
    e2:SetTarget(s.tg_gy)
    e2:SetOperation(s.op_gy)
    c:RegisterEffect(e2)
end

-- Effect 1
function s.filter_tg(c,tp)
    if not (c:IsFaceup() and c:IsRace(RACE_SPELLCASTER)) then return false end
    local attr=c:GetAttribute()
    if c:IsLevelAbove(6) then
        return Duel.IsExistingMatchingCard(s.filter_add6or5,tp,LOCATION_DECK,0,1,nil,attr)
    else
        return Duel.IsExistingMatchingCard(s.filter_add6,tp,LOCATION_DECK,0,1,nil,attr)
    end
end

function s.filter_add6(c,attr)
    return c:IsRace(RACE_SPELLCASTER) and c:IsLevelAbove(6) and not c:IsAttribute(attr) and c:IsAbleToHand()
end

function s.filter_add6or5(c,attr)
    return c:IsRace(RACE_SPELLCASTER)
        and (c:IsLevelAbove(6) or c:IsLevelBelow(5))
        and not c:IsAttribute(attr) and c:IsAbleToHand()
end

function s.tg_activate(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.filter_tg(chkc,tp) end
    if chk==0 then return Duel.IsExistingTarget(s.filter_tg,tp,LOCATION_MZONE,0,1,nil,tp) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    Duel.SelectTarget(tp,s.filter_tg,tp,LOCATION_MZONE,0,1,1,nil,tp)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.op_activate(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if not tc or not tc:IsRelateToEffect(e) or tc:IsFacedown() then return end
    local attr=tc:GetAttribute()
    local g=nil
    if tc:IsLevelAbove(6) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        g=Duel.SelectMatchingCard(tp,s.filter_add6or5,tp,LOCATION_DECK,0,1,1,nil,attr)
    else
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        g=Duel.SelectMatchingCard(tp,s.filter_add6,tp,LOCATION_DECK,0,1,1,nil,attr)
    end
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

-- Effect 2
function s.con_gy(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsMainPhase() and Duel.GetTurnPlayer()==tp
end

function s.cost_gy(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsAbleToRemoveAsCost() end
    Duel.Remove(c,POS_FACEUP,REASON_COST)
end

function s.filter_gy(c)
    return c:IsFaceup() and c:IsRace(RACE_SPELLCASTER)
end

function s.tg_gy(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_REMOVED) and chkc:IsControler(tp) and s.filter_gy(chkc) end
    if chk==0 then return Duel.IsExistingTarget(s.filter_gy,tp,LOCATION_REMOVED,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectTarget(tp,s.filter_gy,tp,LOCATION_REMOVED,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,g,1,0,0)
end

function s.op_gy(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.SendtoGrave(tc,REASON_EFFECT+REASON_RETURN)
    end
end
