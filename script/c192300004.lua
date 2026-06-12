-- ============================================================
-- Card Name: Challenge to Tombguard
-- Passcode : 192300004
-- Type     : Spell / Normal
-- Archetype: Wezaemon (0x783)
-- ============================================================
-- Effect 1: Add 1 "Wezaemon the Tombguard" or 1 Spell/Trap
--           that mentions it from your Deck to your hand. This
--           effect cannot be negated if you control no monsters.
--           For the rest of this turn, you cannot activate
--           monster effects on the field or in the GY, except
--           "Wezaemon the Tombguard" or monsters that mention
--           it. You can only activate 1 "Challenge to Tombguard"
--           per turn.
-- ============================================================

local s,id=GetID()

s.listed_names={192300001}

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Activation: Search Wezaemon or mentioning Spell/Trap
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetTarget(s.tg_search)
    e1:SetOperation(s.op_search)
    c:RegisterEffect(e1)
end

-- ============================================================
-- Effect 1: Filter — Wezaemon or Spell/Trap that mentions it
-- ============================================================
function s.filter_search(c)
    return (c:IsCode(192300001) or (c:IsType(TYPE_SPELL+TYPE_TRAP) and c:ListsCode(192300001)))
        and c:IsAbleToHand()
end

-- ============================================================
-- Effect 1: Target — Check if a valid search target exists
-- ============================================================
function s.tg_search(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.filter_search,tp,LOCATION_DECK,0,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
    -- Cannot be negated if you control no monsters
    if Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0 then
        e:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
        e:GetHandler():RegisterFlagEffect(id,RESET_CHAIN,0,0)
    end
end

-- ============================================================
-- Effect 1: Operation — Search + apply monster effect lock
-- ============================================================
function s.op_search(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.filter_search,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
    -- Restriction: Cannot activate monster effects on field/GY except Wezaemon or monsters that mention it
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_CANNOT_ACTIVATE)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e1:SetTargetRange(1,0)
    e1:SetValue(s.aclimit)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)
end

-- ============================================================
-- Effect 1: Activation limit filter
-- ============================================================
function s.aclimit(e,re,tp)
    local rc=re:GetHandler()
    if not rc:IsType(TYPE_MONSTER) then return false end
    if not (rc:IsLocation(LOCATION_MZONE) or rc:IsLocation(LOCATION_GRAVE)) then return false end
    if rc:IsCode(192300001) then return false end
    if rc:ListsCode(192300001) then return false end
    return true
end
