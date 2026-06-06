-- ============================================================
-- Card Name: Setsuna of Bygone Days
-- Passcode : 192300002
-- Type     : Monster / Link / Effect
-- Attribute: LIGHT
-- Link     : 1
-- ATK      : 0
-- Race     : Cyberse
-- Archetype: Wezaemon (0x783)
-- Materials: 1 monster
-- Markers  : Right (→)
-- ============================================================
-- Effect 1: Cannot be used as Link Material.
-- Effect 2: If this card is Link Summoned: You can Special
--           Summon 1 "Wezaemon the Tombguard" from your hand
--           or Deck, and if you do, banish all other monsters
--           you control. This effect cannot be negated if you
--           control no monsters in your Main Monster Zones.
-- Limit   : You can only Special Summon "Setsuna of Bygone
--           Days" once per turn.
-- ============================================================

local s,id=GetID()

s.listed_names={192300001}

function s.initial_effect(c)
    c:EnableReviveLimit()

    -- ============================================================
    -- Summon Procedure — Link-1, any 1 monster
    -- ============================================================
    Link.AddProcedure(c,nil,1,1)

    -- ============================================================
    -- SS limit: once per turn
    -- ============================================================
    c:SetSPSummonOnce(id)

    -- ============================================================
    -- Effect 1 — Cannot be used as Link Material
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e1:SetValue(1)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — Trigger on Link Summon: SS Wezaemon from hand/Deck
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetCondition(s.spcon)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)
end

-- ============================================================
-- Effect 2: Condition — Must be Link Summoned
-- ============================================================
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

-- ============================================================
-- Effect 2: Filter — Wezaemon in hand or Deck
-- ============================================================
function s.spfilter(c,e,tp)
    return c:IsCode(192300001) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- ============================================================
-- Effect 2: Target — Check if Wezaemon available
-- ============================================================
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
    -- Cannot be negated if no monsters in Main Monster Zones
    -- (Setsuna is in Extra Monster Zone at this point)
    local mg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,e:GetHandler())
    if #mg==0 then
        e:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    end
end

-- ============================================================
-- Effect 2: Operation — SS Wezaemon, banish all other monsters
-- ============================================================
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp)
    if #g>0 then
        if Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)>0 then
            -- Banish all other monsters you control
            local bg=Duel.GetMatchingGroup(s.banishfilter,tp,LOCATION_MZONE,0,nil,g:GetFirst())
            if #bg>0 then
                Duel.Remove(bg,POS_FACEUP,REASON_EFFECT)
            end
        end
    end
end
function s.banishfilter(c,wezaemon)
    return c~=wezaemon and not c:IsCode(192300001)
end
