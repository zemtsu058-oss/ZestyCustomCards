-- ============================================================
-- Card Name: Surtr, Sarkaz of Laevateinn
-- Passcode : 79900016
-- Type     : Monster / Link / Effect
-- Attribute: FIRE
-- Link     : 4
-- ATK      : 2500
-- Race     : Fiend
-- Archetype: Generic (None)
-- Materials: 1+ FIRE monsters
-- Markers  : Left, Right, Bottom-Left, Bottom-Right
-- ============================================================
-- Effect 1: Can only be Link Summoned once per turn.
-- Effect 2: Cannot be destroyed or banished by opponent's card
--           effects during the turn it was Special Summoned.
-- Effect 3: Quick Effect: Banish FIRE monsters from GY; gains
--           300 ATK per monster, and can attack additional times
--           up to the number of opponent's monsters.
-- Effect 4: During the next Standby Phase, destroy this card.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- Link Summon
    c:EnableReviveLimit()
    Link.AddProcedure(c,s.matfilter,1,99)

    -- ============================================================
    -- Effect 1 — Link Summon Limit
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_SPSUMMON_CONDITION)
    e1:SetValue(s.splimit)
    c:RegisterEffect(e1)

    -- Register link summon flag
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetCondition(s.regcon)
    e2:SetOperation(s.regop)
    c:RegisterEffect(e2)

    -- ============================================================
    -- Effect 2 — Protection from destruction and banishment
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e3:SetCondition(s.protcon)
    e3:SetValue(s.indval)
    c:RegisterEffect(e3)

    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetCode(EFFECT_IMMUNE_EFFECT)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCondition(s.protcon)
    e4:SetValue(s.immval)
    c:RegisterEffect(e4)

    -- ============================================================
    -- Effect 3 — GY FIRE banish for ATK and multiple attacks
    -- ============================================================
    local e5=Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id,1))
    e5:SetCategory(CATEGORY_ATKCHANGE)
    e5:SetType(EFFECT_TYPE_QUICK_O)
    e5:SetCode(EVENT_FREE_CHAIN)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCost(s.atkcost)
    e5:SetTarget(s.atktg)
    e5:SetOperation(s.atkop)
    c:RegisterEffect(e5)

    -- ============================================================
    -- Effect 4 — Self-destruction in Standby Phase
    -- ============================================================
    local e6=Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id,2))
    e6:SetCategory(CATEGORY_DESTROY)
    e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e6:SetCode(EVENT_PHASE+PHASE_STANDBY)
    e6:SetRange(LOCATION_MZONE)
    e6:SetCountLimit(1)
    e6:SetTarget(s.destg)
    e6:SetOperation(s.desop)
    c:RegisterEffect(e6)
end

-- ============================================================
-- Summon Procedure: Material Filter — FIRE monsters
-- ============================================================
function s.matfilter(c,lc,sumtype,tp)
    return c:IsAttribute(ATTRIBUTE_FIRE,lc,sumtype,tp)
end

-- ============================================================
-- Effect 1: Summon Limit — Once per turn Link Summon
-- ============================================================
function s.splimit(e,se,sp,st,spos,targetp,sump)
    if (st&SUMMON_TYPE_LINK)==SUMMON_TYPE_LINK then
        return Duel.GetFlagEffect(sump,id)==0
    end
    return true
end

-- ============================================================
-- Effect 1: Summon Condition — Check Link Summon
-- ============================================================
function s.regcon(e,tp,eg,ep,ev,re,r,rp)
    return (e:GetHandler():GetSummonType()&SUMMON_TYPE_LINK)==SUMMON_TYPE_LINK
end

-- ============================================================
-- Effect 1: Summon Operation — Register flag
-- ============================================================
function s.regop(e,tp,eg,ep,ev,re,r,rp)
    Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
end

-- ============================================================
-- Effect 2: Condition — Only during the turn Link Summoned
-- ============================================================
function s.protcon(e)
    return e:GetHandler():GetTurnID()==Duel.GetTurnCount()
end

-- ============================================================
-- Effect 2: Value — Only opponent's card effects
-- ============================================================
function s.indval(e,re,rp)
    return rp==1-e:GetHandlerPlayer()
end

-- ============================================================
-- Effect 2: Value — Only banish effects
-- ============================================================
function s.immval(e,re)
    return re:GetOwnerPlayer()~=e:GetHandlerPlayer() and re:GetCategory()&CATEGORY_REMOVE ~= 0
end

-- ============================================================
-- Effect 3: Filter — FIRE monsters in GY
-- ============================================================
function s.cfilter(c)
    return c:IsAttribute(ATTRIBUTE_FIRE) and c:IsAbleToRemoveAsCost()
end

-- ============================================================
-- Effect 3: Cost — Banish FIRE monsters from GY
-- ============================================================
function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_GRAVE,0,1,nil)
    end
    local g=Duel.GetMatchingGroup(s.cfilter,tp,LOCATION_GRAVE,0,nil)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local sg=g:Select(tp,1,#g,nil)
    Duel.Remove(sg,POS_FACEUP,REASON_COST)
    e:SetLabel(#sg)
end

-- ============================================================
-- Effect 3: Target — Target setup
-- ============================================================
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
end

-- ============================================================
-- Effect 3: Operation — Apply ATK update and extra attacks
-- ============================================================
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
    local count=e:GetLabel()
    if count==0 then return end
    
    -- ATK Up
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetValue(count*300)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
    c:RegisterEffect(e1)
    
    -- Extra attacks
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_EXTRA_ATTACK)
    e2:SetValue(s.atkval)
    e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
    c:RegisterEffect(e2)
end

-- ============================================================
-- Effect 4: Target — Self-destruction setup
-- ============================================================
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,e:GetHandler(),1,0,0)
end

-- ============================================================
-- Effect 4: Operation — Destroy this card
-- ============================================================
function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.Destroy(c,REASON_EFFECT)
    end
end

-- ============================================================
-- Effect 3: Value — Calculate extra attack count dynamically
-- ============================================================
function s.atkval(e,c)
    local handler=e:GetHandler()
    local tp=e:GetHandlerPlayer()
    if handler:HasFlagEffect(id) then
        local label=handler:GetFlagEffectLabel(id)
        if label then return label end
    end
    
    local phase=Duel.GetCurrentPhase()
    if phase>=PHASE_BATTLE_START and phase<=PHASE_BATTLE then
        local opp_count=Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)
        handler:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1,opp_count)
        return opp_count
    end
    return Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)
end

