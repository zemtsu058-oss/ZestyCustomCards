-- ============================================================
-- Card Name: Witchcrafter Bumble Magic
-- Passcode : 29600002
-- Type     : Spell / Normal
-- Archetype: Witchcrafter (0x128)
-- ============================================================
-- Effect 1: Add 1 "Witchcrafter" card from your GY to your hand, then apply 1 of the following effects based on the card type of the card you added:
--   ● Monster: Special Summon 1 Spellcaster monster from your hand with a different Attribute from the added monster.
--   ● Spell: Draw 1 card.
--   ● Trap: You can activate 1 "Witchcrafter" Trap from your hand this turn.
-- Effect 2: During your End Phase, if you control a "Witchcrafter" monster, while this card is in your GY: You can add this card to your hand.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Activate (Add to hand + conditional effect)
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON+CATEGORY_DRAW)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetTarget(s.tg_add)
    e1:SetOperation(s.op_add)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — End Phase GY recovery
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,5))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_LEAVE_GRAVE)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_PHASE+PHASE_END)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e2:SetCondition(s.con_gy)
    e2:SetTarget(s.tg_gy)
    e2:SetOperation(s.op_gy)
    c:RegisterEffect(e2)
end

-- ============================================================
-- Effect 1: Filter — Valid Witchcrafter cards in GY
-- ============================================================
function s.filter_add(c)
    return c:IsSetCard(0x128) and c:IsAbleToHand()
end

-- ============================================================
-- Effect 1: Filter — Hand trap activation condition filter
-- ============================================================
function s.filter_hand_trap(e,c)
    return c:IsSetCard(0x128)
end

-- ============================================================
-- Effect 1: Target — Select a Witchcrafter card in GY to target
-- ============================================================
function s.tg_add(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.filter_add(chkc) end
    if chk==0 then return Duel.IsExistingTarget(s.filter_add,tp,LOCATION_GRAVE,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectTarget(tp,s.filter_add,tp,LOCATION_GRAVE,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end

-- ============================================================
-- Effect 1: Operation — Add to hand, then apply conditional effect
-- ============================================================
function s.op_add(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        if Duel.SendtoHand(tc,nil,REASON_EFFECT)>0 and tc:IsLocation(LOCATION_HAND) then
            Duel.ConfirmCards(1-tp,tc)
            Duel.BreakEffect()
            if tc:IsMonster() then
                -- Monster: Special Summon 1 Spellcaster from hand with different Attribute
                local attr=tc:GetAttribute()
                local spfilter=function(c,e,tp,ex_attr)
                    return c:IsRace(RACE_SPELLCASTER) and not c:IsAttribute(ex_attr)
                        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
                end
                if Duel.GetLocationCount(tp,LOCATION_MZONE)>0
                    and Duel.IsExistingMatchingCard(spfilter,tp,LOCATION_HAND,0,1,nil,e,tp,attr)
                    and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
                    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
                    local sg=Duel.SelectMatchingCard(tp,spfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp,attr)
                    if #sg>0 then
                        Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
                    end
                end
            elseif tc:IsSpell() then
                -- Spell: Draw 1 card
                if Duel.IsPlayerCanDraw(tp,1) and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
                    Duel.Draw(tp,1,REASON_EFFECT)
                end
            elseif tc:IsTrap() then
                -- Trap: Activate 1 Witchcrafter Trap from hand this turn
                if Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
                    local e1=Effect.CreateEffect(e:GetHandler())
                    e1:SetType(EFFECT_TYPE_FIELD)
                    e1:SetCode(EFFECT_TRAP_ACT_IN_HAND)
                    e1:SetTargetRange(LOCATION_HAND,0)
                    e1:SetCountLimit(1)
                    e1:SetTarget(s.filter_hand_trap)
                    e1:SetReset(RESET_PHASE+PHASE_END)
                    e1:SetDescription(aux.Stringid(id,4))
                    Duel.RegisterEffect(e1,tp)
                end
            end
        end
    end
end

-- ============================================================
-- Effect 2: Condition — Control a Witchcrafter monster in End Phase
-- ============================================================
function s.con_gy(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(aux.FaceupFilter(Card.IsSetCard,0x128),tp,LOCATION_MZONE,0,nil)
    return #g>0 and Duel.IsTurnPlayer(tp)
end

-- ============================================================
-- Effect 2: Target — Self to hand
-- ============================================================
function s.tg_gy(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsAbleToHand() end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,tp,LOCATION_GRAVE)
end

-- ============================================================
-- Effect 2: Operation — Add this card to hand
-- ============================================================
function s.op_gy(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SendtoHand(c,nil,REASON_EFFECT)
    end
end
