-- ============================================================
-- Card Name: Lemuria, the Slumbering Eternal City
-- Passcode : 37700001
-- Type     : Spell / Field
-- Archetype: Umi (0x179)
-- ============================================================
-- Effect 1: Always treated as "Umi".
-- Effect 2: On activation: Search or Special Summon 1 "Mermail"
--           or "Atlantean" monster from your Deck or GY.
-- Effect 3: WATER monsters gain 200 ATK/DEF for each "Mermail"
--           or "Atlantean" monster on the field.
-- Effect 4: When your opponent activates a monster effect: Reveal
--           2 WATER monsters from your hand, field, and/or GY;
--           negate the activation (and if it was a non-WATER
--           monster, banish it).
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- ============================================================
    -- Effect 1 — Always treated as Umi
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetCode(EFFECT_CHANGE_CODE)
    e1:SetRange(LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_SZONE)
    e1:SetValue(22702055)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — Search or SS 1 Mermail or Atlantean on activation
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_ACTIVATE)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetCountLimit(1,id)
    e2:SetTarget(s.acttg)
    e2:SetOperation(s.actop)
    c:RegisterEffect(e2)

    -- ============================================================
    -- Effect 3 — ATK/DEF buff for WATER monsters
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_UPDATE_ATTACK)
    e3:SetRange(LOCATION_FZONE)
    e3:SetTargetRange(LOCATION_MZONE,0)
    e3:SetTarget(aux.TargetBoolFunction(Card.IsAttribute,ATTRIBUTE_WATER))
    e3:SetValue(s.atkval)
    c:RegisterEffect(e3)
    local e4=e3:Clone()
    e4:SetCode(EFFECT_UPDATE_DEFENSE)
    c:RegisterEffect(e4)

    -- ============================================================
    -- Effect 4 — Negate monster effect on resolve (Shared HOPT: id)
    -- ============================================================
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e5:SetCode(EVENT_CHAIN_SOLVING)
    e5:SetRange(LOCATION_FZONE)
    e5:SetCondition(s.negcon)
    e5:SetOperation(s.negop)
    c:RegisterEffect(e5)
end

s.listed_names={22702055}
s.listed_series={0x74, 0x77}

-- ============================================================
-- Effect 2: Filter — Valid search or summon targets
-- ============================================================
function s.filter(c,e,tp,ft)
    if not (c:IsType(TYPE_MONSTER) and (c:IsSetCard(0x74) or c:IsSetCard(0x77))) then return false end
    local th=c:IsAbleToHand()
    local sp=ft>0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
    return th or sp
end

-- ============================================================
-- Effect 2: Target — Check if activation search/SS is possible
-- ============================================================
function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk)
    local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
    if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp,ft) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

-- ============================================================
-- Effect 2: Operation — Perform search or special summon
-- ============================================================
function s.actop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELECT)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.filter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp,ft)
    if #g>0 then
        local tc=g:GetFirst()
        local th=tc:IsAbleToHand()
        local sp=ft>0 and tc:IsCanBeSpecialSummoned(e,0,tp,false,false)
        local op=0
        if th and sp then
            op=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))
        elseif th then
            op=0
        else
            op=1
        end
        if op==0 then
            Duel.SendtoHand(tc,nil,REASON_EFFECT)
            Duel.ConfirmCards(1-tp,tc)
        else
            Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
        end
    end
end

-- ============================================================
-- Effect 3: Filter — Face-up Mermail or Atlantean on field
-- ============================================================
function s.bufffilter(c)
    return c:IsFaceup() and (c:IsSetCard(0x74) or c:IsSetCard(0x77))
end

-- ============================================================
-- Effect 3: Value — Gain 200 ATK/DEF per filter monster
-- ============================================================
function s.atkval(e,c)
    return Duel.GetMatchingGroupCount(s.bufffilter,0,LOCATION_MZONE,LOCATION_MZONE,nil)*200
end

-- ============================================================
-- Effect 4: Filter — Valid WATER monsters to show
-- ============================================================
function s.showfilter(c)
    return c:IsAttribute(ATTRIBUTE_WATER) and (c:IsLocation(LOCATION_HAND+LOCATION_ONFIELD) or (c:IsLocation(LOCATION_GRAVE) and c:IsType(TYPE_MONSTER)))
end

-- ============================================================
-- Effect 4: Condition — Opponent activates a monster effect
-- ============================================================
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    if rp==tp or not re:IsActiveType(TYPE_MONSTER) or not Duel.IsChainNegatable(ev) then return false end
    if Duel.GetFlagEffect(tp,id)>0 then return false end
    local g=Duel.GetMatchingGroup(s.showfilter,tp,LOCATION_HAND+LOCATION_ONFIELD+LOCATION_GRAVE,0,nil)
    return #g>=2
end

-- ============================================================
-- Effect 4: Operation — Reveal 2, negate effect & banish if non-WATER
-- ============================================================
function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetFlagEffect(tp,id)>0 then return end
    local g=Duel.GetMatchingGroup(s.showfilter,tp,LOCATION_HAND+LOCATION_ONFIELD+LOCATION_GRAVE,0,nil)
    if #g<2 then return end
    if Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
        Duel.Hint(HINT_CARD,0,id)
        Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
        
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
        local sg=g:Select(tp,2,2,nil)
        Duel.ConfirmCards(1-tp,sg)
        
        if Duel.NegateEffect(ev) then
            local rc=re:GetHandler()
            if rc and rc:IsRelateToEffect(re) and not rc:IsAttribute(ATTRIBUTE_WATER) then
                Duel.Remove(rc,POS_FACEUP,REASON_EFFECT)
            end
        end
    end
end
