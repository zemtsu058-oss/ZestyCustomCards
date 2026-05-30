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
--   (1) Negate the effects of 1 face-up card your opponent controls.
--   (2) Destroy all cards your opponent controls.
--   (3) Take control of 1 monster your opponent controls.
--   You can only use this effect of "Monica, The Legendary Witch"
--   twice per turn.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    c:EnableReviveLimit()
    c:SetSPSummonOnce(id)

    -- Summon Procedure — Link: 2+ Spellcaster monsters
    Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsRace,RACE_SPELLCASTER),2,4)

    -- Effect 1 — Trigger on Link Summon: SS materials from GY to linked zones
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCondition(s.lkcon)
    e1:SetTarget(s.lktg)
    e1:SetOperation(s.lkop)
    c:RegisterEffect(e1)

    -- Effect 2 — Quick Effect: once per chain, twice per turn
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_DISABLE+CATEGORY_DESTROY+CATEGORY_CONTROL)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER)
    e2:SetCountLimit(2,id+100,EFFECT_COUNT_CODE_OATH)
    e2:SetCondition(s.qkcon)
    e2:SetCost(s.qkcost)
    e2:SetTarget(s.qktg)
    e2:SetOperation(s.qkop)
    c:RegisterEffect(e2)
end

-- ============================================================
-- Effect 1: Condition — Must be Link Summoned
-- ============================================================
function s.lkcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

-- ============================================================
-- Effect 1: Filter — material in GY summonable to linked zones
-- ============================================================
function s.lkfilter(c,e,tp,c_link)
    local zone_tp=c_link:GetLinkedZone(tp)
    local zone_op=c_link:GetLinkedZone(1-tp)
    return c:IsLocation(LOCATION_GRAVE)
        and (c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP,tp,zone_tp)
            or c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP,1-tp,zone_op))
end

-- ============================================================
-- Effect 1: Target — at least 1 material is SS-able
-- ============================================================
function s.lktg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    local mg=c:GetMaterial()
    if chk==0 then
        return mg and #mg>0 and mg:IsExists(s.lkfilter,1,nil,e,tp,c)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,0,tp,LOCATION_GRAVE)
end

-- ============================================================
-- Effect 1: Operation — SS materials + Spellcaster-only lock
-- ============================================================
function s.lkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    local mg=c:GetMaterial()
    if not mg then return end
    local sg=mg:Filter(s.lkfilter,nil,e,tp,c)
    if #sg==0 then return end
    
    local zone_tp=c:GetLinkedZone(tp)
    local zone_op=c:GetLinkedZone(1-tp)
    
    local g=sg:Clone()
    local summon_group=Group.CreateGroup()
    while #g>0 do
        local space_tp=Duel.GetLocationCount(tp,LOCATION_MZONE,tp,LOCATION_REASON_TOFIELD,zone_tp)
        local space_op=Duel.GetLocationCount(1-tp,LOCATION_MZONE,tp,LOCATION_REASON_TOFIELD,zone_op)
        if space_tp<=0 and space_op<=0 then break end
        
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local tc=g:Select(tp,1,1,nil):GetFirst()
        if not tc then break end
        g:RemoveCard(tc)
        
        local can_tp=space_tp>0 and tc:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP,tp,zone_tp)
        local can_op=space_op>0 and tc:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP,1-tp,zone_op)
        
        if can_tp or can_op then
            local target_player=tp
            local current_zone=zone_tp
            if can_tp and can_op then
                -- Player chooses: 0 for Self, 1 for Opponent
                local sel=Duel.SelectOption(tp,aux.Stringid(id,6),aux.Stringid(id,7))
                if sel==1 then
                    target_player=1-tp
                    current_zone=zone_op
                end
            elseif can_op then
                target_player=1-tp
                current_zone=zone_op
            end
            
            if Duel.SpecialSummonStep(tc,0,tp,target_player,false,false,POS_FACEUP,current_zone) then
                summon_group:AddCard(tc)
            end
        end
    end
    
    if #summon_group>0 then
        Duel.SpecialSummonComplete()
        -- Spellcaster-only summon lock for rest of duel
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_FIELD)
        e1:SetCode(EFFECT_CANNOT_SUMMON)
        e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_IGNORE_IMMUNE)
        e1:SetTargetRange(1,0)
        e1:SetTarget(s.filter_non_spellcaster)
        Duel.RegisterEffect(e1,tp)
        local e2=Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_FIELD)
        e2:SetCode(EFFECT_CANNOT_FLIP_SUMMON)
        e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_IGNORE_IMMUNE)
        e2:SetTargetRange(1,0)
        e2:SetTarget(s.filter_non_spellcaster)
        Duel.RegisterEffect(e2,tp)
        local e3=Effect.CreateEffect(c)
        e3:SetType(EFFECT_TYPE_FIELD)
        e3:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
        e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_IGNORE_IMMUNE)
        e3:SetTargetRange(1,0)
        e3:SetTarget(s.filter_non_spellcaster)
        Duel.RegisterEffect(e3,tp)
    end
end

-- ============================================================
-- Spellcaster-only lock filter
-- ============================================================
function s.filter_non_spellcaster(e,c)
    return c and not c:IsRace(RACE_SPELLCASTER)
