-- ============================================================
-- Card Name: Witchcrafter Trick
-- Passcode : 29600001
-- Type     : Trap / Normal
-- Archetype: Witchcrafter (0x128)
-- ============================================================
-- Effect 1 [Activate]: If you control a Spellcaster monster:
--   reveal 1 Spell in your hand; this effect become that Spell's
--   effect when that Spell is activated.
--
-- Effect 2 [Quick GY]: During either player's turn, except the
--   turn this card was sent to the GY: You can banish this card
--   in your GY, target 1 Spell in your GY; this effect becomes
--   that Spell's effect when that Spell is activated.
--
-- Restriction: You cannot activate monster effects the turn you
--   activate this card effects, except Spellcaster monsters.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- Effect 1: Activate - Copy Spell in hand
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.con_activate)
    e1:SetCost(s.cost_activate)
    e1:SetTarget(s.tg_activate)
    e1:SetOperation(s.op_activate)
    c:RegisterEffect(e1)

    -- Effect 2: GY - Copy Spell in GY
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetHintTiming(TIMING_DRAW_PHASE|TIMING_MAIN_END|TIMINGS_CHECK_MONSTER_E)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(aux.exccon)
    e2:SetCost(s.cost_gy)
    e2:SetTarget(s.tg_gy)
    e2:SetOperation(s.op_gy)
    c:RegisterEffect(e2)

    -- Add custom activity counter for non-Spellcaster monster effects
    Duel.AddCustomActivityCounter(id,ACTIVITY_CHAIN,s.filter_chain)
end

s.listed_series={0x128}

-- Custom activity counter filter
function s.filter_chain(re,tp,cid)
    return not (re:IsMonsterEffect() and not re:GetHandler():IsRace(RACE_SPELLCASTER))
end

-- Restriction helper
function s.register_restriction(e,tp)
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH+EFFECT_FLAG_CLIENT_HINT)
    e1:SetDescription(aux.Stringid(id,2))
    e1:SetCode(EFFECT_CANNOT_ACTIVATE)
    e1:SetTargetRange(1,0)
    e1:SetValue(s.val_aclimit)
    e1:SetReset(RESET_PHASE|PHASE_END)
    Duel.RegisterEffect(e1,tp)
end

function s.val_aclimit(e,re,tp)
    return re:IsMonsterEffect() and not re:GetHandler():IsRace(RACE_SPELLCASTER)
end

-- Effect 1
function s.con_activate(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsRace,RACE_SPELLCASTER),tp,LOCATION_MZONE,0,1,nil)
end

function s.filter_cost(c)
    return c:IsType(TYPE_SPELL) and not c:IsPublic() and c:CheckActivateEffect(true,true,false)~=nil
end

function s.cost_activate(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetCustomActivityCount(id,tp,ACTIVITY_CHAIN)==0
        and Duel.IsExistingMatchingCard(s.filter_cost,tp,LOCATION_HAND,0,1,nil) end
    s.register_restriction(e,tp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
    local g=Duel.SelectMatchingCard(tp,s.filter_cost,tp,LOCATION_HAND,0,1,1,nil)
    Duel.ConfirmCards(1-tp,g)
    Duel.ShuffleHand(tp)
    e:SetLabelObject(g:GetFirst())
end

function s.tg_activate(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    local tc=e:GetLabelObject()
    if chkc then
        local te=e:GetLabelObject()
        local tg=te:GetTarget()
        return tg and tg(e,tp,eg,ep,ev,re,r,rp,0,chkc)
    end
    if chk==0 then return true end
    local te=tc:CheckActivateEffect(true,true,false)
    e:SetProperty(te:GetProperty())
    e:SetLabel(te:GetLabel())
    e:SetLabelObject(te:GetLabelObject())
    local tg=te:GetTarget()
    if tg then tg(e,tp,eg,ep,ev,re,r,rp,1) end
    te:SetLabel(e:GetLabel())
    te:SetLabelObject(e:GetLabelObject())
    e:SetLabelObject(te)
    Duel.ClearOperationInfo(0)
end

function s.op_activate(e,tp,eg,ep,ev,re,r,rp)
    local te=e:GetLabelObject()
    if not te then return end
    e:SetLabel(te:GetLabel())
    e:SetLabelObject(te:GetLabelObject())
    local op=te:GetOperation()
    if op then op(e,tp,eg,ep,ev,re,r,rp) end
    te:SetLabel(e:GetLabel())
    te:SetLabelObject(e:GetLabelObject())
end

-- Effect 2
function s.cost_gy(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsAbleToRemoveAsCost()
        and Duel.GetCustomActivityCount(id,tp,ACTIVITY_CHAIN)==0 end
    s.register_restriction(e,tp)
    Duel.Remove(c,POS_FACEUP,REASON_COST)
end

function s.filter_gy(c)
    return c:IsType(TYPE_SPELL) and c:CheckActivateEffect(true,true,false)~=nil
end

function s.tg_gy(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then
        local te=e:GetLabelObject()
        local tg=te:GetTarget()
        return tg and tg(e,tp,eg,ep,ev,re,r,rp,0,chkc)
    end
    if chk==0 then return Duel.IsExistingTarget(s.filter_gy,tp,LOCATION_GRAVE,0,1,nil) end
    e:SetProperty(EFFECT_FLAG_CARD_TARGET)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    local g=Duel.SelectTarget(tp,s.filter_gy,tp,LOCATION_GRAVE,0,1,1,nil)
    local te=g:GetFirst():CheckActivateEffect(true,true,false)
    Duel.ClearTargetCard()
    g:GetFirst():CreateEffectRelation(e)
    e:SetProperty(te:GetProperty())
    e:SetLabel(te:GetLabel())
    e:SetLabelObject(te:GetLabelObject())
    local tg=te:GetTarget()
    if tg then tg(e,tp,eg,ep,ev,re,r,rp,1) end
    te:SetLabel(e:GetLabel())
    te:SetLabelObject(e:GetLabelObject())
    e:SetLabelObject(te)
    Duel.ClearOperationInfo(0)
end

function s.op_gy(e,tp,eg,ep,ev,re,r,rp)
    local te=e:GetLabelObject()
    if not te then return end
    if te:GetHandler():IsRelateToEffect(e) then
        e:SetLabel(te:GetLabel())
        e:SetLabelObject(te:GetLabelObject())
        local op=te:GetOperation()
        if op then op(e,tp,eg,ep,ev,re,r,rp) end
        te:SetLabel(e:GetLabel())
        te:SetLabelObject(e:GetLabelObject())
    end
end
