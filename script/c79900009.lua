-- ============================================================
-- Card Name: Chambermaid of the Silver Castle
-- Passcode : 79900009
-- Type     : Monster / Effect
-- Attribute: DARK
-- Level    : 8
-- ATK/DEF  : 3000 / 2500
-- Race     : Fiend
-- Archetype: Labrynth (0x17f)
-- ============================================================
-- Effect 1 [QUICK / HOPT]: When your opponent activates a card
--           or effect in response to the activation of your
--           "Labrynth" card or Normal Trap (Quick Effect):
--           You can send this card from your hand to the GY;
--           negate that effect.
-- Effect 2 [TRIGGER / HOPT]: When the effect of a "Labrynth"
--           monster is activated while this card is in your
--           hand or GY: You can Special Summon this card in
--           Defense Position.
-- Effect 3 [CONTINUOUS]: While this card is in Defense
--           Position, Set cards you control cannot be
--           destroyed by card effects.
-- ============================================================

local s,id=GetID()
s.listed_series={0x17f}

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Quick Effect: Negate opponent response to Labrynth/Normal Trap
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_NEGATE)
    e1:SetType(EFFECT_TYPE_QUICK_O)        -- Quick Effect, can be activated on opponent's turn
    e1:SetCode(EVENT_CHAINING)             -- Fires when a new chain link is being added
    e1:SetRange(LOCATION_HAND)             -- Must be in hand to activate
    e1:SetCountLimit(1,id)  -- Separate HOPT per effect
    e1:SetCondition(s.negcon)
    e1:SetCost(s.negcost)
    e1:SetTarget(s.negtg)
    e1:SetOperation(s.negop)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — Trigger: Special Summon self when a Labrynth monster effect activates
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_QUICK_O)        -- Quick Effect, responds to event activation
    e2:SetCode(EVENT_CHAINING)             -- Fires when a chain link is being added
    e2:SetRange(LOCATION_HAND+LOCATION_GRAVE)  -- Can activate from hand or GY
    e2:SetCountLimit(1,{id,1})  -- Separate HOPT (different index)
    e2:SetCondition(s.spcon)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)

    -- ============================================================
    -- Effect 3 — Continuous Field: Protect Set cards while in Defense Position
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    -- No description needed for continuous protection effects
    e3:SetType(EFFECT_TYPE_FIELD)          -- Always-on field effect
    e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e3:SetRange(LOCATION_MZONE)            -- This card must be on the Monster Zone
    e3:SetTargetRange(LOCATION_MZONE+LOCATION_SZONE,0)  -- Protects cards on controller's side
    e3:SetCondition(s.defcon)
    e3:SetTarget(aux.TargetBoolFunction(Card.IsFacedown))
    e3:SetValue(1)                         -- Cannot be destroyed by card effects
    c:RegisterEffect(e3)
end

-- ============================================================
-- Effect 1: Condition — Opponent is chaining into controller's Labrynth or Normal Trap
-- ============================================================
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    -- ev = current chain link index (the opponent's effect being added)
    -- ev-1 = the chain link being responded to (must be ours)
    if ev<=1 or rp==tp or not Duel.IsChainNegatable(ev) then return false end
    local trigger_re=Duel.GetChainInfo(ev-1,CHAININFO_TRIGGERING_EFFECT)
    if not trigger_re then return false end
    local trig_card=trigger_re:GetHandler()
    local trig_tp=Duel.GetChainInfo(ev-1,CHAININFO_TRIGGERING_PLAYER)
    -- The effect being responded to must belong to the controller
    if trig_tp~=tp then return false end
    -- Must be a Labrynth card/effect OR a Normal Trap activation
    local is_labrynth_card=trig_card:IsSetCard(0x17f)
    local is_normal_trap=(trigger_re:GetType()&EFFECT_TYPE_ACTIVATE)~=0
        and trig_card:IsType(TYPE_TRAP) and trig_card:IsType(TYPE_NORMAL)
    return is_labrynth_card or is_normal_trap
end

-- ============================================================
-- Effect 1: Cost — Send this card from hand to GY
-- ============================================================
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsAbleToGrave() end  -- Can it be sent to GY?
    Duel.SendtoGrave(c,REASON_COST)               -- Pay cost
end

-- ============================================================
-- Effect 1: Target — Declare negate operation info
-- ============================================================
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,nil,0,0,0)
end

-- ============================================================
-- Effect 1: Operation — Negate the chained effect at chain link ev
-- ============================================================
function s.negop(e,tp,eg,ep,ev,re,r,rp)
    Duel.NegateEffect(ev)
end

-- ============================================================
-- Effect 2: Condition — A Labrynth monster effect is being activated
-- ============================================================
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    -- re = the effect currently being added to the chain
    if not re then return false end
    local trig_card=re:GetHandler()
    -- Must be a Labrynth monster (any controller)
    return trig_card:IsSetCard(0x17f) and trig_card:IsType(TYPE_MONSTER)
end

-- ============================================================
-- Effect 2: Target — Check if Special Summon is possible
-- ============================================================
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

-- ============================================================
-- Effect 2: Operation — Special Summon this card in Defense Position
-- ============================================================
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then  -- Guard: card must still be in hand/GY
        Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
    end
end

-- ============================================================
-- Effect 3: Condition — This card must be in Defense Position
-- ============================================================
function s.defcon(e)
    return e:GetHandler():IsPosition(POS_FACEUP_DEFENSE)
end
