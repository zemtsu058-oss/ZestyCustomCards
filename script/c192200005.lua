-- ============================================================
-- Card Name: Morpheus, Dreamspinner of the Castle of Dreams
-- Passcode : 192200005
-- Type     : Monster / Effect
-- Attribute: DARK
-- Level    : 6
-- ATK/DEF  : 2500 / 2000
-- Race     : Spellcaster
-- Archetype: Castle of Dreams (0x782)
-- ============================================================
-- Effect 1: If a monster(s) is Special Summoned from your
--           opponent's Deck and/or Extra Deck: You can Special
--           Summon this card from your hand.
-- Effect 2: If this card is Special Summoned by its own effect:
--           You can place 1 "Castle of Dreams" Field Spell from
--           your Deck face-up on your field.
-- Effect 3: Once per turn, when your opponent activates a card
--           or effect, while you control a "Castle of Dreams"
--           Field Spell (Quick Effect): You can negate the
--           activation, and if you do, your opponent chooses
--           1 of these effects for you to apply.
--           (1) Your opponent draws 1, then discards 2 cards.
--           (2) All monsters your opponent controls gain 500 ATK,
--               but change
--               them to Defense Position.
--           (3) Your opponent gains 1000 LP, but takes 2500 damage
--               during the End Phase of this turn.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Trigger from hand: SS when opponent SS from Deck/ED
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — Trigger when SS by own effect: Place Field Spell from Deck
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCountLimit(1,id+1,EFFECT_COUNT_CODE_OATH)
    e2:SetCondition(s.fspellcon)
    e2:SetTarget(s.tg_place)
    e2:SetOperation(s.op_place)
    c:RegisterEffect(e2)

    -- ============================================================
    -- Effect 3 — Quick Effect: Negate + opponent chooses replacement
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_NEGATE+CATEGORY_DRAW+CATEGORY_ATKCHANGE+CATEGORY_RECOVER+CATEGORY_DAMAGE)
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
-- Effect 1: Filter — Monster SS from opponent's Deck or Extra Deck
-- ============================================================
function s.filter_trigger_ss(c,tp)
    local loc=c:GetSummonLocation()
    return (loc==LOCATION_DECK or loc==LOCATION_EXTRA) and c:GetSummonPlayer()==1-tp
end

-- ============================================================
-- Effect 1: Condition — Opponent SS from Deck/ED
-- ============================================================
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.filter_trigger_ss,1,nil,tp)
end

-- ============================================================
-- Effect 1: Target — Check if this card can be SS from hand
-- ============================================================
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

-- ============================================================
-- Effect 1: Operation — SS this card and set flag for Effect 2
-- ============================================================
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    Duel.SpecialSummon(c,1,tp,tp,false,false,POS_FACEUP)
end

-- ============================================================
-- Effect 2: Condition — This card was SS by own effect (Effect 1)
-- ============================================================
function s.fspellcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():GetSummonType()==SUMMON_TYPE_SPECIAL+1
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
        Duel.Hint(HINT_SELECTMSG,1-tp,aux.Stringid(id,3))
        local op=Duel.SelectOption(1-tp,aux.Stringid(id,3),aux.Stringid(id,4),aux.Stringid(id,5))
        if op==0 then
            if Duel.IsPlayerCanDraw(1-tp,1) then
                Duel.Draw(1-tp,1,REASON_EFFECT)
                Duel.BreakEffect()
                Duel.DiscardHand(1-tp,Card.IsDiscardable,2,2,REASON_EFFECT+REASON_DISCARD)
            end
        elseif op==1 then
            local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
            for tc in aux.Next(g) do
                local e1=Effect.CreateEffect(c)
                e1:SetType(EFFECT_TYPE_SINGLE)
                e1:SetCode(EFFECT_UPDATE_ATTACK)
                e1:SetValue(500)
                e1:SetReset(RESET_EVENT+RESETS_STANDARD)
                tc:RegisterEffect(e1)
                if tc:IsAttackPos() then
                    Duel.ChangePosition(tc,POS_FACEUP_DEFENSE)
                end
            end
        elseif op==2 then
            Duel.Recover(1-tp,1000,REASON_EFFECT)
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
            e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
            e1:SetCode(EVENT_PHASE+PHASE_END)
            e1:SetCountLimit(1)
            e1:SetOperation(s.dmgop_end)
            e1:SetReset(RESET_PHASE+PHASE_END)
            Duel.RegisterEffect(e1,1-tp)
        end
    end
end

-- ============================================================
-- Effect 3 — End Phase damage operation
-- ============================================================
function s.dmgop_end(e,tp,eg,ep,ev,re,r,rp)
    Duel.Damage(tp,2500,REASON_EFFECT)
end
