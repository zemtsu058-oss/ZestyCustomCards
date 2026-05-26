-- ============================================================
-- Card Name: Cautus, Keeper of the Castle of Dreams
-- Passcode : 192200002
-- Type     : Monster / Effect
-- Attribute: WIND
-- Level    : 4
-- ATK/DEF  : 1600 / 1800
-- Race     : Illusion
-- Archetype: Castle of Dreams (0x782)
-- ============================================================
-- Effect 1: If you control only Spellcaster and/or Illusion
--           monsters, you can Special Summon this card from your
--           hand.
-- Effect 2: If this card is Normal or Special Summoned: You can
--           excavate the top 6 cards of your Deck, then if you
--           excavated a "Castle of Dreams" card(s), you can add
--           1 of them to your hand, also place the rest on the
--           top of your Deck in any order.
-- Effect 3: If a Field Spell card you control would be destroyed,
--           you can banish this card from your GY, instead.
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
    -- Effect 2 — Trigger on Summon: Excavate top 6, optionally add 1, reorder rest
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_SUMMON_SUCCESS)
    e2:SetCountLimit(1,id+1,EFFECT_COUNT_CODE_OATH)
    e2:SetTarget(s.tg_excavate)
    e2:SetOperation(s.op_excavate)
    c:RegisterEffect(e2)
    -- Clone for Special Summon trigger (same effect, different event)
    local e3=e2:Clone()
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e3)

    -- ============================================================
    -- Effect 3 — GY banish: protect Field Spell from destruction
    -- ============================================================
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e4:SetCode(EFFECT_DESTROY_REPLACE)
    e4:SetRange(LOCATION_GRAVE)
    e4:SetCountLimit(1,id+2,EFFECT_COUNT_CODE_OATH)
    e4:SetTarget(s.reptg)
    e4:SetValue(s.repval)
    e4:SetOperation(s.repop)
    c:RegisterEffect(e4)
end

-- ============================================================
-- Effect 1: Helper filter — Monsters that are NOT Spellcaster or Illusion
-- ============================================================
function s.filter_not_race(c)
    return not c:IsRace(RACE_SPELLCASTER) and not c:IsRace(0x2000000)
end

-- ============================================================
-- Effect 1: Condition — Control only Spellcaster/Illusion monsters
-- ============================================================
function s.spcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and not Duel.IsExistingMatchingCard(s.filter_not_race,tp,LOCATION_MZONE,0,1,nil)
end

-- ============================================================
-- Effect 2: Target — Check if Deck is not empty
-- ============================================================
function s.tg_excavate(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>0 end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

-- ============================================================
-- Effect 2: Operation — Excavate, optionally add 1, reorder rest
-- ============================================================
function s.op_excavate(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    local ct=math.min(6,Duel.GetFieldGroupCount(tp,LOCATION_DECK,0))
    if ct<=0 then return end
    Duel.ConfirmDecktop(tp,ct)
    local g=Duel.GetDecktopGroup(tp,ct)
    if g:IsExists(s.filter_castle_to_hand,1,nil)
        and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local sg=g:FilterSelect(tp,s.filter_castle_to_hand,1,1,nil)
        if #sg>0 then
            Duel.SendtoHand(sg,nil,REASON_EFFECT)
            Duel.ConfirmCards(1-tp,sg)
            g:Sub(sg)
        end
    end
    Duel.DisableShuffleCheck()
    if #g>0 then
        Duel.SortDecktop(tp,tp,#g)
    end
end

function s.filter_castle_to_hand(c)
    return c:IsSetCard(0x782) and c:IsAbleToHand()
end

-- ============================================================
-- Effect 3: Filter — face-up Castle of Dreams Field Spell about to be destroyed
-- ============================================================
function s.repfilter(c,tp)
    return c:IsFaceup() and c:IsControler(tp) and c:IsLocation(LOCATION_FZONE)
        and c:IsReason(REASON_EFFECT) and not c:IsReason(REASON_REPLACE)
end

-- ============================================================
-- Effect 3: Target — Ask player if they want to replace
-- ============================================================
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then
        return eg:IsExists(s.repfilter,1,nil,tp)
    end
    return Duel.SelectEffectYesNo(tp,c,96)
end

-- ============================================================
-- Effect 3: Value — Confirm the card qualifies for replacement
-- ============================================================
function s.repval(e,c)
    return s.repfilter(c,e:GetHandlerPlayer())
end

-- ============================================================
-- Effect 3: Operation — Banish this card from GY
-- ============================================================
function s.repop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    Duel.Remove(c,POS_FACEUP,REASON_EFFECT+REASON_REPLACE)
end
