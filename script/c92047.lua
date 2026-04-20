local s,id=GetID()

---------------------------------------------------
-- 1. ĐỊNH NGHĨA CÁC HÀM TRƯỚC (Để tránh lỗi nil function)
---------------------------------------------------

-- Filter nguyên liệu
function s.ffilter(c,fc,sumtype,tp)
    return c:IsLocation(LOCATION_GRAVE) or (c:IsLocation(LOCATION_MZONE) and c:IsSummonLocation(LOCATION_GRAVE))
end

-- Tính ATK/DEF từ nguyên liệu
function s.matop(e,c)
    local g=c:GetMaterial()
    if not g or #g==0 then return end
    local atk,def=0,0
    for tc in aux.Next(g) do
        atk=atk+math.max(tc:GetBaseAttack(),0)
        def=def+math.max(tc:GetBaseDefense(),0)
    end
    -- Gán ATK gốc
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_SET_BASE_ATTACK)
    e1:SetValue(atk)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TOFIELD)
    c:RegisterEffect(e1)
    -- Gán DEF gốc
    local e2=e1:Clone()
    e2:SetCode(EFFECT_SET_BASE_DEFENSE) 
    e2:SetValue(def)
    c:RegisterEffect(e2)
end

-- Điều kiện kháng hiệu ứng (Cần Field Spell ID 45128)
function s.immcon(e)
    return Duel.IsEnvironment(45128)
end
function s.efilter(e,re)
    return e:GetHandlerPlayer()~=re:GetOwnerPlayer()
end

-- Cơ chế trừ DEF thay cho mất LP
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
    return ep==tp and ev and ev>0 and e:GetHandler():GetDefense()>=math.floor(ev/2)
end
function s.damop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
        Duel.Hint(HINT_CARD,0,id)
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_DEFENSE)
        e1:SetValue(-math.floor(ev/2))
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        c:RegisterEffect(e1)
        Duel.ChangeDamage(tp,0)
    end
end

-- Hiệu ứng khi rời sân
function s.lftg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    local def=e:GetHandler():GetPreviousDefenseOnField() or 0
    Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,def)
end
function s.lfop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local atk=c:GetPreviousAttackOnField() or 0
    local def=c:GetPreviousDefenseOnField() or 0
    if c:IsType(TYPE_FUSION) then
        Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
    end
    Duel.Recover(tp,def,REASON_EFFECT)
    if c:GetReasonPlayer()==1-tp then
        local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
        local dg=g:Filter(function(tc) return tc:GetAttack()<atk end,nil)
        if #dg>0 then
            Duel.Destroy(dg,REASON_EFFECT)
        end
    end
end

---------------------------------------------------
-- 2. ĐĂNG KÝ HIỆU ỨNG (Sau khi các hàm đã sẵn sàng)
---------------------------------------------------
function s.initial_effect(c)
    c:EnableReviveLimit()
    Fusion.AddProcFunRep(c,s.ffilter,2,false)
    c:SetUniqueOnField(1,0,id)

    -- Material check
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_MATERIAL_CHECK)
    e1:SetOperation(s.matop)
    c:RegisterEffect(e1)

    -- Immune
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCode(EFFECT_IMMUNE_EFFECT)
    e2:SetCondition(s.immcon)
    e2:SetValue(s.efilter)
    c:RegisterEffect(e2)

    -- Damage replace (Sửa EVENT_PRE_DAMAGE thành hằng số chuẩn)
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e4:SetCode(EVENT_PRE_BATTLE_DAMAGE)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCondition(s.damcon)
    e4:SetOperation(s.damop)
    c:RegisterEffect(e4)
    -- Thêm hiệu ứng cho sát thương từ Effect
    local e4b=e4:Clone()
    e4b:SetCode(EVENT_DAMAGE)
    c:RegisterEffect(e4b)

    -- Leave field
    local e5=Effect.CreateEffect(c)
    e5:SetCategory(CATEGORY_RECOVER+CATEGORY_DESTROY+CATEGORY_TOEXTRA)
    e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e5:SetCode(EVENT_LEAVE_FIELD)
    e5:SetTarget(s.lftg)
    e5:SetOperation(s.lfop)
    c:RegisterEffect(e5)
end
