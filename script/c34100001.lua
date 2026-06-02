-- ============================================================
-- Card Name: Ohime the Curious Mikanko
-- Passcode : 34100001
-- Type     : Monster / Xyz / Effect
-- Attribute: LIGHT
-- Rank     : 3
-- ATK/DEF  : 0 / 0
-- Race     : Fairy
-- Archetype: Mikanko (0x18e)
-- Materials: 2 Level 3 "Mikanko" monsters
-- ============================================================
-- You can also Xyz Summon this card by using 1 "Mikanko" Xyz
-- monster or 1 "Mikanko" Ritual Monster you control as material.
-- If all materials attached to this card are "Mikanko" cards, it
-- cannot be destroyed by battle or card effects, also neither player
-- takes battle damage from battles involving it.
-- If this card is Special Summoned: Destroy all Spells/Traps on the
-- field, and neither player can activate Spell/Trap Cards or effects
-- in response to this effect.
-- During your Main Phase: Detach all materials from this card; Special
-- Summon 1 "Mikanko" Xyz Monster from your Extra Deck using this card as
-- material, and equip 1 Equip Spell from your Deck or GY to 1 monster.
-- You cannot activate monster effects the turn you Special Summon this
-- card, except "Mikanko" monster effects.
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    c:EnableReviveLimit()
    Xyz.AddProcedure(c,s.filter_xyz_material,3,2,s.filter_overlay,aux.Stringid(id,0),2,s.op_overlay)

    -- ============================================================
    -- Effect 1 - Protection while every material is a "Mikanko" card
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
    e1:SetCondition(s.con_mikanko_materials)
    e1:SetValue(1)
    c:RegisterEffect(e1)
    local e2=e1:Clone()
    e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    c:RegisterEffect(e2)
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e3:SetCode(EVENT_PRE_BATTLE_DAMAGE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCondition(s.con_no_battle_damage)
    e3:SetOperation(s.op_no_battle_damage)
    c:RegisterEffect(e3)

    -- ============================================================
    -- Effect 2 - Special Summon trigger: destroy all Spells/Traps
    -- ============================================================
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,1))
    e4:SetCategory(CATEGORY_DESTROY)
    e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e4:SetProperty(EFFECT_FLAG_DELAY)
    e4:SetCode(EVENT_SPSUMMON_SUCCESS)
    e4:SetCountLimit(1,{id,1},EFFECT_COUNT_CODE_OATH)
    e4:SetTarget(s.tg_destroy_spell_trap)
    e4:SetOperation(s.op_destroy_spell_trap)
    c:RegisterEffect(e4)

    -- ============================================================
    -- Effect 3 - Xyz upgrade from Extra Deck, then equip an Equip Spell
    -- ============================================================
    local e5=Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id,2))
    e5:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_EQUIP)
    e5:SetType(EFFECT_TYPE_IGNITION)
    e5:SetRange(LOCATION_MZONE)
    e5:SetCountLimit(1,{id,2},EFFECT_COUNT_CODE_OATH)
    e5:SetCost(s.cost_detach_all)
    e5:SetTarget(s.tg_xsummon)
    e5:SetOperation(s.op_xsummon)
    c:RegisterEffect(e5)

    -- ============================================================
    -- Effect 4 - Non-"Mikanko" monster effect lock after this card is Summoned
    -- ============================================================
    local e6=Effect.CreateEffect(c)
    e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e6:SetCode(EVENT_SPSUMMON_SUCCESS)
    e6:SetOperation(s.op_monster_lock)
    c:RegisterEffect(e6)
end

function s.filter_xyz_material(c,xyz,sumtype,tp)
    return c:IsSetCard(0x18e,xyz,sumtype,tp)
end

function s.filter_overlay(c,tp,xyzc)
    return c:IsFaceup() and c:IsSetCard(0x18e,xyzc,SUMMON_TYPE_XYZ,tp)
        and c:IsType(TYPE_XYZ+TYPE_RITUAL,xyzc,SUMMON_TYPE_XYZ,tp)
end

function s.op_overlay(e,tp,chk)
    if chk==0 then return Duel.GetFlagEffect(tp,id)==0 end
    Duel.RegisterFlagEffect(tp,id,RESET_PHASE|PHASE_END,0,1)
    return true
