-- ============================================================
-- Card Name: Castle of Dreams - Betrayal
-- Passcode : 192200012
-- Type     : Trap / Normal
-- Archetype: Castle of Dreams (0x782)
-- ============================================================
-- Effect 1: If 2 or more monsters were Special Summoned from your
--           opponent's Deck and/or Extra Deck this turn, while you
--           control a "Castle of Dreams" Field Spell: Take control
--           of 1 monster your opponent controls, then if you took
--           control of an Effect Monster, that monster gains the
--           following effect:
--           Once per turn, when your opponent activates a monster
--           effect: Destroy that monster.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    s.global_check(c)

    -- ============================================================
    -- Effect 1 — Normal Trap activation: Take control + grant effect
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_CONTROL)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCondition(s.condition)
    e1:SetTarget(s.tg_control)
    e1:SetOperation(s.op_control)
    c:RegisterEffect(e1)
end

-- ============================================================
-- Effect 1: Filter — Castle of Dreams Field Spell
-- ============================================================
function s.filter_fspell(c)
    return c:IsFaceup() and c:IsSetCard(0x782) and c:IsType(TYPE_FIELD)
end

-- ============================================================
-- Global tracker: Count monsters each player Special Summons from Deck/ED this turn
-- ============================================================
function s.global_check(c)
    if s.global_checked then return end
    s.global_checked=true
    local ge=Effect.CreateEffect(c)
    ge:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    ge:SetCode(EVENT_SPSUMMON_SUCCESS)
    ge:SetOperation(s.regop)
    Duel.RegisterEffect(ge,0)
end

function s.regfilter(c)
    local loc=c:GetSummonLocation()
    return c:IsSummonType(SUMMON_TYPE_SPECIAL)
        and (loc==LOCATION_DECK or loc==LOCATION_EXTRA)
end

function s.regop(e,tp,eg,ep,ev,re,r,rp)
    for tc in aux.Next(eg) do
        if s.regfilter(tc) then
            Duel.RegisterFlagEffect(tc:GetSummonPlayer(),id,RESET_PHASE+PHASE_END,0,1)
        end
    end
end

-- ============================================================
-- Effect 1: Condition — You control a Field Spell + 2+ opponent SS from Deck/ED
-- ============================================================
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(s.filter_fspell,tp,LOCATION_FZONE,0,1,nil)
        and Duel.GetFlagEffect(1-tp,id)>=2
end

-- ============================================================
-- Effect 1: Target — Select 1 opponent's monster to take control of
-- ============================================================
function s.tg_control(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and chkc:IsControlerCanBeChanged() end
    if chk==0 then
        return Duel.IsExistingTarget(Card.IsControlerCanBeChanged,tp,0,LOCATION_MZONE,1,nil)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
    local g=Duel.SelectTarget(tp,Card.IsControlerCanBeChanged,tp,0,LOCATION_MZONE,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_CONTROL,g,1,0,0)
end

-- ============================================================
-- Effect 1: Operation — Take control, grant destroy effect if Effect Monster
-- ============================================================
function s.op_control(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and Duel.GetControl(tc,tp)~=0 then
        if tc:IsType(TYPE_EFFECT) then
            -- ============================================================
            -- Granted Effect — Quick: Destroy an opponent's monster that activated its effect
            -- ============================================================
            local e1=Effect.CreateEffect(tc)
            e1:SetDescription(aux.Stringid(id,1))
            e1:SetCategory(CATEGORY_DESTROY)
            e1:SetType(EFFECT_TYPE_QUICK_O)
            e1:SetCode(EVENT_CHAINING)
            e1:SetRange(LOCATION_MZONE)
            e1:SetCountLimit(1)
            e1:SetCondition(s.grant_con)
            e1:SetTarget(s.grant_tg)
            e1:SetOperation(s.grant_op)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD)
            tc:RegisterEffect(e1,true)
        end
    end
end

-- ============================================================
-- Granted Effect: Condition — Opponent activated a monster effect
-- ============================================================
function s.grant_con(e,tp,eg,ep,ev,re,r,rp)
    return rp==1-tp and re:IsActiveType(TYPE_MONSTER)
end

-- ============================================================
-- Granted Effect: Target — Always true
-- ============================================================
function s.grant_tg(e,tp,eg,ep,ev,re,r,rp,chk)
    local rc=re:GetHandler()
    if chk==0 then return rc and rc:IsDestructable() end
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,rc,1,0,0)
end

-- ============================================================
-- Granted Effect: Operation — Destroy the monster that activated its effect
-- ============================================================
function s.grant_op(e,tp,eg,ep,ev,re,r,rp)
    local rc=re:GetHandler()
    if rc:IsRelateToEffect(re) and rc:IsDestructable() then
        Duel.Destroy(rc,REASON_EFFECT)
    end
end
