-- ============================================================
-- Card Name: Ghost Ogre & Rabbit Spirit
-- Passcode  : 79900017
-- Type      : Monster / Tuner / Effect
-- Attribute : LIGHT
-- Race      : Psychic
-- ============================================================
-- Effect 1  : Opponent monster activates hand/field: Send self from hand/field to GY;
--             destroy that monster, if not destroyed opponent must send it to GY (HOPT).
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- Quick Effect: Send self to GY to destroy & force send
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DESTROY+CATEGORY_TOGRAVE)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_CHAINING)
    e1:SetRange(LOCATION_HAND+LOCATION_MZONE)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.condition)
    e1:SetCost(s.cost)
    e1:SetTarget(s.target)
    e1:SetOperation(s.operation)
    c:RegisterEffect(e1)
end

-- ============================================================
-- Condition: Opponent activates monster effect in hand or field
-- ============================================================
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    if rp==tp or not re:IsMonsterEffect() then return false end
    local loc=Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION)
    return (loc&LOCATION_HAND~=0) or (loc&LOCATION_ONFIELD~=0)
end

-- ============================================================
-- Cost: Send self to GY
-- ============================================================
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsAbleToGraveAsCost() end
    Duel.SendtoGrave(c,REASON_COST)
end

-- ============================================================
-- Target
-- ============================================================
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    local tc=re:GetHandler()
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,tc,1,0,0)
    Duel.SetPossibleOperationInfo(0,CATEGORY_TOGRAVE,tc,1,0,0)
end

-- ============================================================
-- Operation
-- ============================================================
function s.operation(e,tp,eg,ep,ev,re,r,rp)
    local tc=re:GetHandler()
    if tc and tc:IsRelateToEffect(re) then
        -- Attempt to destroy the monster
        if Duel.Destroy(tc,REASON_EFFECT)==0 then
            -- If not destroyed, opponent must send it to the GY (player-affecting bypasses immunity)
            Duel.SendtoGrave(tc,REASON_RULE,PLAYER_NONE,1-tp)
        end
    end
end
