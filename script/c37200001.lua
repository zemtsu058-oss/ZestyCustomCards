-- ============================================================
-- Card Name: Exosister Nunctis
-- Passcode : 37200001
-- Type     : Monster / Xyz / Effect
-- Attribute: LIGHT
-- Rank     : 8
-- ATK      : 2800
-- DEF      : 2800
-- Race     : Warrior
-- Archetype: Exosister (0x174)
-- Materials: 2 Rank 4 "Exosister" Xyz Monsters
-- ============================================================
-- Effect 1: Once per turn, if a card(s) you control would be
--           destroyed, you can prevent that destruction instead.
-- Effect 2: Quick Effect: Detach 1 material; return 1 card from
--           your opponent's field or GY to the hand.
-- Effect 3: Quick Effect: Return this card and all Xyz Monsters
--           from your GY to the Extra Deck; Set 1 "Exosister"
--           Trap from your Deck (can activate this turn).
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- Must be Xyz Summoned
    c:EnableReviveLimit()
    Xyz.AddProcedure(c,s.xyzfilter,nil,2)

    -- Must be Xyz Summoned using the correct materials
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_SPSUMMON_CONDITION)
    e0:SetValue(s.splimit)
    c:RegisterEffect(e0)

    -- ============================================================
    -- Effect 1 — Continuous Protection: Destruction replacement
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_INDESTRUCTABLE_COUNT)
    e1:SetRange(LOCATION_MZONE)
    e1:SetTargetRange(LOCATION_ONFIELD,0)
    e1:SetTarget(s.indtg)
    e1:SetValue(s.indval)
    e1:SetCountLimit(1)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — Quick Effect: Detach 1 to bounce 1 opponent's card
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1)
    e2:SetCost(s.cost_detach)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)

    -- ============================================================
    -- Effect 3 — Quick Effect: Return to Extra & Set Trap
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1,id)
    e3:SetCost(s.spcost)
    e3:SetTarget(s.settg)
    e3:SetOperation(s.setop)
    c:RegisterEffect(e3)
end

s.listed_series={0x174}

-- ============================================================
-- Summon Procedure: Materials filter
-- ============================================================
function s.xyzfilter(c,xyz,sumtype,tp)
    return c:IsType(TYPE_XYZ,xyz,sumtype,tp) and c:IsSetCard(0x174,xyz,sumtype,tp) and c:IsRank(4)
end

function s.splimit(e,se,sp,st)
    return (st&SUMMON_TYPE_XYZ)==SUMMON_TYPE_XYZ and not se
end

-- ============================================================
-- Effect 1: Target — Filter protected cards
-- ============================================================
function s.indtg(e,c)
    return c:IsControler(e:GetHandlerPlayer()) and c:IsLocation(LOCATION_ONFIELD)
end

-- ============================================================
-- Effect 1: Value — Protect from battle and card effects
-- ============================================================
function s.indval(e,re,r,rp)
    return (r&REASON_BATTLE+REASON_EFFECT)~=0
end

-- ============================================================
-- Effect 2: Cost — Detach 1 material
-- ============================================================
function s.cost_detach(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
    e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

-- ============================================================
-- Effect 2: Filter — Valid bounce targets
-- ============================================================
function s.thfilter(c)
    return c:IsAbleToHand()
end

-- ============================================================
-- Effect 2: Target — Select 1 card to bounce
-- ============================================================
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsControler(1-tp) and (chkc:IsOnField() or chkc:IsLocation(LOCATION_GRAVE)) and s.thfilter(chkc) end
    if chk==0 then return Duel.IsExistingTarget(s.thfilter,tp,0,LOCATION_ONFIELD+LOCATION_GRAVE,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
    local g=Duel.SelectTarget(tp,s.thfilter,tp,0,LOCATION_ONFIELD+LOCATION_GRAVE,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end

-- ============================================================
-- Effect 2: Operation — Return targeted card to hand
-- ============================================================
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.SendtoHand(tc,nil,REASON_EFFECT)
    end
end

-- ============================================================
-- Effect 3: Filter — Valid Xyz monsters in GY
-- ============================================================
function s.xyzfilter_gy(c)
    return c:IsType(TYPE_XYZ)
end

-- ============================================================
-- Effect 3: Cost — Return this card & all Xyz from GY to Extra
-- ============================================================
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    local g=Duel.GetMatchingGroup(s.xyzfilter_gy,tp,LOCATION_GRAVE,0,nil)
    if chk==0 then
        return c:IsAbleToExtraAsCost()
            and #g>0
            and not g:IsExists(function(tc) return not tc:IsAbleToExtraAsCost() end,1,nil)
    end
    local tg=Group.FromCards(c)
    tg:Merge(g)
    Duel.SendtoDeck(tg,nil,SEQ_DECKTOP,REASON_COST)
end

-- ============================================================
-- Effect 3: Filter — Valid Exosister Traps in Deck
-- ============================================================
function s.setfilter(c)
    return c:IsSetCard(0x174) and c:IsType(TYPE_TRAP) and c:IsSSetable()
end

-- ============================================================
-- Effect 3: Target — Check if Set is possible
-- ============================================================
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil) end
end

-- ============================================================
-- Effect 3: Operation — Set 1 Trap from Deck (can activate turn)
-- ============================================================
function s.setop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
    local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
    local tc=g:GetFirst()
    if tc and Duel.SSet(tp,tc)>0 then
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
        e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e1)
    end
end
