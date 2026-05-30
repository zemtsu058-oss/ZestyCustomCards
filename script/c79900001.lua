-- ============================================================
-- Card Name: Elaina, The Wandering Witch
-- Passcode : 79900001
-- Type     : Monster / Link / Effect
-- Attribute: LIGHT
-- Link     : 1  ATK: 1000
-- Race     : Spellcaster
-- Materials: 1 non-Link Spellcaster monster
-- Markers  : Bottom (0x2)
-- ============================================================
-- Effect 1 [Ignition / HOPT]: Once per turn, during your Main
--   Phase: You can discard 1 Spell Card; excavate up to 10 cards
--   from the top of your Deck, then if you excavated 2 or more
--   Spell Cards, your opponent chooses 2 among them, you can add
--   1 of chosen cards to your hand and send the other card to the GY.
--
-- Effect 2 [Trigger / End Phase / HOPT]: During the End Phase,
--   while this card is on the field or in your GY: You can return
--   this card to the Extra Deck.
--
-- Summon Limit: You can only Special Summon 1 "Elaina, The Wandering Witch" per turn.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    c:EnableReviveLimit()
    c:SetSPSummonOnce(id)

    -- Summon Procedure — Link: 1 non-Link Spellcaster monster
    Link.AddProcedure(c,s.matfilter,1,1)

    -- Effect 1 — Ignition: Discard Spell -> Excavate up to 10
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_TOGRAVE+CATEGORY_DECKDES)
    e1:SetType(EFFECT_TYPE_IGNITION) -- SetCode is implicit (EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.exc_cost)
    e1:SetTarget(s.exc_tg)
    e1:SetOperation(s.exc_op)
    c:RegisterEffect(e1)

    -- Effect 2 — Trigger/Optional: End Phase return to Extra Deck
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOEXTRA)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_PHASE+PHASE_END)
    e2:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
    e2:SetCountLimit(1,id+1)
    e2:SetTarget(s.retdtg)
    e2:SetOperation(s.retdop)
    c:RegisterEffect(e2)
end

-- Link material filter: 1 non-Link Spellcaster monster
function s.matfilter(c,lc,sumtype,tp)
    return c:IsRace(RACE_SPELLCASTER,lc,sumtype,tp) and not c:IsType(TYPE_LINK,lc,sumtype,tp)
end

-- Effect 1: Discard Spell cost
function s.costfilter(c)
    return c:IsType(TYPE_SPELL) and c:IsDiscardable()
end
function s.exc_cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_HAND,0,1,nil) end
    Duel.DiscardHand(tp,s.costfilter,1,1,REASON_COST+REASON_DISCARD)
end

-- Effect 1: Target
function s.exc_tg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>0 end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end

-- Effect 1: Operation
function s.exc_op(e,tp,eg,ep,ev,re,r,rp)
    local deck_count=Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)
    if deck_count==0 then return end
    local max_excavate=math.min(10,deck_count)

    -- Let the player choose a number from 1 to max_excavate
    local opts={}
    for i=1,max_excavate do
        table.insert(opts,i)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NUMBER)
    local ct=Duel.AnnounceNumber(tp,table.unpack(opts))

    Duel.ConfirmDecktop(tp,ct)
    local g=Duel.GetDecktopGroup(tp,ct)
    if #g==0 then return end

    -- Count how many Spell Cards were excavated
    local spells=g:Filter(Card.IsType,nil,TYPE_SPELL)

    if #spells>=2 then
        -- Opponent chooses 2 among the excavated Spell Cards
        Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_SELECT)
        local sg=spells:Select(1-tp,2,2,nil)
        if #sg==2 then
            -- You can add 1 of the chosen cards to your hand
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
            local to_hand=sg:Select(tp,1,1,nil)
            if #to_hand>0 then
                local tc=to_hand:GetFirst()
                Duel.SendtoHand(tc,nil,REASON_EFFECT)
                Duel.ConfirmCards(1-tp,tc)

                sg:RemoveCard(tc)
                local to_grave=sg:GetFirst()
                if to_grave then
                    Duel.SendtoGrave(to_grave,REASON_EFFECT)
                end

                -- Remove them from the group of remaining cards
                g:RemoveCard(tc)
                g:RemoveCard(to_grave)
            end
        end
    end

    -- Shuffle the remaining cards back into the Deck
    if #g>0 then
        Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
    end
end

-- Effect 2: Target
function s.retdtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsAbleToExtra() end
    Duel.SetOperationInfo(0,CATEGORY_TOEXTRA,e:GetHandler(),1,0,0)
end

-- Effect 2: Operation
function s.retdop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
    end
end
