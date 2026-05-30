-- ============================================================
-- Card Name: Power of the Dominators
-- Passcode : 44700001
-- Type     : Trap / Normal
-- Archetype: Dominus (0x1bf)
-- ============================================================
-- Effect: If you have no monster in your GY, you can activate
--         this card from your hand. When a card or effect is
--         activated in your opponent GY/banishment, or a card
--         or effect is activated that would move a card from
--         your opponent GY/banishment to a difference place:
--         Negate that effect, then if you have a Trap in your GY,
--         you can add 1 "Dominus" card from your Deck to your hand.
--         If you activate this card from your hand, you cannot
--         Special Summon monster from your hand, GY and banishment,
--         until the end of the next turn.
-- You can only activate 1 "Power of the Dominators" per turn.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- Effect 1: Activate / Negate
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_NEGATE+CATEGORY_TOHAND+CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_CHAINING)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCondition(s.negcon)
    e1:SetTarget(s.negtg)
    e1:SetOperation(s.negop)
    c:RegisterEffect(e1)

    -- Effect 2: Activate from hand
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_TRAP_ACT_IN_HAND)
    e2:SetCondition(s.handcon)
    c:RegisterEffect(e2)
end

-- Hand activation condition
function s.handcon(e)
    return Duel.GetMatchingGroupCount(Card.IsType,e:GetHandlerPlayer(),LOCATION_GRAVE,0,nil,TYPE_MONSTER)==0
end

-- Negate condition
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    if not Duel.IsChainNegatable(ev) then return false end
    
    -- Check 1: Activated in opponent's GY/banishment
    local loc=Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION)
    if rp==1-tp and (loc==LOCATION_GRAVE or loc==LOCATION_REMOVED) then
        return true
    end
    
    -- Check 2: Targets a card in opponent's GY/banishment
    local tg=Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS)
    if tg and tg:IsExists(function(c) return c:IsLocation(LOCATION_GRAVE|LOCATION_REMOVED)
        and c:IsControler(1-tp) end) then
        return true
    end
    
    -- Check 3: Opponent activates effect moving cards from GY/banishment (non-targeting)
    local cat=re:GetCategory()
    local is_move_cat=(cat&(CATEGORY_TOHAND|CATEGORY_TODECK
        |CATEGORY_SPECIAL_SUMMON|CATEGORY_REMOVE|CATEGORY_TOGRAVE))~=0
    if rp==1-tp and is_move_cat and Duel.GetFieldGroupCount(1-tp,LOCATION_GRAVE|LOCATION_REMOVED,0)>0 then
        return true
    end
    
    return false
end

-- Search filter for Dominus cards
function s.thfilter(c)
    return c:IsSetCard(0x1bf) and c:IsAbleToHand()
end

-- Negate target
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    
    -- Store hand activation flag
    if e:GetHandler():IsPreviousLocation(LOCATION_HAND) then
        e:SetLabel(1)
    else
        e:SetLabel(0)
    end
    
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end

-- Special Summon limit filter
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
    -- chk==0
    local loc=c:GetLocation()
    return (loc&(LOCATION_HAND|LOCATION_GRAVE|LOCATION_REMOVED))~=0
end

-- Negate operation
function s.negop(e,tp,eg,ep,ev,re,r,rp)
    -- IsRelateToEffect check is not required for Normal Trap activation
    -- Negate effect
    if Duel.NegateActivation(ev) then
        -- Optional search if Trap is in our GY
        if Duel.IsExistingMatchingCard(Card.IsType,tp,LOCATION_GRAVE,0,1,nil,TYPE_TRAP)
            and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
            and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
            Duel.BreakEffect()
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
            local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
            if #g>0 then
                Duel.SendtoHand(g,nil,REASON_EFFECT)
                Duel.ConfirmCards(1-tp,g)
            end
        end
    end
    
    -- Apply hand activation penalty
    if e:GetLabel()==1 then
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_FIELD)
        e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
        e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
        e1:SetTargetRange(1,0)
        e1:SetTarget(s.splimit)
        e1:SetReset(RESET_PHASE+PHASE_END,2)
        Duel.RegisterEffect(e1,tp)
        
        -- Client hint message
        aux.RegisterClientHint(e:GetHandler(),nil,tp,1,0,aux.Stringid(id,1),RESET_PHASE+PHASE_END,2)
    end
end
