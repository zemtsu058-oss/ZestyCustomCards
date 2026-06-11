-- ============================================================
-- Card Name: Purple Eyes Ultra Max Dragon
-- Passcode  : 22100002
-- Type      : Monster / Fusion / Effect
-- Attribute : LIGHT
-- Level     : 8
-- ATK/DEF   : 4000 / 2500
-- Race      : Dragon
-- Archetype : Blue_Eye (0xdd)
-- ============================================================
-- Effect 1  : Must be Fusion Summoned.
-- Effect 2  : Cannot be destroyed by card effects.
-- Effect 3  : Unaffected by other cards' effects during Battle Phase.
-- Effect 4  : Fusion Summoned: Add 1 Spell/Trap mentioning BEWD or REBD.
-- Effect 5  : Negate activation (Quick Effect, up to Normal materials per turn).
-- Effect 6  : Can make a second attack during each Battle Phase.
-- Effect 7  : Gains 500 ATK for each opponent's monster destroyed.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- Enable Fusion Summon limit
    c:EnableReviveLimit()
    Fusion.AddProcMix(c,true,true,s.matfilter1,s.matfilter2)

    -- ============================================================
    -- Effect 1 — Must be Fusion Summoned
    -- ============================================================
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_SPSUMMON_CONDITION)
    e0:SetValue(aux.fuslimit)
    c:RegisterEffect(e0)

    -- Register fusion materials count on summon
    local e_reg=Effect.CreateEffect(c)
    e_reg:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e_reg:SetCode(EVENT_SPSUMMON_SUCCESS)
    e_reg:SetCondition(s.regcon)
    e_reg:SetOperation(s.regop)
    c:RegisterEffect(e_reg)

    -- ============================================================
    -- Effect 2 — Cannot be destroyed by card effects
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e1:SetValue(1)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 3 — Unaffected during Battle Phase
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCode(EFFECT_IMMUNE_EFFECT)
    e2:SetCondition(s.bpcon)
    e2:SetValue(s.efilter)
    c:RegisterEffect(e2)

    -- ============================================================
    -- Effect 4 — Search Spell/Trap mentioning BEWD or REBD
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCondition(s.thcon)
    e3:SetTarget(s.thtg)
    e3:SetOperation(s.thop)
    c:RegisterEffect(e3)

    -- ============================================================
    -- Effect 5 — Negate activation (Quick Effect)
    -- ============================================================
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,1))
    e4:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
    e4:SetType(EFFECT_TYPE_QUICK_O)
    e4:SetCode(EVENT_CHAINING)
    e4:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCondition(s.negcon)
    e4:SetTarget(s.negtg)
    e4:SetOperation(s.negop)
    c:RegisterEffect(e4)

    -- ============================================================
    -- Effect 6 — Double attack
    -- ============================================================
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE)
    e5:SetCode(EFFECT_EXTRA_ATTACK)
    e5:SetValue(1)
    c:RegisterEffect(e5)

    -- ============================================================
    -- Effect 7 — ATK gain on opponent monster destruction
    -- ============================================================
    local e6=Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id,2))
    e6:SetCategory(CATEGORY_ATKCHANGE)
    e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e6:SetCode(EVENT_DESTROYED)
    e6:SetRange(LOCATION_MZONE)
    e6:SetCondition(s.atkcon)
    e6:SetOperation(s.atkop)
    c:RegisterEffect(e6)
end

-- ============================================================
-- Fusion Materials & Verification
-- ============================================================
function s.matfilter1(c,fc,sumtype,tp)
    return c:IsCode(74677422) or (c:IsRace(RACE_DRAGON) and c:IsType(TYPE_EFFECT))
end

function s.matfilter2(c,fc,sumtype,tp)
    return c:IsCode(89631139)
end

-- ============================================================
-- Dynamic limit registration
-- ============================================================
function s.regcon(e,tp,eg,ep,ev,re,r,rp)
    return (e:GetHandler():GetSummonType()&SUMMON_TYPE_FUSION)==SUMMON_TYPE_FUSION
end

function s.regop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local mat=c:GetMaterial()
    local ct=0
    if mat then
        local tc=mat:GetFirst()
        while tc do
            if tc:IsType(TYPE_NORMAL) then
                ct=ct+1
            end
            tc=mat:GetNext()
        end
    end
    c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1,ct)
end

-- ============================================================
-- Effect 3: Protection (Battle Phase)
-- ============================================================
function s.bpcon(e)
    local ph=Duel.GetCurrentPhase()
    return ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE
end

function s.efilter(e,re)
    return re:GetOwner()~=e:GetHandler()
end

-- ============================================================
-- Effect 4: Search Spell/Trap
-- ============================================================
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

function s.thfilter(c)
    return c:IsType(TYPE_SPELL+TYPE_TRAP) and (c:ListsCode(89631139) or c:ListsCode(74677422)) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

-- ============================================================
-- Effect 5: Negate activation
-- ============================================================
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsStatus(STATUS_BATTLE_DESTROYED) then return false end
    if not Duel.IsChainNegatable(ev) then return false end
    local limit=0
    if c:HasFlagEffect(id) then
        limit=c:GetFlagEffectLabel(id) or 0
    end
    if limit==0 then return false end
    return c:GetFlagEffect(id+100)<limit
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    local c=e:GetHandler()
    c:RegisterFlagEffect(id+100,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
        Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
    end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
        Duel.Destroy(eg,REASON_EFFECT)
    end
end

-- ============================================================
-- Effect 7: ATK gain on destruction
-- ============================================================
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.cfilter2,1,nil,1-tp)
end

function s.cfilter2(c,opp)
    return c:IsPreviousControler(opp) and c:IsPreviousLocation(LOCATION_MZONE)
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsFaceup() and c:IsRelateToEffect(e) then
        local ct=eg:FilterCount(s.cfilter2,nil,1-tp)
        if ct>0 then
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_UPDATE_ATTACK)
            e1:SetValue(ct*500)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
            c:RegisterEffect(e1)
        end
    end
end
