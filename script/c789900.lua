-- Khai báo ID của lá bài (Thay 12345678 bằng ID thật của bạn)
local s, id = GetID()

function s.initial_effect(c)
    -- Hiệu ứng 1: Fusion Summon (Quick Effect)
    local e1 = Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id, 0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON + CATEGORY_FUSION_SUMMON + CATEGORY_TODECK + CATEGORY_DRAW + CATEGORY_DAMAGE)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1, id)
    e1:SetCost(s.fs_cost)
    e1:SetTarget(s.fs_tg)
    e1:SetOperation(s.fs_op)
    c:RegisterEffect(e1)

    -- Hiệu ứng 2: Return to hand during opponent's End Phase
    local e2 = Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id, 1))
    e2:SetCategory(CATEGORY_TOHAND)
    e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_F)
    e2:SetCode(EVENT_PHASE + PHASE_END)
    e2:SetRange(LOCATION_MZONE + LOCATION_GRAVE) -- Có thể chỉnh sửa vị trí tùy ý
    e2:SetCountLimit(1)
    e2:SetCondition(s.ret_con)
    e2:SetTarget(s.ret_tg)
    e2:SetOperation(s.ret_op)
    c:RegisterEffect(e2)
end

-- --- Logic Hiệu ứng 1 ---
function s.fs_cost(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return e:GetHandler():IsDiscardable() end
    Duel.SendtoGrave(e:GetHandler(), REASON_COST + REASON_DISCARD)
end

function s.filter1(c)
    return c:IsType(TYPE_MONSTER) and c:IsCanBeFusionMaterial() and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup()) and c:IsAbleToDeck()
end

function s.filter2(c, e, tp, m, f, ch)
    return c:IsType(TYPE_FUSION) and (not f or f(c))
        and c:IsCanBeSpecialSummoned(e, SUMMON_TYPE_FUSION, tp, false, false) and c:CheckFusionMaterial(m, nil, ch)
end

function s.fs_tg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        local mg = Duel.GetMatchingGroup(s.filter1, tp, LOCATION_GRAVE + LOCATION_REMOVED, 0, nil)
        return Duel.IsExistingMatchingCard(s.filter2, tp, LOCATION_EXTRA, 0, 1, nil, e, tp, mg, nil, ch)
    end
    Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, tp, LOCATION_EXTRA)
    Duel.SetOperationInfo(0, CATEGORY_TODECK, nil, 1, tp, LOCATION_GRAVE + LOCATION_REMOVED)
end

function s.fs_op(e, tp, eg, ep, ev, re, r, rp)
    local mg = Duel.GetMatchingGroup(s.filter1, tp, LOCATION_GRAVE + LOCATION_REMOVED, 0, nil)
    local sg = Duel.GetMatchingGroup(s.filter2, tp, LOCATION_EXTRA, 0, nil, e, tp, mg, nil, ch)
    if #sg > 0 then
        Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_SPSUMMON)
        local tg = sg:Select(tp, 1, 1, nil)
        local tc = tg:GetFirst()
        local mat = Duel.SelectFusionMaterial(tp, tc, mg, nil, ch)
        tc:SetMaterial(mat)
        
        -- Shuffle materials and count them
        local ct = Duel.SendtoDeck(mat, nil, SEQ_DECKSHUFFLE, REASON_EFFECT + REASON_MATERIAL + REASON_FUSION)
        Duel.BreakEffect()
        
        -- Special Summon
        if Duel.SpecialSummon(tc, SUMMON_TYPE_FUSION, tp, tp, false, false, POS_FACEUP) ~= 0 then
            -- Cannot attack
            local e1 = Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_CANNOT_ATTACK)
            e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
            e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
            tc:RegisterEffect(e1)
            
            -- Damage
            Duel.Damage(tp, tc:GetAttack(), REASON_EFFECT)
            
            -- Draw cards
            if ct > 0 then
                Duel.Draw(tp, ct, REASON_EFFECT)
            end
        end
    end
end

-- --- Logic Hiệu ứng 2 ---
function s.ret_con(e, tp, eg, ep, ev, re, r, rp)
    return Duel.GetTurnPlayer() ~= tp
end

function s.ret_tg(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then return true end
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, e:GetHandler(), 1, 0, 0)
end

function s.ret_op(e, tp, eg, ep, ev, re, r, rp)
    local c = e:GetHandler()
    if c:IsRelateToEffect(e) then
        Duel.SendtoHand(c, nil, REASON_EFFECT)
    end
end
