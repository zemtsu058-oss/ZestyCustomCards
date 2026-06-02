-- ============================================================
-- Card Name: Waking Nightmare
-- Passcode : 79900004
-- Type     : Spell / Normal
-- Archetype: None (0x0)
-- ============================================================
-- Effect 1 [Activate]: At the start of your Main Phase 1: Until
--   the End Phase of the next turn, neither player can activate
--   the effect of monster Special Summoned from the GY, nor
--   using them as material for Fusion, Synchro, Xyz, Link, or
--   Ritual Summon.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- Effect 1: Lock Special Summoned from GY monsters
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCondition(s.con_activate)
    e1:SetOperation(s.op_activate)
    c:RegisterEffect(e1)
end

function s.con_activate(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsPhase(PHASE_MAIN1) and not Duel.CheckPhaseActivity()
end

function s.op_activate(e,tp,eg,ep,ev,re,r,rp)
    -- IsRelateToEffect check is not required for Normal Spell activation
    local c=e:GetHandler()

    -- 1. Neither player can activate effects of monsters Special Summoned from GY
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e1:SetCode(EFFECT_CANNOT_ACTIVATE)
    e1:SetTargetRange(1,1) -- Both players
    e1:SetValue(s.val_aclimit)
    e1:SetReset(RESET_PHASE|PHASE_END,2)
    Duel.RegisterEffect(e1,tp)

    -- 2. Cannot be used as material for Fusion Summons
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL)
    e2:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
    e2:SetTarget(s.tg_mat)
    e2:SetValue(1)
    e2:SetReset(RESET_PHASE|PHASE_END,2)
    Duel.RegisterEffect(e2,tp)

    -- 3. Cannot be used as material for Synchro Summons
    local e3=e2:Clone()
    e3:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL)
    Duel.RegisterEffect(e3,tp)

    -- 4. Cannot be used as material for Xyz Summons
    local e4=e2:Clone()
    e4:SetCode(EFFECT_CANNOT_BE_XYZ_MATERIAL)
    Duel.RegisterEffect(e4,tp)

    -- 5. Cannot be used as material for Link Summons
    local e5=e2:Clone()
    e5:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
    Duel.RegisterEffect(e5,tp)

    -- 6. Cannot be used as material for Ritual Summons
    local e6=e2:Clone()
    e6:SetCode(EFFECT_CANNOT_BE_MATERIAL)
    e6:SetValue(s.val_mat)
    Duel.RegisterEffect(e6,tp)
end

function s.val_aclimit(e,re,tp)
    local rc=re:GetHandler()
    return re:IsMonsterEffect() and rc:IsSpecialSummoned() and rc:IsSummonLocation(LOCATION_GRAVE)
end

function s.tg_mat(e,c)
    -- chk==0
    return c:IsSpecialSummoned() and c:IsSummonLocation(LOCATION_GRAVE)
end

function s.val_mat(e,c,sumtype,gp,g)
    return sumtype==SUMMON_TYPE_RITUAL
end
