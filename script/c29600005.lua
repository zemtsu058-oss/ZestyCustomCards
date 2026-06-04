-- ============================================================
-- Card Name: Witchcrafter Garden
-- Passcode : 29600005
-- Type     : Spell / Continuous
-- Archetype: Witchcrafter (0x128)
-- ============================================================
-- Effect 1: On activation: Search 1 Level 4 or lower "Witchcrafter"
--           monster, or 1 "Witchcrafter" Trap if you control a
--           "Witchcrafter" monster.
-- Effect 2: "Witchcrafter" monster cost replacement (send this
--           card to the GY instead).
-- Effect 3: During your End Phase, if you control a "Witchcrafter"
--           monster: Place this card from your GY face-up in
--           your Spell & Trap Zone.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — On activation: Search 1 Witchcrafter card
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — Replace discard cost (Shared HOPT: id+1)
    -- ============================================================
    local e2=Witchcrafter.CreateCostReplaceEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetRange(LOCATION_SZONE)
    e2:SetCountLimit(1,id+1)
    e2:SetCondition(function(base) return base:GetHandler():IsAbleToGraveAsCost() end)
    e2:SetOperation(function(base) Duel.SendtoGrave(base:GetHandler(),REASON_COST) end)
    c:RegisterEffect(e2)

    -- ============================================================
    -- Effect 3 — Place from GY to Spell/Trap Zone (Shared HOPT: id+1)
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e3:SetRange(LOCATION_GRAVE)
    e3:SetCode(EVENT_PHASE+PHASE_END)
    e3:SetCountLimit(1,id+1)
    e3:SetCondition(s.tfcond)
    e3:SetTarget(s.tftg)
    e3:SetOperation(s.tfop)
    c:RegisterEffect(e3)
end

s.listed_series={0x128}

-- ============================================================
-- Effect 1: Filter — Valid Witchcrafter monsters
-- ============================================================
function s.thfilter1(c)
    return c:IsSetCard(0x128) and c:IsType(TYPE_MONSTER) and c:IsLevelBelow(4) and c:IsAbleToHand()
end

-- ============================================================
-- Effect 1: Filter — Valid Witchcrafter Traps
-- ============================================================
function s.thfilter2(c)
    return c:IsSetCard(0x128) and c:IsType(TYPE_TRAP) and c:IsAbleToHand()
end

-- ============================================================
-- Effect 1: Target — Check if search is possible
-- ============================================================
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    local ctrl=Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,0x128),tp,LOCATION_MZONE,0,1,nil)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.thfilter1,tp,LOCATION_DECK,0,1,nil)
            or (ctrl and Duel.IsExistingMatchingCard(s.thfilter2,tp,LOCATION_DECK,0,1,nil))
    end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

-- ============================================================
-- Effect 1: Operation — Search and add to hand
-- ============================================================
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local ctrl=Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,0x128),tp,LOCATION_MZONE,0,1,nil)
    local g1=Duel.GetMatchingGroup(s.thfilter1,tp,LOCATION_DECK,0,nil)
    local g2=Duel.GetMatchingGroup(s.thfilter2,tp,LOCATION_DECK,0,nil)
    
    local opt=0
    if ctrl and #g1>0 and #g2>0 then
        opt=Duel.SelectOption(tp,aux.Stringid(id,3),aux.Stringid(id,4))
    elseif ctrl and #g2>0 then
        opt=1
    else
        opt=0
    end
    
    local sg=nil
    if opt==0 then
        if #g1==0 then return end
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        sg=Duel.SelectMatchingCard(tp,s.thfilter1,tp,LOCATION_DECK,0,1,1,nil)
    else
        if #g2==0 then return end
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        sg=Duel.SelectMatchingCard(tp,s.thfilter2,tp,LOCATION_DECK,0,1,1,nil)
    end
    
    if sg and #sg>0 then
        Duel.SendtoHand(sg,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,sg)
    end
end

-- ============================================================
-- Effect 3: Condition — Control a Witchcrafter during your End Phase
-- ============================================================
function s.tfcond(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,0x128),tp,LOCATION_MZONE,0,1,nil) and Duel.GetTurnPlayer()==tp
end

-- ============================================================
-- Effect 3: Target — Check if placing is possible
-- ============================================================
function s.tftg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0 end
    Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,e:GetHandler(),1,tp,0)
end

-- ============================================================
-- Effect 3: Operation — Place this card in your Spell/Trap Zone
-- ============================================================
function s.tfop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
    if c:IsRelateToEffect(e) then
        Duel.MoveToField(c,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
    end
end
