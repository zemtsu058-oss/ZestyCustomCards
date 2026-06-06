-- ============================================================
-- Card Name: Guided by the Stars
-- Passcode : 79900014
-- Type     : Spell / Quick-Play
-- Archetype: Stardust (0x43)
-- ============================================================
-- Effect 1: Synchro Summon 1 Synchro Monster by banishing
--           materials from hand, field, and/or GY. If "Stardust
--           Dragon" was used as material, the Summoned monster
--           is unaffected by opponent's card effects until the
--           end of the next turn.
-- Effect 2: Banish from GY: Search 1 Tuner and 1 "Junk" monster,
--           or Special Summon 1 "Stardust Dragon" from GY/banish
--           (redirect banish on leave).
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Synchro Summon from Hand/Field/GY by banishing materials
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.target)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — Banish from GY to search Tuner+Junk or SS Stardust Dragon
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,id+1)
    e2:SetCost(aux.bfgcost)
    e2:SetTarget(s.gytg)
    e2:SetOperation(s.gyop)
    c:RegisterEffect(e2)
end

s.listed_names={44508094}
s.listed_series={0x43}

-- ============================================================
-- Effect 1: Filter — Tuners that can be banished
-- ============================================================
function s.tunerfilter(c)
    return c:IsType(TYPE_TUNER) and c:IsAbleToRemove()
end

-- ============================================================
-- Effect 1: Filter — Non-tuners with Level that can be banished
-- ============================================================
function s.ntfilter(c)
    return not c:IsType(TYPE_TUNER) and c:IsAbleToRemove() and c:HasLevel()
end

-- ============================================================
-- Effect 1: Filter — Synchro monsters in Extra Deck
-- ============================================================
function s.synfilter(c,e,tp)
    return c:IsType(TYPE_SYNCHRO) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,false)
        and s.check_materials(c,tp)
end

-- ============================================================
-- Effect 1: Material Check Helper
-- ============================================================
function s.check_materials(sc,tp)
    local lv=sc:GetLevel()
    local tg=Duel.GetMatchingGroup(s.tunerfilter,tp,LOCATION_HAND+LOCATION_ONFIELD+LOCATION_GRAVE,0,nil)
    local ntg=Duel.GetMatchingGroup(s.ntfilter,tp,LOCATION_HAND+LOCATION_ONFIELD+LOCATION_GRAVE,0,nil)
    return tg:IsExists(s.tuner_check,1,nil,ntg,lv)
end

-- ============================================================
-- Effect 1: Tuner Check Helper
-- ============================================================
function s.tuner_check(t,ntg,lv)
    local target_sum=lv-t:GetLevel()
    if target_sum<=0 then return false end
    local ntg_filtered=ntg:Clone()
    ntg_filtered:RemoveCard(t)
    return ntg_filtered:CheckWithSumEqual(Card.GetLevel,target_sum,1,99)
end

-- ============================================================
-- Effect 1: Target — Check if Extra Synchro is possible
-- ============================================================
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCountFromEx(tp,tp,nil,TYPE_SYNCHRO)>0
            and Duel.IsExistingMatchingCard(s.synfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

-- ============================================================
-- Effect 1: Operation — Banish materials & Synchro Summon
-- ============================================================
function s.operation(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCountFromEx(tp,tp,nil,TYPE_SYNCHRO)<=0 then return end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local sg=Duel.SelectMatchingCard(tp,s.synfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
    local sc=sg:GetFirst()
    if not sc then return end
    
    local lv=sc:GetLevel()
    local tg=Duel.GetMatchingGroup(s.tunerfilter,tp,LOCATION_HAND+LOCATION_ONFIELD+LOCATION_GRAVE,0,nil)
    local ntg=Duel.GetMatchingGroup(s.ntfilter,tp,LOCATION_HAND+LOCATION_ONFIELD+LOCATION_GRAVE,0,nil)
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local tuner=tg:FilterSelect(tp,s.tuner_check,1,1,nil,ntg,lv):GetFirst()
    if not tuner then return end
    
    local target_sum=lv-tuner:GetLevel()
    local ntg_filtered=ntg:Clone()
    ntg_filtered:RemoveCard(tuner)
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local mat=ntg_filtered:SelectWithSumEqual(tp,Card.GetLevel,target_sum,1,99)
    mat:AddCard(tuner)
    
    local has_stardust=mat:IsExists(Card.IsCode,1,nil,44508094)
    
    if Duel.Remove(mat,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL+REASON_SYNCHRO)>0 then
        sc:SetMaterial(mat)
        if Duel.SpecialSummon(sc,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)>0 then
            sc:CompleteProcedure()
            
            if has_stardust then
                local e1=Effect.CreateEffect(e:GetHandler())
                e1:SetType(EFFECT_TYPE_SINGLE)
                e1:SetCode(EFFECT_IMMUNE_EFFECT)
                e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
                e1:SetRange(LOCATION_MZONE)
                e1:SetValue(s.efilter)
                e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,2)
                sc:RegisterEffect(e1)
            end
        end
    end
end

-- ============================================================
-- Effect 1: Protection Filter — Unaffected by opponent's effects
-- ============================================================
function s.efilter(e,re)
    return e:GetOwnerPlayer()~=re:GetOwnerPlayer()
end

-- ============================================================
-- Effect 2: Filter — Valid "Junk" monsters in Deck
-- ============================================================
function s.junkfilter(c)
    return c:IsSetCard(0x43) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

-- ============================================================
-- Effect 2: Filter — Valid Tuners in Deck
-- ============================================================
function s.tunerfilter_search(c)
    return c:IsType(TYPE_TUNER) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

-- ============================================================
-- Effect 2: Filter — Valid Stardust Dragon to Summon
-- ============================================================
function s.stardustfilter(c,e,tp)
    return c:IsCode(44508094) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- ============================================================
-- Effect 2: Target — Choose search or Special Summon
-- ============================================================
function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
    local opt1=Duel.IsExistingMatchingCard(s.junkfilter,tp,LOCATION_DECK,0,1,nil)
        and Duel.IsExistingMatchingCard(s.tunerfilter_search,tp,LOCATION_DECK,0,1,nil)
    local opt2=Duel.IsExistingMatchingCard(s.stardustfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp)
    
    if chk==0 then return opt1 or opt2 end
    
    local op=0
    if opt1 and opt2 then
        op=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))
    elseif opt1 then
        op=0
    else
        op=1
    end
    
    e:SetLabel(op)
    if op==0 then
        e:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
        Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_DECK)
    else
        e:SetCategory(CATEGORY_SPECIAL_SUMMON)
        Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
    end
end

-- ============================================================
-- Effect 2: Operation — Perform search or Special Summon
-- ============================================================
function s.gyop(e,tp,eg,ep,ev,re,r,rp)
    local op=e:GetLabel()
    if op==0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local g1=Duel.SelectMatchingCard(tp,s.tunerfilter_search,tp,LOCATION_DECK,0,1,1,nil)
        if #g1==0 then return end
        
        local junk_g=Duel.GetMatchingGroup(s.junkfilter,tp,LOCATION_DECK,0,g1:GetFirst())
        if #junk_g==0 then return end
        
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local g2=junk_g:Select(tp,1,1,nil)
        g1:Merge(g2)
        
        Duel.SendtoHand(g1,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g1)
    else
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local g=Duel.SelectMatchingCard(tp,s.stardustfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,e,tp)
        local tc=g:GetFirst()
        if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
            e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
            e1:SetValue(LOCATION_REMOVED)
            e1:SetReset(RESET_EVENT+RESETS_REDIRECT)
            tc:RegisterEffect(e1)
        end
    end
end
