-- ============================================================
-- Card Name: Monica, The Legendary Witch
-- Passcode : 79900010
-- Type     : Monster / Link / Effect
-- Attribute: LIGHT
-- Link     : 4  ATK: 3100
-- Race     : Spellcaster
-- Materials: 2+ Spellcaster monsters
-- ============================================================
-- Effect 1 [Trigger / HOPT]: If this card is Link Summoned:
--   You can Special Summon all materials used for this card's
--   Summon from your GY to the zones this card points to.
--   If you do, you cannot Summon monsters for the rest of this
--   Duel, except Spellcaster monsters. You can only Special
--   Summon 1 "Monica, The Legendary Witch" per turn.
--
-- Effect 2 [Quick / Twice per turn]: Once per Chain (Quick
--   Effect): Tribute 1 other Spellcaster monster you control
--   or discard 1 Spell Card; apply 1 of these effects:
--   (1) Negate the effect of 1 face-up card your opponent controls.
--   (2) Destroy all cards your opponent controls.
--   (3) Take control of 1 monster your opponent controls.
--   You can only use this effect of "Monica, The Legendary Witch"
--   twice per turn.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    c:EnableReviveLimit()
    c:SetSPSummonOnce(id)

    -- ============================================================
    -- Summon Procedure — Link Summon: 2+ Spellcaster monsters
    -- ============================================================
    Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsRace,RACE_SPELLCASTER),2,4)

    -- ============================================================
    -- Effect 1 — Trigger on Link Summon: SS materials from GY
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.lkcon)
    e1:SetTarget(s.tg_lk)
    e1:SetOperation(s.op_lk)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — Quick Effect (twice per turn): pay cost, choose 1 of 3
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY+CATEGORY_CONTROL)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(2,id+100)
    e2:SetCondition(s.qcon)
    e2:SetCost(s.qcost)
    e2:SetTarget(s.tg_q)
    e2:SetOperation(s.op_q)
    c:RegisterEffect(e2)
end

-- ============================================================
-- Effect 1: Condition — Must be Link Summoned (not revived)
-- ============================================================
function s.lkcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

-- ============================================================
-- Effect 1: Filter — material that can be Special Summoned
-- ============================================================
function s.filter_material(c,e,tp,zone)
    return c:IsLocation(LOCATION_GRAVE)
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP,tp,zone)
end

-- ============================================================
-- Effect 1: Target — check if any material is in GY
-- ============================================================
function s.tg_lk(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    local g=c:GetMaterial()
    local zone=c:GetLinkedZone(tp)
    if chk==0 then
        return zone~=0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and g and g:IsExists(s.filter_material,1,nil,e,tp,zone)
    end
    local sg=g:Filter(s.filter_material,nil,e,tp,zone)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,sg,sg:GetCount(),0,0)
end

-- ============================================================
-- Effect 1: Operation — SS materials to linked zones + lock Spellcaster only
-- ============================================================
function s.op_lk(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    local mg=c:GetMaterial()
    if not mg then return end

    -- Filter cards that can still be Special Summoned (they may have left GY)
    local zone=c:GetLinkedZone(tp)
    local sg=mg:Filter(s.filter_material,nil,e,tp,zone)
    if sg:GetCount()==0 or zone==0 or Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

    -- Summon to zones this card points to
    local count=Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP,zone)

    -- If at least 1 was summoned, this player can only Summon Spellcasters for the rest of the Duel.
    if count>0 then
        local function filter_non_spellcaster(c)
            return not c:IsRace(RACE_SPELLCASTER)
        end
        local ef1=Effect.CreateEffect(c)
        ef1:SetType(EFFECT_TYPE_FIELD)
        ef1:SetCode(EFFECT_CANNOT_SUMMON)
        ef1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_IGNORE_IMMUNE)
        ef1:SetTargetRange(1,0)
        ef1:SetTarget(filter_non_spellcaster)
        ef1:SetReset(RESET_NONE)
        Duel.RegisterEffect(ef1,tp)

        local ef1b=ef1:Clone()
        ef1b:SetCode(EFFECT_CANNOT_FLIP_SUMMON)
        Duel.RegisterEffect(ef1b,tp)

        local ef2=Effect.CreateEffect(c)
        ef2:SetType(EFFECT_TYPE_FIELD)
        ef2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
        ef2:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_IGNORE_IMMUNE)
        ef2:SetTargetRange(1,0)
        ef2:SetTarget(filter_non_spellcaster)
        ef2:SetReset(RESET_NONE)
        Duel.RegisterEffect(ef2,tp)
    end
end

-- ============================================================
-- Effect 2: Condition — once per Chain
-- ============================================================
function s.qcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetFlagEffect(tp,id)==0
end

function s.filter_tribute(c)
    return c:IsRace(RACE_SPELLCASTER) and c:IsReleasable()
end

function s.filter_discard(c)
    return c:IsType(TYPE_SPELL) and c:IsDiscardable()
end

