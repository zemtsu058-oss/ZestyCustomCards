-- ============================================================
-- Card Name: Tenshei
-- Passcode : 192300012
-- Type     : Trap / Counter
-- Archetype: Wezaemon (0x783)
-- ============================================================
-- Effect 1: If your LP are 2000 or less, you can activate this
--           card from your hand, also the activation and effect
--           of this card cannot be negated. When your opponent
--           activates a card or effect while you control
--           "Wezaemon the Tombguard": Negate that effect, and
--           if you do, banish all cards your opponent controls
--           in the same column as that card, then gain 800 LP
--           for each card banished by this effect.
-- Limit   : You can only activate 1 "Tenshei" per turn.
-- ============================================================

local s,id=GetID()

s.listed_names={192300001}

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Counter Trap: Negate + banish same column
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE+CATEGORY_RECOVER)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_CHAINING)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCondition(s.negcon)
    e1:SetTarget(s.negtg)
    e1:SetOperation(s.negop)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Hand activation when LP <= 2000 + cannot be negated
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_TRAP_ACT_IN_HAND)
    e2:SetCondition(s.handcon)
    c:RegisterEffect(e2)
    -- Cannot be negated when activated from hand (LP <= 2000)
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_CANNOT_DISABLE)
    e3:SetCondition(s.nonega_con)
    c:RegisterEffect(e3)
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetCode(EFFECT_CANNOT_INACTIVATE)
    e4:SetCondition(s.nonega_con)
    c:RegisterEffect(e4)
end

-- ============================================================
-- Hand activation condition — LP <= 2000
-- ============================================================
function s.handcon(e)
    return Duel.GetLP(e:GetHandlerPlayer())<=2000
end

-- ============================================================
-- Cannot negate condition — LP <= 2000
-- ============================================================
function s.nonega_con(e)
    return Duel.GetLP(e:GetHandlerPlayer())<=2000
end

-- ============================================================
-- Effect 1: Condition — Opponent activates + control Wezaemon
-- ============================================================
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    if ep==tp or not Duel.IsChainNegatable(ev) then return false end
    return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,192300001),tp,LOCATION_MZONE,0,1,nil)
end

-- ============================================================
-- Effect 1: Target — Standard negate check
-- ============================================================
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end

-- ============================================================
-- Effect 1: Operation — Negate + banish same column + gain LP
-- ============================================================
function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if not Duel.NegateEffect(ev) then return end
    -- Get the card whose effect was negated
    local rc=re:GetHandler()
    if not rc:IsOnField() then return end
    local seq=rc:GetSequence()
    local loc=rc:GetLocation()
    -- Find all cards opponent controls in the same column
    local bg=Group.CreateGroup()
    -- Check opponent's Monster Zones
    local mg=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
    for tc in mg:Iter() do
        if tc:GetSequence()==seq then
            bg:AddCard(tc)
        end
    end
    -- Check opponent's S/T Zones
    local sg=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_SZONE,nil)
    for tc in sg:Iter() do
        if tc:GetSequence()==seq then
            bg:AddCard(tc)
        end
    end
    -- Include the negated card itself if on field
    if rc:IsControler(1-tp) then
        bg:AddCard(rc)
    end
    -- Banish all found cards
    if #bg>0 then
        local ct=Duel.Remove(bg,POS_FACEUP,REASON_EFFECT)
        -- Gain 800 LP for each banished card
        if ct>0 then
            Duel.Recover(tp,ct*800,REASON_EFFECT)
        end
    end
end
