-- ============================================================
-- Card Name: Battle Machine - Kirin
-- Passcode : 192300010
-- Type     : Trap / Continuous
-- Archetype: Wezaemon (0x783)
-- ============================================================
-- Effect 1: You can pay 800 LP: Special Summon this card as a
--           Normal Monster (Machine/LIGHT/Level 6/ATK 1600/
--           DEF 2400). (This card is also still a Trap.) Then,
--           if you control "Wezaemon the Tombguard", you can
--           target 1 face-up card your opponent controls;
--           negate its effects.
-- Effect 2: You can banish this card from your GY; Set 1 Trap
--           that mentions "Wezaemon the Tombguard" directly
--           from your Deck, except "Battle Machine - Kirin".
--           You can only use this effect of "Battle Machine -
--           Kirin" once per turn.
-- Control: You can only control 1 "Battle Machine - Kirin".
-- ============================================================

local s,id=GetID()

s.listed_names={192300001}

function s.initial_effect(c)
    -- ============================================================
    -- Control limit: only 1 "Battle Machine - Kirin"
    -- ============================================================
    c:SetUniqueOnField(1,0,id)

    -- ============================================================
    -- Effect 1 — Activation: Trap Monster + optional negate
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DISABLE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCost(s.cost_lp)
    e1:SetTarget(s.tg_trapmon)
    e1:SetOperation(s.op_trapmon)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — GY: Banish to Set a Trap (GIỮ NGUYÊN QUICK_O)
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetType(EFFECT_TYPE_QUICK_O) -- Giữ nguyên Quick Effect như cũ theo ý bạn
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
    e2:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e2:SetCost(s.cost_banish)
    e2:SetTarget(s.tg_set_trap)
    e2:SetOperation(s.op_set_trap)
    c:RegisterEffect(e2)
end

-- ============================================================
-- Cost — Pay 800 LP
-- ============================================================
function s.cost_lp(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.CheckLPCost(tp,800) end
    Duel.PayLPCost(tp,800)
end

-- ============================================================
-- Effect 1: Target — Check zone available
-- ============================================================
function s.tg_trapmon(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,tp,0)
end

-- ============================================================
-- Effect 1: Operation — Become Trap Monster + optional negate
-- ============================================================
function s.op_trapmon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    -- Special Summon as monster (still a Trap)
    if not Duel.MoveToField(c,tp,tp,LOCATION_MZONE,POS_FACEUP,true) then return end
    -- Set monster stats
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_CHANGE_TYPE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e1:SetValue(TYPE_TRAP+TYPE_CONTINUOUS+TYPE_MONSTER+TYPE_NORMAL)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    c:RegisterEffect(e1)
    -- Set Race
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_CHANGE_RACE)
    e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e2:SetValue(RACE_MACHINE)
    e2:SetReset(RESET_EVENT+RESETS_STANDARD)
    c:RegisterEffect(e2)
    -- Set Attribute
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_SINGLE)
    e3:SetCode(EFFECT_CHANGE_ATTRIBUTE)
    e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e3:SetValue(ATTRIBUTE_LIGHT)
    e3:SetReset(RESET_EVENT+RESETS_STANDARD)
    c:RegisterEffect(e3)
    -- Set Level
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_SINGLE)
    e4:SetCode(EFFECT_CHANGE_LEVEL)
    e4:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e4:SetValue(6)
    e4:SetReset(RESET_EVENT+RESETS_STANDARD)
    c:RegisterEffect(e4)
    -- Set ATK
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_SINGLE)
    e5:SetCode(EFFECT_SET_BASE_ATTACK)
    e5:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e5:SetValue(1600)
    e5:SetReset(RESET_EVENT+RESETS_STANDARD)
    c:RegisterEffect(e5)
    -- Set DEF
    local e6=Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_SINGLE)
    e6:SetCode(EFFECT_SET_BASE_DEFENSE)
    e6:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e6:SetValue(2400)
    e6:SetReset(RESET_EVENT+RESETS_STANDARD)
    c:RegisterEffect(e6)
    -- Then, if you control Wezaemon: optional negate
    if Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,192300001),tp,LOCATION_MZONE,0,1,nil)
        and Duel.IsExistingTarget(s.negfilter,tp,0,LOCATION_ONFIELD,1,nil) then
        if Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
            local g=Duel.SelectTarget(tp,s.negfilter,tp,0,LOCATION_ONFIELD,1,1,nil)
            if #g>0 then
                local tc=g:GetFirst()
                if tc:IsRelateToEffect(e) and tc:IsFaceup() then
                    Duel.NegateRelatedChain(tc,RESET_TURN_SET)
                    local ne=Effect.CreateEffect(c)
                    ne:SetType(EFFECT_TYPE_SINGLE)
                    ne:SetCode(EFFECT_DISABLE)
                    ne:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
                    tc:RegisterEffect(ne)
                    local ne2=Effect.CreateEffect(c)
                    ne2:SetType(EFFECT_TYPE_SINGLE)
                    ne2:SetCode(EFFECT_DISABLE_EFFECT)
                    ne2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
                    tc:RegisterEffect(ne2)
                end
            end
        end
    end
end
function s.negfilter(c)
    return c:IsFaceup()
end

-- ============================================================
-- Effect 2: Cost — Banish from GY
-- ============================================================
function s.cost_banish(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsAbleToRemoveAsCost() end
    Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end

-- ============================================================
-- Effect 2: Filter — Trap mentioning Wezaemon, except this card
-- ============================================================
function s.settrapfilter(c)
    return c:IsType(TYPE_TRAP) and c:ListsCode(192300001) and not c:IsCode(id) and c:IsSSetable()
end

-- ============================================================
-- Effect 2: Target — Check valid trap exists
-- ============================================================
function s.tg_set_trap(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.settrapfilter,tp,LOCATION_DECK,0,1,nil)
    end
end

-- ============================================================
-- Effect 2: Operation — Set trap from Deck (ĐÃ FIX KHÔNG CHO ACTIVATE)
-- ============================================================
function s.op_set_trap(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local g=Duel.SelectMatchingCard(tp,s.settrapfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        local tc=g:GetFirst()
        Duel.SSet(tp,tc)
        -- Đã loại bỏ hoàn toàn block e1 (EFFECT_TRAP_ACT_IN_SET_TURN)
    end
end
