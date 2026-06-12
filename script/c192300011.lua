-- ============================================================
-- Card Name: Seiten Taisei
-- Passcode : 192300011
-- Type     : Trap / Continuous
-- Archetype: Wezaemon (0x783)
-- ============================================================
-- Effect 1: While your LP are 3000 or less, "Wezaemon the
--           Tombguard" you control is unaffected by your
--           opponent's activated effects, also it cannot leave
--           the field while an effect is resolving.
-- Effect 2: You take no effect damage while you control
--           "Wezaemon the Tombguard".
-- Effect 3: "Wezaemon the Tombguard" you control inflicts
--           piercing battle damage.
-- Effect 4: If "Wezaemon the Tombguard" you control destroys
--           an opponent's monster by battle: You gain LP equal
--           to half the ATK or DEF (whichever is higher) of
--           that monster.
-- Effect 5: Once per turn: You can pay 800 LP; Set 1
--           Spell/Trap that mentions "Wezaemon the Tombguard"
--           from your GY or Banished. It can be activated this
--           turn.
-- Control: You can only control 1 "Seiten Taisei".
-- ============================================================

local s,id=GetID()

s.listed_names={192300001}

function s.initial_effect(c)
    -- ============================================================
    -- Control limit: only 1 "Seiten Taisei"
    -- ============================================================
    c:SetUniqueOnField(1,0,id)

    -- ============================================================
    -- Activation — Continuous Trap
    -- ============================================================
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_ACTIVATE)
    e0:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e0)

    -- ============================================================
    -- Effect 1 — Wezaemon unaffected by opponent's activated effects (LP <= 3000)
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_IMMUNE_EFFECT)
    e1:SetRange(LOCATION_SZONE)
    e1:SetTargetRange(LOCATION_MZONE,0)
    e1:SetTarget(s.immtg)
    e1:SetValue(s.immval)
    c:RegisterEffect(e1)

    -- Effect 1b — Cannot leave the field while an effect is resolving
    local e1b=Effect.CreateEffect(c)
    e1b:SetType(EFFECT_TYPE_FIELD)
    e1b:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e1b:SetRange(LOCATION_SZONE)
    e1b:SetTargetRange(LOCATION_MZONE,0)
    e1b:SetTarget(s.immtg)
    e1b:SetValue(s.indval)
    c:RegisterEffect(e1b)

    -- ============================================================
    -- Effect 2 — No effect damage while you control Wezaemon
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_CHANGE_DAMAGE)
    e2:SetRange(LOCATION_SZONE)
    e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e2:SetTargetRange(1,0)
    e2:SetCondition(s.damcon)
    e2:SetValue(s.damval)
    c:RegisterEffect(e2)

    -- ============================================================
    -- Effect 3 — Wezaemon inflicts piercing battle damage
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_PIERCE)
    e3:SetRange(LOCATION_SZONE)
    e3:SetTargetRange(LOCATION_MZONE,0)
    e3:SetTarget(s.wetarget)
    c:RegisterEffect(e3)

    -- ============================================================
    -- Effect 4 — LP gain when Wezaemon destroys by battle
    -- ============================================================
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,0))
    e4:SetCategory(CATEGORY_RECOVER)
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e4:SetCode(EVENT_BATTLE_DESTROYING)
    e4:SetRange(LOCATION_SZONE)
    e4:SetCondition(s.lpcon)
    e4:SetTarget(s.lptg)
    e4:SetOperation(s.lpop)
    c:RegisterEffect(e4)

    -- ============================================================
    -- Effect 5 — Set Spell/Trap mentioning Wezaemon from GY/Banished
    -- ============================================================
    local e5=Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id,1))
    e5:SetType(EFFECT_TYPE_QUICK_O)
    e5:SetCode(EVENT_FREE_CHAIN)
    e5:SetRange(LOCATION_SZONE)
    e5:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
    e5:SetCountLimit(1)
    e5:SetCost(s.setcost)
    e5:SetTarget(s.settg)
    e5:SetOperation(s.setop)
    c:RegisterEffect(e5)
end

-- ============================================================
-- Wezaemon target filter (for continuous effects)
-- ============================================================
function s.wetarget(e,c)
    return c:IsFaceup() and c:IsCode(192300001)
end

-- ============================================================
-- Effect 1: Target/Value — Unaffected by opponent's activated effects (LP <= 3000)
-- ============================================================
function s.immtg(e,c)
    return c:IsFaceup() and c:IsCode(192300001) and Duel.GetLP(e:GetHandlerPlayer())<=3000
end
function s.immval(e,re)
    return re:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

-- Effect 1b: Value — Cannot be affected by effects (cannot leave field while resolving)
function s.indval(e,re,rp)
    return rp~=e:GetHandlerPlayer()
end

-- ============================================================
-- Effect 2: Condition — Control Wezaemon
-- ============================================================
function s.damcon(e)
    return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,192300001),e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end
function s.damval(e,re,val,r,rp,rc)
    if bit.band(r,REASON_EFFECT)~=0 then
        return 0
    end
    return val
end

-- ============================================================
-- Effect 4: Condition — Wezaemon destroyed opponent's monster by battle
-- ============================================================
function s.lpcon(e,tp,eg,ep,ev,re,r,rp)
    local tc=eg:GetFirst()
    local bc=tc:GetBattleTarget()
    if not bc then return false end
    if tc:IsCode(192300001) and tc:IsControler(tp) and tc:IsRelateToBattle() then
        -- tc is Wezaemon, bc is opponent's monster
        return bc:IsLocation(LOCATION_GRAVE) and bc:IsControler(1-tp)
    end
    if bc:IsCode(192300001) and bc:IsControler(tp) and bc:IsRelateToBattle() then
        -- bc is Wezaemon, tc is opponent's monster
        return tc:IsLocation(LOCATION_GRAVE) and tc:IsControler(1-tp)
    end
    return false
end

-- ============================================================
-- Effect 4: Target — Calculate LP gain
-- ============================================================
function s.lptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    -- Find the destroyed opponent's monster
    local tc=eg:GetFirst()
    local bc=tc:GetBattleTarget()
    local destroyed_mon
    if tc:IsCode(192300001) and tc:IsControler(tp) then
        destroyed_mon=bc
    else
        destroyed_mon=tc
    end
    local atk=destroyed_mon:GetAttack()
    local def=destroyed_mon:GetDefense()
    local gain=math.floor(math.max(atk,def)/2)
    e:SetLabel(gain)
    Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,gain)
end

-- ============================================================
-- Effect 4: Operation — Gain LP
-- ============================================================
function s.lpop(e,tp,eg,ep,ev,re,r,rp)
    local gain=e:GetLabel()
    if gain>0 then
        Duel.Recover(tp,gain,REASON_EFFECT)
    end
end

-- ============================================================
-- Effect 5: Cost — Pay 800 LP
-- ============================================================
function s.setcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.CheckLPCost(tp,800) end
    Duel.PayLPCost(tp,800)
end

-- ============================================================
-- Effect 5: Filter — Spell/Trap mentioning Wezaemon in GY/Banished
-- ============================================================
function s.setfilter(c)
    return c:IsType(TYPE_SPELL+TYPE_TRAP) and c:ListsCode(192300001) and c:IsSSetable()
end

-- ============================================================
-- Effect 5: Target — Check valid card exists
-- ============================================================
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil)
    end
end

-- ============================================================
-- Effect 5: Operation — Set from GY/Banished + can activate this turn
-- ============================================================
function s.setop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
    if #g>0 then
        local tc=g:GetFirst()
        Duel.SSet(tp,tc)
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
        e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        tc:RegisterEffect(e1)
    end
end