end

function s.con_mikanko_materials(e)
    local c=e:GetHandler()
    local g=c:GetOverlayGroup()
    return #g>0 and g:FilterCount(Card.IsSetCard,nil,0x18e)==#g
end

function s.con_no_battle_damage(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsRelateToBattle() and s.con_mikanko_materials(e)
end

function s.op_no_battle_damage(e,tp,eg,ep,ev,re,r,rp)
    Duel.ChangeBattleDamage(ep,0)
end

function s.chainlimit_spell_trap(e,rp,tp)
    return not e:IsActiveType(TYPE_SPELL+TYPE_TRAP)
end

function s.filter_spell_trap(c)
    return c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsDestructable()
end

function s.tg_destroy_spell_trap(e,tp,eg,ep,ev,re,r,rp,chk)
    local g=Duel.GetMatchingGroup(s.filter_spell_trap,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
    if chk==0 then return #g>0 end
    Duel.SetChainLimit(s.chainlimit_spell_trap)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end

function s.op_destroy_spell_trap(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(s.filter_spell_trap,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
    if #g>0 then
        Duel.Destroy(g,REASON_EFFECT)
    end
end

function s.cost_detach_all(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    local ct=c:GetOverlayCount()
    if chk==0 then return ct>0 end
    c:RemoveOverlayCard(tp,ct,ct,REASON_COST)
end

function s.filter_extra_xyz(c,e,tp,mc)
    local mg=Group.FromCards(mc)
    return c:IsSetCard(0x18e) and c:IsType(TYPE_XYZ)
        and mc:IsCanBeXyzMaterial(c,tp,REASON_XYZ)
        and Duel.GetLocationCountFromEx(tp,tp,mg,c)>0
        and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end

function s.filter_equip_target(tc,tp)
    return tc:IsFaceup()
        and Duel.IsExistingMatchingCard(s.filter_equip,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,tc)
end

function s.filter_equip(c,tc)
    return c:IsType(TYPE_EQUIP) and c:CheckEquipTarget(tc)
end

function s.tg_xsummon(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.filter_extra_xyz,tp,LOCATION_EXTRA,0,1,nil,e,tp,c)
            and Duel.IsExistingMatchingCard(s.filter_equip_target,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil,tp)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
    Duel.SetOperationInfo(0,CATEGORY_EQUIP,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.op_xsummon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.filter_extra_xyz,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,c)
    local sc=g:GetFirst()
    if not sc or not s.filter_extra_xyz(sc,e,tp,c) then return end
    local mg=Group.FromCards(c)
    sc:SetMaterial(mg)
    Duel.Overlay(sc,mg,true)
    if not Duel.SpecialSummonStep(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP) then return end
    sc:CompleteProcedure()
    Duel.SpecialSummonComplete()
    if Duel.IsExistingMatchingCard(s.filter_equip_target,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil,tp) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
        local tg=Duel.SelectMatchingCard(tp,s.filter_equip_target,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil,tp)
        local tc=tg:GetFirst()
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
        local eqc=Duel.SelectMatchingCard(tp,s.filter_equip,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,tc):GetFirst()
        if eqc and Duel.Equip(tp,eqc,tc) then
            local e1=Effect.CreateEffect(sc)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
            e1:SetCode(EFFECT_EQUIP_LIMIT)
            e1:SetReset(RESET_EVENT|RESETS_STANDARD)
            e1:SetLabelObject(tc)
            e1:SetValue(s.val_equip_limit)
            eqc:RegisterEffect(e1)
        end
    end
end

function s.val_equip_limit(e,c)
    return c==e:GetLabelObject()
end

function s.op_monster_lock(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    local p=c:GetControler()
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e1:SetCode(EFFECT_CANNOT_ACTIVATE)
    e1:SetTargetRange(1,0)
    e1:SetValue(s.val_monster_lock)
    e1:SetReset(RESET_PHASE|PHASE_END)
    Duel.RegisterEffect(e1,p)
end

function s.val_monster_lock(e,re,tp)
    return re:IsActiveType(TYPE_MONSTER) and not re:GetHandler():IsSetCard(0x18e)
end
