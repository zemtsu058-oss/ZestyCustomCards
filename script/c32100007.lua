-- ============================================================
-- Card Name: Rikka Invitation
-- Passcode  : 32100007
-- Type      : Spell / Normal
-- Archetype : Rikka (0x141)
-- ============================================================
-- Effect 1  : If you control no monsters: SS 1 Rikka monster from Deck, then you can Tribute 1 monster on your field to SS 2 Rikka monsters from Deck (HOPT).
-- Effect 2  : If a Plant monster you control would be destroyed, banish this card from GY instead.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Special Summon from Deck
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_RELEASE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — GY protection
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EFFECT_DESTROY_REPLACE)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetTarget(s.reptg)
    e2:SetValue(s.repval)
    e2:SetOperation(s.repop)
    c:RegisterEffect(e2)
end

-- ============================================================
-- Effect 1: Filter & target
-- ============================================================
function s.rikka_spfilter(c,e,tp)
    return c:IsSetCard(0x141) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        if Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)>0 then return false end
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(s.rikka_spfilter,tp,LOCATION_DECK,0,1,nil,e,tp)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

-- ============================================================
-- Effect 1: Operation
-- ============================================================
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    -- Restriction: plant monsters only
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
    e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e1:SetTargetRange(1,0)
    e1:SetTarget(s.splimit)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)

    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.rikka_spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
    if #g>0 and Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)>0 then
        local rg=Duel.GetMatchingGroup(Card.IsReleasableByEffect,tp,LOCATION_MZONE,0,nil)
        local sp_g=Duel.GetMatchingGroup(s.rikka_spfilter,tp,LOCATION_DECK,0,nil,e,tp)

        local can_tribute_and_summon = false
        if #sp_g>=2 and #rg>0 and not Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then
            local tc=rg:GetFirst()
            while tc do
                local zone_count = Duel.GetLocationCount(tp,LOCATION_MZONE)
                if tc:IsLocation(LOCATION_MZONE) and tc:GetSequence()<5 then
                    zone_count = zone_count + 1
                end
                if zone_count>=2 then
                    can_tribute_and_summon = true
                    break
                end
                tc=rg:GetNext()
            end
        end

        if can_tribute_and_summon and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
            Duel.BreakEffect()
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
            local sg=rg:Select(tp,1,1,nil)
            if #sg>0 and Duel.Release(sg,REASON_EFFECT)>0 then
                if Duel.GetLocationCount(tp,LOCATION_MZONE)>=2 then
                    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
                    local sg2=Duel.SelectMatchingCard(tp,s.rikka_spfilter,tp,LOCATION_DECK,0,2,2,nil,e,tp)
                    if #sg2==2 then
                        Duel.SpecialSummon(sg2,0,tp,tp,false,false,POS_FACEUP)
                    end
                end
            end
        end
    end
end

function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
    return not c:IsRace(RACE_PLANT)
end

-- ============================================================
-- Effect 2: GY Protection replacement logic
-- ============================================================
function s.repfilter(c,tp)
    return c:IsFaceup() and c:IsControler(tp) and c:IsLocation(LOCATION_MZONE)
        and c:IsRace(RACE_PLANT) and (c:IsReason(REASON_EFFECT) or c:IsReason(REASON_BATTLE))
        and not c:IsReason(REASON_REPLACE)
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsAbleToRemove() and eg:IsExists(s.repfilter,1,nil,tp) end
    return Duel.SelectEffectYesNo(tp,e:GetHandler(),96)
end

function s.repval(e,c)
    return s.repfilter(c,e:GetHandlerPlayer())
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_EFFECT)
end

