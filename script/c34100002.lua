-- ============================================================
-- Card Name: Mikanko Illusion Dance
-- Passcode : 34100002
-- Type     : Spell / Equip
-- Archetype: Mikanko (0x18e)
-- ============================================================
-- The equipped monster cannot be destroyed by card effects.
-- You can only use each of the following effects once per turn.
-- (1) During your Main Phase, while this card is on the field, in
-- your GY, or banishment: Return this card to the hand; Special
-- Summon 1 "Mikanko" monster from your hand.
-- (2) During your Main Phase, while this card is equipped to a
-- monster: Return another "Mikanko" card on your field to the hand;
-- Special Summon 1 "Mikanko" monster from your hand or Deck.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    aux.AddEquipProcedure(c,nil,aux.FilterBoolFunction(Card.IsFaceup))

    -- ============================================================
    -- Effect 1 - Equipped monster cannot be destroyed by card effects
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_EQUIP)
    e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e1:SetValue(1)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 - Return this card to hand; Special Summon from hand
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_SZONE+LOCATION_GRAVE+LOCATION_REMOVED)
    e2:SetCountLimit(1,{id,1},EFFECT_COUNT_CODE_OATH)
    e2:SetCost(s.cost_self_to_hand)
    e2:SetTarget(s.tg_summon_hand)
    e2:SetOperation(s.op_summon_hand)
    c:RegisterEffect(e2)

    -- ============================================================
    -- Effect 3 - Return another "Mikanko" card; Special Summon from hand or Deck
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetRange(LOCATION_SZONE)
    e3:SetCountLimit(1,{id,2},EFFECT_COUNT_CODE_OATH)
    e3:SetCondition(s.con_equipped)
    e3:SetCost(s.cost_other_to_hand)
    e3:SetTarget(s.tg_summon_hand_deck)
    e3:SetOperation(s.op_summon_hand_deck)
    c:RegisterEffect(e3)
end

function s.filter_mikanko_summon(c,e,tp)
    return c:IsSetCard(0x18e) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.con_equipped(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():GetEquipTarget()~=nil
end

function s.cost_self_to_hand(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsAbleToHandAsCost() end
    Duel.SendtoHand(c,nil,REASON_COST)
end

function s.tg_summon_hand(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(s.filter_mikanko_summon,tp,LOCATION_HAND,0,1,nil,e,tp)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
end

function s.op_summon_hand(e,tp,eg,ep,ev,re,r,rp)
    -- IsRelateToEffect check is not required because this card returned to hand as cost.
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.filter_mikanko_summon,tp,LOCATION_HAND,0,1,1,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end

function s.filter_other_to_hand(c,ec)
    return c:IsSetCard(0x18e) and c~=ec and c:IsAbleToHandAsCost()
end

function s.cost_other_to_hand(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.filter_other_to_hand,tp,LOCATION_ONFIELD,0,1,nil,c)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
    local g=Duel.SelectMatchingCard(tp,s.filter_other_to_hand,tp,LOCATION_ONFIELD,0,1,1,nil,c)
    Duel.SendtoHand(g,nil,REASON_COST)
end

function s.tg_summon_hand_deck(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(s.filter_mikanko_summon,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end

function s.op_summon_hand_deck(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.filter_mikanko_summon,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end
