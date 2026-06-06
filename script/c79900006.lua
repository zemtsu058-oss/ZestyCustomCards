-- ============================================================
-- Card Name: Don't Ash The Witch!
-- Passcode : 79900006
-- Type     : Spell / Quick-Play
-- Archetype: None (0x0)
-- ============================================================
-- Effect 1 [Activate]: When your opponent activates a card or
--   effect in response to your Spellcaster monster's effect or
--   Spell Card's effect that would Special Summon a monster(s)
--   from your Deck: Negate the activation, and if you do,
--   destroy it and 1 random card in your opponent's hand.
--
-- Effect 2 [GY]: During your Main Phase, while this card is in
--   your GY: You can shuffle this card to the Deck, then draw 1 card.
--
-- Shared HOPT Limit: You can only use 1 effect of "Don't Ash
--   The Witch!" per turn, and only once that turn.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- Effect 1: Negate response to Special Summon from Deck
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_CHAINING)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.con_negate)
    e1:SetTarget(s.tg_negate)
    e1:SetOperation(s.op_negate)
    c:RegisterEffect(e1)

    -- Effect 2: Shuffle from GY to Deck to draw 1
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
    e2:SetType(EFFECT_TYPE_IGNITION) -- SetCode is implicit
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,id)
    e2:SetCondition(s.con_draw)
    e2:SetTarget(s.tg_draw)
    e2:SetOperation(s.op_draw)
    c:RegisterEffect(e2)
end

-- Helper function to check if the effect can Special Summon from Deck
function s.check_sp(ev,re)
    return function(category,checkloc)
        if not checkloc and re:IsHasCategory(category) then return true end
        local ex1,g1,gc1,dp1,dv1=Duel.GetOperationInfo(ev,category)
        local ex2,g2,gc2,dp2,dv2=Duel.GetPossibleOperationInfo(ev,category)
        if not (ex1 or ex2) then return false end
        local g=Group.CreateGroup()
        if g1 then g:Merge(g1) end
        if g2 then g:Merge(g2) end
        return (((dv1 or 0)|(dv2 or 0))&LOCATION_DECK)~=0 or (#g>0 and g:IsExists(Card.IsLocation,1,nil,LOCATION_DECK))
    end
end

-- Effect 1 Condition
function s.con_negate(e,tp,eg,ep,ev,re,r,rp)
    if ep==tp then return false end
    if not Duel.IsChainNegatable(ev) then return false end
    if ev<2 then return false end
    local pe,ptp=Duel.GetChainInfo(ev-1,CHAININFO_TRIGGERING_EFFECT,CHAININFO_TRIGGERING_PLAYER)
    if not pe or ptp~=tp then return false end
    local ph=pe:GetHandler()
    local is_spellcaster_monster = ph:IsMonster() and ph:IsRace(RACE_SPELLCASTER)
    local is_spell_card = pe:IsActiveType(TYPE_SPELL)
    if not (is_spellcaster_monster or is_spell_card) then return false end
    local checkfunc=s.check_sp(ev-1,pe)
    return checkfunc(CATEGORY_SPECIAL_SUMMON,true)
end

-- Effect 1 Target
function s.tg_negate(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    if re:GetHandler():IsRelateToEffect(re) then
        Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
    end
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,1-tp,LOCATION_HAND)
end

-- Effect 1 Operation
function s.op_negate(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) then
        local dg=Group.CreateGroup()
        if re:GetHandler():IsRelateToEffect(re) then
            dg:AddCard(re:GetHandler())
        end
        local hg=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
        if #hg>0 then
            local sg=hg:RandomSelect(tp,1)
            dg:Merge(sg)
        end
        if #dg>0 then
            Duel.Destroy(dg,REASON_EFFECT)
        end
    end
end

-- Effect 2 Condition
function s.con_draw(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsMainPhase() and Duel.GetTurnPlayer()==tp
end

-- Effect 2 Target
function s.tg_draw(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsAbleToDeck() and Duel.IsPlayerCanDraw(tp,1) end
    Duel.SetOperationInfo(0,CATEGORY_TODECK,c,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

-- Effect 2 Operation
function s.op_draw(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e)
        and Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0
        and c:IsLocation(LOCATION_DECK) then
        Duel.ShuffleDeck(tp)
        Duel.BreakEffect()
        Duel.Draw(tp,1,REASON_EFFECT)
    end
end
