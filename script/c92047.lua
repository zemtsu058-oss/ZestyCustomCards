-- ============================================================
-- Card Name: Pollux, Netherwing Husk, Ferry of Souls
-- Passcode : 92047
-- Type     : Dragon / Fusion / Effect
-- Attribute: DARK
-- Level    : 10
-- ATK/DEF  : ? / ?
-- ============================================================
-- Materials: 2 monsters in the GY and/or Special Summoned from the GY.
-- Effect 1: The original ATK/DEF of this card becomes the combined
--           original ATK/DEF of the materials used for its Fusion Summon.
-- Effect 2: You can only control 1 "Pollux, Netherwing Husk, Ferry
--           of Souls".
-- Effect 3: Unaffected by your opponent's card effects while
--           "Dragonbone City Styxia" is in your Field Zone.
-- Effect 4: If you would lose LP, you can make this card lose DEF
--           equal to half of the LP lost instead.
-- Effect 5: If this card leaves the field: return it to the Extra
--           Deck; gain LP equal to the original DEF it had on the
--           field, then if it leaves the field because of an
--           opponent's card, destroy all monsters your opponent
--           controls with ATK less than the original ATK it had on
--           the field.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- Enable revive limit
    c:EnableReviveLimit()
    -- Fusion material
    Fusion.AddProcFunRep(c,s.ffilter,2,false)
    -- Unique control
    c:SetUniqueOnField(1,0,id)

    -- ============================================================
    -- Effect 1 — Continuous: Combined ATK/DEF from materials
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_MATERIAL_CHECK)
    e1:SetValue(s.matop)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 3 — Continuous: Immune to opponent effects while Styxia on field
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCode(EFFECT_IMMUNE_EFFECT)
    e2:SetCondition(s.immcon)
    e2:SetValue(s.efilter)
    c:RegisterEffect(e2)

    -- ============================================================
    -- Effect 4a — Continuous: Replace battle damage with DEF loss
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e3:SetCode(EVENT_PRE_BATTLE_DAMAGE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetOperation(s.op_replace_battle)
    c:RegisterEffect(e3)

    -- ============================================================
    -- Effect 4b — Field: Replace effect damage with DEF loss (auto)
    -- ============================================================
    local e3b=Effect.CreateEffect(c)
    e3b:SetType(EFFECT_TYPE_FIELD)
    e3b:SetCode(EFFECT_CHANGE_DAMAGE)
    e3b:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e3b:SetRange(LOCATION_MZONE)
    e3b:SetTargetRange(1,0)
    e3b:SetValue(s.val_replace_effdmg)
    c:RegisterEffect(e3b)

    -- ============================================================
    -- Effect 5 — Trigger: When leaves the field
    -- ============================================================
    local e4=Effect.CreateEffect(c)
    e4:SetCategory(CATEGORY_RECOVER+CATEGORY_DESTROY+CATEGORY_TOEXTRA)
    e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e4:SetCode(EVENT_LEAVE_FIELD)
    e4:SetCondition(s.lfcon)
    e4:SetTarget(s.lftg)
    e4:SetOperation(s.lfop)
    c:RegisterEffect(e4)
end

-- ============================================================
-- Effect 1: Filter — Valid materials (GY or MZone if summoned from GY)
-- ============================================================
function s.ffilter(c,fc,sumtype,tp)
    return c:IsLocation(LOCATION_GRAVE) or (c:IsLocation(LOCATION_MZONE) and c:IsSummonLocation(LOCATION_GRAVE))
end

-- ============================================================
-- Effect 1: Operation — Set original ATK/DEF and register flags
-- ============================================================
function s.matop(e,c)
    local g=c:GetMaterial()
    if not g or #g==0 then return end
    local atk,def=0,0
    for tc in aux.Next(g) do
        atk=atk+math.max(tc:GetBaseAttack(),0)
        def=def+math.max(tc:GetBaseDefense(),0)
    end
    -- Set base ATK
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_SET_BASE_ATTACK)
    e1:SetValue(atk)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TOFIELD)
    c:RegisterEffect(e1)
    -- Set base DEF
    local e2=e1:Clone()
    e2:SetCode(EFFECT_SET_BASE_DEFENSE)
    e2:SetValue(def)
    c:RegisterEffect(e2)

    -- Register flag effects for leaving field stats
    c:ResetFlagEffect(id)
    c:ResetFlagEffect(id+100)
    c:RegisterFlagEffect(id,0,0,1,atk)
    c:RegisterFlagEffect(id+100,0,0,1,def)
