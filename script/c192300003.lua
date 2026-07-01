-- ============================================================
-- Card Name: Battle Machine - Kirin Armor
-- Passcode : 192300003
-- Type     : Monster / Fusion / Effect
-- Attribute: LIGHT
-- Level    : 8
-- ATK/DEF  : 2400 / 3000
-- Race     : Machine
-- Archetype: Wezaemon (0x783)
-- ============================================================
-- Effect 1: Must be Special Summoned (from your Extra Deck) by
--           sending 1 face-up "Battle Machine - Kirin" you
--           control to the GY.
-- Effect 2: If you control "Wezaemon the Tombguard", this
--           card's ATK is doubled and it inflicts piercing
--           battle damage.
-- Effect 3: Once per turn, during the Main Phase (Quick
--           Effect): You can equip this card to a "Wezaemon
--           the Tombguard" you control. The equipped monster
--           gains 2400 ATK and cannot be destroyed by your
--           opponent's card effects.
-- Limit   : You can only Special Summon "Battle Machine -
--           Kirin Armor" once per turn.
-- ============================================================

local s,id=GetID()

s.listed_names={192300001,192300010}

function s.initial_effect(c)
    c:EnableReviveLimit()

    -- ============================================================
    -- Effect 1 — Nomi SS: Send face-up Battle Machine - Kirin to GY
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_EXTRA)
    e1:SetCondition(s.sprcon)
    e1:SetOperation(s.sprop)
    c:RegisterEffect(e1)

    -- Nomi restriction: Must be Special Summoned by above method
    local e1b=Effect.CreateEffect(c)
    e1b:SetType(EFFECT_TYPE_SINGLE)
    e1b:SetCode(EFFECT_SPSUMMON_CONDITION)
    e1b:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    c:RegisterEffect(e1b)

    -- SS limit: once per turn
    c:SetSPSummonOnce(id)

    -- ============================================================
    -- Effect 2 — ATK double + piercing when Wezaemon is on field
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_SET_ATTACK_FINAL)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCondition(s.atkcon)
    e2:SetValue(s.atkval)
    c:RegisterEffect(e2)
    -- Piercing
    local e2b=Effect.CreateEffect(c)
    e2b:SetType(EFFECT_TYPE_SINGLE)
    e2b:SetCode(EFFECT_PIERCE)
    e2b:SetRange(LOCATION_MZONE)
    e2b:SetCondition(s.atkcon)
    c:RegisterEffect(e2b)

    -- ============================================================
    -- Effect 3 — Quick Effect: Equip to Wezaemon
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetRange(LOCATION_MZONE)
    e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
    e3:SetCountLimit(1)
    e3:SetCondition(s.eqcon)
    e3:SetTarget(s.eqtg)
    e3:SetOperation(s.eqop)
    c:RegisterEffect(e3)
end

-- ============================================================
-- Effect 1: Condition — Face-up "Battle Machine - Kirin" exists on your field
-- ============================================================
function s.sprcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.GetLocationCount(tp,LOCATION_MZONE)>-1
        and Duel.IsExistingMatchingCard(s.kirinfilter,tp,LOCATION_MZONE+LOCATION_SZONE,0,1,nil)
end
function s.kirinfilter(c)
    return c:IsFaceup() and c:IsCode(192300010) and c:IsAbleToGraveAsCost()
end

-- ============================================================
-- Effect 1: Operation — Send Battle Machine - Kirin to GY
-- ============================================================
function s.sprop(e,tp,eg,ep,ev,re,r,rp,c)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.kirinfilter,tp,LOCATION_MZONE+LOCATION_SZONE,0,1,1,nil)
    Duel.SendtoGrave(g,REASON_COST)
end

-- ============================================================
-- Effect 2: Condition — Control Wezaemon
-- ============================================================
function s.atkcon(e)
    return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,192300001),e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end

-- ============================================================
-- Effect 2: Value — Double base ATK (2400 * 2 = 4800)
-- ============================================================
function s.atkval(e,c)
    return c:GetBaseAttack()*2
end

-- ============================================================
-- Effect 3: Condition — Main Phase only
-- ============================================================
function s.eqcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsMainPhase()
end

-- ============================================================
-- Effect 3: Target — A Wezaemon you control exists
-- ============================================================
function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and chkc:IsCode(192300001) and chkc:IsFaceup() end
    if chk==0 then
        return Duel.IsExistingTarget(aux.FaceupFilter(Card.IsCode,192300001),tp,LOCATION_MZONE,0,1,e:GetHandler())
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
    Duel.SelectTarget(tp,aux.FaceupFilter(Card.IsCode,192300001),tp,LOCATION_MZONE,0,1,1,e:GetHandler())
end

-- ============================================================
-- Effect 3: Operation — Equip this card to Wezaemon
-- ============================================================
function s.eqop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()
    if not (c:IsRelateToEffect(e) and tc:IsRelateToEffect(e) and tc:IsFaceup()) then return end
    if not Duel.Equip(tp,c,tc) then return end
    -- Limit equip to this target only
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_EQUIP_LIMIT)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e1:SetValue(s.eqlimit)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    c:RegisterEffect(e1)
    -- +2400 ATK to equipped monster
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_EQUIP)
    e2:SetCode(EFFECT_UPDATE_ATTACK)
    e2:SetValue(2400)
    e2:SetReset(RESET_EVENT+RESETS_STANDARD)
    c:RegisterEffect(e2)
    -- Cannot be destroyed by opponent's card effects
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_EQUIP)
    e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e3:SetValue(s.indval)
    e3:SetReset(RESET_EVENT+RESETS_STANDARD)
    c:RegisterEffect(e3)
end
function s.eqlimit(e,c)
    return c:IsCode(192300001)
end
function s.indval(e,re,rp)
    return rp~=e:GetHandlerPlayer()
end
