-- ============================================================
-- Card Name: Laundry Fusion
-- Passcode : 30700002
-- Type     : Spell / Normal
-- Archetype: None
-- ============================================================
-- Effect 1: Send the top 6 cards of your Deck to the GY, then
--           you can Fusion Summon 1 monster from your Extra Deck,
--           by banishing its materials from your field or GY.
--           You cannot activate card effects in your GY the turn
--           you activate this card.
--           You can only activate 1 "Laundry Fusion" per turn.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 - Normal Spell activation: Mill 6, then Fusion Summon
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCondition(s.condition)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)

    -- GY activation tracker (registered once globally per duel)
    if not s.global_check then
        s.global_check=true
        local ge1=Effect.CreateEffect(c)
        ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        ge1:SetCode(EVENT_CHAINING)
        ge1:SetOperation(s.checkop)
        Duel.RegisterEffect(ge1,0)
    end
end

-- ============================================================
-- GY activation tracker logic
-- ============================================================
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
    if re:GetActivateLocation()==LOCATION_GRAVE then
        Duel.RegisterFlagEffect(rp,id,RESET_PHASE+PHASE_END,0,1)
    end
end

-- ============================================================
-- Effect 1: Condition - Cannot activate if player already activated GY effects this turn
-- ============================================================
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetFlagEffect(tp,id)==0
end

-- ============================================================
-- Effect 1: Target - Mill 6 cards
-- ============================================================
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsPlayerCanDiscardDeck(tp,6) end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,6,tp,LOCATION_DECK)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_ONFIELD+LOCATION_GRAVE)
end

-- ============================================================
-- Effect 1: Filters for Fusion Summon
-- ============================================================
function s.matfilter(c)
    return c:IsType(TYPE_MONSTER) and c:IsCanBeFusionMaterial() and c:IsAbleToRemove()
end

function s.fusfilter(c,e,tp,mg)
    return c:IsType(TYPE_FUSION) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
        and c:CheckFusionMaterial(mg,nil,tp)
end

-- ============================================================
-- Effect 1: Operation - Register lock, mill 6, then optional Fusion Summon
-- ============================================================
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    
    -- Register lock: Cannot activate GY effects for the rest of this turn
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
    e1:SetCode(EFFECT_CANNOT_ACTIVATE)
    e1:SetTargetRange(1,0)
    e1:SetValue(s.aclimit)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
    
    -- Discard 6 cards from the Deck
    if Duel.DiscardDeck(tp,6,REASON_EFFECT)<=0 then return end
    
    -- Check for Spirit Elimination
    local location = LOCATION_ONFIELD
    if not Duel.IsPlayerAffectedByEffect(tp,CARD_SPIRIT_ELIMINATION) then
        location = location + LOCATION_GRAVE
    end
    
    -- Gather materials and check if we can Fusion Summon
    local mg=Duel.GetMatchingGroup(s.matfilter,tp,location,0,nil)
    local sg=Duel.GetMatchingGroup(s.fusfilter,tp,LOCATION_EXTRA,0,nil,e,tp,mg)
    
    if #sg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local tg=sg:Select(tp,1,1,nil)
        local tc=tg:GetFirst()
        if tc then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
            local mat=Duel.SelectFusionMaterial(tp,tc,mg,nil,tp)
            if #mat>0 then
                tc:SetMaterial(mat)
                Duel.Remove(mat,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
                Duel.BreakEffect()
                if Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)>0 then
                    tc:CompleteProcedure()
                end
            end
        end
    end
end

function s.aclimit(e,re,tp)
    return re:GetActivateLocation()==LOCATION_GRAVE
end
