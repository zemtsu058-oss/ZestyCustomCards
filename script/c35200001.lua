-- ============================================================
-- Card Name: Branded's New Adventure
-- Passcode : 35200001
-- Type     : Spell / Quick-Play
-- Archetype: Branded (0x160)
-- ============================================================
-- Effect 1: If this card is drawn during the Draw Phase, reveal it.
--           Apply protection to your Level 8 or higher Fusion Monsters
--           and prevent responses to your Fusion Summoning Spell effects
--           until the end of this turn, then banish this card face-down
--           during the End Phase.
-- Effect 2: If this card is added to your hand, except by drawing it:
--           send it to the GY, send 1 Spell/Trap from your hand or field
--           to the GY, add 1 "Branded" Spell/Trap from your Deck, GY,
--           or banishment to your hand, then Fusion Summon 1 Level 8
--           or higher Fusion Monster by banishing monsters from your
--           Deck and/or Extra Deck equal to the monsters your opponent
--           controls.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 - Draw Phase reveal, protection, and End Phase banish
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_REMOVE)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_DRAW)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCondition(s.con_drawn)
    e1:SetOperation(s.op_drawn)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 - Added to hand: send, search, and Fusion Summon
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SEARCH+CATEGORY_TOHAND+CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_TO_HAND)
    e2:SetCountLimit(1,id+1,EFFECT_COUNT_CODE_OATH)
    e2:SetCondition(s.con_added)
    e2:SetTarget(s.tg_added)
    e2:SetOperation(s.op_added)
    c:RegisterEffect(e2)
end

-- ============================================================
-- Effect 1: Condition - this card was drawn during the Draw Phase
-- ============================================================
function s.con_drawn(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return Duel.IsPhase(PHASE_DRAW) and c:IsReason(REASON_RULE)
end

-- ============================================================
-- Effect 1: Operation - reveal, apply turn effects, schedule banish
-- ============================================================
function s.op_drawn(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    Duel.ConfirmCards(1-tp,Group.FromCards(c))
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_PUBLIC)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
    c:RegisterEffect(e1)
    s.apply_turn_protection(c,tp)
    s.schedule_end_phase_banish(c,tp)
end

-- ============================================================
-- Effect 1: Helper - protect your Level 8+ Fusion Monsters this turn
-- ============================================================
function s.apply_turn_protection(c,tp)
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e1:SetTargetRange(LOCATION_MZONE,0)
    e1:SetTarget(s.tg_protected_fusion)
    e1:SetValue(s.val_opponent_only)
    e1:SetLabel(tp)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)

    local e2=e1:Clone()
    e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e2:SetValue(s.val_opponent_only)
    Duel.RegisterEffect(e2,tp)

    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_CANNOT_ACTIVATE)
    e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e3:SetTargetRange(0,1)
    e3:SetValue(s.val_no_response_to_fusion_spell)
    e3:SetLabel(tp)
    e3:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e3,tp)
end

-- ============================================================
-- Effect 1: Target - Level 8 or higher Fusion Monsters you control
-- ============================================================
function s.tg_protected_fusion(e,c)
    return c:IsFaceup() and c:IsType(TYPE_FUSION) and c:IsLevelAbove(8)
end

-- ============================================================
-- Effect 1: Value - opponent's card effects only
-- ============================================================
function s.val_opponent_only(e,re,rp)
    return rp==1-e:GetLabel()
end

-- ============================================================
-- Effect 1: Value - opponent cannot chain to your Fusion Spell effects
-- ============================================================
function s.val_no_response_to_fusion_spell(e,re,tp)
    local ch=Duel.GetCurrentChain()
    if ch==0 then return false end
    local te,p=Duel.GetChainInfo(ch,CHAININFO_TRIGGERING_EFFECT,CHAININFO_TRIGGERING_PLAYER)
    if p~=e:GetLabel() or not te then return false end
    local tc=te:GetHandler()
    return tc:IsType(TYPE_SPELL) and te:IsHasCategory(CATEGORY_SPECIAL_SUMMON)
end

-- ============================================================
-- Effect 1: Helper - banish this card face-down during the End Phase
-- ============================================================
function s.schedule_end_phase_banish(c,tp)
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EVENT_PHASE+PHASE_END)
    e1:SetCountLimit(1)
    e1:SetLabelObject(c)
    e1:SetOperation(s.op_end_phase_banish)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
end

-- ============================================================
-- Effect 1: Operation - End Phase face-down banish
-- ============================================================
function s.op_end_phase_banish(e,tp,eg,ep,ev,re,r,rp)
    local tc=e:GetLabelObject()
    if tc and tc:IsLocation(LOCATION_HAND) and tc:IsControler(tp) then
        Duel.Remove(tc,POS_FACEDOWN,REASON_EFFECT)
    end
end

