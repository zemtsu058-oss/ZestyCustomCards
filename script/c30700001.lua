-- ============================================================
-- Card Name: Dragonmaid's Soul!?
-- Passcode : 30700001
-- Type     : Spell / Normal
-- Archetype: Dragonmaid (0x133)
-- ============================================================
-- Effect 1: Send 1 "Dragonmaid" monster from your Deck or Extra
--           Deck to the GY; Special Summon 1 Dragon monster from
--           your Deck with the same Type as that monster.
-- Effect 2: You can banish this card from your GY, then apply 1
--           of these effects.
--           * Target 1 Dragon monster in either GY; Special
--             Summon it, but send it to the GY during the End Phase.
--           * If you control a "Dragonmaid" monster, take control
--             of 1 monster your opponent controls until the End Phase.
-- You can only use 1 "Dragonmaid's Soul!?" effect per turn, and
-- only once that turn.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 - Normal Spell activation: send, then Special Summon
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCost(s.cost_send)
    e1:SetTarget(s.tg_summon)
    e1:SetOperation(s.op_summon)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 - GY ignition: revive a Dragon or take control
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON+CATEGORY_CONTROL)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e2:SetCost(s.cost_banish)
    e2:SetTarget(s.tg_gy)
    e2:SetOperation(s.op_gy)
    c:RegisterEffect(e2)
end

-- ============================================================
-- Effect 1: Filter - "Dragonmaid" monster to send as cost
-- ============================================================
function s.filter_send(c,e,tp)
    return c:IsSetCard(0x133) and c:IsType(TYPE_MONSTER) and c:IsAbleToGraveAsCost()
        and Duel.IsExistingMatchingCard(s.filter_deck_summon,tp,LOCATION_DECK,0,1,nil,e,tp,c:GetRace(),c)
end

-- ============================================================
-- Effect 1: Filter - Dragon monster in Deck with the same Type
-- ============================================================
function s.filter_deck_summon(c,e,tp,race,exclude)
    return c~=exclude and c:IsRace(RACE_DRAGON) and c:IsRace(race)
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- ============================================================
-- Effect 1: Cost - Send 1 "Dragonmaid" monster to the GY
-- ============================================================
function s.cost_send(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(s.filter_send,tp,LOCATION_DECK+LOCATION_EXTRA,0,1,nil,e,tp)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.filter_send,tp,LOCATION_DECK+LOCATION_EXTRA,0,1,1,nil,e,tp)
    local tc=g:GetFirst()
    if tc and Duel.SendtoGrave(tc,REASON_COST)>0 then
        e:SetLabel(tc:GetRace())
    else
        e:SetLabel(0)
    end
end

-- ============================================================
-- Effect 1: Target - Check Deck Special Summon is possible
-- ============================================================
function s.tg_summon(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
    end
    local race=e:GetLabel()
    if race==0 then return end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

-- ============================================================
-- Effect 1: Operation - Special Summon from Deck
-- ============================================================
function s.op_summon(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    local race=e:GetLabel()
    if race==0 or Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.filter_deck_summon,tp,LOCATION_DECK,0,1,1,nil,e,tp,race)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- ============================================================
-- Effect 2: Cost - Banish this card from the GY
-- ============================================================
function s.cost_banish(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsAbleToRemoveAsCost() end
    Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end

-- ============================================================
-- Effect 2: Filter - Dragon monster in either GY
-- ============================================================
function s.filter_gy_summon(c,e,tp)
    return c:IsRace(RACE_DRAGON) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- ============================================================
-- Effect 2: Filter - Face-up "Dragonmaid" monster you control
-- ============================================================
function s.filter_dragonmaid_control(c)
    return c:IsFaceup() and c:IsSetCard(0x133) and c:IsType(TYPE_MONSTER)
end

-- ============================================================
-- Effect 2: Filter - Opponent's monster to control
-- ============================================================
function s.filter_control(c)
    return c:IsFaceup() and c:IsControlerCanBeChanged()
end

-- ============================================================
-- Effect 2: Target - Choose revive or control
-- ============================================================
function s.tg_gy(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then
        local op=e:GetLabel()
        if op==0 then
            return chkc:IsLocation(LOCATION_GRAVE) and s.filter_gy_summon(chkc,e,tp)
        end
        return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and s.filter_control(chkc)
    end
    local can_summon=Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingTarget(s.filter_gy_summon,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,nil,e,tp)
    local can_control=Duel.IsExistingMatchingCard(s.filter_dragonmaid_control,tp,LOCATION_MZONE,0,1,nil)
        and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingTarget(s.filter_control,tp,0,LOCATION_MZONE,1,nil)
    if chk==0 then return can_summon or can_control end

    local op=0
    if can_summon and can_control then
        op=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))
    elseif can_control then
        Duel.SelectOption(tp,aux.Stringid(id,2))
        op=1
    else
        Duel.SelectOption(tp,aux.Stringid(id,1))
    end
    e:SetLabel(op)
    if op==0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local g=Duel.SelectTarget(tp,s.filter_gy_summon,tp,LOCATION_GRAVE,LOCATION_GRAVE,1,1,nil,e,tp)
        Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
    else
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
        local g=Duel.SelectTarget(tp,s.filter_control,tp,0,LOCATION_MZONE,1,1,nil)
        Duel.SetOperationInfo(0,CATEGORY_CONTROL,g,1,0,0)
    end
end

-- ============================================================
-- Effect 2: Operation - Resolve selected GY effect
-- ============================================================
function s.op_gy(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if not tc or not tc:IsRelateToEffect(e) then return end
    local op=e:GetLabel()
    if op==0 then
        if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
        if Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
            e1:SetCode(EVENT_PHASE+PHASE_END)
            e1:SetCountLimit(1)
            e1:SetLabelObject(tc)
            e1:SetOperation(s.op_send_gy)
            e1:SetReset(RESET_PHASE+PHASE_END)
            Duel.RegisterEffect(e1,tp)
        end
    else
        if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
        Duel.GetControl(tc,tp,PHASE_END,1)
    end
end

-- ============================================================
-- Effect 2: Delayed operation - Send revived monster to the GY
-- ============================================================
function s.op_send_gy(e,tp,eg,ep,ev,re,r,rp)
    local tc=e:GetLabelObject()
    if tc and tc:IsLocation(LOCATION_MZONE) then
        Duel.SendtoGrave(tc,REASON_EFFECT)
    end
end
