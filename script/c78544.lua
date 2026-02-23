-- Witchcrafter in Profusion
local s,id=GetID()
function s.initial_effect(c)

    --------------------------------------------------
    -- EFFECT 1: Fusion Summon
    --------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.fustg)
    e1:SetOperation(s.fusop)
    c:RegisterEffect(e1)

    --------------------------------------------------
    -- EFFECT 2: GY search same-name Spell
    --------------------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_DISCARD)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
    e2:SetCountLimit(1,id+100)
    e2:SetCondition(s.thcon)
    e2:SetCost(aux.bfgcost)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
end

--------------------------------------------------
-- FUSION SECTION
--------------------------------------------------

function s.fusfilter(c,e,tp,mg,chkf)
    return c:IsSetCard(0x128)
        and c:IsType(TYPE_FUSION)
        and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
        and c:CheckFusionMaterial(mg,nil,chkf)
end

function s.spellmat(c)
    return c:IsType(TYPE_SPELL) and c:IsAbleToGrave()
end

-- TARGET
function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        local mg=Duel.GetFusionMaterial(tp)
        local sg=Duel.GetMatchingGroup(s.spellmat,tp,LOCATION_HAND,0,nil)
        if #sg>0 then
            mg:Merge(sg)
        end
        return Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg,0)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

-- OPERATION
function s.fusop(e,tp,eg,ep,ev,re,r,rp)

    local mg=Duel.GetFusionMaterial(tp)
    local sg=Duel.GetMatchingGroup(s.spellmat,tp,LOCATION_HAND,0,nil)

    -- Biến Spell thành Monster tạm thời
    if #sg>0 then
        for sc in aux.Next(sg) do
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_ADD_TYPE)
            e1:SetValue(TYPE_MONSTER)
            e1:SetReset(RESET_CHAIN)
            sc:RegisterEffect(e1)

            local e2=Effect.CreateEffect(e:GetHandler())
            e2:SetType(EFFECT_TYPE_SINGLE)
            e2:SetCode(EFFECT_CHANGE_RACE)
            e2:SetValue(RACE_SPELLCASTER)
            e2:SetReset(RESET_CHAIN)
            sc:RegisterEffect(e2)

            local e3=Effect.CreateEffect(e:GetHandler())
            e3:SetType(EFFECT_TYPE_SINGLE)
            e3:SetCode(EFFECT_CHANGE_ATTRIBUTE)
            e3:SetValue(ATTRIBUTE_WIND)
            e3:SetReset(RESET_CHAIN)
            sc:RegisterEffect(e3)
        end

        mg:Merge(sg)
    end

    -- Chọn Fusion trước
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local tg=Duel.SelectMatchingCard(tp,s.fusfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mg,0)
    local tc=tg:GetFirst()
    if not tc then return end

    -- Chọn material (Spell tự hiện nếu hợp lệ)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
    local mat=Duel.SelectFusionMaterial(tp,tc,mg,nil,0)
    if not mat then return end

    -- Giới hạn tối đa 1 Spell
    if mat:FilterCount(Card.IsType,nil,TYPE_SPELL)>1 then return end

    tc:SetMaterial(mat)
    Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
    Duel.BreakEffect()

    Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
    tc:CompleteProcedure()
end

--------------------------------------------------
-- SEARCH SECTION
--------------------------------------------------

function s.cfilter(c,tp)
    return c:IsType(TYPE_SPELL) and c:IsControler(tp)
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.cfilter,1,nil,tp)
end

function s.tgfilter(c)
    return c:IsType(TYPE_SPELL)
        and (c:IsLocation(LOCATION_GRAVE)
        or (c:IsLocation(LOCATION_REMOVED) and c:IsFaceup()))
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then
        return chkc:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED)
            and s.tgfilter(chkc)
    end
    if chk==0 then
        return Duel.IsExistingTarget(s.tgfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    Duel.SelectTarget(tp,s.tgfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local g=Duel.SelectMatchingCard(tp,Card.IsCode,tp,LOCATION_DECK,0,1,1,nil,tc:GetCode())
        if #g>0 then
            Duel.SendtoHand(g,nil,REASON_EFFECT)
            Duel.ConfirmCards(1-tp,g)
        end
    end
end