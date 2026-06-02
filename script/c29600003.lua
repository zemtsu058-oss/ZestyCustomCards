-- ============================================================
-- Card Name: Witchcrafter Unit Furnacer
-- Passcode : 29600003
-- Type     : Monster / Link / Effect
-- Attribute: WATER
-- Race     : Spellcaster
-- ATK      : 1500
-- Link     : 2
-- Markers  : Top, Bottom
-- Archetype: Witchcrafter (0x128)
-- Materials: 2 Spellcaster monsters, including a "Witchcrafter" monster
-- ============================================================
-- Effect 1: During your Main Phase: You can discard 1 card; draw 2 cards.
-- Effect 2: During your Main Phase: You can discard 1 card; send 1 "Witchcrafter" card from your Deck to the GY.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    c:EnableReviveLimit()

    -- Link Summon procedure
    Link.AddProcedure(c,s.matfilter,2,2,s.lcheck)

    -- ============================================================
    -- Effect 1 — Discard 1, Draw 2
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DRAW)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.cost_discard)
    e1:SetTarget(s.tg_draw)
    e1:SetOperation(s.op_draw)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — Discard 1, Send Witchcrafter from Deck to GY
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOGRAVE)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCost(s.cost_discard)
    e2:SetTarget(s.tg_send)
    e2:SetOperation(s.op_send)
    c:RegisterEffect(e2)
end

-- Link Summon materials checks
function s.matfilter(c,lc,sumtype,tp)
    return c:IsRace(RACE_SPELLCASTER,lc,sumtype,tp)
end

function s.lcheck(g,lc,sumtype,tp)
    return g:IsExists(Card.IsSetCard,1,nil,0x128,lc,sumtype,tp)
end

-- Shared Discard Cost
function s.cost_discard(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
    Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD,nil)
end

-- ============================================================
-- Effect 1: Target — Check if player can draw 2
-- ============================================================
function s.tg_draw(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsPlayerCanDraw(tp,2) end
    Duel.SetTargetPlayer(tp)
    Duel.SetTargetParam(2)
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
end

-- ============================================================
-- Effect 1: Operation — Draw 2 cards
-- ============================================================
function s.op_draw(e,tp,eg,ep,ev,re,r,rp)
    local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
    Duel.Draw(p,d,REASON_EFFECT)
end

-- ============================================================
-- Effect 2: Filter — Witchcrafter card to send
-- ============================================================
function s.filter_send(c)
    return c:IsSetCard(0x128) and c:IsAbleToGrave()
end

-- ============================================================
-- Effect 2: Target — Check if Witchcrafter card exists in Deck
-- ============================================================
function s.tg_send(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.filter_send,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end

-- ============================================================
-- Effect 2: Operation — Send from Deck to GY
-- ============================================================
function s.op_send(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.filter_send,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoGrave(g,REASON_EFFECT)
    end
end
