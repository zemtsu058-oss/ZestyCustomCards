-- ============================================================
-- Card Name: The Journeying Three Magi
-- Passcode  : 79900019
-- Type      : Spell / Normal
-- Archetype : None
-- ============================================================
-- Effect 1  : Reveal 3 Level 4 Spellcasters with different Attributes from Deck:
--             Opponent adds 1 to hand, controller sends 1 to GY, shuffles last to Deck (HOPT).
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- Activate
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_TOGRAVE+CATEGORY_TODECK)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

-- ============================================================
-- Eligibility Check & Target
-- ============================================================
function s.magifilter(c)
    return c:IsLevel(4) and c:IsRace(RACE_SPELLCASTER) and c:IsMonster()
end

function s.check_magi(g)
    local attrs=0
    for c in aux.Next(g) do
        attrs=attrs|c:GetAttribute()
    end
    local count=0
    while attrs>0 do
        if attrs&1~=0 then count=count+1 end
        attrs=attrs>>1
    end
    return count>=3
end

function s.magifilter_diff(c,attr1)
    return s.magifilter(c) and c:GetAttribute()~=attr1
end

function s.magifilter_diff2(c,attr_mask)
    return s.magifilter(c) and (c:GetAttribute()&attr_mask)==0
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    local g=Duel.GetMatchingGroup(s.magifilter,tp,LOCATION_DECK,0,nil)
    if chk==0 then return s.check_magi(g) end
    
    -- Select 3 cards with different attributes sequentially
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
    local g1=Duel.SelectMatchingCard(tp,s.magifilter,tp,LOCATION_DECK,0,1,1,nil)
    local tc1=g1:GetFirst()
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
    local g2=Duel.SelectMatchingCard(tp,s.magifilter_diff,tp,LOCATION_DECK,0,1,1,tc1,tc1:GetAttribute())
    local tc2=g2:GetFirst()
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
    local g3=Duel.SelectMatchingCard(tp,s.magifilter_diff2,tp,LOCATION_DECK,0,1,1,Group.FromCards(tc1,tc2),tc1:GetAttribute()|tc2:GetAttribute())
    local tc3=g3:GetFirst()
    
    local sg=Group.FromCards(tc1,tc2,tc3)
    Duel.ConfirmCards(1-tp,sg)
    Duel.ShuffleDeck(tp)
    
    e:SetLabelObject(sg)
    sg:KeepAlive()
    
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
    Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_DECK)
end

-- ============================================================
-- Operation
-- ============================================================
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local sg=e:GetLabelObject()
    if not sg then return end
    
    -- Filter to keep only cards that are still in Deck
    local g=sg:Filter(Card.IsLocation,nil,LOCATION_DECK)
    if #g<3 then
        sg:DeleteGroup()
        return
    end
    
    -- Opponent chooses 1 to add to tp's hand
    Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_ATOHAND)
    local opg=g:Select(1-tp,1,1,nil)
    local tc1=opg:GetFirst()
    if tc1 then
        Duel.SendtoHand(tc1,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,tc1)
        g:RemoveCard(tc1)
        
        -- tp chooses 1 of the remaining 2 to send to GY
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
        local tpg=g:Select(tp,1,1,nil)
        local tc2=tpg:GetFirst()
        if tc2 then
            Duel.SendtoGrave(tc2,REASON_EFFECT)
            g:RemoveCard(tc2)
            
            -- Shuffle the last one into the Deck
            local tc3=g:GetFirst()
            if tc3 then
                Duel.SendtoDeck(tc3,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
            end
        end
    end
    sg:DeleteGroup() -- clean up
end
