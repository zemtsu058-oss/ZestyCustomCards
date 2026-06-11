-- ============================================================
-- Card Name: Blue Eye Flute of Summoning Dragon
-- Passcode  : 22100001
-- Type      : Spell / Quick-Play
-- Archetype : Blue_Eye (0xdd)
-- ============================================================
-- Effect 1  : Special Summon 1 LIGHT Warrior or Spellcaster from Hand/Deck,
--             then if it mentions BEWD, SS up to 2 BEWD,
--             otherwise negate their effects.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Quick-Play Spell activation
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetTarget(s.target)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)
end

-- ============================================================
-- Filters & Conditions
-- ============================================================
function s.spfilter(c,e,tp)
    return c:IsAttribute(ATTRIBUTE_LIGHT) and (c:IsRace(RACE_WARRIOR) or c:IsRace(RACE_SPELLCASTER))
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.befilter(c,e,tp)
    return c:IsCode(89631139) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- ============================================================
-- Target Function
-- ============================================================
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        local loc1=Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        local loc2=Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
        local g1=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,nil,e,tp)
        local g2=Duel.GetMatchingGroup(s.spfilter,1-tp,LOCATION_HAND+LOCATION_DECK,0,nil,e,1-tp)
        return (loc1 and #g1>0) or (loc2 and #g2>0)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,PLAYER_ALL,LOCATION_HAND+LOCATION_DECK)
end

-- ============================================================
-- Operation Function
-- ============================================================
function s.operation(e,tp,eg,ep,ev,re,r,rp)
    local loc1=Duel.GetLocationCount(tp,LOCATION_MZONE)>0
    local loc2=Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
    
    local g1=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,nil,e,tp)
    local sg1=Group.CreateGroup()
    local is_deck1=false
    if loc1 and #g1>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        sg1=g1:Select(tp,1,1,nil)
        local tc1=sg1:GetFirst()
        if tc1 and tc1:IsLocation(LOCATION_DECK) then
            is_deck1=true
        end
    end

    local g2=Duel.GetMatchingGroup(s.spfilter,1-tp,LOCATION_HAND+LOCATION_DECK,0,nil,e,1-tp)
    local sg2=Group.CreateGroup()
    local is_deck2=false
    if loc2 and #g2>0 and Duel.SelectYesNo(1-tp,aux.Stringid(id,0)) then
        Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_SPSUMMON)
        sg2=g2:Select(1-tp,1,1,nil)
        local tc2=sg2:GetFirst()
        if tc2 and tc2:IsLocation(LOCATION_DECK) then
            is_deck2=true
        end
    end

    local tg=Group.CreateGroup()
    tg:Merge(sg1)
    tg:Merge(sg2)

    if #tg==0 then return end

    -- Perform Special Summon Step
    local tc=tg:GetFirst()
    while tc do
        local p=tc:GetControler()
        Duel.SpecialSummonStep(tc,0,p,p,false,false,POS_FACEUP)
        tc=tg:GetNext()
    end
    Duel.SpecialSummonComplete()

    if is_deck1 then Duel.ShuffleDeck(tp) end
    if is_deck2 then Duel.ShuffleDeck(1-tp) end

    -- Check activator's summoned monster
    local tc1=sg1:GetFirst()
    local mentions_bewd=false
    if tc1 and tc1:IsLocation(LOCATION_MZONE) and tc1:IsFaceup() and tc1:ListsCode(89631139) then
        mentions_bewd=true
    end

    if mentions_bewd then
        -- Special Summon up to 2 Blue-Eyes White Dragons from hand or Deck
        local bg=Duel.GetMatchingGroup(s.befilter,tp,LOCATION_HAND+LOCATION_DECK,0,nil,e,tp)
        local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
        if #bg>0 and ft>0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
            local max_summon=math.min(2,ft)
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
            local sgb=bg:Select(tp,1,max_summon,nil)
            if #sgb>0 then
                local is_deck_be=false
                local tc_be=sgb:GetFirst()
                while tc_be do
                    if tc_be:IsLocation(LOCATION_DECK) then
                        is_deck_be=true
                    end
                    Duel.SpecialSummonStep(tc_be,0,tp,tp,false,false,POS_FACEUP)
                    tc_be=sgb:GetNext()
                end
                Duel.SpecialSummonComplete()
                if is_deck_be then Duel.ShuffleDeck(tp) end
            end
        end
    else
        -- Negate the effects of the summoned monsters
        local nc=tg:GetFirst()
        while nc do
            if nc:IsLocation(LOCATION_MZONE) and nc:IsFaceup() then
                local e1=Effect.CreateEffect(e:GetHandler())
                e1:SetType(EFFECT_TYPE_SINGLE)
                e1:SetCode(EFFECT_DISABLE)
                e1:SetReset(RESET_EVENT+RESETS_STANDARD)
                nc:RegisterEffect(e1)
                local e2=Effect.CreateEffect(e:GetHandler())
                e2:SetType(EFFECT_TYPE_SINGLE)
                e2:SetCode(EFFECT_DISABLE_EFFECT)
                e2:SetReset(RESET_EVENT+RESETS_STANDARD)
                nc:RegisterEffect(e2)
            end
            nc=tg:GetNext()
        end
    end
end
