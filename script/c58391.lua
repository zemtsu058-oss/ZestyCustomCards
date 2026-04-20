--Melodious Fusion (Continuous Spell)
local s,id=GetID()

function s.initial_effect(c)

    ---------------------------------------------------
    -- Activation → Fusion Summon (SHUFFLE MATERIAL)
    ---------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetTarget(s.fustg)
    e1:SetOperation(s.fusop)
    c:RegisterEffect(e1)

    ---------------------------------------------------
    -- Negate + destroy
    ---------------------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_CHAINING)
    e2:SetRange(LOCATION_SZONE)
    e2:SetCountLimit(1,id)
    e2:SetCondition(s.negcon)
    e2:SetTarget(s.negtg)
    e2:SetOperation(s.negop)
    c:RegisterEffect(e2)

end

---------------------------------------------------
-- Fusion target (SHUFFLE ONLY)
---------------------------------------------------
function s.matfilter(c)
    return c:IsSetCard(0x9b) and c:IsAbleToDeck()
        and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup())
end

function s.fusfilter(c,e,tp,mg)
    return c:IsSetCard(0x9b) and c:IsType(TYPE_FUSION)
        and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
        and c:CheckFusionMaterial(mg,nil,tp)
end

function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)

    local mg=Duel.GetMatchingGroup(s.matfilter,tp,
        LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_PZONE,0,nil)

    if chk==0 then
        return Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg)
    end

    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

---------------------------------------------------
-- Fusion operation (REAL SHUFFLE)
---------------------------------------------------
function s.fusop(e,tp,eg,ep,ev,re,r,rp)

    local mg=Duel.GetMatchingGroup(s.matfilter,tp,
        LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_PZONE,0,nil)

    if #mg==0 then return end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

    local sg=Duel.SelectMatchingCard(tp,s.fusfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mg)
    local sc=sg:GetFirst()
    if not sc then return end   -- 🔥 FIX crash nil

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
    local mat=Duel.SelectFusionMaterial(tp,sc,mg,nil,tp)

    if not mat or #mat==0 then return end -- 🔥 FIX crash

    sc:SetMaterial(mat)

    -- shuffle materials về deck / extra
    for tc in aux.Next(mat) do
        if tc:IsLocation(LOCATION_PZONE) then
            Duel.SendtoExtraP(tc,nil,REASON_EFFECT)
        else
            Duel.SendtoDeck(tc,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
        end
    end

    Duel.BreakEffect()

    Duel.SpecialSummon(sc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
    sc:CompleteProcedure()
end

---------------------------------------------------
-- Negate condition
---------------------------------------------------
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return rp~=tp and Duel.IsChainNegatable(ev)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    if re:GetHandler() then
        Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
    end
end

---------------------------------------------------
-- Negate operation + delayed punishment
---------------------------------------------------
function s.negop(e,tp,eg,ep,ev,re,r,rp)

    if Duel.NegateActivation(ev) then
        if re:GetHandler() then
            Duel.Destroy(re:GetHandler(),REASON_EFFECT)
        end

        ---------------------------------------------------
        -- Delayed punish (NEXT TIME only)
        ---------------------------------------------------
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        e1:SetCode(EVENT_CHAIN_SOLVED)
        e1:SetCondition(s.pencon)
        e1:SetOperation(s.penop)
        e1:SetReset(RESET_PHASE+PHASE_END)
        Duel.RegisterEffect(e1,tp)
    end
end

---------------------------------------------------
-- Check next Melodious effect
---------------------------------------------------
function s.pencon(e,tp,eg,ep,ev,re,r,rp)
    return rp==tp and re:IsActiveType(TYPE_MONSTER)
        and re:GetHandler()~=nil
        and re:GetHandler():IsSetCard(0x9b)
end

---------------------------------------------------
-- Apply punish AFTER effect resolves
---------------------------------------------------
function s.penop(e,tp,eg,ep,ev,re,r,rp)

    local g=Duel.GetMatchingGroup(function(c)
        return c:IsFaceup() and c:IsSetCard(0x9b) and c:IsAbleToRemove()
    end,tp,LOCATION_MZONE,0,nil)

    if #g>=3 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
        local sg=g:Select(tp,3,3,nil)
        Duel.Remove(sg,POS_FACEUP,REASON_EFFECT)
    else
        -- không đủ → negate effect vừa resolve (đúng card text)
        Duel.NegateEffect(ev)
    end

    e:Reset()
end