--[[
===========================================
  POLLUX (Fusion Monster)
  ID: 92047 | ATK/DEF tính từ nguyên liệu
===========================================

  [Điều kiện Fusion]
    - 2+ quái thú bất kỳ từ Mộ (hoặc từ MZone nếu điều kiện
      triệu hồi của chúng là Mộ). Hỗ trợ thay thế nguyên liệu (RepFusion).
    - Giới hạn 1 bản trên sân (UniqueOnField).

  [HU1 - Khi được Fusion Summon] ATK/DEF từ nguyên liệu
    - ATK = Tổng Base ATK của tất cả nguyên liệu Fusion.
    - DEF = Tổng Base DEF của tất cả nguyên liệu Fusion.

  [HU2 - CONTINUOUS, trong khi ở MZone] Miễn dịch hiệu ứng
    - Điều kiện: Field Spell 45128 (Dragonbone City Styxia) đang ở vùng Field.
    - Miễn dịch với tất cả hiệu ứng của đối thủ.

  [HU3 - CONTINUOUS] Chuyển đổi sát thương sang giảm DEF
    - Khi người chơi sẽ nhận sát thương chiến đấu hoặc hiệu ứng:
    - Có thể chọn Có/Không để thay vào đó giảm DEF của lá này
      đi 1/2 lượng sát thương đó (không mất LP).
    - Điều kiện: DEF hiện tại >= 1/2 lượng sát thương.

  [HU4 - TRIGGER_F] Khi rời sân
    - Hồi LP bằng DEF hiện tại của lá này lúc rời sân.
    - Nếu là loại Fusion: trả về Extra Deck.
    - Nếu bị đối thủ loại bỏ: phá hủy tất cả quái thú của đối thủ
      có ATK thấp hơn ATK của lá này lúc rời sân.

===========================================
]]

local s,id=GetID()

---------------------------------------------------
-- KHAI BÁO CÁC HÀM HELPER TRƯỚC initial_effect
-- (đảm bảo không bị lỗi nil function khi đăng ký)
---------------------------------------------------

-- Filter nguyên liệu hợp lệ: phải ở Mộ hoặc MZone với điều kiện triệu hồi là Mộ
function s.ffilter(c,fc,sumtype,tp)
    return c:IsLocation(LOCATION_GRAVE) or (c:IsLocation(LOCATION_MZONE) and c:IsSummonLocation(LOCATION_GRAVE))
end

-- Tính tổng ATK/DEF từ tất cả nguyên liệu Fusion và gán làm giá trị gốc cho lá này
function s.matop(e,c)
    local g=c:GetMaterial()
    if not g or #g==0 then return end
    local atk,def=0,0
    for tc in aux.Next(g) do
        atk=atk+math.max(tc:GetBaseAttack(),0)
        def=def+math.max(tc:GetBaseDefense(),0)
    end
    -- Gán ATK gốc bằng tổng ATK nguyên liệu
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_SET_BASE_ATTACK)
    e1:SetValue(atk)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TOFIELD)
    c:RegisterEffect(e1)
    -- Gán DEF gốc bằng tổng DEF nguyên liệu
    local e2=e1:Clone()
    e2:SetCode(EFFECT_SET_BASE_DEFENSE)
    e2:SetValue(def)
    c:RegisterEffect(e2)
end

---------------------------------------------------
-- HU2: MIỄN DỊCH HIỆU ỨNG ĐỐI THỦ
---------------------------------------------------

-- Điều kiện: Field Spell Dragonbone City Styxia (ID 45128) phải đang hoạt động
function s.immcon(e)
    return Duel.IsEnvironment(45128)
end

-- Chỉ chọn lọc hiệu ứng của đối thủ (người sở hữu hiệu ứng khác người điều khiển lá)
function s.efilter(e,re)
    return e:GetHandlerPlayer()~=re:GetOwnerPlayer()
end

---------------------------------------------------
-- HU3: CHUYỂN SÁT THƯƠNG SANG GIẢM DEF
---------------------------------------------------

-- Điều kiện kích hoạt: người chơi nhận sát thương, DEF hiện tại >= 1/2 sát thương đó
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
    return ep==tp and ev and ev>0 and e:GetHandler():GetDefense()>=math.floor(ev/2)
end

-- HU3a operation: trừ DEF và hủy sát thương chiến đấu
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
        Duel.ChangeBattleDamage(tp,0)
    end
end

