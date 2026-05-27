-- ============================================================
-- Card Name: Castle of Dreams - Fairytale
-- Passcode : 192200008
-- Type     : Spell / Field
-- Archetype: Castle of Dreams (0x782)
-- ============================================================
-- Effect 1: During your Main Phase: You can add 1 "Castle of
--           Dreams" monster from your Deck to your hand.
-- Effect 2: Each turn, when your opponent activates a card or
--           effect that would negate the effect of another card
--           (Quick Effect): You can negate that effect, and if
--           you do, your opponent chooses
--           1 of these effects for you to apply.
--           (1) Both players draw 1 card.
--           (2) All monsters on the field gain 500 ATK.
--           (3) Both players gain 1000 LP.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Activation — Field Spell placeholder (no on-activation effect)
    -- ============================================================
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_ACTIVATE)
    e0:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e0)

    -- ============================================================
    -- Effect 1 — Ignition: Search a Castle of Dreams monster from Deck
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_FZONE)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetTarget(s.tg_search)
    e1:SetOperation(s.op_search)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — Quick Effect: Negate opponent's effect negate, opponent chooses replacement
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_NEGATE+CATEGORY_DRAW+CATEGORY_ATKCHANGE+CATEGORY_RECOVER)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_CHAINING)
    e2:SetRange(LOCATION_FZONE)
    e2:SetCountLimit(1,id+1,EFFECT_COUNT_CODE_OATH)
    e2:SetCondition(s.cond_negate)
    e2:SetTarget(s.tg_negate)
    e2:SetOperation(s.op_negate)
    c:RegisterEffect(e2)
end

-- ============================================================
-- Effect 1: Filter — Castle of Dreams monsters in Deck
-- ============================================================
function s.filter_monster(c)
    return c:IsSetCard(0x782) and c:IsMonster() and c:IsAbleToHand()
end

-- ============================================================
-- Effect 1: Target — Check for valid search targets in Deck
-- ============================================================
function s.tg_search(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.filter_monster,tp,LOCATION_DECK,0,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

-- ============================================================
-- Effect 1: Operation — Select 1 monster from Deck, add to hand
-- ============================================================
function s.op_search(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.filter_monster,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

-- ============================================================
-- Effect 2: Condition — Opponent activated an effect-negate effect
-- ============================================================
function s.cond_negate(e,tp,eg,ep,ev,re,r,rp)
    return rp==1-tp and (re:IsHasCategory(CATEGORY_DISABLE) or re:IsHasCategory(CATEGORY_NEGATE))
        and Duel.IsChainNegatable(ev)
end

-- ============================================================
-- Effect 2: Target — Always true (instant chain response)
-- ============================================================
function s.tg_negate(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,nil,0,0,0)
end

-- ============================================================
-- Effect 2: Operation — Negate opponent's effect, opponent chooses replacement
-- ============================================================
function s.op_negate(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    Duel.NegateActivation(ev)
    Duel.Hint(HINT_SELECTMSG,1-tp,aux.Stringid(id,2))
    local op=Duel.SelectOption(1-tp,aux.Stringid(id,2),aux.Stringid(id,3),aux.Stringid(id,4))
    if op==0 then
        if Duel.IsPlayerCanDraw(tp,1) and Duel.IsPlayerCanDraw(1-tp,1) then
            Duel.Draw(tp,1,REASON_EFFECT)
            Duel.Draw(1-tp,1,REASON_EFFECT)
        end
    elseif op==1 then
        local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
        for tc in aux.Next(g) do
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_UPDATE_ATTACK)
            e1:SetValue(500)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD)
            tc:RegisterEffect(e1)
        end
    elseif op==2 then
        Duel.Recover(tp,1000,REASON_EFFECT)
        Duel.Recover(1-tp,1000,REASON_EFFECT)
    end
end
