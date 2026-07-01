-- ============================================================
-- Card Name: Ttf Holy Sanctuary
-- Passcode : 78900102
-- Type     : Spell / Field
-- Archetype: TTF (0x789)
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- Activate Field Spell
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_ACTIVATE)
    e0:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e0)

    -- Effect 1: When you Summon or Special Summon a "Ttf" monster:
    -- Target 1 "Ttf" monster with a different Attribute in GY/banished; Special Summon it.
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
    e1:SetRange(LOCATION_FZONE)
    e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)
    local e2=e1:Clone()
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e2)

    -- Effect 2: If you Special Summon a "Ttf" monster from Extra Deck: Draw 1 card.
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_DRAW)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetRange(LOCATION_FZONE)
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    e3:SetCountLimit(1,id+1)
    e3:SetCondition(s.drcon)
    e3:SetTarget(s.drtg)
    e3:SetOperation(s.drop)
    c:RegisterEffect(e3)

    -- Effect 3: All "Ttf" monsters you control gain 200 ATK for each different Attribute of "Ttf" in GY.
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD)
    e4:SetCode(EFFECT_UPDATE_ATTACK)
    e4:SetRange(LOCATION_FZONE)
    e4:SetTargetRange(LOCATION_MZONE,0)
    e4:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0x789))
    e4:SetValue(s.atkval)
    c:RegisterEffect(e4)
end

-- Effect 1 helpers
function s.cfilter(c,tp)
    return c:IsFaceup() and c:IsSetCard(0x789) and c:IsControler(tp)
end

function s.get_summon_attr(eg,tp)
    local att=0
    for tc in aux.Next(eg) do
        if tc:IsFaceup() and tc:IsSetCard(0x789) and tc:IsControler(tp) then
            att = att | tc:GetAttribute()
        end
    end
    return att
end

function s.spfilter(c,e,tp,att)
    return c:IsSetCard(0x789) 
        and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup())
        and (c:GetAttribute() & att) == 0 
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.cfilter,1,nil,tp)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    local att = s.get_summon_attr(eg,tp)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED) and chkc:IsControler(tp) and s.spfilter(chkc,e,tp,att) end
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingTarget(s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp,att)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,e,tp,att)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
    end
end

-- Effect 2 helpers
function s.drfilter(c,tp)
    return c:IsFaceup() and c:IsSetCard(0x789) and c:IsControler(tp) and c:IsPreviousLocation(LOCATION_EXTRA)
end

function s.drcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.drfilter,1,nil,tp)
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsPlayerCanDraw(tp,1) end
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    Duel.Draw(tp,1,REASON_EFFECT)
end

-- Effect 3 helpers
function s.atkval(e,c)
    local tp=e:GetHandlerPlayer()
    local g=Duel.GetMatchingGroup(Card.IsSetCard,tp,LOCATION_GRAVE,0,nil,0x789)
    local attributes=0
    for tc in aux.Next(g) do
        attributes = attributes | tc:GetAttribute()
    end
    local count=0
    local val=attributes
    while val>0 do
        if (val & 1) == 1 then count = count + 1 end
        val = val >> 1
    end
    return count * 200
end
