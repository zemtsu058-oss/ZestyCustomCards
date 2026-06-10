-- ============================================================
-- Card Name: Kanzashi the Rikka Flower
-- Passcode  : 32100002
-- Type      : Monster / Xyz / Effect
-- Archetype : Rikka (0x141)
-- ============================================================
-- Xyz Summon: 2+ Level 8 monsters
-- Alternative: You can also Xyz Summon this card by using "Kanzashi the Rikka Queen" you control.
-- Effect 1  : Return 3 Rikka monsters from GY to Deck; draw 2 cards (HOPT).
-- Effect 2  : Detach 2: Negate opponent activation, Tribute 1 random card in opponent hand.
--             (treated as Quick Effect if this card has a Plant material).
-- Effect 3  : Detach 1: Search 1 Rikka card from Deck (HOPT).
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- Xyz Summon Procedure
    Xyz.AddProcedure(c,nil,8,2,99,s.ovfilter,aux.Stringid(id,0),3,s.xyzop)
    c:EnableReviveLimit()

    -- ============================================================
    -- Effect 1 — Return 3 Rikka from GY, draw 2 cards
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,1))
    e1:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.drtg)
    e1:SetOperation(s.drop)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — Negate activation and Tribute 1 card in opponent's hand
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,2))
    e2:SetCategory(CATEGORY_NEGATE+CATEGORY_RELEASE)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_CHAINING)
    e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCondition(s.negcon)
    e2:SetCost(s.detach2cost)
    e2:SetTarget(s.negtg)
    e2:SetOperation(s.negop)
    c:RegisterEffect(e2)

    -- ============================================================
    -- Effect 3 — Detach 1: Search Rikka card
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,3))
    e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1,id+100)
    e3:SetCost(s.detach1cost)
    e3:SetTarget(s.thtg)
    e3:SetOperation(s.thop)
    c:RegisterEffect(e3)
end

-- ============================================================
-- Alternative Summon Logic
-- ============================================================
function s.ovfilter(c,tp,lc)
    return c:IsFaceup() and c:IsSummonCode(lc,SUMMON_TYPE_XYZ,tp,6284176)
end

function s.xyzop(e,tp,chk)
    if chk==0 then return Duel.GetFlagEffect(tp,id)==0 end
    Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
    return true
end

-- ============================================================
-- Effect 1: Return 3 Rikka to draw 2
-- ============================================================
function s.drfilter(c)
    return c:IsSetCard(0x141) and c:IsMonster() and c:IsAbleToDeck()
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsPlayerCanDraw(tp,2)
            and Duel.IsExistingMatchingCard(s.drfilter,tp,LOCATION_GRAVE,0,3,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,3,tp,LOCATION_GRAVE)
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local g=Duel.SelectMatchingCard(tp,s.drfilter,tp,LOCATION_GRAVE,0,3,3,nil)
    if #g==3 then
        Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
        local og=Duel.GetOperatedGroup()
        if og:IsExists(Card.IsLocation,1,nil,LOCATION_DECK+LOCATION_EXTRA) then
            Duel.Draw(tp,2,REASON_EFFECT)
        end
    end
end

-- ============================================================
-- Effect 2: Negate activation and Tribute random card in hand
-- ============================================================
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local has_plant=c:GetOverlayGroup():IsExists(Card.IsRace,1,nil,RACE_PLANT)
    if not has_plant and Duel.GetTurnPlayer()~=tp then return false end
    return Duel.IsChainNegatable(ev) and rp~=tp
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_RELEASE,nil,1,1-tp,LOCATION_HAND)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) then
        local g=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
        if #g>0 then
            local sg=g:RandomSelect(tp,1)
            Duel.Release(sg,REASON_EFFECT)
        end
    end
end

-- ============================================================
-- Effect 3: Search Rikka card
-- ============================================================
function s.thfilter(c)
    return c:IsSetCard(0x141) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)
        Duel.ShuffleDeck(tp)
    end
end

-- ============================================================
-- Cost Functions
-- ============================================================
function s.detach1cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
    e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

function s.detach2cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,2,REASON_COST) end
    e:GetHandler():RemoveOverlayCard(tp,2,2,REASON_COST)
end

