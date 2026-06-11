-- ============================================================
-- Card Name: Blue Eye Ultimammoth Arrow Dragon
-- Passcode  : 22100003
-- Type      : Monster / Fusion / Effect
-- Attribute : LIGHT
-- Level     : 10
-- ATK/DEF   : 4500 / 0
-- Race      : Zombie
-- Archetype : Blue_Eye (0xdd)
-- ============================================================
-- Effect 1  : Special Summon from Extra Deck to opponent's field
--             by discarding 1 Spell and sending materials to GY
--             (1 from each player's field).
-- Effect 2  : Cannot declare an attack.
-- Effect 3  : Monsters cannot be destroyed by battle with this card.
-- Effect 4  : Controller takes battle damage the opponent would take instead.
-- Effect 5  : End Battle Phase if controller takes battle damage involving this card.
-- Effect 6  : During each player's End Phase: loses 500 ATK.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- Enable Revive Limit
    c:EnableReviveLimit()
    c:SetSPSummonOnce(id)

    -- Fusion Materials: "Mammoth Graveyard" + 1 Fusion monster
    Fusion.AddProcMix(c,true,true,s.matfilter1,s.matfilter2)

    -- ============================================================
    -- Effect 1 — Special Summon to opponent's field
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_SPSUM_PARAM)
    e1:SetRange(LOCATION_EXTRA)
    e1:SetTargetRange(POS_FACEUP,1) -- 1 means opponent's side of the field
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — Cannot declare an attack
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_CANNOT_ATTACK)
    c:RegisterEffect(e2)

    -- ============================================================
    -- Effect 3 — Monsters cannot be destroyed by battle with this card
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
    e3:SetTarget(s.batg)
    e3:SetValue(1)
    c:RegisterEffect(e3)

    -- ============================================================
    -- Effect 4 — Redirect battle damage (Opponent's damage to you)
    -- ============================================================
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD)
    e4:SetCode(EFFECT_REFLECT_BATTLE_DAMAGE)
    e4:SetRange(LOCATION_MZONE)
    e4:SetTargetRange(0,LOCATION_MZONE)
    e4:SetTarget(s.damtg)
    e4:SetValue(1)
    c:RegisterEffect(e4)

    -- ============================================================
    -- Effect 5 — End Battle Phase
    -- ============================================================
    local e5=Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id,1))
    e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e5:SetCode(EVENT_BATTLE_DAMAGE)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCondition(s.bpcon)
    e5:SetOperation(s.bpop)
    c:RegisterEffect(e5)

    -- ============================================================
    -- Effect 6 — Loses 500 ATK
    -- ============================================================
    local e6=Effect.CreateEffect(c)
    e6:SetDescription(aux.Stringid(id,2))
    e6:SetCategory(CATEGORY_ATKCHANGE)
    e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
    e6:SetCode(EVENT_PHASE+PHASE_END)
    e6:SetRange(LOCATION_MZONE)
    e6:SetCountLimit(1)
    e6:SetOperation(s.atkop)
    c:RegisterEffect(e6)
end

-- ============================================================
-- Material Filter Functions
-- ============================================================
function s.matfilter1(c,fc,sumtype,tp)
    return c:IsCode(40374923)
end

function s.matfilter2(c,fc,sumtype,tp)
    return c:IsType(TYPE_FUSION)
end

-- ============================================================
-- Effect 1 (Special Summon Procedure) Helpers
-- ============================================================
function s.discardfilter(c)
    return c:IsType(TYPE_SPELL) and c:IsDiscardable()
end

function s.valpair(c1,c2)
    return (s.matfilter1(c1) and s.matfilter2(c2)) or (s.matfilter2(c1) and s.matfilter1(c2))
end

function s.spcon(e,c,tp)
    if c==nil then return true end
    local tp=c:GetControler()
    if not Duel.IsExistingMatchingCard(s.discardfilter,tp,LOCATION_HAND,0,1,nil) then return false end
    if Duel.GetLocationCount(1-tp,LOCATION_MZONE)<=0 then return false end
    local g1=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
    local g2=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
    return g1:IsExists(function(tc1)
        return g2:IsExists(s.valpair,1,nil,tc1)
    end,1,nil)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
    local g1=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
    local g2=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
    
    -- Select and discard 1 Spell Card from hand
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
    local disc=Duel.SelectMatchingCard(tp,s.discardfilter,tp,LOCATION_HAND,0,1,1,nil)
    if #disc==0 then return false end
    Duel.SendtoGrave(disc,REASON_COST+REASON_DISCARD)
    
    -- Select the first material (your monster)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local mc1=g1:FilterSelect(tp,function(tc1)
        return g2:IsExists(s.valpair,1,nil,tc1)
    end,1,1,nil):GetFirst()
    
    -- Select the second material (opponent's monster)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local mc2=g2:FilterSelect(tp,s.valpair,1,1,nil,mc1):GetFirst()
    
    local g=Group.FromCards(mc1,mc2)
    g:KeepAlive()
    e:SetLabelObject(g)
    return true
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c,sg)
    local g=e:GetLabelObject()
    if not g then return end
    c:SetMaterial(g)
    Duel.SendtoGrave(g,REASON_MATERIAL+REASON_FUSION)
    g:DeleteGroup()
end

-- ============================================================
-- Battle Target Filtering Helpers
-- ============================================================
function s.batg(e,c)
    local handler=e:GetHandler()
    return c==handler or c==handler:GetBattleTarget()
end

function s.damtg(e,c)
    return c==e:GetHandler():GetBattleTarget()
end

-- ============================================================
-- Effect 5: End Battle Phase Helpers
-- ============================================================
function s.bpcon(e,tp,eg,ep,ev,re,r,rp)
    return ep==tp and e:GetHandler():IsRelateToBattle()
end

function s.bpop(e,tp,eg,ep,ev,re,r,rp)
    Duel.SkipPhase(Duel.GetTurnPlayer(),PHASE_BATTLE,RESET_PHASE+PHASE_BATTLE,1)
end

-- ============================================================
-- Effect 6: Loses 500 ATK Helpers
-- ============================================================
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
    local c=Card.GetRelatedHandler(e:GetHandler(),e)
    if c and c:IsFaceup() and c:IsRelateToEffect(e) then
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(-500)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        c:RegisterEffect(e1)
    end
end