end

-- ============================================================
-- Effect 3: Condition — Styxia is in your Field Zone
-- ============================================================
function s.immcon(e)
    return Duel.IsExistingMatchingCard(Card.IsCode,e:GetHandlerPlayer(),LOCATION_FZONE,0,1,nil,45128)
end

-- ============================================================
-- Effect 3: Filter — Immune only to opponent's effects
-- ============================================================
function s.efilter(e,re)
    return e:GetHandlerPlayer()~=re:GetOwnerPlayer()
end

-- ============================================================
-- Effect 4a: Operation — Replace battle damage with DEF loss
-- ============================================================
function s.op_replace_battle(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if ep~=tp then return end
    if ev<=0 then return end
    local half=math.floor(ev/2)
    if c:GetDefense()<half then return end
    if not Duel.SelectYesNo(tp,aux.Stringid(id,0)) then return end
    Duel.Hint(HINT_CARD,0,id)
    Duel.ChangeBattleDamage(tp,0)
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_UPDATE_DEFENSE)
    e1:SetValue(-half)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    c:RegisterEffect(e1)
end

-- ============================================================
-- Effect 4b: Value — Auto-replace effect damage with DEF loss
-- ============================================================
function s.val_replace_effdmg(e,re,dam,r,rp,rc)
    local c=e:GetHandler()
    if dam<=0 then return dam end
    local half=math.floor(dam/2)
    if c:GetDefense()<half then return dam end
    Duel.Hint(HINT_CARD,0,id)
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_UPDATE_DEFENSE)
    e1:SetValue(-half)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    c:RegisterEffect(e1)
    return 0
end

-- ============================================================
-- Effect 5: Condition — Must be face-up on the field before leaving
-- ============================================================
function s.lfcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsPreviousLocation(LOCATION_ONFIELD)
end

-- ============================================================
-- Effect 5: Target — Declare categories and operations
-- ============================================================
function s.lftg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    local c=e:GetHandler()
    local def=c:GetFlagEffectLabel(id+100) or 0
    Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,def)
    if c:IsType(TYPE_FUSION) then
        Duel.SetOperationInfo(0,CATEGORY_TOEXTRA,c,1,0,0)
    end
    if c:GetReasonPlayer()==1-tp then
        Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,1-tp,LOCATION_MZONE)
    end
end

-- ============================================================
-- Effect 5: Operation — Send to Extra Deck, gain LP, destroy opponent's monsters
-- ============================================================
function s.lfop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local atk=c:GetFlagEffectLabel(id) or 0
    local def=c:GetFlagEffectLabel(id+100) or 0
    local removed_by_opponent=c:GetReasonPlayer()==1-tp
    -- Clear flag effects
    c:ResetFlagEffect(id)
    c:ResetFlagEffect(id+100)
    -- Return to Extra Deck (face-down)
    if c:IsType(TYPE_FUSION) then
        Duel.SendtoDeck(c,nil,SEQ_DECKTOP,REASON_EFFECT)
    end
    -- Gain LP equal to original DEF
    Duel.Recover(tp,def,REASON_EFFECT)
    -- Destroy opponent monsters with ATK < original ATK
    if removed_by_opponent and atk>0 then
        local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
        local dg=g:Filter(function(tc) return tc:GetAttack()<atk end,nil)
        if #dg>0 then
            Duel.Destroy(dg,REASON_EFFECT)
        end
    end
end
