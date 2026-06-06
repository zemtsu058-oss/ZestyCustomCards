-- ============================================================
-- Card Name: Dragon Restday
-- Passcode : 79900011
-- Type     : Spell / Normal
-- Archetype: Generic (None)
-- ============================================================
-- Effect 1: Send 1 Dragon monster from Deck to GY, or Set 1
--           Dragon monster from Deck face-down if only opponent
--           controls a monster (cannot activate monster effects
--           of same name this turn).
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Send 1 Dragon to GY or Set 1 Dragon
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.target)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)
end

-- ============================================================
-- Effect 1: Filter — Valid Dragon monsters in Deck
-- ============================================================
function s.tgfilter(c,e,tp,cond)
    if not (c:IsRace(RACE_DRAGON) and c:IsType(TYPE_MONSTER)) then return false end
    local to_gy=c:IsAbleToGrave()
    local to_field=cond and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEDOWN_DEFENSE)
    return to_gy or to_field
end

-- ============================================================
-- Effect 1: Target — Check if send or Set is possible
-- ============================================================
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    local cond=Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
        and Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)>0
    if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil,e,tp,cond) end
end

-- ============================================================
-- Effect 1: Operation — Perform send or Special Summon Set
-- ============================================================
function s.operation(e,tp,eg,ep,ev,re,r,rp)
    local cond=Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
        and Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)>0
    
    local g=Duel.GetMatchingGroup(s.tgfilter,tp,LOCATION_DECK,0,nil,e,tp,cond)
    if #g==0 then return end
    
    local can_set=cond and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and g:IsExists(Card.IsCanBeSpecialSummoned,1,nil,e,0,tp,false,false,POS_FACEDOWN_DEFENSE)
    
    local opt=0
    if can_set then
        opt=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))
    else
        opt=0
    end
    
    if opt==0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
        local sg=Duel.SelectMatchingCard(tp,function(c) return c:IsRace(RACE_DRAGON) and c:IsAbleToGrave() end,tp,LOCATION_DECK,0,1,1,nil)
        if #sg>0 then
            Duel.SendtoGrave(sg,REASON_EFFECT)
        end
    else
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local sg=Duel.SelectMatchingCard(tp,function(c) return c:IsRace(RACE_DRAGON) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEDOWN_DEFENSE) end,tp,LOCATION_DECK,0,1,1,nil)
        local tc=sg:GetFirst()
        if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEDOWN_DEFENSE)>0 then
            Duel.ConfirmCards(1-tp,tc)
            
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_FIELD)
            e1:SetCode(EFFECT_CANNOT_ACTIVATE)
            e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
            e1:SetTargetRange(1,0)
            e1:SetValue(s.aclimit)
            e1:SetLabel(tc:GetCode())
            e1:SetReset(RESET_PHASE+PHASE_END)
            Duel.RegisterEffect(e1,tp)
        end
    end
end

-- ============================================================
-- Effect 1: Activation Limit — Prevent activating monster effects of same name
-- ============================================================
function s.aclimit(e,re,tp)
    local code=e:GetLabel()
    return re:GetHandler():IsCode(code) and re:IsActiveType(TYPE_MONSTER)
end
