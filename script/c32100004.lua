-- ============================================================
-- Card Name: Rikka Fleurness
-- Passcode  : 32100004
-- Type      : Trap / Counter
-- Archetype : Rikka (0x141)
-- ============================================================
-- Effect 1  : Negate opponent card/effect, Tribute that card.
--             If Tributed, Set 1 Rikka Normal Trap from Deck (can activate in Set turn).
-- Effect 2  : Can activate from hand. If so, for the rest of duel you can only
--             Special Summon if a Plant monster is on field/hand.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- Activate
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_NEGATE+CATEGORY_RELEASE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_CHAINING)
    e1:SetCondition(s.condition)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)

    -- Activate from hand
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_TRAP_ACT_IN_HAND)
    c:RegisterEffect(e2)
end

-- ============================================================
-- Activation Condition
-- ============================================================
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return rp~=tp and Duel.IsChainNegatable(ev)
end

-- ============================================================
-- Target
-- ============================================================
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    -- Check if activated from hand
    if e:GetHandler():IsStatus(STATUS_ACT_FROM_HAND) then
        e:SetLabel(1)
    else
        e:SetLabel(0)
    end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    if re:GetHandler():IsRelateToEffect(re) then
        Duel.SetOperationInfo(0,CATEGORY_RELEASE,eg,1,0,0)
    end
end

-- ============================================================
-- Operation & Restriction
-- ============================================================
function s.trapfilter(c)
    return c:IsSetCard(0x141) and c:IsNormalTrap() and c:IsSSetable()
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    
    -- Apply hand activation restriction
    if e:GetLabel()==1 then
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_FIELD)
        e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
        e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
        e1:SetDescription(aux.Stringid(id,1))
        e1:SetTargetRange(1,0)
        e1:SetTarget(s.splimit)
        Duel.RegisterEffect(e1,tp)
    end
    
    if Duel.NegateActivation(ev) then
        local tc=re:GetHandler()
        if tc and tc:IsRelateToEffect(re) then
            if Duel.Release(tc,REASON_EFFECT)>0 then
                -- Set 1 Rikka Normal Trap from Deck
                local g=Duel.GetMatchingGroup(s.trapfilter,tp,LOCATION_DECK,0,nil)
                if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
                    Duel.BreakEffect()
                    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
                    local sg=g:Select(tp,1,1,nil)
                    local sc=sg:GetFirst()
                    if sc then
                        Duel.SSet(tp,sc)
                        -- Can activate this turn
                        local e2=Effect.CreateEffect(c)
                        e2:SetType(EFFECT_TYPE_SINGLE)
                        e2:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
                        e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
                        sc:RegisterEffect(e2)
                    end
                end
            end
        end
    end
end

-- Special Summon Limit: can only Special Summon if a Plant monster is on field or hand
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
    local tp=e:GetHandlerPlayer()
    local has_plant=Duel.IsExistingMatchingCard(Card.IsRace,tp,LOCATION_MZONE+LOCATION_HAND,0,1,nil,RACE_PLANT)
    return not has_plant
end
