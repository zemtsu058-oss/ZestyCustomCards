-- The Crystal Cave: Mana Field
-- 798599
local s,id=GetID()
function s.initial_effect(c)

    --------------------------------------------------
    -- Enable Mana Counter
    --------------------------------------------------
    c:EnableCounterPermit(0x177)
    c:SetCounterLimit(0x177,99)

    --------------------------------------------------
    -- Return SS Spellcaster from Deck to Deck
    --------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetRange(LOCATION_DECK)
    e1:SetCondition(s.retcon)
    e1:SetOperation(s.retop)
    c:RegisterEffect(e1)

    --------------------------------------------------
    -- All monsters become Spellcaster
    --------------------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_CHANGE_RACE)
    e2:SetRange(LOCATION_SZONE)
    e2:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
    e2:SetValue(RACE_SPELLCASTER)
    c:RegisterEffect(e2)

    --------------------------------------------------
    -- Add Mana Counter when Spell resolves
    --------------------------------------------------
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e3:SetCode(EVENT_CHAIN_SOLVED)
    e3:SetRange(LOCATION_SZONE)
    e3:SetCondition(s.addcon)
    e3:SetOperation(s.addop)
    c:RegisterEffect(e3)

    --------------------------------------------------
    -- Your monsters gain ATK
    --------------------------------------------------
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD)
    e4:SetCode(EFFECT_UPDATE_ATTACK)
    e4:SetRange(LOCATION_SZONE)
    e4:SetTargetRange(LOCATION_MZONE,0)
    e4:SetTarget(s.atkfilter)
    e4:SetValue(s.atkval)
    c:RegisterEffect(e4)

    --------------------------------------------------
    -- Opponent monsters lose ATK
    --------------------------------------------------
    local e5=e4:Clone()
    e5:SetTargetRange(0,LOCATION_MZONE)
    e5:SetValue(s.atkval_opp)
    c:RegisterEffect(e5)

    --------------------------------------------------
    -- Disable monsters with 0 ATK
    --------------------------------------------------
    local e6=Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_FIELD)
    e6:SetCode(EFFECT_DISABLE)
    e6:SetRange(LOCATION_SZONE)
    e6:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
    e6:SetTarget(s.disablefilter)
    c:RegisterEffect(e6)

    local e7=e6:Clone()
    e7:SetCode(EFFECT_DISABLE_EFFECT)
    c:RegisterEffect(e7)
end

--------------------------------------------------
-- Return condition
--------------------------------------------------
function s.retfilter(c,tp)
    return c:IsRace(RACE_SPELLCASTER)
        and c:IsPreviousLocation(LOCATION_DECK)
        and c:GetOwner()==tp
end

function s.retcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.retfilter,1,nil,tp)
end

function s.retop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
    if not Duel.SelectYesNo(tp,aux.Stringid(id,0)) then return end

    local g=eg:Filter(s.retfilter,nil,tp)
    if #g>0 then
        Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
    end

    Duel.MoveToField(c,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
end

--------------------------------------------------
-- Mana Counter
--------------------------------------------------
function s.addcon(e,tp,eg,ep,ev,re,r,rp)
    return re and re:IsActiveType(TYPE_SPELL)
end

function s.addop(e,tp,eg,ep,ev,re,r,rp)
    e:GetHandler():AddCounter(0x177,1)
end

--------------------------------------------------
-- ATK
--------------------------------------------------
function s.atkfilter(e,c)
    return c:IsFaceup() and c:IsRace(RACE_SPELLCASTER)
end

function s.atkval(e,c)
    return e:GetHandler():GetCounter(0x177)*100
end

function s.atkval_opp(e,c)
    return -e:GetHandler():GetCounter(0x177)*100
end

--------------------------------------------------
-- Disable
--------------------------------------------------
function s.disablefilter(e,c)
    return c:IsFaceup() and c:GetAttack()==0
end