-- ============================================================
-- Card Name: Iris, Master of the Castle of Dreams
-- Passcode : 192200004
-- Type     : Monster / Effect
-- Attribute: LIGHT
-- Level    : 6
-- ATK/DEF  : 2000 / 2500
-- Race     : Spellcaster
-- Archetype: Castle of Dreams (0x782)
-- ============================================================
-- Effect 1: If your opponent controls a monster that was Special
--           Summoned from their Deck or Extra Deck, or you
--           control no monster in your Main Monster Zone, you can
--           Special Summon this card from your hand.
-- Effect 2: Once per turn, during your Main Phase: You can place
--           1 "Castle of Dreams" Field Spell from your Deck
--           face-up on your field.
-- Effect 3: Once per turn, when your opponent activates a card
--           or effect, while you control a "Castle of Dreams"
--           Field Spell (Quick Effect): You can negate the
--           activation, and if you do, your opponent chooses
--           1 of these effects for you to apply.
--           (1) You draw 2, then your opponent draws 1.
--           (2) All monsters on the field gain 500 ATK, then all
--               monsters you control gain 500 ATK.
--           (3) You gain 2000 LP, then your opponent gains 1000 LP.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Inherent Special Summon from hand
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCondition(s.spcon)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — Ignition: Place a Castle of Dreams Field Spell from Deck
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,id+1,EFFECT_COUNT_CODE_OATH)
    e2:SetTarget(s.tg_place)
    e2:SetOperation(s.op_place)
    c:RegisterEffect(e2)

    -- ============================================================
    -- Effect 3 — Quick Effect: Negate + opponent chooses replacement
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_NEGATE+CATEGORY_DRAW+CATEGORY_ATKCHANGE+CATEGORY_RECOVER)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_CHAINING)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1,id+2,EFFECT_COUNT_CODE_OATH)
    e3:SetCondition(s.negcon)
    e3:SetTarget(s.negtg)
    e3:SetOperation(s.negop)
    c:RegisterEffect(e3)
end

-- ============================================================
-- Effect 1: Filter — Only Main Monster Zone (exclude Extra Monster Zone)
-- ============================================================
function s.filter_mainzone(c)
    return c:GetSequence()<5
end

-- ============================================================
-- Effect 1: Filter — Opponent's monster SS from Deck or Extra Deck
-- ============================================================
function s.filter_opp_ss(c,tp)
    local loc=c:GetSummonLocation()
    return c:IsSummonType(SUMMON_TYPE_SPECIAL) and c:GetSummonPlayer()==1-tp
        and (loc==LOCATION_DECK or loc==LOCATION_EXTRA)
end

-- ============================================================
-- Effect 1: Condition — Opponent has SS from Deck/ED, or you control no monster
-- ============================================================
function s.spcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return false end
    local opp_ss=Duel.IsExistingMatchingCard(s.filter_opp_ss,tp,0,LOCATION_MZONE,1,nil,tp)
    local no_monster=not Duel.IsExistingMatchingCard(s.filter_mainzone,tp,LOCATION_MZONE,0,1,nil)
    return opp_ss or no_monster
end

-- ============================================================
-- Effect 2: Filter — Castle of Dreams Field Spell in Deck
-- ============================================================
function s.filter_fspell(c)
    return c:IsSetCard(0x782) and c:IsFieldSpell() and not c:IsForbidden()
end

-- ============================================================
-- Effect 2: Target — Check for valid Field Spell in Deck
-- ============================================================
function s.tg_place(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.filter_fspell,tp,LOCATION_DECK,0,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_SEARCH,nil,1,tp,LOCATION_DECK)
end

-- ============================================================
-- Effect 2: Operation — Activate Field Spell from Deck to Field Zone
-- ============================================================
function s.op_place(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
    local g=Duel.SelectMatchingCard(tp,s.filter_fspell,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        local tc=g:GetFirst()
        local fc=Duel.GetFieldCard(tp,LOCATION_FZONE,0)
        if fc then
            Duel.SendtoGrave(fc,REASON_RULE)
            Duel.BreakEffect()
        end
        Duel.MoveToField(tc,tp,tp,LOCATION_FZONE,POS_FACEUP,true)
    end
end

-- ============================================================
-- Effect 3: Filter — Castle of Dreams Field Spell
-- ============================================================
function s.fspell_filter(c)
    return c:IsFaceup() and c:IsSetCard(0x782) and c:IsType(TYPE_FIELD)
end

-- ============================================================
-- Effect 3: Condition — Opponent activates while you control a Field Spell
-- ============================================================
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return rp==1-tp and Duel.IsChainNegatable(ev)
        and Duel.IsExistingMatchingCard(s.fspell_filter,tp,LOCATION_FZONE,0,1,nil)
end

-- ============================================================
-- Effect 3: Target — Always true (instant chain response)
-- ============================================================
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,tp,0)
end

-- ============================================================
-- Effect 3: Operation — Negate, opponent chooses replacement effect
-- ============================================================
function s.negop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    if Duel.NegateActivation(ev) then
        Duel.Hint(HINT_SELECTMSG,1-tp,aux.Stringid(id,2))
        local op=Duel.SelectOption(1-tp,aux.Stringid(id,2),aux.Stringid(id,3),aux.Stringid(id,4))
        if op==0 then
            if Duel.IsPlayerCanDraw(tp,2) and Duel.IsPlayerCanDraw(1-tp,1) then
                Duel.Draw(tp,2,REASON_EFFECT)
                Duel.Draw(1-tp,1,REASON_EFFECT)
            end
        elseif op==1 then
            local g_all=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
            for tc in aux.Next(g_all) do
                local e1=Effect.CreateEffect(c)
                e1:SetType(EFFECT_TYPE_SINGLE)
                e1:SetCode(EFFECT_UPDATE_ATTACK)
                e1:SetValue(500)
                e1:SetReset(RESET_EVENT+RESETS_STANDARD)
                tc:RegisterEffect(e1)
            end
            local g_opp=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
            for tc in aux.Next(g_opp) do
                local e1=Effect.CreateEffect(c)
                e1:SetType(EFFECT_TYPE_SINGLE)
                e1:SetCode(EFFECT_UPDATE_ATTACK)
                e1:SetValue(500)
                e1:SetReset(RESET_EVENT+RESETS_STANDARD)
                tc:RegisterEffect(e1)
            end
        elseif op==2 then
            Duel.Recover(tp,2000,REASON_EFFECT)
            Duel.Recover(1-tp,1000,REASON_EFFECT)
        end
    end
end
