--[[
===========================================
  Chambermaid of the Silver Castle
  ID: 79900009 | Effect Monster (ATK 3000 DEF 2500 Level 8 DARK/FIEND)
===========================================

  [HU1 - QUICK (Counter) / HOPT] Vô hiệu hóa hiệu ứng đối thủ từ tay
    - Điều kiện: Đối thủ kích hoạt lá/hiệu ứng để phản hồi khi quái "Labrynth"
      hoặc Normal Trap của bạn kích hoạt
    - Hiệu ứng: Gửi lá này từ tay xuống GY, vô hiệu hóa hiệu ứng đó

  [HU2 - TRIGGER / HOPT] Đặc triệu hồi lá này từ tay/GY ở Tư thế Phòng thủ
    - Kích hoạt khi hiệu ứng của quái "Labrynth" kích hoạt
      trong khi lá này đang ở tay hoặc GY

  [HU3 - CONTINUOUS] Bảo vệ Set cards
    - Khi lá này ở Tư thế Phòng thủ, Set cards bạn kiểm soát
      không thể bị phá hủy bởi hiệu ứng lá

===========================================
]]
local s, id = GetID()
s.listed_series = {0x17f}

function s.initial_effect(c)
    -- 1. Quick Effect (Counter): Gửi từ tay để vô hiệu hóa
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_NEGATE)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_CHAINED)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1, id)
    e1:SetCondition(s.negcon)
    e1:SetCost(s.negcost)
    e1:SetTarget(s.negtg)
    e1:SetOperation(s.negop)
    c:RegisterEffect(e1)

    -- 2. Trigger: Đặc triệu hồi khi quái Labrynth kích hoạt
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_CHAINING)
    e2:SetRange(LOCATION_HAND + LOCATION_GRAVE)
    e2:SetCountLimit(1, id + 100)
    e2:SetCondition(s.spcon)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)

    -- 3. Continuous: Set cards không thể bị phá hủy bởi hiệu ứng khi ở Def
    local e3 = Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_CANNOT_DESTROY_CARD)
    e3:SetRange(LOCATION_MZONE)
    e3:SetTargetRange(LOCATION_MZONE + LOCATION_SZONE, 0)
    e3:SetCondition(s.defcon)
    e3:SetValue(s.defval)
    c:RegisterEffect(e3)
end

-- ========== Hiệu ứng 1: Vô hiệu hóa ==========
function s.negcon(e, tp, eg, ep, ev, re, r, rp)
    -- Kích hoạt khi đối thủ chain vào hiệu ứng của quái Labrynth hoặc Normal Trap của ta
    -- re = effect của đối thủ đang chain; ev-1 = index của effect bị chain vào
    if ev < 1 then return false end
    local trigger_re = Duel.GetChainInfo(ev - 1, CHAININFO_TRIGGERING_EFFECT)
    if not trigger_re then return false end
    local trig_card = trigger_re:GetHandler()
    local trig_tp = Duel.GetChainInfo(ev - 1, CHAININFO_TRIGGERING_PLAYER)
    -- Effect bị chain vào phải là của ta
    if trig_tp ~= tp then return false end
    -- Và phải là quái Labrynth hoặc Normal Trap (không phải Counter Trap)
    local is_labrynth = trig_card:IsSetCard(0x17f) and trig_card:IsType(TYPE_MONSTER)
    local is_normal_trap = (trigger_re:GetType() & EFFECT_TYPE_ACTIVATE) ~= 0
        and trig_card:IsType(TYPE_TRAP) and not trig_card:IsType(TYPE_COUNTER)
    return is_labrynth or is_normal_trap
end

function s.negcost(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then return c:IsAbleToGrave() end
    Duel.SendtoGrave(c, REASON_COST)
end

function s.negtg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_NEGATE, nil, 0, 0, 0)
end

function s.negop(e, tp, eg, ep, ev, re, r, rp)
    Duel.NegateEffect(ev)
end

-- ========== Hiệu ứng 2: Đặc triệu hồi khi quái Labrynth kích hoạt ==========
function s.spcon(e, tp, eg, ep, ev, re, r, rp)
    -- Kiểm tra hiệu ứng đang chain là của quái Labrynth
    local trigger_re = re
    if not trigger_re then return false end
    local trig_card = trigger_re:GetHandler()
    -- Phải là quái Labrynth và phải là của ta (hoặc bất kỳ - card text nói "a Labrynth monster")
    return trig_card:IsSetCard(0x17f) and trig_card:IsType(TYPE_MONSTER)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk)
    local c = e:GetHandler()
    if chk == 0 then
        return Duel.GetLocationCount(tp, LOCATION_MZONE) > 0
            and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
    end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, c, 1, 0, 0)
end

function s.spop(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SpecialSummon(c, 0, tp, tp, false, false, POS_FACEUP_DEFENCE)
    end
end

-- ========== Hiệu ứng 3: Bảo vệ Set cards khi ở Def ==========
function s.defcon(e)
    -- Chỉ áp dụng khi lá này ở Tư thế Phòng thủ
    local c = e:GetHandler()
    return c:IsPosition(POS_FACEUP_DEFENCE)
end

function s.defval(e, re, r, rp, c)
    -- Chặn phá hủy bởi hiệu ứng lá (REASON_EFFECT), chỉ áp dụng cho Set cards (face-down)
    return re ~= nil and (r & REASON_EFFECT) ~= 0 and c:IsFacedown()
end
