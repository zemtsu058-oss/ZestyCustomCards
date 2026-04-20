-- Majestic Quasar Dragon
local s,id=GetID()

function s.initial_effect(c)
    -- 1. THIẾT LẬP ĐIỀU KIỆN TRIỆU HỒI (Must first be Synchro Summoned)
    c:EnableReviveLimit()
    local e0=Effect.CreateEffect(c)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_SINGLE_RANGE)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetRange(LOCATION_EXTRA)
    e0:SetCode(EFFECT_SPSUMMON_CONDITION)
    e0:SetValue(aux.synlimit)
    c:RegisterEffect(e0)

    -- 2. CÔNG THỨC TRIỆU HỒI
    -- Majestic Dragon + 2+ non-Tuner Synchro monsters
    -- Tham số thứ 11 là s.syncheck để tránh lỗi IsExists
    Synchro.AddProcedure(c, s.tfilter, 1, 1, s.ntfilter, 2, 99, nil, nil, nil, nil, s.syncheck)

    -- 3. HIỆU ỨNG TẤN CÔNG (Tấn công tất cả quái thú)
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_ATTACK_ALL)
    e1:SetValue(1)
    c:RegisterEffect(e1)

    -- 4. VÔ HIỆU HÓA KHI CHIẾN ĐẤU
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_BATTLE_START)
    e2:SetOperation(s.disop)
    c:RegisterEffect(e2)

    -- 5. QUICK EFFECT: NEGATE & BANISH & LOCK
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetCategory(CATEGORY_NEGATE+CATEGORY_REMOVE)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_CHAINING)
    e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
    e3:SetRange(LOCATION_MZONE)
    e3:SetCountLimit(1,id)
    e3:SetCondition(s.negcon)
    e3:SetCost(s.negcost)
    e3:SetTarget(s.negtg)
    e3:SetOperation(s.negop)
    c:RegisterEffect(e3)
end

-------------------------------------------------------------------------
-- HỖ TRỢ TRIỆU HỒI
-------------------------------------------------------------------------
function s.tfilter(c,scard,sumtype,tp)
    return c:IsCode(21159309) -- Majestic Dragon
end

function s.ntfilter(c,scard,sumtype,tp)
    return c:IsType(TYPE_SYNCHRO,scard,sumtype,tp)
end

function s.syncheck(g,scard,tp)
    return g:IsExists(Card.IsRace, 1, nil, RACE_DRAGON)
end

-------------------------------------------------------------------------
-- LOGIC HIỆU ỨNG
-------------------------------------------------------------------------

-- Khóa quái vật khi giao tranh
function s.disop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local bc=c:GetBattleTarget()
    if bc and bc:IsControler(1-tp) and bc:IsFaceup() then
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_DISABLE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        bc:RegisterEffect(e1)
        local e2=e1:Clone()
        e2:SetCode(EFFECT_DISABLE_EFFECT)
        bc:RegisterEffect(e2)
    end
end

-- Điều kiện Negate
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return rp==1-tp and not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED) and Duel.IsChainNegatable(ev)
end

-- Cost: Trục xuất tạm thời
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsAbleToRemoveAsCost() end
    if Duel.Remove(c,POS_FACEUP,REASON_COST+REASON_TEMPORARY)~=0 then
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        e1:SetCode(EVENT_PHASE+PHASE_END)
        e1:SetReset(RESET_PHASE+PHASE_END)
        e1:SetLabelObject(c)
        e1:SetCountLimit(1)
        e1:SetOperation(s.retop)
        Duel.RegisterEffect(e1,tp)
    end
end

function s.retop(e,tp,eg,ep,ev,re,r,rp)
    local tc=e:GetLabelObject()
    if tc and tc:IsLocation(LOCATION_REMOVED) then
        Duel.ReturnToField(tc)
    end
end

-- Target
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
    if re:GetHandler():IsRelateToEffect(re) then
        Duel.SetOperationInfo(0,CATEGORY_REMOVE,eg,1,0,0)
    end
end

-- Xử lý Negate và LOCK cùng tên (FIXED)
function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
        local rc=re:GetHandler()
        if Duel.Remove(eg,POS_FACEUP,REASON_EFFECT)~=0 then
            -- Lấy code của lá bài bị trục xuất (kể cả khi nó đổi code trên sân)
            local code=rc:GetCode()
            
            -- Đăng ký hiệu ứng cấm kích hoạt lên đối thủ
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_FIELD)
            e1:SetCode(EFFECT_CANNOT_ACTIVATE)
            e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
            e1:SetTargetRange(0,1) -- Chỉ đối thủ (0 là mình, 1 là đối thủ)
            e1:SetLabel(code)
            e1:SetValue(s.aclimit)
            e1:SetReset(RESET_PHASE+PHASE_END)
            Duel.RegisterEffect(e1,tp)
            
            -- Hiện thông báo card bị khóa
            Duel.Hint(HINT_CARD,0,code)
        end
    end
end

-- Hàm lọc card bị cấm
function s.aclimit(e,re,tp)
    return re:GetHandler():IsCode(e:GetLabel())
end
