-- ============================================================
-- Card Name: Whispers of the White Forest
-- Passcode : 42600001
-- Type     : Spell / Quick-Play
-- Archetype: White Forest (0x1AA)
-- ============================================================
-- Effect 1: If you control a Spellcaster: Add 1 Spell from your Deck
--           or GY to your hand that mentions "White Forest" or "Sinful Spoils"
-- Effect 2: If a S/T is sent to GY by a monster effect: Banish this card
--           from GY, target 1 of those cards; Set it. If it is a Quick-Play
--           Spell or Trap and you control a "Diabell" or "White Forest"
--           monster, it can be activated this turn.
-- Effect 3: If this card is sent to the GY to activate a monster effect:
--           Set this card.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Activate: Search Spell mentioning White Forest / Sinful Spoils
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCondition(s.condition1)
    e1:SetTarget(s.target1)
    e1:SetOperation(s.operation1)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — GY trigger: When S/T sent by monster effect, banish to Set
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_LEAVE_GRAVE)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,id+1,EFFECT_COUNT_CODE_OATH)
    e2:SetCondition(s.condition2)
    e2:SetCost(s.cost2)
    e2:SetTarget(s.target2)
    e2:SetOperation(s.operation2)
    c:RegisterEffect(e2)

    -- ============================================================
    -- Effect 3 — GY trigger: Self-Set when sent as cost for monster effect
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_TO_GRAVE)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCountLimit(1,id+2,EFFECT_COUNT_CODE_OATH)
    e3:SetCondition(s.condition3)
    e3:SetTarget(s.target3)
    e3:SetOperation(s.operation3)
    c:RegisterEffect(e3)
end

-- ============================================================
-- Effect 1: Filter — Spell (incl. Field) mentioning White Forest / Sinful Spoils
-- ============================================================
function s.filter1(c)
    return c:IsType(TYPE_SPELL)
        and (c:IsSetCard(0x1aa) or c:IsSetCard(0x204))
        and c:IsAbleToHand()
end

-- ============================================================
-- Effect 1: Condition — Must control a Spellcaster
-- ============================================================
function s.condition1(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(Card.IsRace,tp,LOCATION_MZONE,0,1,nil,RACE_SPELLCASTER)
end

-- ============================================================
-- Effect 1: Target — Check for valid cards in Deck or GY
-- ============================================================
function s.target1(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.filter1,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

-- ============================================================
-- Effect 1: Operation — Select and add to hand
-- ============================================================
function s.operation1(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.filter1,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end

-- ============================================================
-- Effect 2: Filter — Diabell or White Forest monster on your field
-- ============================================================
function s.filter_diabell_wf(c)
    return c:IsFaceup() and (c:IsSetCard(0x203) or c:IsSetCard(0x1aa))
end

-- ============================================================
-- Effect 2: Filter — S/T cards still in GY from the event group
-- ============================================================
function s.filter2(c)
    return c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsLocation(LOCATION_GRAVE)
end

-- ============================================================
-- Effect 2: Condition — S/T sent to GY by a monster effect
-- ============================================================
function s.condition2(e,tp,eg,ep,ev,re,r,rp)
    if not re or not re:IsActiveType(TYPE_MONSTER) then return false end
    return eg:IsExists(s.filter2,1,nil)
end

-- ============================================================
-- Effect 2: Cost — Banish this card from GY
-- ============================================================
function s.cost2(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsAbleToRemoveAsCost() end
    Duel.Remove(c,POS_FACEUP,REASON_COST)
end

-- ============================================================
-- Effect 2: Target — Select 1 S/T from the event group to Set
-- ============================================================
function s.target2(e,tp,eg,ep,ev,re,r,rp,chk)
    local g=eg:Filter(s.filter2,nil)
    if chk==0 then return #g>0 and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local sg=g:Select(tp,1,1,nil)
    Duel.SetTargetCard(sg)
    Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,sg,1,0,0)
end

-- ============================================================
-- Effect 2: Operation — Set targeted S/T; grant activation this turn if eligible
-- ============================================================
function s.operation2(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if not tc or not tc:IsRelateToEffect(e) then return end
    if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
    if Duel.SSet(tp,tc)<=0 then return end
    if (tc:IsType(TYPE_QUICKPLAY) or tc:IsType(TYPE_TRAP))
        and Duel.IsExistingMatchingCard(s.filter_diabell_wf,tp,LOCATION_MZONE,0,1,nil) then
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        if tc:IsType(TYPE_QUICKPLAY) then
            e1:SetCode(EFFECT_QP_ACT_IN_SET_TURN)
        else
            e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
        end
        tc:RegisterEffect(e1)
    end
end

-- ============================================================
-- Effect 3: Condition — Sent to GY as cost for a monster effect
-- ============================================================
function s.condition3(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsReason(REASON_COST) then return false end
    local re_cost=c:GetReasonEffect()
    return re_cost and re_cost:IsActiveType(TYPE_MONSTER)
end

-- ============================================================
-- Effect 3: Target — Check if this card can be set
-- ============================================================
function s.target3(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsSSetable()
        and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 end
    Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,e:GetHandler(),1,0,0)
end

-- ============================================================
-- Effect 3: Operation — Set this card from GY
-- ============================================================
function s.operation3(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
        Duel.SSet(tp,c)
    end
end
