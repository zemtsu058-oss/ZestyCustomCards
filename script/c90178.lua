--[[
===========================================
  Farewell Labrynth
  ID: 90178 | Bẫy Thường (Normal Trap)
===========================================

  [HU1 - ACTIVATE / HOPT chung] Phí Kích Hoạt - Gửi Bài Vào Mộ
    - Điều kiện: có quái thú "Labrynth" trên sân của bạn
    - Hiệu ứng: trong lượt này, mỗi khi 1 người chơi kích hoạt
      1 lá bài hoặc hiệu ứng, người đó phải gửi 1 lá từ tay vào Mộ
    - Nếu người đó không có lá trên tay → chuyển thẳng đến End Phase

  [HU2 - IGNITION / HOPT chung] Hiệu ứng Mộ - Hồi Phục Lá Trục Xuất
    - Chi phí: Trục xuất lá này từ Mộ (face-up)
    - Mục tiêu: 1 lá bài bị Trục xuất (của bất kỳ người chơi nào)
    - Hiệu ứng: Gửi lá đó vào Mộ

===========================================
]]
--Farewell Labrynth
local s, id = GetID()

s.listed_series = {0x17f}

function s.initial_effect(c)

    -- HOPT chung: ngăn bị vô hiệu hóa để bảo vệ giới hạn OPT
    local e0 = Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_CANNOT_DISABLE)
    c:RegisterEffect(e0)

    -- Hiệu ứng 1: ACTIVATE - đặt hiệu ứng phí gửi bài cho cả lượt
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_HANDES + CATEGORY_TOGRAVE)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH)
    e1:SetCondition(s.actcon)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)

    -- Hiệu ứng 2: Ignition từ Mộ - gửi 1 lá bị Trục xuất về Mộ
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_TOGRAVE)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1, id, EFFECT_COUNT_CODE_OATH)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetCost(s.gycost)
    e2:SetTarget(s.gytg)
    e2:SetOperation(s.gyop)
    c:RegisterEffect(e2)

end

---------------------------------------------------
-- ĐIỀU KIỆN KÍCH HOẠT - Phải có quái thú Labrynth trên sân
---------------------------------------------------

function s.labmonfilter(c)
    -- Lọc quái thú bộ Labrynth trên Monster Zone
    return c:IsSetCard(0x17f) and c:IsType(TYPE_MONSTER)
end

function s.actcon(e, tp, eg, ep, ev, re, r, rp)
    -- Phải có ít nhất 1 quái thú Labrynth trên sân của bạn
    return Duel.IsExistingMatchingCard(s.labmonfilter, tp, LOCATION_MZONE, 0, 1, nil)
end

---------------------------------------------------
-- ACTIVATE OPERATION - Đăng ký hiệu ứng phí kích hoạt liên tục
---------------------------------------------------

function s.activate(e, tp, eg, ep, ev, re, r, rp)
    -- Đăng ký 1 hiệu ứng field: mỗi khi có kích hoạt, người đó gửi 1 lá vào Mộ
    -- Hiệu ứng tự động áp dụng cho cả 2 người (rp xác định ai phải trả)
    local e1 = Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EVENT_CHAINING)
    e1:SetReset(RESET_PHASE + PHASE_END)
    e1:SetOperation(s.chainop)
    Duel.RegisterEffect(e1, tp)
end

function s.chainop(e, tp, eg, ep, ev, re, r, rp)
    -- rp = người vừa kích hoạt lá trong chain
    if Duel.IsExistingMatchingCard(Card.IsDiscardable, rp, LOCATION_HAND, 0, 1, nil) then
        -- Có lá trên tay → gửi 1 lá vào Mộ (không phải "bỏ", là "gửi" theo văn bản lá)
        Duel.Hint(HINT_SELECTMSG, rp, HINTMSG_TOGRAVE)
        local sg = Duel.SelectMatchingCard(rp, Card.IsDiscardable, rp, LOCATION_HAND, 0, 1, 1, nil)
        if #sg > 0 then
            Duel.SendtoGrave(sg, REASON_EFFECT)
        end
    else
        -- Không có lá trên tay → chuyển thẳng đến End Phase
        -- Bỏ qua Main Phase 1, Battle Phase, Main Phase 2 còn lại
        local curr_tp = Duel.GetTurnPlayer()
        Duel.SkipPhase(curr_tp, PHASE_MAIN1, RESET_PHASE + PHASE_END, 1)
        Duel.SkipPhase(curr_tp, PHASE_BATTLE, RESET_PHASE + PHASE_END, 1)
        Duel.SkipPhase(curr_tp, PHASE_MAIN2, RESET_PHASE + PHASE_END, 1)
    end
end

---------------------------------------------------
-- GY EFFECT - Chi phí, Mục tiêu và Hiệu ứng
---------------------------------------------------

function s.gycost(e, tp, eg, ep, ev, re, r, rp, chk)
    -- Chi phí: Trục xuất lá này từ Mộ (face-up)
    local c = e:GetHandler()
    if chk == 0 then return c:IsAbleToRemoveAsCost() end
    Duel.Remove(c, POS_FACEUP, REASON_COST)
end

function s.removedfilter(c)
    -- Bất kỳ lá nào đang bị Trục xuất đều có thể làm mục tiêu
    return true
end

function s.gytg(e, tp, eg, ep, ev, re, r, rp, chk)
    -- Mục tiêu: 1 lá bị Trục xuất của bất kỳ người chơi nào
    if chk == 0 then
        return Duel.IsExistingMatchingCard(s.removedfilter, tp, LOCATION_REMOVED, LOCATION_REMOVED, 1, nil)
    end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_TARGET)
    local g = Duel.SelectTarget(tp, s.removedfilter, tp, LOCATION_REMOVED, LOCATION_REMOVED, 1, 1, nil)
    Duel.SetOperationInfo(0, CATEGORY_TOGRAVE, g, 1, 0, 0)
end

function s.gyop(e, tp, eg, ep, ev, re, r, rp)
    -- Gửi lá đã chọn mục tiêu về Mộ
    local tc = Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.SendtoGrave(tc, REASON_EFFECT)
    end
end
