-- ============================================================
-- Card Name: Possessed Bond
-- Passcode  : 79900018
-- Type      : Spell / Normal
-- Archetype : Possessed (0xc0)
-- ============================================================
-- Effect 1  : Reveal 1 Level 5 "Possessed" monster from hand/Deck:
--             Add 1 "Charmer" or "Familiar-Possessed" and 1 Spellcaster with same Attribute from Deck,
--             then discard 1 card (HOPT).
-- Effect 2  : GY: Banish self + reveal 2 monsters with same Attribute in hand:
--             Special Summon 1, then can shuffle 1 Level 5+ from hand to Deck and draw 1 (HOPT).
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- Activate: Search 2 cards and discard 1
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_HANDES)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id)
    e1:SetCost(s.cost1)
    e1:SetTarget(s.tg1)
    e1:SetOperation(s.op1)
    c:RegisterEffect(e1)

    -- GY Effect: Banish to SS and Draw
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK+CATEGORY_DRAW)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,id+100)
    e2:SetCost(s.gycost)
    e2:SetTarget(s.gytg)
    e2:SetOperation(s.gyop)
    c:RegisterEffect(e2)
end

-- ============================================================
-- Effect 1 Logic
-- ============================================================
function s.revealfilter(c,tp)
    return c:IsLevel(5) and c:IsSetCard(0xc0) and c:IsMonster() and not c:IsPublic()
        and Duel.IsExistingMatchingCard(s.addfilter1,tp,LOCATION_DECK,0,1,nil,c:GetAttribute())
end

function s.addfilter1(c,attr)
    return (c:IsSetCard(0xbf) or c:IsSetCard(0x10c0)) and c:IsMonster() and c:IsAttribute(attr) and c:IsAbleToHand()
        and Duel.IsExistingMatchingCard(s.addfilter2,c:GetControler(),LOCATION_DECK,0,1,c,attr)
end

function s.addfilter2(c,attr)
    return c:IsRace(RACE_SPELLCASTER) and c:IsAttribute(attr) and c:IsAbleToHand()
end

function s.cost1(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.revealfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,tp) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
    local g=Duel.SelectMatchingCard(tp,s.revealfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,tp)
    local tc=g:GetFirst()
    Duel.ConfirmCards(1-tp,g)
    e:SetLabel(tc:GetAttribute())
    if tc:IsLocation(LOCATION_DECK) then
        Duel.ShuffleDeck(tp)
    end
end

function s.tg1(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_DECK)
    Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,tp,1)
end

function s.op1(e,tp,eg,ep,ev,re,r,rp)
    local attr=e:GetLabel()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g1=Duel.SelectMatchingCard(tp,s.addfilter1,tp,LOCATION_DECK,0,1,1,nil,attr)
    if #g1==0 then return end
    local tc1=g1:GetFirst()
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g2=Duel.SelectMatchingCard(tp,s.addfilter2,tp,LOCATION_DECK,0,1,1,tc1,attr)
    if #g2==0 then return end
    local tc2=g2:GetFirst()
    
    local sg=Group.FromCards(tc1,tc2)
    if Duel.SendtoHand(sg,nil,REASON_EFFECT)==2 then
        Duel.ConfirmCards(1-tp,sg)
        Duel.ShuffleDeck(tp)
        Duel.ShuffleHand(tp)
        Duel.BreakEffect()
        Duel.DiscardHand(tp,nil,1,1,REASON_EFFECT+REASON_DISCARD)
    end
end

-- ============================================================
-- Effect 2 Logic (GY)
-- ============================================================
function s.check_pairs(hg,e,tp)
    for c1 in aux.Next(hg) do
        for c2 in aux.Next(hg) do
            if c1~=c2 and c1:GetAttribute()==c2:GetAttribute()
                and (c1:IsCanBeSpecialSummoned(e,0,tp,false,false)
                or c2:IsCanBeSpecialSummoned(e,0,tp,false,false)) then
                return true
            end
        end
    end
    return false
end

function s.rev_filter1(c,hg,e,tp)
    return hg:IsExists(s.rev_filter2,1,c,c:GetAttribute(),c,e,tp)
end

function s.rev_filter2(c,attr,tc1,e,tp)
    return c:GetAttribute()==attr
        and (c:IsCanBeSpecialSummoned(e,0,tp,false,false)
        or tc1:IsCanBeSpecialSummoned(e,0,tp,false,false))
end

function s.gycost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    local hg=Duel.GetMatchingGroup(Card.IsMonster,tp,LOCATION_HAND,0,nil)
    if chk==0 then
        return c:IsAbleToRemoveAsCost() and s.check_pairs(hg,e,tp)
    end
    Duel.Remove(c,POS_FACEUP,REASON_COST)
    
    -- Select first card to reveal
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
    local g1=hg:Filter(s.rev_filter1,nil,hg,e,tp):Select(tp,1,1,nil)
    local tc1=g1:GetFirst()
    
    -- Select second card to reveal
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
    local g2=hg:Filter(s.rev_filter2,tc1,tc1:GetAttribute(),tc1,e,tp):Select(tp,1,1,nil)
    local tc2=g2:GetFirst()
    
    local sg=Group.FromCards(tc1,tc2)
    Duel.ConfirmCards(1-tp,sg)
    e:SetLabelObject(sg)
    sg:KeepAlive()
end

function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    local sg=e:GetLabelObject()
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,sg,1,tp,LOCATION_HAND)
end

function s.spfilter_bond(c,e,tp)
    return c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.shuffilter(c)
    return c:IsLevelAbove(5) and c:IsAbleToDeck()
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
    local sg=e:GetLabelObject()
    if not sg then return end
    local g=sg:Filter(s.spfilter_bond,nil,e,tp):Filter(Card.IsLocation,nil,LOCATION_HAND)
    if #g==0 then return end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local sc=g:Select(tp,1,1,nil):GetFirst()
    if sc and Duel.SpecialSummon(sc,0,tp,tp,false,false,POS_FACEUP)>0 then
        -- Optional: Shuffle Level 5+ to draw 1
        local hand_mon=Duel.GetMatchingGroup(s.shuffilter,tp,LOCATION_HAND,0,nil)
        if #hand_mon>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
            Duel.BreakEffect()
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
            local sh=hand_mon:Select(tp,1,1,nil)
            if Duel.SendtoDeck(sh,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
                Duel.Draw(tp,1,REASON_EFFECT)
            end
        end
    end
    sg:DeleteGroup() -- clean up
end
