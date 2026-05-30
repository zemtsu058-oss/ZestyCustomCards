-- ============================================================
-- Card Name: Maliss of the Fallen Game
-- Passcode : 44100001
-- Type     : Spell / Normal
-- Archetype: Maliss (0x1b9)
-- ============================================================
-- Effect: Pay half your LP; banish all cards in your GY, then,
--         for every 2 "Maliss" cards banished by this effect,
--         randomly banish 1 card from your opponent's Extra Deck
--         until the End Phase.
--         Opponents' cards that are banished by this card's
--         effect cannot activate their effects until the End Phase.
-- You can only activate 1 "Maliss of the Fallen Game" per turn.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Normal Spell activation: Pay half LP, banish GY,
    --            then banish from opponent's Extra Deck
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_REMOVE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCost(s.cost)
    e1:SetTarget(s.tg_activate)
    e1:SetOperation(s.op_activate)
    c:RegisterEffect(e1)
end

-- ============================================================
-- Effect 1: Cost — Pay half your LP
-- ============================================================
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    local lp=Duel.GetLP(tp)
    Duel.PayLPCost(tp,lp//2)
end

-- ============================================================
-- Effect 1: Target — Check if there are cards in your GY
-- ============================================================
function s.tg_activate(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(aux.TRUE,tp,LOCATION_GRAVE,0,1,nil)
    end
    local g=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_GRAVE,0,nil)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,#g,0,0)
end

-- ============================================================
-- Effect 1: Operation — Banish all GY cards, then randomly banish
--           from opponent's Extra Deck based on Maliss count
-- ============================================================
function s.op_activate(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    -- Step 1: Banish all cards in your GY
    local g=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_GRAVE,0,nil)
    if #g==0 then return end
    Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
    
    -- Count how many "Maliss" cards were actually banished
    local og=Duel.GetOperatedGroup()
    local maliss_count=0
    local tc=og:GetFirst()
    while tc do
        if tc:IsSetCard(0x1b9) then
            maliss_count=maliss_count+1
        end
        tc=og:GetNext()
    end
    
    -- Step 2: For every 2 Maliss cards banished, randomly banish 1
    -- from opponent's Extra Deck until the End Phase
    local banish_count=maliss_count//2
    if banish_count<=0 then return end
    local eg_extra=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_EXTRA,nil)
    if #eg_extra<=0 then return end
    local actual_banish=math.min(banish_count,#eg_extra)
    
    -- Randomly select cards from opponent's Extra Deck
    local selected=eg_extra:RandomSelect(tp,actual_banish)
    if #selected>0 and Duel.Remove(selected,POS_FACEUP,REASON_EFFECT)>0 then
        local og2=Duel.GetOperatedGroup()
        local tc2=og2:GetFirst()
        while tc2 do
            -- Register activation-lock directly on the banished card
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_CANNOT_TRIGGER)
            e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
            tc2:RegisterEffect(e1)
            tc2=og2:GetNext()
        end
        
        -- Register return effect for End Phase as a group
        og2:KeepAlive()
        local e2=Effect.CreateEffect(e:GetHandler())
        e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        e2:SetCode(EVENT_PHASE+PHASE_END)
        e2:SetReset(RESET_PHASE+PHASE_END)
        e2:SetLabelObject(og2)
        e2:SetCountLimit(1)
        e2:SetOperation(s.op_return)
        Duel.RegisterEffect(e2,tp)
    end
end

-- ============================================================
-- Effect 1: Return — Send banished card back to Extra Deck
-- ============================================================
function s.op_return(e,tp,eg,ep,ev,re,r,rp)
    local g=e:GetLabelObject()
    local sg=g:Filter(Card.IsLocation,nil,LOCATION_REMOVED)
    if #sg>0 then
        Duel.SendtoDeck(sg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
    end
    g:DeleteGroup()
    e:Reset()
end
