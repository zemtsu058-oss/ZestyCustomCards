-- ============================================================
-- Card Name: Wandering Ghost of the Castle of Dreams
-- Passcode : 192200007
-- Type     : Monster / Link / Effect
-- Attribute: DARK
-- Link     : 1
-- ATK       : 1500
-- Race     : Illusion
-- Archetype: Castle of Dreams (0x782)
-- Materials: 1 "Castle of Dreams" monster
-- Markers  : Bottom (0x2)
-- ============================================================
-- Effect 1: If a Field Spell you control would leave the field
--           by card effects, you can banish this card (from your
--           field or GY), instead.
-- Effect 2: If this card is in your banishment, while you control
--           a Field Spell: You can Special Summon this card.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    c:EnableReviveLimit()

    -- ============================================================
    -- Summon Procedure — Link Summon: 1 Castle of Dreams monster
    -- ============================================================
    Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x782),1,1)

    -- ============================================================
    -- Effect 1a — From field, banish to protect Field Spell from leaving
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EFFECT_SEND_REPLACE)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1,id+1,EFFECT_COUNT_CODE_OATH)
    e1:SetTarget(s.reptg_field)
    e1:SetValue(s.repval)
    e1:SetOperation(s.repop)
    c:RegisterEffect(e1)
    local e1b=e1:Clone()
    e1b:SetCode(EFFECT_DESTROY_REPLACE)
    c:RegisterEffect(e1b)

    -- ============================================================
    -- Effect 1b — From GY, banish to protect Field Spell from leaving
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EFFECT_SEND_REPLACE)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,id+1,EFFECT_COUNT_CODE_OATH)
    e2:SetTarget(s.reptg_gy)
    e2:SetValue(s.repval)
    e2:SetOperation(s.repop)
    c:RegisterEffect(e2)
    local e2b=e2:Clone()
    e2b:SetCode(EFFECT_DESTROY_REPLACE)
    c:RegisterEffect(e2b)

    -- ============================================================
    -- Effect 2 — Ignition from banishment: SS self while you control a Field Spell
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetRange(LOCATION_REMOVED)
    e3:SetCountLimit(1,id+2,EFFECT_COUNT_CODE_OATH)
    e3:SetCondition(s.sscon)
    e3:SetTarget(s.sstg)
    e3:SetOperation(s.ssop)
    c:RegisterEffect(e3)
end

-- ============================================================
-- Effect 1: Filter — Face-up Field Spell about to leave by card effect
-- ============================================================
function s.repfilter(c,tp)
    return c:IsFaceup() and c:IsControler(tp) and c:IsLocation(LOCATION_FZONE)
        and c:IsReason(REASON_EFFECT) and not c:IsReason(REASON_REPLACE)
end

-- ============================================================
-- Effect 1a: Target — From field location
-- ============================================================
function s.reptg_field(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then
        return c:IsLocation(LOCATION_MZONE) and eg:IsExists(s.repfilter,1,nil,tp)
    end
    return Duel.SelectEffectYesNo(tp,c,96)
end

-- ============================================================
-- Effect 1b: Target — From GY location
-- ============================================================
function s.reptg_gy(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then
        return c:IsLocation(LOCATION_GRAVE) and eg:IsExists(s.repfilter,1,nil,tp)
    end
    return Duel.SelectEffectYesNo(tp,c,96)
end

-- ============================================================
-- Effect 1: Value — Confirm the card qualifies for replacement
-- ============================================================
function s.repval(e,c)
    return s.repfilter(c,e:GetHandlerPlayer())
end

-- ============================================================
-- Effect 1: Operation — Banish this card
-- ============================================================
function s.repop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    Duel.Remove(c,POS_FACEUP,REASON_EFFECT+REASON_REPLACE)
end

-- ============================================================
-- Effect 2: Condition — You control a face-up Field Spell
-- ============================================================
function s.sscon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,LOCATION_FZONE,0,1,nil)
end

-- ============================================================
-- Effect 2: Target — Check if this card can be SS from banishment
-- ============================================================
function s.sstg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

-- ============================================================
-- Effect 2: Operation — SS this card from banishment
-- ============================================================
function s.ssop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
end