-- ============================================================
-- Effect 2: Cost — Tribute 1 other Spellcaster OR discard 1 Spell
-- ============================================================
function s.qcost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    local can_tribute=Duel.IsExistingMatchingCard(
        s.filter_tribute,tp,LOCATION_MZONE,0,1,c)
    local can_discard=Duel.IsExistingMatchingCard(s.filter_discard,tp,LOCATION_HAND,0,1,nil)
    if chk==0 then return can_tribute or can_discard end
    Duel.RegisterFlagEffect(tp,id,RESET_CHAIN,0,1)

    -- chk==1: actually pay cost
    if can_tribute and can_discard then
        local sel=Duel.SelectOption(tp,
            aux.Stringid(id,1),   -- "Tribute 1 Spellcaster monster you control"
            aux.Stringid(id,2))   -- "Discard 1 Spell Card"
        if sel==0 then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TRIBUTE)
            local g=Duel.SelectMatchingCard(tp,
                s.filter_tribute,tp,LOCATION_MZONE,0,1,1,c)
            Duel.Release(g,REASON_COST)
        else
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
            local g=Duel.SelectMatchingCard(tp,s.filter_discard,tp,LOCATION_HAND,0,1,1,nil)
            Duel.SendtoGrave(g,REASON_COST+REASON_DISCARD)
        end
    elseif can_tribute then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TRIBUTE)
        local g=Duel.SelectMatchingCard(tp,s.filter_tribute,tp,LOCATION_MZONE,0,1,1,c)
        Duel.Release(g,REASON_COST)
    else
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
        local g=Duel.SelectMatchingCard(tp,s.filter_discard,tp,LOCATION_HAND,0,1,1,nil)
        Duel.SendtoGrave(g,REASON_COST+REASON_DISCARD)
    end
end

function s.can_negate(tp)
    return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE+LOCATION_SZONE,1,nil)
end

function s.can_destroy(tp)
    return Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_MZONE+LOCATION_SZONE,1,nil)
end

function s.can_control(tp)
    return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(aux.FilterBoolFunctionEx(Card.IsType,TYPE_MONSTER),tp,0,LOCATION_MZONE,1,nil)
end

function s.get_options(tp)
    local ops={}
    local descs={}
    if s.can_negate(tp) then
        table.insert(ops,0)
        table.insert(descs,aux.Stringid(id,3))
    end
    if s.can_destroy(tp) then
        table.insert(ops,1)
        table.insert(descs,aux.Stringid(id,4))
    end
    if s.can_control(tp) then
        table.insert(ops,2)
        table.insert(descs,aux.Stringid(id,5))
    end
    return ops,descs
end

-- ============================================================
-- Effect 2: Target — at least 1 sub-effect is usable
-- ============================================================
function s.tg_q(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return s.can_negate(tp) or s.can_destroy(tp) or s.can_control(tp)
    end
    local ops,descs=s.get_options(tp)
    local sel=Duel.SelectOption(tp,table.unpack(descs))
    local op=ops[sel+1]
    e:SetLabel(op)
    if op==0 then
        Duel.SetOperationInfo(0,CATEGORY_NEGATE,nil,1,1-tp,LOCATION_MZONE+LOCATION_SZONE)
    elseif op==1 then
        Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,0,1-tp,LOCATION_MZONE+LOCATION_SZONE)
    else
        Duel.SetOperationInfo(0,CATEGORY_CONTROL,nil,1,1-tp,LOCATION_MZONE)
    end
end

-- ============================================================
-- Effect 2: Operation — select and resolve 1 of 3 sub-effects
-- ============================================================
function s.op_q(e,tp,eg,ep,ev,re,r,rp)
    local op=e:GetLabel()

    if op==0 then
        -- (1) Negate effect of 1 face-up card opponent controls
        if not s.can_negate(tp) then return end
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELECT)
        local g=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,0,LOCATION_MZONE+LOCATION_SZONE,1,1,nil)
        local tc=g:GetFirst()
        if tc then
            local eneg=Effect.CreateEffect(e:GetHandler())
            eneg:SetType(EFFECT_TYPE_SINGLE)
            eneg:SetCode(EFFECT_DISABLE)
            eneg:SetReset(RESET_EVENT+0x1fe0000)
            tc:RegisterEffect(eneg)
            local eneg2=eneg:Clone()
            eneg2:SetCode(EFFECT_DISABLE_EFFECT)
            tc:RegisterEffect(eneg2)
        end

    elseif op==1 then
        -- (2) Destroy all cards opponent controls
        local g=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_MZONE+LOCATION_SZONE,nil)
        if g:GetCount()>0 then
            Duel.Destroy(g,REASON_EFFECT)
        end

    else
        -- (3) Take control of 1 monster opponent controls
        if not s.can_control(tp) then return end
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELECT)
        local g=Duel.SelectMatchingCard(tp,aux.FilterBoolFunctionEx(Card.IsType,TYPE_MONSTER),tp,0,LOCATION_MZONE,1,1,nil)
        local tc=g:GetFirst()
        if tc then
            local ectrl=Effect.CreateEffect(e:GetHandler())
            ectrl:SetType(EFFECT_TYPE_SINGLE)
            ectrl:SetCode(EFFECT_SET_CONTROL)
            ectrl:SetValue(tp)
            ectrl:SetReset(RESET_PHASE+PHASE_END+RESET_SELF_TURN)
            tc:RegisterEffect(ectrl)
        end
    end
end