end

-- ============================================================
-- Effect 2: Condition — Once per Chain
-- ============================================================
function s.qkcon(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetFlagEffect(tp,id)==0
end

-- ============================================================
-- Effect 2: Filter — other Spellcaster to tribute
-- ============================================================
function s.tribfilter(c)
    return c:IsRace(RACE_SPELLCASTER) and c:IsReleasable()
end

-- ============================================================
-- Effect 2: Filter — Spell to discard
-- ============================================================
function s.discfilter(c)
    return c:IsType(TYPE_SPELL) and c:IsDiscardable()
end

-- ============================================================
-- Effect 2: Cost — Tribute 1 other Spellcaster OR discard 1 Spell + chain flag
-- ============================================================
function s.qkcost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    local can_tribute=Duel.IsExistingMatchingCard(s.tribfilter,tp,LOCATION_MZONE,0,1,c)
    local can_discard=Duel.IsExistingMatchingCard(s.discfilter,tp,LOCATION_HAND,0,1,nil)
    if chk==0 then return can_tribute or can_discard end
    Duel.RegisterFlagEffect(tp,id,RESET_CHAIN,0,1)
    if can_tribute and can_discard then
        local sel=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))
        if sel==0 then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
            local g=Duel.SelectMatchingCard(tp,s.tribfilter,tp,LOCATION_MZONE,0,1,1,c)
            Duel.Release(g,REASON_COST)
        else
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
            local g=Duel.SelectMatchingCard(tp,s.discfilter,tp,LOCATION_HAND,0,1,1,nil)
            Duel.SendtoGrave(g,REASON_COST+REASON_DISCARD)
        end
    elseif can_tribute then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
        local g=Duel.SelectMatchingCard(tp,s.tribfilter,tp,LOCATION_MZONE,0,1,1,c)
        Duel.Release(g,REASON_COST)
    else
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
        local g=Duel.SelectMatchingCard(tp,s.discfilter,tp,LOCATION_HAND,0,1,1,nil)
        Duel.SendtoGrave(g,REASON_COST+REASON_DISCARD)
    end
end

-- ============================================================
-- Effect 2: Sub-effect legality checks
-- ============================================================
function s.can_negate(tp)
    return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_ONFIELD,1,nil)
end

function s.can_destroy(tp)
    return Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil)
end

function s.can_control(tp)
    return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
        and Duel.IsExistingMatchingCard(Card.IsControlerCanBeChanged,tp,0,LOCATION_MZONE,1,nil)
end

-- ============================================================
-- Effect 2: Build dynamic option list
-- ============================================================
function s.get_options(tp)
    local ops={}
    local descs={}
    if s.can_negate(tp) then table.insert(ops,0); table.insert(descs,aux.Stringid(id,3)) end
    if s.can_destroy(tp) then table.insert(ops,1); table.insert(descs,aux.Stringid(id,4)) end
    if s.can_control(tp) then table.insert(ops,2); table.insert(descs,aux.Stringid(id,5)) end
    return ops,descs
end

-- ============================================================
-- Effect 2: Target — at least 1 sub-effect usable, select option
-- ============================================================
function s.qktg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return s.can_negate(tp) or s.can_destroy(tp) or s.can_control(tp)
    end
    local ops,descs=s.get_options(tp)
    local sel=Duel.SelectOption(tp,table.unpack(descs))
    local op=ops[sel+1]
    e:SetLabel(op)
    if op==0 then
        Duel.SetOperationInfo(0,CATEGORY_DISABLE,nil,1,1-tp,LOCATION_ONFIELD)
    elseif op==1 then
        Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,0,1-tp,LOCATION_ONFIELD)
    else
        Duel.SetOperationInfo(0,CATEGORY_CONTROL,nil,1,1-tp,LOCATION_MZONE)
    end
end

-- ============================================================
-- Effect 2: Operation — resolve selected sub-effect
-- ============================================================
function s.qkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    local op=e:GetLabel()
    if op==0 then
        -- (1) Negate effects of 1 face-up card opponent controls
        if not s.can_negate(tp) then return end
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
        local g=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,0,LOCATION_ONFIELD,1,1,nil)
        if #g>0 then
            local tc=g:GetFirst()
            local e1=Effect.CreateEffect(c)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_DISABLE)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD)
            tc:RegisterEffect(e1)
            local e2=Effect.CreateEffect(c)
            e2:SetType(EFFECT_TYPE_SINGLE)
            e2:SetCode(EFFECT_DISABLE_EFFECT)
            e2:SetReset(RESET_EVENT+RESETS_STANDARD)
            tc:RegisterEffect(e2)
        end
    elseif op==1 then
        -- (2) Destroy all cards opponent controls
        local g=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_ONFIELD,nil)
        if #g>0 then
            Duel.Destroy(g,REASON_EFFECT)
        end
    else
        -- (3) Take control of 1 monster opponent controls (permanent)
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
        local g=Duel.SelectMatchingCard(tp,Card.IsControlerCanBeChanged,tp,0,LOCATION_MZONE,1,1,nil)
        if #g>0 then
            Duel.GetControl(g,tp)
        end
    end
end
