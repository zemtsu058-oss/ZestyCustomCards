-- ============================================================
-- Card Name: Memory of the White Forest
-- Passcode : 42600002
-- Type     : Spell / Normal
-- Archetype: White Forest (0x1aa)
-- ============================================================
-- Effect 1: Take 1 "White Forest" monster from your Deck, and either add it to your hand, or if you control no monsters and your opponent activated a card or effect this turn, you can Special Summon it instead.
-- Effect 2: If this card is sent to the GY to activate a monster effect: You can Set this card.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Search or Special Summon
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.tg_search)
    e1:SetOperation(s.op_search)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — GY recovery
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,2))
    e2:SetCategory(CATEGORY_LEAVE_GRAVE+CATEGORY_SET)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.con_set)
    e2:SetTarget(s.tg_set)
    e2:SetOperation(s.op_set)
    c:RegisterEffect(e2)

    -- Custom activity counter to track any activation by the opponent
    Duel.AddCustomActivityCounter(id,ACTIVITY_CHAIN,s.filter_chain)
end

-- Custom activity counter filter
function s.filter_chain(re,tp,cid)
    return false
end

-- ============================================================
-- Effect 1: Filter — White Forest monster in Deck
-- ============================================================
function s.filter_search(c)
    return c:IsSetCard(0x1aa) and c:IsMonster() and c:IsAbleToHand()
end

-- ============================================================
-- Effect 1: Target — Check if a search target exists in Deck
-- ============================================================
function s.tg_search(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.filter_search,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
    Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

-- ============================================================
-- Effect 1: Operation — Search or Special Summon
-- ============================================================
function s.op_search(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.filter_search,tp,LOCATION_DECK,0,1,1,nil)
    local tc=g:GetFirst()
    if tc then
        local can_sp = Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
            and Duel.GetCustomActivityCount(id,1-tp,ACTIVITY_CHAIN)>0
            and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and tc:IsCanBeSpecialSummoned(e,0,tp,false,false)
            
        if can_sp and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
            Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
        else
            Duel.SendtoHand(tc,nil,REASON_EFFECT)
            Duel.ConfirmCards(1-tp,tc)
        end
    end
end

-- ============================================================
-- Effect 2: Condition — Sent to GY as cost for monster effect
-- ============================================================
function s.con_set(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:IsReason(REASON_COST) and re and re:IsActivated() and re:IsMonsterEffect()
end

-- ============================================================
-- Effect 2: Target — Set this card
-- ============================================================
function s.tg_set(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsSSetable() end
    Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,c,1,tp,0)
end

-- ============================================================
-- Effect 2: Operation — SSet this card from GY
-- ============================================================
function s.op_set(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) and c:IsSSetable() then
        Duel.SSet(tp,c)
    end
end
