-- ============================================================
-- Card Name: Nyudogumo
-- Passcode : 192300008
-- Type     : Spell / Quick-Play
-- Archetype: Wezaemon (0x783)
-- ============================================================
-- Effect 1: If you control only "Wezaemon the Tombguard": You
--           can pay 800 LP, then target up to 2 monsters your
--           opponent controls, or target all monsters your
--           opponent controls if they control 5 or more
--           monsters; halve their ATK, then destroy all Attack
--           Position monsters your opponent controls with ATK
--           less than the ATK of "Wezaemon the Tombguard" you
--           control.
-- Effect 2: You can banish this card from your GY; add up to 1
--           "Tachikaze" and up to 1 "Raisho" from your GY
--           and/or banishment to your hand. You can only use
--           each effect of "Nyudogumo" once per turn.
-- ============================================================

local s,id=GetID()

s.listed_names={192300001,192300006,192300007}

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Quick-Play: Halve ATK + conditional destroy
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DESTROY)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCost(s.cost_lp)
    e1:SetCondition(s.onlywecon)
    e1:SetTarget(s.tg_halve)
    e1:SetOperation(s.op_halve)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — GY: Banish to add Tachikaze and/or Raisho
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
    e2:SetCountLimit(1,{id,1},EFFECT_COUNT_CODE_OATH)
    e2:SetCost(s.cost_banish)
    e2:SetTarget(s.tg_recover)
    e2:SetOperation(s.op_recover)
    c:RegisterEffect(e2)
end

-- ============================================================
-- Condition — You control only "Wezaemon the Tombguard"
-- ============================================================
function s.onlywecon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)>0
        and not Duel.IsExistingMatchingCard(s.nonwefilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.nonwefilter(c)
    return not c:IsCode(192300001)
end

-- ============================================================
-- Cost — Pay 800 LP
-- ============================================================
function s.cost_lp(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.CheckLPCost(tp,800) end
    Duel.PayLPCost(tp,800)
end

-- ============================================================
-- Effect 1: Target — Target up to 2 (or all if opponent has 5+)
-- ============================================================
function s.tg_halve(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    local omc=Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)
    local maxc=2
    if omc>=5 then maxc=omc end
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and chkc:IsFaceup() end
    if chk==0 then
        return Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    local g=Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,maxc,nil)
    Duel.SetOperationInfo(0,CATEGORY_ATKCHANGE,g,#g,0,0)
end

-- ============================================================
-- Effect 1: Operation — Halve ATK, then destroy ATK-Position
--           monsters with ATK < Wezaemon's ATK
-- ============================================================
function s.op_halve(e,tp,eg,ep,ev,re,r,rp)
    local tg=Duel.GetTargetCards(e)
    if #tg==0 then return end
    -- Step 1: Halve ATK of targeted monsters
    for tc in tg:Iter() do
        if tc:IsRelateToEffect(e) and tc:IsFaceup() then
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_SET_ATTACK_FINAL)
            e1:SetValue(math.floor(tc:GetAttack()/2))
            e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
            tc:RegisterEffect(e1)
        end
    end
    -- Step 2: Get Wezaemon's ATK
    local wg=Duel.GetMatchingGroup(aux.FaceupFilter(Card.IsCode,192300001),tp,LOCATION_MZONE,0,nil)
    if #wg==0 then return end
    local wezatk=wg:GetFirst():GetAttack()
    -- Step 3: Destroy all ATK Position opponent's monsters with ATK < Wezaemon ATK
    local dg=Duel.GetMatchingGroup(s.destfilter,tp,0,LOCATION_MZONE,nil,wezatk)
    if #dg>0 then
        Duel.Destroy(dg,REASON_EFFECT)
    end
end
function s.destfilter(c,wezatk)
    return c:IsFaceup() and c:IsAttackPos() and c:GetAttack()<wezatk and c:IsDestructable()
end

-- ============================================================
-- Effect 2: Cost — Banish from GY
-- ============================================================
function s.cost_banish(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsAbleToRemoveAsCost() end
    Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end

-- ============================================================
-- Effect 2: Filter — Tachikaze or Raisho in GY/Banished
-- ============================================================
function s.recfilter_tachi(c)
    return c:IsCode(192300006) and c:IsAbleToHand()
end
function s.recfilter_raisho(c)
    return c:IsCode(192300007) and c:IsAbleToHand()
end
function s.recfilter(c)
    return (c:IsCode(192300006) or c:IsCode(192300007)) and c:IsAbleToHand()
end

-- ============================================================
-- Effect 2: Target — Check at least 1 valid card exists
-- ============================================================
function s.tg_recover(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.recfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
end

-- ============================================================
-- Effect 2: Operation — Add up to 1 Tachikaze and up to 1 Raisho
-- ============================================================
function s.op_recover(e,tp,eg,ep,ev,re,r,rp)
    local sg=Group.CreateGroup()
    -- Select up to 1 Tachikaze
    local g1=Duel.GetMatchingGroup(s.recfilter_tachi,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
    if #g1>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local sel1=g1:Select(tp,0,1,nil)
        sg:Merge(sel1)
    end
    -- Select up to 1 Raisho
    local g2=Duel.GetMatchingGroup(s.recfilter_raisho,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
    if #g2>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local sel2=g2:Select(tp,0,1,nil)
        sg:Merge(sel2)
    end
    if #sg>0 then
        Duel.SendtoHand(sg,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,sg)
    end
end
