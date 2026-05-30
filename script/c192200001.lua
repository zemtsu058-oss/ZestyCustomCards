-- ============================================================
-- Card Name: Bena, Guardian of the Castle of Dreams
-- Passcode : 192200001
-- Type     : Monster / Effect
-- Attribute: WATER
-- Level    : 4
-- ATK/DEF  : 1600 / 1800
-- Race     : Illusion
-- Archetype: Castle of Dreams (0x782)
-- ============================================================
-- Effect 1: If this card is Normal or Special Summoned: You can
--           Set 1 "Castle of Dreams" Normal Spell/Trap from your
--           Deck to your field.
-- Effect 2: If a Field Spell card you control would be destroyed,
--           you can banish this card from your GY, instead.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Trigger on Summon: Set a Castle of Dreams Normal Spell/Trap
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SUMMON_SUCCESS)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetTarget(s.tg_set)
    e1:SetOperation(s.op_set)
    c:RegisterEffect(e1)
    -- Clone for Special Summon trigger (same effect, different event)
    local e2=e1:Clone()
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e2)

    -- ============================================================
    -- Effect 2 — GY banish: protect Field Spell from destruction
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e3:SetCode(EFFECT_DESTROY_REPLACE)
    e3:SetRange(LOCATION_GRAVE)
    e3:SetCountLimit(1,id+1,EFFECT_COUNT_CODE_OATH)
    e3:SetTarget(s.reptg)
    e3:SetValue(s.repval)
    e3:SetOperation(s.repop)
    c:RegisterEffect(e3)
end

-- ============================================================
-- Effect 1: Filter — Castle of Dreams Normal Spell/Trap that can be Set
-- ============================================================
function s.filter_set(c)
    return c:IsSetCard(0x782) and c:IsSpellTrap()
        and not c:IsType(TYPE_FIELD) and not c:IsType(TYPE_CONTINUOUS)
        and not c:IsType(TYPE_QUICKPLAY) and not c:IsType(TYPE_EQUIP)
        and not c:IsType(TYPE_RITUAL) and not c:IsType(TYPE_COUNTER)
        and c:IsSSetable()
end

-- ============================================================
-- Effect 1: Target — Check if a valid Set target exists
-- ============================================================
function s.tg_set(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
            and Duel.IsExistingMatchingCard(s.filter_set,tp,LOCATION_DECK,0,1,nil)
    end
end

-- ============================================================
-- Effect 1: Operation — Select 1 card from Deck, Set to field
-- ============================================================
function s.op_set(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local g=Duel.SelectMatchingCard(tp,s.filter_set,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SSet(tp,g)
    end
end

-- ============================================================
-- Effect 2: Filter — face-up Castle of Dreams Field Spell about to be destroyed
-- ============================================================
function s.repfilter(c,tp)
    return c:IsFaceup() and c:IsControler(tp) and c:IsLocation(LOCATION_FZONE)
        and c:IsReason(REASON_EFFECT) and not c:IsReason(REASON_REPLACE)
end

-- ============================================================
-- Effect 2: Target — Ask player if they want to replace
-- ============================================================
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then
        return eg:IsExists(s.repfilter,1,nil,tp)
    end
    return Duel.SelectEffectYesNo(tp,c,96)
end

-- ============================================================
-- Effect 2: Value — Confirm the card qualifies for replacement
-- ============================================================
function s.repval(e,c)
    return s.repfilter(c,e:GetHandlerPlayer())
end

-- ============================================================
-- Effect 2: Operation — Banish this card from GY
-- ============================================================
function s.repop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    Duel.Remove(c,POS_FACEUP,REASON_EFFECT+REASON_REPLACE)
end
