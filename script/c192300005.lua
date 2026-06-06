-- ============================================================
-- Card Name: The End of Greatest Warrior
-- Passcode : 192300005
-- Type     : Spell / Field
-- Archetype: Wezaemon (0x783)
-- ============================================================
-- Effect 1: When this card is activated: You can activate 1 of
--           these effects.
--           ● If you control no "Wezaemon the Tombguard":
--             Special Summon 1 "Wezaemon the Tombguard" from
--             your Deck.
--           ● If you control "Wezaemon the Tombguard": Set 1
--             Spell/Trap that mentions "Wezaemon the Tombguard"
--             directly from your Deck. It can be activated this
--             turn.
--           For the rest of this turn after this effect
--           resolves, you cannot activate monster effects on
--           the field or in the GY, except "Wezaemon the
--           Tombguard" or monsters that mention it.
-- Effect 2: If a "Wezaemon the Tombguard" you control leaves
--           the field: You can pay 800 LP and banish this card
--           from your GY; add 1 "Wezaemon the Tombguard" from
--           your Deck or GY to your hand. You can only use
--           each effect of "The End of Greatest Warrior" once
--           per turn.
-- ============================================================

local s,id=GetID()

s.listed_names={192300001}

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Field Spell activation: SS Wezaemon or Set S/T
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetTarget(s.tg_activate)
    e1:SetOperation(s.op_activate)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — GY: When Wezaemon leaves field, add from Deck/GY
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_LEAVE_FIELD)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,{id,1},EFFECT_COUNT_CODE_OATH)
    e2:SetCondition(s.leavcon)
    e2:SetCost(s.leavcost)
    e2:SetTarget(s.tg_add)
    e2:SetOperation(s.op_add)
    c:RegisterEffect(e2)
end

-- ============================================================
-- Effect 1: Target — Check if either option is available
-- ============================================================
function s.tg_activate(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        -- Option 1: No Wezaemon → SS from Deck
        local opt1=not Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,192300001),tp,LOCATION_MZONE,0,1,nil)
            and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp)
        -- Option 2: Has Wezaemon → Set mentioning S/T from Deck
        local opt2=Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,192300001),tp,LOCATION_MZONE,0,1,nil)
            and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil)
        return opt1 or opt2
    end
end

-- ============================================================
-- Effect 1: Filters
-- ============================================================
function s.spfilter(c,e,tp)
    return c:IsCode(192300001) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.mentionfilter(c)
    return c:IsType(TYPE_SPELL+TYPE_TRAP) and c:ListsCode(192300001)
end
function s.setfilter(c)
    return s.mentionfilter(c) and c:IsSSetable()
end

-- ============================================================
-- Effect 1: Operation — Choose and execute
-- ============================================================
function s.op_activate(e,tp,eg,ep,ev,re,r,rp)
    -- Check available options
    local haswe=Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,192300001),tp,LOCATION_MZONE,0,1,nil)
    local opt1=not haswe
        and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp)
    local opt2=haswe
        and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil)
    local sel=0
    if opt1 and opt2 then
        sel=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))
    elseif opt1 then
        sel=0
    elseif opt2 then
        sel=1
    else
        -- Apply restriction anyway
        s.apply_restriction(e,tp)
        return
    end
    if sel==0 then
        -- Option 1: SS Wezaemon from Deck
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
        if #g>0 then
            Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
        end
    else
        -- Option 2: Set mentioning S/T from Deck
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
        local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
        if #g>0 then
            local tc=g:GetFirst()
            Duel.SSet(tp,tc)
            -- Allow activation this turn
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
            e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
            tc:RegisterEffect(e1)
        end
    end
    -- Apply restriction
    s.apply_restriction(e,tp)
end

-- ============================================================
-- Apply monster effect restriction
-- ============================================================
function s.apply_restriction(e,tp)
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_CANNOT_ACTIVATE)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e1:SetTargetRange(1,0)
    e1:SetValue(s.aclimit)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
end
function s.aclimit(e,re,tp)
    local rc=re:GetHandler()
    if not rc:IsType(TYPE_MONSTER) then return false end
    if not (rc:IsLocation(LOCATION_MZONE) or rc:IsLocation(LOCATION_GRAVE)) then return false end
    if rc:IsCode(192300001) then return false end
    if rc:ListsCode(192300001) then return false end
    return true
end

-- ============================================================
-- Effect 2: Condition — Wezaemon you controlled left the field
-- ============================================================
function s.leavcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.leavfilter,1,nil,tp)
end
function s.leavfilter(c,tp)
    return c:IsCode(192300001) and c:IsPreviousControler(tp) and c:IsPreviousLocation(LOCATION_MZONE)
end

-- ============================================================
-- Effect 2: Cost — Pay 800 LP + banish this card from GY
-- ============================================================
function s.leavcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.CheckLPCost(tp,800) and e:GetHandler():IsAbleToRemoveAsCost() end
    Duel.PayLPCost(tp,800)
    Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end

-- ============================================================
-- Effect 2: Filter — Wezaemon in Deck or GY
-- ============================================================
function s.addfilter(c)
    return c:IsCode(192300001) and c:IsAbleToHand()
end

-- ============================================================
-- Effect 2: Target — Check Wezaemon exists in Deck or GY
-- ============================================================
function s.tg_add(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.addfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

-- ============================================================
-- Effect 2: Operation — Add Wezaemon from Deck/GY to hand
-- ============================================================
function s.op_add(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.addfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end
