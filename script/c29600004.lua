-- ============================================================
-- Card Name: Verre Magic Mastery
-- Passcode : 29600004
-- Type     : Trap / Counter
-- Archetype: Witchcrafter (0x128) & Magistus (0x152)
-- ============================================================
-- Effect 1: When a monster effect is activated, while you control
--           a LIGHT Spellcaster monster with 2800 DEF: Negate the
--           activation, then take control of that monster (if it
--           was on the field), and if you do, its Type becomes
--           Spellcaster, then immediately after this effect resolves,
--           Fusion Summon 1 monster, using monsters you control as materials.
-- Effect 2: During the Main Phase, while this card is in your GY:
--           You can banish this card; add 1 "Verre Magic" card from
--           your Deck to your hand, except "Verre Magic Mastery".
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- This card is always treated as a "Witchcrafter" and "Magistus" card
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_ADD_SETCODE)
    e0:SetValue(0x128)
    c:RegisterEffect(e0)
    local e1=e0:Clone()
    e1:SetValue(0x152)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 1 — Negate + Control + Fusion Summon
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_NEGATE+CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_ACTIVATE)
    e2:SetCode(EVENT_CHAINING)
    e2:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e2:SetCondition(s.con_neg)
    e2:SetTarget(s.tg_neg)
    e2:SetOperation(s.op_neg)
    c:RegisterEffect(e2)

    -- ============================================================
    -- Effect 2 — GY search
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetRange(LOCATION_GRAVE)
    e3:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e3:SetCondition(s.con_search)
    e3:SetCost(s.cost_search)
    e3:SetTarget(s.tg_search)
    e3:SetOperation(s.op_search)
    e3:SetHintTiming(0,TIMING_MAIN_END)
    c:RegisterEffect(e3)
end

-- ============================================================
-- Effect 1: Filter — Verre control check (LIGHT Spellcaster 2800 DEF)
-- ============================================================
function s.filter_verre(c)
    return c:IsFaceup() and c:IsAttribute(ATTRIBUTE_LIGHT)
        and c:IsRace(RACE_SPELLCASTER) and c:IsDefense(2800)
end

-- ============================================================
-- Effect 1: Filter — Fusion monster check
-- ============================================================
function s.filter_fusion(c,e,tp,mg)
    return c:IsType(TYPE_FUSION)
        and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
        and c:CheckFusionMaterial(mg,nil,tp)
end

-- ============================================================
-- Effect 1: Condition — Control Verre & monster effect activates
-- ============================================================
function s.con_neg(e,tp,eg,ep,ev,re,r,rp)
    if not (re:IsActiveType(TYPE_MONSTER) and Duel.IsChainNegatable(ev)) then return false end
    return Duel.IsExistingMatchingCard(s.filter_verre,tp,LOCATION_MZONE,0,1,nil)
end

-- ============================================================
-- Effect 1: Target — Negate activation
-- ============================================================
function s.tg_neg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end

-- ============================================================
-- Effect 1: Operation — Negate, control, and Fusion Summon
-- ============================================================
function s.op_neg(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) then
        local rc=re:GetHandler()
        if rc:IsRelateToEffect(re) and rc:IsOnField()
            and rc:IsControler(1-tp) and rc:IsControlerCanBeChanged() then
            if Duel.GetControl(rc,tp) then
                -- Type becomes Spellcaster
                local e1=Effect.CreateEffect(e:GetHandler())
                e1:SetType(EFFECT_TYPE_SINGLE)
                e1:SetCode(EFFECT_CHANGE_RACE)
                e1:SetValue(RACE_SPELLCASTER)
                e1:SetReset(RESET_EVENT+RESETS_STANDARD)
                rc:RegisterEffect(e1)
            end
        end
        -- Immediately after this resolves, Fusion Summon (Mandatory)
        local mg=Duel.GetMatchingGroup(Card.IsCanBeFusionMaterial,tp,LOCATION_MZONE,0,nil)
        if Duel.IsExistingMatchingCard(s.filter_fusion,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg) then
            Duel.BreakEffect()
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
            local sg=Duel.SelectMatchingCard(tp,s.filter_fusion,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mg)
            local sc=sg:GetFirst()
            if sc then
                Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
                local mat=Duel.SelectFusionMaterial(tp,sc,mg,nil,tp)
                sc:SetMaterial(mat)
                Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
                Duel.BreakEffect()
                Duel.SpecialSummon(sc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
                sc:CompleteProcedure()
            end
        end
    end
end

-- ============================================================
-- Effect 2: Filter — Verre Magic card to search
-- ============================================================
function s.filter_search_target(c)
    -- Verre Magic cards except itself (transformation, sleep time, lacrima)
    return c:IsCode(22121392, 79846799, 73664385) and c:IsAbleToHand()
end

-- ============================================================
-- Effect 2: Condition — During the Main Phase
-- ============================================================
function s.con_search(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsMainPhase()
end

-- ============================================================
-- Effect 2: Cost — Banish itself from GY
-- ============================================================
function s.cost_search(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsAbleToRemoveAsCost() end
    Duel.Remove(c,POS_FACEUP,REASON_COST)
end

-- ============================================================
-- Effect 2: Target — Check if target in Deck
-- ============================================================
function s.tg_search(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.filter_search_target,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

-- ============================================================
-- Effect 2: Operation — Add search target to hand
-- ============================================================
function s.op_search(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.filter_search_target,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
    end
end
