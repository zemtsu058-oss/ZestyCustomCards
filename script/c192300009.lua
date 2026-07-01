-- ============================================================
-- Card Name: Ohshike
-- Passcode : 192300009
-- Type     : Spell / Quick-Play
-- Archetype: Wezaemon (0x783)
-- ============================================================
-- Effect 1: If your LP are 4000 or less, you can activate this
--           card from your hand during your opponent's turn.
--           When your opponent activates a card or effect that
--           targets a card(s) you control, while you control
--           "Wezaemon the Tombguard": You can pay 800 LP;
--           negate the activation, and if you do, destroy that
--           card.
-- Effect 2: You can banish this card from your GY; add 1
--           "Wezaemon the Tombguard" from your GY to your
--           hand, then you can Special Summon 1 Zombie monster
--           from your hand. If you do, for the rest of this
--           turn, you cannot activate monster effects on the
--           field or in the GY, except "Wezaemon the Tombguard"
--           or monsters that mention it. You can only use each
--           effect of "Ohshike" once per turn.
-- ============================================================

local s,id=GetID()

s.listed_names={192300001}

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Counter: Negate targeting activation + destroy
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_CHAINING)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCondition(s.negcon)
    e1:SetCost(s.negcost)
    e1:SetTarget(s.negtg)
    e1:SetOperation(s.negop)
    c:RegisterEffect(e1)
    -- Hand activation condition (LP <= 4000, opponent's turn)
    local e1b=Effect.CreateEffect(c)
    e1b:SetType(EFFECT_TYPE_SINGLE)
    e1b:SetCode(EFFECT_QP_ACT_IN_NTPHAND)
    e1b:SetCondition(s.handcon)
    c:RegisterEffect(e1b)

    -- ============================================================
    -- Effect 2 — GY: Banish to add Wezaemon + SS Zombie from hand
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON)
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
-- Effect 1: Hand activation condition — LP <= 4000
-- ============================================================
function s.handcon(e)
    return Duel.GetLP(e:GetHandlerPlayer())<=4000
end

-- ============================================================
-- Effect 1: Condition — Opponent activates targeting effect + control Wezaemon
-- ============================================================
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    if ep==tp or not Duel.IsChainNegatable(ev) then return false end
    -- Must control Wezaemon
    if not Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,192300001),tp,LOCATION_MZONE,0,1,nil) then return false end
    -- The activating card/effect must target a card you control
    local ex,tg,tc=Duel.GetOperationInfo(ev,CATEGORY_DESTROY)
    -- Check if the effect has targets
    local cg=Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS)
    if not cg or #cg==0 then return false end
    return cg:IsExists(Card.IsControler,1,nil,tp)
end

-- ============================================================
-- Effect 1: Cost — Pay 800 LP
-- ============================================================
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.CheckLPCost(tp,800) end
    Duel.PayLPCost(tp,800)
end

-- ============================================================
-- Effect 1: Target — Check negate legality
-- ============================================================
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    local rc=re:GetHandler()
    if rc:IsDestructable() and rc:IsRelateToEffect(re) then
        Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
    end
end

-- ============================================================
-- Effect 1: Operation — Negate + destroy
-- ============================================================
function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) then
        local rc=re:GetHandler()
        if rc:IsRelateToEffect(re) then
            Duel.Destroy(rc,REASON_EFFECT)
        end
    end
end

-- ============================================================
-- Effect 2: Cost — Banish from GY
-- ============================================================
function s.cost_banish(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsAbleToRemoveAsCost() end
    Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end

-- ============================================================
-- Effect 2: Filter — Wezaemon in GY
-- ============================================================
function s.wefilter(c)
    return c:IsCode(192300001) and c:IsAbleToHand()
end

-- ============================================================
-- Effect 2: Target — Check Wezaemon exists in GY
-- ============================================================
function s.tg_recover(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.wefilter,tp,LOCATION_GRAVE,0,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end

-- ============================================================
-- Effect 2: Operation — Add Wezaemon + optional SS Zombie
-- ============================================================
function s.op_recover(e,tp,eg,ep,ev,re,r,rp)
    -- Add Wezaemon from GY to hand
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.wefilter,tp,LOCATION_GRAVE,0,1,1,nil)
    if #g==0 then return end
    Duel.SendtoHand(g,nil,REASON_EFFECT)
    Duel.ConfirmCards(1-tp,g)
    -- Then, optionally SS 1 Zombie from hand
    if Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND,0,1,nil,e,tp) then
        if Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
            local sg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp)
            if #sg>0 then
                Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
                -- Apply monster effect restriction
                local e1=Effect.CreateEffect(e:GetHandler())
                e1:SetType(EFFECT_TYPE_FIELD)
                e1:SetCode(EFFECT_CANNOT_ACTIVATE)
                e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
                e1:SetTargetRange(1,0)
                e1:SetValue(s.aclimit)
                e1:SetReset(RESET_PHASE+PHASE_END)
                Duel.RegisterEffect(e1,tp)
            end
        end
    end
end
function s.spfilter(c,e,tp)
    return c:IsRace(RACE_ZOMBIE) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- ============================================================
-- Activation limit filter — Only Wezaemon or monsters that mention it
-- ============================================================
function s.aclimit(e,re,tp)
    local rc=re:GetHandler()
    if not rc:IsType(TYPE_MONSTER) then return false end
    if not (rc:IsLocation(LOCATION_MZONE) or rc:IsLocation(LOCATION_GRAVE)) then return false end
    if rc:IsCode(192300001) then return false end
    if rc:ListsCode(192300001) then return false end
    return true
end