-- HU3b operation: trừ DEF và hủy sát thương từ hiệu ứng
-- EVENT_PRE_DAMAGE cho phép thay đổi damage trước khi LP bị trừ
function s.edamop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if (r&REASON_EFFECT)==0 then return end
    if not (ep==tp and ev and ev>0) then return end
    if c:GetDefense()<math.floor(ev/2) then return end
    if Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
        Duel.Hint(HINT_CARD,0,id)
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_DEFENSE)
        e1:SetValue(-math.floor(ev/2))
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        c:RegisterEffect(e1)
        -- Đăng ký EFFECT_CHANGE_DAMAGE tạm thời để hủy sát thương hiệu ứng
        local e2=Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_FIELD)
        e2:SetCode(EFFECT_CHANGE_DAMAGE)
        e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
        e2:SetTargetRange(1,0)
        e2:SetValue(0)
        e2:SetReset(RESET_CHAIN)
        Duel.RegisterEffect(e2,tp)
    end
end

---------------------------------------------------
-- HU4: HIỆU ỨNG KHI RỜI SÂN (TRIGGER_F)
---------------------------------------------------

-- Khai báo các danh mục hiệu ứng sẽ thực hiện khi rời sân
function s.lftg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    local c=e:GetHandler()
    local atk=c:GetPreviousAttackOnField() or 0
    local def=c:GetPreviousDefenseOnField() or 0
    Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,def)
    -- Chỉ khai báo TOEXTRA khi là Fusion Monster thực sự
    if c:IsType(TYPE_FUSION) then
        Duel.SetOperationInfo(0,CATEGORY_TOEXTRA,nil,1,tp,0)
    end
    if c:GetReasonPlayer()==1-tp then
        Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,0,1-tp,LOCATION_MZONE)
    end
end

-- Thực thi hiệu ứng khi rời sân
function s.lfop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    -- Kiểm tra tính hợp lệ: bắt buộc cho TRIGGER_F để tránh xử lý sai khi chain thay đổi
    if not c:IsRelateToEffect(e) then return end
    local atk=c:GetPreviousAttackOnField() or 0
    local def=c:GetPreviousDefenseOnField() or 0
    -- Trả về Extra Deck (face-down) nếu là Fusion Monster
    -- SendtoDeck tự động gửi Extra Deck monster về Extra Deck thay vì Main Deck
    if c:IsType(TYPE_FUSION) then
        Duel.SendtoDeck(c,nil,SEQ_DECKTOP,REASON_EFFECT)
    end
    -- Hồi phục LP bằng DEF hiện tại khi rời sân
    Duel.Recover(tp,def,REASON_EFFECT)
    -- Nếu bị đối thủ loại bỏ: phá hủy toàn bộ quái thú đối thủ có ATK thấp hơn ATK của lá này
    if c:GetReasonPlayer()==1-tp then
        local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
        local dg=g:Filter(function(tc) return tc:GetAttack()<atk end,nil)
        if #dg>0 then
            Duel.Destroy(dg,REASON_EFFECT)
        end
    end
end

---------------------------------------------------
-- ĐĂNG KÝ HIỆU ỨNG
---------------------------------------------------
function s.initial_effect(c)
    c:EnableReviveLimit()
    Fusion.AddProcFunRep(c,s.ffilter,2,false)
    c:SetUniqueOnField(1,0,id)

    -- HU1: Tính ATK/DEF từ nguyên liệu khi được Fusion Summon
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_MATERIAL_CHECK)
    e1:SetOperation(s.matop)
    c:RegisterEffect(e1)

    -- HU2: Miễn dịch hiệu ứng đối thủ khi Field Spell 45128 đang hoạt động
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCode(EFFECT_IMMUNE_EFFECT)
    e2:SetCondition(s.immcon)
    e2:SetValue(s.efilter)
    c:RegisterEffect(e2)

    -- HU3a: Bắt sát thương chiến đấu (EVENT_PRE_BATTLE_DAMAGE)
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e4:SetCode(EVENT_PRE_BATTLE_DAMAGE)
    e4:SetRange(LOCATION_MZONE)
    e4:SetCondition(s.damcon)
    e4:SetOperation(s.damop)
    c:RegisterEffect(e4)
    -- HU3b: Bắt sát thương từ hiệu ứng (EVENT_PRE_DAMAGE) - dùng logic riêng
    local e4b=Effect.CreateEffect(c)
    e4b:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e4b:SetCode(EVENT_PRE_DAMAGE)
    e4b:SetRange(LOCATION_MZONE)
    e4b:SetOperation(s.edamop)
    c:RegisterEffect(e4b)

    -- HU4: Khi rời sân: hồi LP, trả Extra Deck, phá hủy quái thú đối thủ
    local e5=Effect.CreateEffect(c)
    e5:SetCategory(CATEGORY_RECOVER+CATEGORY_DESTROY+CATEGORY_TOEXTRA)
    e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e5:SetCode(EVENT_LEAVE_FIELD)
    e5:SetTarget(s.lftg)
    e5:SetOperation(s.lfop)
    c:RegisterEffect(e5)
end
