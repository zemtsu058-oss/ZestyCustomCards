--[[
===========================================
  Monica, The Legendary Witch
  ID: 79900010 | Link Monster | ATK 3100 LINK-4
===========================================

  Link Material: 2+ Spellcaster monsters

  [HU1 - TRIGGER / HOPT] Khi Link Summon thành công
    - Special Summon tất cả material dùng để Summon lá này từ GY
      về các zone mà lá này trỏ tới
    - Nếu làm vậy, phần còn lại của Duel chỉ có thể Summon Spellcaster

  [HU2 - QUICK / 2 lần/turn] Quick Effect
    - Tribute 1 Spellcaster khác bạn control HOẶC discard 1 Spell Card
    - Áp dụng 1 trong 3 hiệu ứng:
      (1) Negate hiệu ứng của 1 lá face-up đối thủ control
      (2) Destroy tất cả lá đối thủ control
      (3) Giành quyền control 1 monster đối thủ control

===========================================
]]
local s,id=GetID()

function s.initial_effect(c)

    -- Link Summon procedure: 2+ Spellcaster monsters
    c:EnableReviveLimit()
    Link.AddProcedure(c,
        aux.FilterBoolFunctionEx(Card.IsRace,RACE_SPELLCASTER),
        2,99)

    -------------------------------------------------
    -- HU1: Trigger khi Link Summon thành công
    -------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.lkcon)
    e1:SetTarget(s.lktg)
    e1:SetOperation(s.lkop)
    c:RegisterEffect(e1)

    -------------------------------------------------
    -- HU2: Quick Effect (2 lần/turn)
    -------------------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY+CATEGORY_CONTROL)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(2,id+100)
    e2:SetCost(s.qcost)
    e2:SetTarget(s.qtg)
    e2:SetOperation(s.qop)
    c:RegisterEffect(e2)
end

-------------------------------------------------
-- HU1: Phải là Link Summon
-------------------------------------------------
function s.lkcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

-------------------------------------------------
-- HU1: Target - kiểm tra có material nào trong GY không
-------------------------------------------------
function s.lkcon2(c)
    return c:IsAbleToSummon()
end

function s.lktg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    -- Lấy group các lá đã dùng làm material từ GY
    local g=c:GetMaterialGroup()
    if chk==0 then
        return g and g:IsExists(s.lkcon2,1,nil)
    end
    if not g then return end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,g:GetCount(),0,0)
end

-------------------------------------------------
-- HU1: Operation - Summon material từ GY + lock Spellcaster only
-------------------------------------------------
function s.lkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local g=c:GetMaterialGroup()
    if not g then return end

    -- Lọc các lá có thể Special Summon từ GY
    local sg=g:Filter(s.lkcon2,nil)
    if sg:GetCount()==0 then return end

    -- Special Summon về các zone lá này trỏ tới
    local zone=c:GetLinkedZone(tp)
    local summon_count=Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP,zone)

    -- Nếu Summon thành công ít nhất 1 lá → lock Spellcaster only (cả hai player)
    if summon_count>0 then
        -- Restrict summon: chỉ Spellcaster
        local function spellcaster_only(c)
            return not c:IsRace(RACE_SPELLCASTER)
        end
        for i=0,1 do
            local eflock=Effect.CreateEffect(c)
            eflock:SetType(EFFECT_TYPE_FIELD)
            eflock:SetCode(EFFECT_CANNOT_SUMMON)
            eflock:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_IGNORE_IMMUNE)
            eflock:SetTargetRange(1,1)
            eflock:SetTarget(spellcaster_only)
            -- Lock đến hết Duel (không có reset theo turn/phase)
            eflock:SetReset(RESET_EVENT+0x1fe0000)
            Duel.RegisterEffect(eflock,i)

            local eflocksp=Effect.CreateEffect(c)
            eflocksp:SetType(EFFECT_TYPE_FIELD)
            eflocksp:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
            eflocksp:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_IGNORE_IMMUNE)
            eflocksp:SetTargetRange(1,1)
            eflocksp:SetTarget(spellcaster_only)
            -- Lock đến hết Duel (không có reset theo turn/phase)
            eflocksp:SetReset(RESET_EVENT+0x1fe0000)
            Duel.RegisterEffect(eflocksp,i)
        end
    end
end

