-- DoomZ Command J.U.P.I.T.E.R
local s,id=GetID()

function s.initial_effect(c)

    ---------------------------------------------------
    -- Luôn được coi là card "Rank-Up-Magic"
    ---------------------------------------------------
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetCode(EFFECT_ADD_SETCODE)
    e0:SetValue(0x95) 
    c:RegisterEffect(e0)

    ---------------------------------------------------
    -- Thủ tục trang bị (Equip Procedure)
    ---------------------------------------------------
    aux.AddEquipProcedure(c,nil,aux.FilterBoolFunction(Card.IsFaceup))

    ---------------------------------------------------
    -- Bảo vệ: Không thể bị chọn làm mục tiêu
    ---------------------------------------------------
    -- Cho chính lá bài này
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetRange(LOCATION_SZONE)
    e1:SetValue(aux.tgoval)
    c:RegisterEffect(e1)

    -- Cho quái vật đang được trang bị
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_EQUIP)
    e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e2:SetValue(aux.tgoval)
    c:RegisterEffect(e2)

    ---------------------------------------------------
    -- Hiệu ứng Quick Xyz Summon
    ---------------------------------------------------
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetRange(LOCATION_SZONE)
    e3:SetCountLimit(1)
    e3:SetCost(s.cost)
    e3:SetTarget(s.tg)
    e3:SetOperation(s.op)
    c:RegisterEffect(e3)

end

---------------------------------------------------
-- Chi phí kích hoạt (Cost)
---------------------------------------------------
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.CheckLPCost(tp,1000) end
    Duel.PayLPCost(tp,1000)
end

---------------------------------------------------
-- Lấy giá trị Level/Rank
---------------------------------------------------
function s.getvalue(c)
    if not c then return 0 end
    return c:IsType(TYPE_XYZ) and c:GetRank() or c:GetLevel()
end

---------------------------------------------------
-- Lọc Xyz Monster trong Extra Deck
---------------------------------------------------
function s.xyzfilter(c,e,tp,mc)
    if not (c:IsAttribute(ATTRIBUTE_WIND) and c:IsRace(RACE_MACHINE) and c:IsType(TYPE_XYZ)) then
        return false
    end
    if not c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false) then
        return false
    end

    local val=s.getvalue(mc)
    if val<=0 then return false end

    if mc:IsType(TYPE_XYZ) then
        return c:GetRank()==val or c:GetRank()==val+1 or c:GetRank()==val+2
    else
        return c:GetRank()==val
    end
end

---------------------------------------------------
-- Mục tiêu (Target)
---------------------------------------------------
function s.tg(e,tp,eg,ep,ev,re,r,rp,chk)
    local mc=e:GetHandler():GetEquipTarget()
    if chk==0 then
        return mc and s.getvalue(mc)>0
        and Duel.GetLocationCountFromEx(tp,tp,mc)>0
        and Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mc)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

---------------------------------------------------
-- Xử lý chính (Operation)
---------------------------------------------------
function s.op(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local mc=c:GetEquipTarget()
    
    if not c:IsRelateToEffect(e) or not mc then return end

    local val=s.getvalue(mc)
    if val<=0 then return end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local sc=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mc):GetFirst()
    if not sc then return end

    -- Gộp Material
    local mg=mc:GetOverlayGroup()
    mg:AddCard(mc)
    sc:SetMaterial(mg)
    Duel.Overlay(sc,mg)

    -- Triệu hồi quái thú Xyz
    if Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)>0 then
        sc:CompleteProcedure()

        -- 1. FIX: Trang bị lại ngay lập tức để không bị mất mục tiêu
        Duel.Equip(tp,c,sc)

        -- 2. Gắn 1 lá bài "DoomZ" từ Deck làm Material
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
        local g=Duel.SelectMatchingCard(tp,function(tc) return tc:IsSetCard(0x1cb) end,tp,LOCATION_DECK,0,1,1,nil)
        if #g>0 then
            Duel.Overlay(sc,g)
        end

        -- 3. FIX: Hiệu ứng phá hủy sân cho Jupiter (Sử dụng Custom Event để tránh bị trôi timing)
        if sc:IsCode(68231287) then
            local e1=Effect.CreateEffect(c)
            e1:SetDescription(aux.Stringid(id,1))
            e1:SetCategory(CATEGORY_DESTROY)
            e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
            e1:SetCode(EVENT_CUSTOM+id) 
            e1:SetProperty(EFFECT_FLAG_DELAY)
            e1:SetTarget(s.destg)
            e1:SetOperation(s.desop)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD)
            sc:RegisterEffect(e1,true)

            -- Ép hệ thống kích hoạt hiệu ứng vừa gán
            Duel.RaiseSingleEvent(sc, EVENT_CUSTOM+id, e, REASON_EFFECT, tp, tp, 0)
        end
    end
end

---------------------------------------------------
-- Hiệu ứng hủy diệt của Jupiter
---------------------------------------------------
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_ONFIELD,1,nil) end
    local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
    if #g>0 then
        Duel.Destroy(g,REASON_EFFECT)
    end
end
