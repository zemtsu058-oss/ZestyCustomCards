-- ============================================================
-- Card Name: Rikka Vow
-- Passcode  : 32100009
-- Type      : Spell / Normal
-- Archetype : Rikka (0x141)
-- ============================================================
-- Effect 1  : Trigger from Deck: Add this card to hand if you control 6 Rikka monsters (HOPT).
-- Effect 2  : Destroy 6 Rikka monsters you control; inflict 100000 damage to both players.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Trigger from Deck: Add to hand
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetRange(LOCATION_DECK)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.thcon)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)

    local e1b=e1:Clone()
    e1b:SetCode(EVENT_SUMMON_SUCCESS)
    c:RegisterEffect(e1b)

    local e1c=e1:Clone()
    e1c:SetCode(EVENT_FLIP_SUMMON_SUCCESS)
    c:RegisterEffect(e1c)

    local e1d=e1:Clone()
    e1d:SetCode(EVENT_CONTROL_CHANGED)
    c:RegisterEffect(e1d)

    -- ============================================================
    -- Effect 2 — Activate: Destroy 6 and inflict damage
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_DESTROY+CATEGORY_DAMAGE)
    e2:SetType(EFFECT_TYPE_ACTIVATE)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetTarget(s.destg)
    e2:SetOperation(s.desop)
    c:RegisterEffect(e2)
end

-- ============================================================
-- Effect 1: Trigger logic
-- ============================================================
function s.rikka_filter(c)
    return c:IsFaceup() and c:IsSetCard(0x141)
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetMatchingGroupCount(s.rikka_filter,tp,LOCATION_MZONE,0,nil)>=6
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsAbleToHand() end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,0,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        if Duel.SendtoHand(c,nil,REASON_EFFECT)>0 then
            Duel.ConfirmCards(1-tp,c)
        end
    end
end

-- ============================================================
-- Effect 2: Activation logic
-- ============================================================
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    local g=Duel.GetMatchingGroup(s.rikka_filter,tp,LOCATION_MZONE,0,nil)
    if chk==0 then return #g>=6 end
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,6,0,0)
    Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,PLAYER_ALL,100000)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(s.rikka_filter,tp,LOCATION_MZONE,0,nil)
    if #g<6 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local sg=g:Select(tp,6,6,nil)
    if #sg==6 then
        local ct=Duel.Destroy(sg,REASON_EFFECT)
        if ct==6 then
            Duel.Damage(tp,100000,REASON_EFFECT,true)
            Duel.Damage(1-tp,100000,REASON_EFFECT,true)
            Duel.RDComplete()
        end
    end
end