-------------------------------------------------
-- HU2: Cost - Tribute 1 Spellcaster khác HOẶC discard 1 Spell
-------------------------------------------------
function s.qcost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    local can_tribute=Duel.IsExistingMatchingCard(
        aux.FilterBoolFunctionEx(Card.IsRace,RACE_SPELLCASTER),
        tp,LOCATION_MZONE,0,1,c)
    local can_discard=Duel.IsExistingMatchingCard(
        aux.FilterBoolFunctionEx(Card.IsType,TYPE_SPELL),
        tp,LOCATION_HAND,0,1,nil)
    if chk==0 then return can_tribute or can_discard end

    -- Offer choice
    if can_tribute and can_discard then
        local sel=Duel.SelectOption(tp,
            aux.Stringid(id,0),  -- "Tribute 1 Spellcaster"
            aux.Stringid(id,1))  -- "Discard 1 Spell"
        if sel==0 then
            -- Tribute a Spellcaster
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TRIBUTE)
            local g=Duel.SelectMatchingCard(tp,
                aux.FilterBoolFunctionEx(Card.IsRace,RACE_SPELLCASTER),
                tp,LOCATION_MZONE,0,1,1,c)
            Duel.SendtoGrave(g,REASON_COST+REASON_TRIBUTE)
        else
            -- Discard a Spell
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
            local g=Duel.SelectMatchingCard(tp,
                aux.FilterBoolFunctionEx(Card.IsType,TYPE_SPELL),
                tp,LOCATION_HAND,0,1,1,nil)
            Duel.SendtoGrave(g,REASON_COST+REASON_DISCARD)
        end
    elseif can_tribute then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TRIBUTE)
        local g=Duel.SelectMatchingCard(tp,
            aux.FilterBoolFunctionEx(Card.IsRace,RACE_SPELLCASTER),
            tp,LOCATION_MZONE,0,1,1,c)
        Duel.SendtoGrave(g,REASON_COST+REASON_TRIBUTE)
    else
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
        local g=Duel.SelectMatchingCard(tp,
            aux.FilterBoolFunctionEx(Card.IsType,TYPE_SPELL),
            tp,LOCATION_HAND,0,1,1,nil)
        Duel.SendtoGrave(g,REASON_COST+REASON_DISCARD)
    end
end

-------------------------------------------------
-- HU2: Target - chọn 1 trong 3 hiệu ứng
-------------------------------------------------
function s.qtg(e,tp,eg,ep,ev,re,r,rp,chk)
    local opp = 1 - tp
    if chk==0 then
        -- Option 1: có lá face-up của đối thủ
        local has_face_up=Duel.IsExistingMatchingCard(
            Card.IsFaceup,tp,0,LOCATION_MZONE+LOCATION_SZONE,1,nil)
        -- Option 2: có lá nào đó của đối thủ trên sân
        local has_card=Duel.IsExistingMatchingCard(
            aux.TRUE,tp,0,LOCATION_MZONE+LOCATION_SZONE,1,nil)
        -- Option 3: có quái của đối thủ
        local has_monster=Duel.IsExistingMatchingCard(
            aux.FilterBoolFunctionEx(Card.IsType,TYPE_MONSTER),
            tp,0,LOCATION_MZONE,1,nil)
        return has_face_up or has_card or has_monster
    end
    -- Announce options
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,nil,1,opp,LOCATION_MZONE+LOCATION_SZONE)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,0,opp,LOCATION_MZONE+LOCATION_SZONE)
    Duel.SetOperationInfo(0,CATEGORY_CONTROL,nil,1,opp,LOCATION_MZONE)
end

-------------------------------------------------
-- HU2: Operation - chọn và thực hiện 1 trong 3
-------------------------------------------------
function s.qop(e,tp,eg,ep,ev,re,r,rp)
    -- Prompt player to choose effect
    local sel=Duel.SelectOption(tp,
        aux.Stringid(id,2),   -- "(1) Negate effect of 1 face-up card opponent controls"
        aux.Stringid(id,3),   -- "(2) Destroy all cards opponent controls"
        aux.Stringid(id,4))   -- "(3) Take control of 1 monster opponent controls"

    if sel==0 then
        -- (1) Negate effect of 1 face-up card opponent controls
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELECT)
        local g=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,0,LOCATION_MZONE+LOCATION_SZONE,1,1,nil)
        local tc=g:GetFirst()
        if tc then
            local neg=Effect.CreateEffect(e:GetHandler())
            neg:SetType(EFFECT_TYPE_SINGLE)
            neg:SetCode(EFFECT_DISABLE)
            neg:SetReset(RESET_EVENT+0x1fe0000)
            tc:RegisterEffect(neg)
        end

    elseif sel==1 then
        -- (2) Destroy all cards opponent controls
        local g=Duel.GetMatchingGroup(
            aux.TRUE,tp,0,LOCATION_MZONE+LOCATION_SZONE,nil)
        if g:GetCount()>0 then
            Duel.Destroy(g,REASON_EFFECT)
        end

    else
        -- (3) Take control of 1 monster opponent controls
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELECT)
        local g=Duel.SelectMatchingCard(tp,
            aux.FilterBoolFunctionEx(Card.IsType,TYPE_MONSTER),
            tp,0,LOCATION_MZONE,1,1,nil)
        local tc=g:GetFirst()
        if tc then
            local ctrl=Effect.CreateEffect(e:GetHandler())
            ctrl:SetType(EFFECT_TYPE_SINGLE)
            ctrl:SetCode(EFFECT_CHANGE_CONTROL)
            ctrl:SetReset(RESET_PHASE+PHASE_END+RESET_SELF_TURN)
            tc:RegisterEffect(ctrl)
        end
    end
end
