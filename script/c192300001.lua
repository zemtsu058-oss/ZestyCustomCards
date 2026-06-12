-- ============================================================
-- Card Name: Wezaemon the Tombguard
-- Passcode : 192300001
-- Type     : Monster / Effect
-- Attribute: EARTH
-- Level    : 10
-- ATK/DEF  : ? / 0
-- Race     : Zombie
-- Archetype: Wezaemon (0x783)
-- ============================================================
-- Effect 1: If you control no monsters, you can Special Summon
--           this card (from your hand).
-- Effect 2: You can only control 1 "Wezaemon the Tombguard".
-- Effect 3: This card's ATK becomes the difference between 8000
--           and your LP.
-- Effect 4: If you Set a card or activate a Spell/Trap that
--           mentions "Wezaemon the Tombguard": You can Set 1
--           Spell/Trap that mentions "Wezaemon the Tombguard"
--           directly from your Deck. It can be activated this
--           turn. You cannot activate monster effects on the
--           field or in the GY the turn you activate this
--           effect, except "Wezaemon the Tombguard" or monsters
--           that mention it. You can only use this effect of
--           "Wezaemon the Tombguard" once per turn.
-- ============================================================

local s,id=GetID()

-- Cards that mention "Wezaemon the Tombguard" (archetype Spell/Traps)
s.listed_names={id}

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Special Summon from hand when you control no monsters
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_HAND)
    e1:SetCondition(s.spcon)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — Control limit: only 1 "Wezaemon the Tombguard"
    -- ============================================================
    c:SetUniqueOnField(1,0,id)

    -- ============================================================
    -- Effect 3 — ATK = 8000 - your LP (continuous, single)
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_SET_BASE_ATTACK)
    e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetValue(s.atkval)
    c:RegisterEffect(e3)

    -- ============================================================
    -- Effect 4 — Trigger: When Set/Activate Spell/Trap mentioning
    --            this card → Set 1 mentioning Spell/Trap from Deck
    -- ============================================================
    -- Effect 4a — Trigger on activation of a mentioning Spell/Trap
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,0))
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e4:SetCode(EVENT_CHAINING)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e4:SetCondition(s.setcon_chain)
    e4:SetTarget(s.settg)
    e4:SetOperation(s.setop)
    c:RegisterEffect(e4)
    -- Effect 4b — Trigger on setting a mentioning Spell/Trap
    local e4b=Effect.CreateEffect(c)
    e4b:SetDescription(aux.Stringid(id,0))
    e4b:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e4b:SetCode(EVENT_SSET)
    e4b:SetRange(LOCATION_MZONE)
    e4b:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e4b:SetCondition(s.setcon_set)
    e4b:SetTarget(s.settg)
    e4b:SetOperation(s.setop)
    c:RegisterEffect(e4b)
end

-- ============================================================
-- Effect 1: Condition — No monsters on your field
-- ============================================================
function s.spcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
end

-- ============================================================
-- Effect 3: Value — ATK = 8000 - LP
-- ============================================================
function s.atkval(e,c)
    local tp=c:GetControler()
    local lp=Duel.GetLP(tp)
    local atk=8000-lp
    if atk<0 then atk=0 end
    return atk
end

-- ============================================================
-- Effect 4: Filter — Spell/Trap that lists this card's name
-- ============================================================
function s.mentionfilter(c)
    return c:IsType(TYPE_SPELL+TYPE_TRAP) and c:ListsCode(id)
end

-- ============================================================
-- Effect 4a: Condition — Player activated a Spell/Trap mentioning this card
-- ============================================================
function s.setcon_chain(e,tp,eg,ep,ev,re,r,rp)
    -- tp = controller of this Wezaemon; rp = player who activated the chain
    if rp~=tp then return false end
    local rc=re:GetHandler()
    return rc and rc:IsType(TYPE_SPELL+TYPE_TRAP) and rc:ListsCode(id)
end

-- ============================================================
-- Effect 4b: Condition — Player set a Spell/Trap mentioning this card
-- ============================================================
function s.setcon_set(e,tp,eg,ep,ev,re,r,rp)
    -- tp = controller of this Wezaemon; ep = player who performed the set
    if ep~=tp then return false end
    return eg:IsExists(s.mentionfilter,1,nil)
end

-- ============================================================
-- Effect 4: Filter — Valid Set targets in Deck
-- ============================================================
function s.setfilter(c)
    return s.mentionfilter(c) and c:IsSSetable()
end

-- ============================================================
-- Effect 4: Target — Check if a valid set target exists
-- ============================================================
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil)
    end
end

-- ============================================================
-- Effect 4: Operation — Set 1 Spell/Trap from Deck + restrictions
-- ============================================================
function s.setop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        local tc=g:GetFirst()
        Duel.SSet(tp,tc)
        -- Allow activation this turn
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
        e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        tc:RegisterEffect(e1)
        -- Restriction: Cannot activate monster effects on field/GY except Wezaemon or monsters that mention it
        local e2=Effect.CreateEffect(e:GetHandler())
        e2:SetType(EFFECT_TYPE_FIELD)
        e2:SetCode(EFFECT_CANNOT_ACTIVATE)
        e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
        e2:SetTargetRange(1,0)
        e2:SetValue(s.aclimit)
        e2:SetReset(RESET_PHASE+PHASE_END)
        Duel.RegisterEffect(e2,tp)
    end
end

-- ============================================================
-- Effect 4: Activation limit filter
-- ============================================================
function s.aclimit(e,re,tp)
    local rc=re:GetHandler()
    if not rc:IsType(TYPE_MONSTER) then return false end
    if not (rc:IsLocation(LOCATION_MZONE) or rc:IsLocation(LOCATION_GRAVE)) then return false end
    -- Allow Wezaemon the Tombguard itself
    if rc:IsCode(id) then return false end
    -- Allow monsters that mention Wezaemon
    if rc:ListsCode(id) then return false end
    return true
end
