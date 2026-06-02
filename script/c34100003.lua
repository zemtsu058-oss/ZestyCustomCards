-- ============================================================
-- Card Name: Mikanko Fire Soul
-- Passcode : 34100003
-- Type     : Spell / Equip
-- Archetype: Mikanko (0x18e)
-- ============================================================
-- The equipped monster cannot be destroyed by card effects.
-- During the Main Phase: You can send this card and the monster
-- equipped with this card to the GY; Special Summon up to 2 "Mikanko"
-- monsters from your Deck and/or GY, max. 1 from each location. You
-- can only use this effect of "Mikanko Fire Soul" once per turn.
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
    -- Effect 2 - Send this card and equipped monster; Special Summon from Deck/GY
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_SZONE)
    e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
    e2:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e2:SetCondition(s.con_main_phase)
    e2:SetCost(s.cost_send_equipped)
    e2:SetTarget(s.tg_summon_deck_grave)
    e2:SetOperation(s.op_summon_deck_grave)
    c:RegisterEffect(e2)
end

function s.con_main_phase(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsMainPhase()
end

function s.cost_send_equipped(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    local ec=c:GetEquipTarget()
    if chk==0 then
        return ec and c:IsAbleToGraveAsCost() and ec:IsAbleToGraveAsCost()
    end
    local g=Group.FromCards(c,ec)
    Duel.SendtoGrave(g,REASON_COST)
end

function s.filter_mikanko_summon(c,e,tp)
    return c:IsSetCard(0x18e) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.tg_summon_deck_grave(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(s.filter_mikanko_summon,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.op_summon_deck_grave(e,tp,eg,ep,ev,re,r,rp)
    local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
    if ft<=0 then return end
    local sg=Group.CreateGroup()
    if Duel.IsExistingMatchingCard(s.filter_mikanko_summon,tp,LOCATION_DECK,0,1,nil,e,tp)
        and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local dg=Duel.SelectMatchingCard(tp,s.filter_mikanko_summon,tp,LOCATION_DECK,0,1,1,nil,e,tp)
        sg:Merge(dg)
    end
    if #sg<ft and Duel.IsExistingMatchingCard(s.filter_mikanko_summon,tp,LOCATION_GRAVE,0,1,nil,e,tp)
        and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local gg=Duel.SelectMatchingCard(tp,s.filter_mikanko_summon,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
        sg:Merge(gg)
    end
    if #sg==0 then
        local loc=LOCATION_DECK
        if not Duel.IsExistingMatchingCard(s.filter_mikanko_summon,tp,LOCATION_DECK,0,1,nil,e,tp) then
            loc=LOCATION_GRAVE
        end
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        sg=Duel.SelectMatchingCard(tp,s.filter_mikanko_summon,tp,loc,0,1,1,nil,e,tp)
    end
    if #sg>0 then
        Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
    end
end