-- ============================================================
-- Effect 2: Condition - added to hand, except by drawing
-- ============================================================
-- ============================================================
-- Effect 2: Condition - added to hand, except by drawing
-- ============================================================
function s.con_added(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:IsLocation(LOCATION_HAND) and not (Duel.IsPhase(PHASE_DRAW) and c:IsReason(REASON_RULE))
end

-- ============================================================
-- Effect 2: Filters
-- ============================================================
function s.filter_send_st(c)
    return (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP)) and c:IsAbleToGrave()
end

-- ============================================================
-- Effect 2: Filter Branded Spell/Trap
-- ============================================================
function s.filter_branded_st(c)
    return c:IsSetCard(0x160) and (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP)) and c:IsAbleToHand()
end

-- ============================================================
-- Effect 2: Filter Material
-- ============================================================
function s.filter_material(c)
    return c:IsType(TYPE_MONSTER) and c:IsCanBeFusionMaterial() and c:IsAbleToRemove()
end

-- ============================================================
-- Effect 2: Filter Fusion Ready
-- ============================================================
function s.filter_fusion_ready(c,e,tp,mg,ct)
    if not (c:IsType(TYPE_FUSION) and c:IsLevelAbove(8)
        and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)) then
        return false
    end
    local mg2=mg:Clone()
    mg2:RemoveCard(c)
    local rescon=function(sg,e,tp,mg)
        return c:CheckFusionMaterial(sg,nil,tp)
    end
    return aux.SelectUnselectGroup(mg2,e,tp,ct,ct,rescon,0)
end

-- ============================================================
-- Effect 2: Target - verify all sequence requirements
-- ============================================================
function s.tg_added(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    local ct=Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)
    if chk==0 then
        local mg=Duel.GetMatchingGroup(s.filter_material,tp,LOCATION_DECK+LOCATION_EXTRA,0,nil)
        return c:IsAbleToGrave()
            and Duel.IsExistingMatchingCard(s.filter_send_st,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,c)
            and Duel.IsExistingMatchingCard(s.filter_branded_st,tp,
                LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil)
            and ct>0
            and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(s.filter_fusion_ready,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg,ct)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,c,1,tp,LOCATION_HAND)
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_HAND+LOCATION_ONFIELD)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,ct,tp,LOCATION_DECK+LOCATION_EXTRA)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

-- ============================================================
-- Effect 2: Operation - send, search, restrict, and Fusion Summon
-- ============================================================
function s.op_added(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    if Duel.SendtoGrave(c,REASON_EFFECT)==0 or not c:IsLocation(LOCATION_GRAVE) then return end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local sg=Duel.SelectMatchingCard(tp,s.filter_send_st,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,1,nil)
    if #sg==0 or Duel.SendtoGrave(sg,REASON_EFFECT)==0 then return end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local ag=Duel.SelectMatchingCard(tp,s.filter_branded_st,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
    local ac=ag:GetFirst()
    if not ac then return end
    if Duel.SendtoHand(ac,nil,REASON_EFFECT)==0 then return end
    Duel.ConfirmCards(1-tp,ag)
    s.register_activation_lock(c,tp,ac:GetCode())

    s.perform_fusion_summon(e,tp)
end

-- ============================================================
-- Effect 2: Helper - searched card cannot be activated this turn
-- ============================================================
function s.register_activation_lock(c,tp,code)
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_CANNOT_ACTIVATE)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e1:SetTargetRange(1,0)
    e1:SetLabel(code)
    e1:SetValue(s.val_added_card_lock)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
end

-- ============================================================
-- Effect 2: Value - block activation by searched card code
-- ============================================================
function s.val_added_card_lock(e,re,tp)
    return re:GetHandler():IsCode(e:GetLabel())
end

-- ============================================================
-- Effect 2: Helper - Fusion Summon using Deck/Extra Deck materials
-- ============================================================
function s.perform_fusion_summon(e,tp)
    local ct=Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)
    if ct<=0 or Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

    local mg=Duel.GetMatchingGroup(s.filter_material,tp,LOCATION_DECK+LOCATION_EXTRA,0,nil)

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local fg=Duel.SelectMatchingCard(tp,s.filter_fusion_ready,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mg,ct)
    local fc=fg:GetFirst()
    if not fc then return end

    local mg2=mg:Clone()
    mg2:RemoveCard(fc)

    local rescon=function(sg,e,tp,mg)
        return fc:CheckFusionMaterial(sg,nil,tp)
    end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
    local sg=aux.SelectUnselectGroup(mg2,e,tp,ct,ct,rescon,1,tp,HINTMSG_REMOVE)
    if #sg~=ct then return end

    fc:SetMaterial(sg)
    if Duel.Remove(sg,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)~=ct then return end
    for mc in aux.Next(sg) do
        if mc:IsLocation(LOCATION_REMOVED) then
            s.register_material_lock(mc)
        end
    end
    
    Duel.BreakEffect()
    if Duel.SpecialSummon(fc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)>0 then
        fc:CompleteProcedure()
    end
end

-- ============================================================
-- Effect 2: Helper - materials cannot activate effects this turn
-- ============================================================
function s.register_material_lock(c)
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_CANNOT_TRIGGER)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
    c:RegisterEffect(e1)
end
