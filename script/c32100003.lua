-- ============================================================
-- Card Name: Rikka Blizzard
-- Passcode  : 32100003
-- Type      : Spell / Quick-Play
-- Archetype : Rikka (0x141)
-- ============================================================
-- Effect 1  : Reveal 5 Rikka monsters: Tribute all opponent monsters (HOPT).
-- Effect 2  : Reveal 10 Rikka cards: Tribute all opponent cards, SS Rikka monsters from revealed ones (HOPT).
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- Activate
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_RELEASE+CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

-- ============================================================
-- Option Check & Target
-- ============================================================
function s.filter_mon(c)
    return c:IsSetCard(0x141) and c:IsMonster()
end

function s.filter_all(c)
    return c:IsSetCard(0x141)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    local g5=Duel.GetMatchingGroup(s.filter_mon,tp,LOCATION_DECK+LOCATION_HAND+LOCATION_GRAVE,0,nil)
    local g10=Duel.GetMatchingGroup(s.filter_all,tp,LOCATION_DECK+LOCATION_HAND+LOCATION_GRAVE,0,nil)
    
    local opt1=#g5>=5
    local opt2=#g10>=10
    
    if chk==0 then return opt1 or opt2 end
    
    local op=0
    if opt1 and opt2 then
        op=Duel.SelectOption(tp,aux.Stringid(id,0),aux.Stringid(id,1))
    elseif opt1 then
        op=Duel.SelectOption(tp,aux.Stringid(id,0))
    else
        op=Duel.SelectOption(tp,aux.Stringid(id,1))+1
    end
    e:SetLabel(op)
    
    if op==0 then
        -- Select and reveal 5 monsters from Deck/Hand/GY
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
        local sg=g5:Select(tp,5,5,nil)
        Duel.ConfirmCards(1-tp,sg)
        e:SetLabelObject(sg)
        sg:KeepAlive()
        
        Duel.SetOperationInfo(0,CATEGORY_RELEASE,nil,0,1-tp,LOCATION_MZONE+LOCATION_HAND)
    else
        -- Select and reveal 10 cards from Deck/Hand/GY
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
        local sg=g10:Select(tp,10,10,nil)
        Duel.ConfirmCards(1-tp,sg)
        e:SetLabelObject(sg)
        sg:KeepAlive()
        
        Duel.SetOperationInfo(0,CATEGORY_RELEASE,nil,0,1-tp,LOCATION_ONFIELD+LOCATION_HAND)
        Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,0,tp,LOCATION_DECK+LOCATION_HAND+LOCATION_GRAVE)
    end
end

-- ============================================================
-- Operation
-- ============================================================
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local op=e:GetLabel()
    local sg=e:GetLabelObject()
    if not sg then return end
    
    if op==0 then
        -- (1) Tribute opponent monsters
        local tg=Duel.GetMatchingGroup(Card.IsMonster,tp,0,LOCATION_MZONE+LOCATION_HAND,nil)
        if #tg>0 then
            Duel.Release(tg,REASON_EFFECT)
        end
    else
        -- (2) Tribute all opponent cards
        local tg=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD+LOCATION_HAND,nil)
        if #tg>0 then
            Duel.Release(tg,REASON_EFFECT)
        end
        
        -- Special Summon up to revealed Rikka monsters
        local spg=sg:Filter(Card.IsMonster,nil)
        -- Keep only those that are still in valid locations (Hand, GY, Deck)
        local valid_spg=spg:Filter(function(c) return c:IsLocation(LOCATION_HAND+LOCATION_GRAVE+LOCATION_DECK) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end, nil)
        
        local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
        local max_ss=math.min(ft,#valid_spg)
        if max_ss>0 and #valid_spg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
            Duel.BreakEffect()
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
            local ssg=valid_spg:Select(tp,0,max_ss,nil)
            if #ssg>0 then
                Duel.SpecialSummon(ssg,0,tp,tp,false,false,POS_FACEUP)
            end
        end
    end
    sg:DeleteGroup() -- clean up
end
