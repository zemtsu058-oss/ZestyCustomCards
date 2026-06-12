-- ============================================================
-- Card Name: Rikka Siesta
-- Passcode  : 32100008
-- Type      : Spell / Normal
-- Archetype : Rikka (0x141)
-- ============================================================
-- Effect 1  : When you activate a Rikka card/effect: Reveal this in Deck/GY; add to hand (HOPT).
-- Effect 2  : Gain 1000 LP, target 1 Rikka Spell and 1 Plant monster in banishment; add 1 to hand, place the other on Deck bottom (HOPT).
-- Effect 3  : Quick Effect from GY: Banish face-down; gain 8000 LP, cannot activate card effects until next opponent's Standby Phase (HOPT).
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Reveal and add to hand
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_CHAINING)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetRange(LOCATION_DECK+LOCATION_GRAVE)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.thcon)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — Normal Spell Activation
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_RECOVER+CATEGORY_TOHAND+CATEGORY_TODECK)
    e2:SetType(EFFECT_TYPE_ACTIVATE)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetCountLimit(1,{id,1})
    e2:SetTarget(s.acttg)
    e2:SetOperation(s.actop)
    c:RegisterEffect(e2)

    -- ============================================================
    -- Effect 3 — Banish face-down from GY to gain 8000 LP
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_RECOVER)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetRange(LOCATION_GRAVE)
    e3:SetCountLimit(1,{id,2})
    e3:SetCondition(s.lpcon)
    e3:SetCost(s.lpcost)
    e3:SetTarget(s.lptg)
    e3:SetOperation(s.lpop)
    c:RegisterEffect(e3)
end

-- ============================================================
-- Effect 1: Trigger logic
-- ============================================================
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    if rp~=tp then return false end
    local rc=re:GetHandler()
    return rc and rc:IsSetCard(0x141) and not rc:IsCode(id)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsAbleToHand() end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,tp,c:GetLocation())
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.ConfirmCards(1-tp,c)
        if Duel.SendtoHand(c,nil,REASON_EFFECT)>0 then
            Duel.ConfirmCards(1-tp,c)
            if c:GetPreviousLocation()==LOCATION_DECK then
                Duel.ShuffleDeck(tp)
            end
        end
    end
end

-- ============================================================
-- Effect 2: Normal Spell activation logic
-- ============================================================
function s.spfilter(c)
    return c:IsFaceup() and c:IsSetCard(0x141) and c:IsType(TYPE_SPELL)
end

function s.monfilter(c)
    return c:IsFaceup() and c:IsRace(RACE_PLANT) and c:IsMonster()
end

function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return false end
    if chk==0 then
        return Duel.IsExistingTarget(s.spfilter,tp,LOCATION_REMOVED,0,1,nil)
            and Duel.IsExistingTarget(s.monfilter,tp,LOCATION_REMOVED,0,1,nil)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g1=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_REMOVED,0,1,1,nil)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local g2=Duel.SelectTarget(tp,s.monfilter,tp,LOCATION_REMOVED,0,1,1,nil)
    g1:Merge(g2)
    Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,1000)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,g1,1,0,0)
    Duel.SetOperationInfo(0,CATEGORY_TODECK,g1,1,0,0)
end

function s.actop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Recover(tp,1000,REASON_EFFECT)
    local g=Duel.GetTargetCards(e)
    if #g~=2 then return end
    local tc1=g:Filter(s.spfilter,nil):GetFirst()
    local tc2=g:Filter(s.monfilter,nil):GetFirst()
    if not tc1 or not tc2 then return end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local sg=g:Select(tp,1,1,nil)
    if #sg>0 then
        local th=sg:GetFirst()
        local td=g:Filter(function(c) return c~=th end,nil):GetFirst()
        if Duel.SendtoHand(th,nil,REASON_EFFECT)>0 then
            Duel.ConfirmCards(1-tp,th)
            Duel.SendtoDeck(td,nil,SEQ_DECKBOTTOM,REASON_EFFECT)
        end
    end
end

-- ============================================================
-- Effect 3: GY Quick Effect logic
-- ============================================================
function s.lpcon(e,tp,eg,ep,ev,re,r,rp)
    local main_phase = Duel.GetCurrentPhase()==PHASE_MAIN1 or Duel.GetCurrentPhase()==PHASE_MAIN2
    if not main_phase then return false end
    if Duel.GetTurnPlayer()==tp then return true end
    return Duel.IsExistingMatchingCard(function(c) return c:IsRace(RACE_PLANT) and c:IsMonster() end,
        tp, LOCATION_HAND, 0, 1, nil)
end

function s.lpcost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsAbleToRemoveAsCost() end
    Duel.Remove(c,POS_FACEDOWN,REASON_COST)
end

function s.lptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,8000)
end

function s.lpop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Recover(tp,8000,REASON_EFFECT)

    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
    e1:SetCode(EFFECT_CANNOT_ACTIVATE)
    e1:SetTargetRange(1,0)
    e1:SetValue(s.aclimit)
    e1:SetReset(RESET_PHASE+PHASE_STANDBY+RESET_OPPO_TURN)
    Duel.RegisterEffect(e1,tp)
end

function s.aclimit(e,re,tp)
    return true
end

