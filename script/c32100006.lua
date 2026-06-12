-- ============================================================
-- Card Name: Cecilia the Rikka Queen
-- Passcode  : 32100006
-- Type      : Monster / Link / Effect
-- Archetype : Rikka (0x141)
-- ============================================================
-- Effect 1  : If Link Summoned using a "Rikka" monster: Special Summon 1 "Rikka" monster from GY (HOPT).
-- Effect 2  : Tribute 1 Rikka monster from Deck and 1 from field, target 1 Rikka Xyz monster; Overlay 2 materials from GY/banished and boost ATK (HOPT).
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    c:EnableReviveLimit()

    -- Link Summon procedure: 2 Plant monsters
    Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsRace,RACE_PLANT),2,2)

    -- ============================================================
    -- Effect 1 — Special Summon 1 "Rikka" monster from GY
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — Tribute Deck/Field to attach materials & boost ATK
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_RELEASE+CATEGORY_ATKCHANGE)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,{id,1})
    e2:SetTarget(s.attachtg)
    e2:SetOperation(s.attachop)
    c:RegisterEffect(e2)
end

-- ============================================================
-- Effect 1: Trigger condition & target
-- ============================================================
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:IsSummonType(SUMMON_TYPE_LINK) and c:GetMaterial():IsExists(Card.IsSetCard,1,nil,0x141)
end

function s.spfilter(c,e,tp)
    return c:IsSetCard(0x141) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.spfilter(chkc,e,tp) end
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingTarget(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- ============================================================
-- Effect 2: Target & Operation
-- ============================================================
function s.xyzfilter(c)
    return c:IsFaceup() and c:IsSetCard(0x141) and c:IsType(TYPE_XYZ)
end

function s.deckfilter(c)
    return c:IsMonster() and c:IsSetCard(0x141) and c:IsReleasableByEffect()
end

function s.fieldfilter(c)
    return c:IsFaceup() and c:IsMonster() and c:IsSetCard(0x141) and c:IsReleasableByEffect()
end

function s.attachfilter(c)
    return not c:IsLocation(LOCATION_REMOVED) or c:IsFaceup()
end

function s.attachtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.xyzfilter(chkc) end
    if chk==0 then
        return Duel.IsExistingTarget(s.xyzfilter,tp,LOCATION_MZONE,0,1,nil)
            and Duel.IsExistingMatchingCard(s.deckfilter,tp,LOCATION_DECK,0,1,nil)
            and Duel.IsExistingMatchingCard(s.fieldfilter,tp,LOCATION_MZONE,0,1,nil)
            and Duel.IsExistingMatchingCard(s.attachfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,2,nil)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    Duel.SelectTarget(tp,s.xyzfilter,tp,LOCATION_MZONE,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_RELEASE,nil,2,tp,LOCATION_DECK+LOCATION_MZONE)
end

function s.attachop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if not tc or not tc:IsRelateToEffect(e) or tc:IsFacedown() then return end

    local dg=Duel.GetMatchingGroup(s.deckfilter,tp,LOCATION_DECK,0,nil)
    local fg=Duel.GetMatchingGroup(s.fieldfilter,tp,LOCATION_MZONE,0,nil)
    if #dg==0 or #fg==0 then return end

    local c=e:GetHandler()
    local atk=c:IsRelateToEffect(e) and c:IsFaceup() and c:GetAttack() or 1800

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
    local tc_deck=dg:Select(tp,1,1,nil):GetFirst()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
    local tc_field=fg:Select(tp,1,1,nil):GetFirst()

    local rg=Group.FromCards(tc_deck,tc_field)
    if Duel.Release(rg,REASON_EFFECT)==2 then
        local ag=Duel.GetMatchingGroup(s.attachfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
        if #ag>=2 then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATTACH)
            local sg=ag:Select(tp,2,2,nil)
            if #sg==2 then
                Duel.Overlay(tc,sg)
            end
        end
        if tc:IsFaceup() and atk>0 then
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_UPDATE_ATTACK)
            e1:SetValue(atk)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END+RESET_OPPO_TURN)
            tc:RegisterEffect(e1)
        end
    end
end

