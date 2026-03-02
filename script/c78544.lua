local s,id=GetID()
local SET_WITCHCRAFTER = 0x128

function s.initial_effect(c)
    -- 1. Fusion Summon
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.condition)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
    
    -- 2. GY Effect (Giữ nguyên)
    local e2=Effect.CreateEffect(c)
    e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.gycon)
    e2:SetCost(aux.bfgcost)
    e2:SetTarget(s.gytg)
    e2:SetOperation(s.gyop)
    c:RegisterEffect(e2)
end

-- CHẶN KÍCH HOẠT KHI KHÔNG CÓ QUÁI
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(Card.IsType,tp,LOCATION_HAND+LOCATION_MZONE,0,1,e:GetHandler(),TYPE_MONSTER)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.ffilter,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.ffilter(c,e,tp)
    return c:IsRace(RACE_SPELLCASTER) and c:IsType(TYPE_FUSION) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local fgc=Duel.GetMatchingGroup(s.ffilter,tp,LOCATION_EXTRA,0,nil,e,tp)
    if #fgc==0 then return end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local tc=fgc:Select(tp,1,1,nil):GetFirst()
    if not tc then return end

    local mg=Duel.GetMatchingGroup(Card.IsCanBeFusionMaterial,tp,LOCATION_HAND+LOCATION_MZONE,0,c)
    local sub_effects={}

    -- XỬ LÝ BIẾN HÌNH SPELL (NẾU LÀ WITCHCRAFTER)
    if tc:IsSetCard(SET_WITCHCRAFTER) then
        local sg=Duel.GetMatchingGroup(Card.IsType,tp,LOCATION_HAND,0,c,TYPE_SPELL)
        if #sg>0 and Duel.SelectEffectYesNo(tp,c,aux.Stringid(id,0)) then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
            local mat_spell=sg:Select(tp,1,1,nil):GetFirst()
            
            if mat_spell then
                -- Biến thành quái vật đa hệ, đúng chỉ số Verre yêu cầu
                local e1=Effect.CreateEffect(c)
                e1:SetType(EFFECT_TYPE_SINGLE)
                e1:SetCode(EFFECT_ADD_TYPE)
                e1:SetValue(TYPE_MONSTER)
                mat_spell:RegisterEffect(e1)
                
                local e2=e1:Clone()
                e2:SetCode(EFFECT_ADD_RACE)
                e2:SetValue(RACE_SPELLCASTER)
                mat_spell:RegisterEffect(e2)

                local e3=e1:Clone()
                e3:SetCode(EFFECT_ADD_ATTRIBUTE)
                e3:SetValue(ATTRIBUTE_LIGHT+ATTRIBUTE_WIND) -- Đa hệ để Madame cũng nhận
                mat_spell:RegisterEffect(e3)

                local e4=e1:Clone()
                e4:SetCode(EFFECT_SET_ATTACK)
                e4:SetValue(1000)
                mat_spell:RegisterEffect(e4)

                local e5=e1:Clone()
                e5:SetCode(EFFECT_SET_DEFENSE)
                e5:SetValue(2800)
                mat_spell:RegisterEffect(e5)

                -- ÉP ENGINE CHẤP NHẬN ĐÂY LÀ NGUYÊN LIỆU THAY THẾ
                local e6=e1:Clone()
                e6:SetCode(EFFECT_FUSION_SUBSTITUTE)
                mat_spell:RegisterEffect(e6)

                table.insert(sub_effects,{e1,e2,e3,e4,e5,e6,mat_spell})
                mg:AddCard(mat_spell)
            end
        end
    end

    -- SỬ DỤNG HÀM CHỌN CHUẨN ĐỂ KHÔNG BỊ TỊT NGÒI
    local mat=Duel.SelectFusionMaterial(tp,tc,mg,nil,tp)
    if #mat>0 then
        tc:SetMaterial(mat)
        -- Chuyển nguyên liệu xuống mộ
        Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
        Duel.BreakEffect()
        Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
        tc:CompleteProcedure()
    end

    -- RESET HIỆU ỨNG GIẢ
    for _,data in ipairs(sub_effects) do
        for i=1,6 do data[i]:Reset() end
    end
end

-- PHẦN GY (GIỮ NGUYÊN)
function s.gycon(e,tp,eg,ep,ev,re,r,rp)
    return rp==tp and (r&REASON_DISCARD)>0 and eg:IsExists(Card.IsType,1,nil,TYPE_SPELL)
end
function s.tgfilter(c,tp)
    return c:IsType(TYPE_SPELL) and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup())
        and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil,c:GetOriginalCode())
end
function s.thfilter(c,code)
    return c:GetOriginalCode()==code and c:IsAbleToHand()
end
function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsControler(tp) and s.tgfilter(chkc,tp) end
    if chk==0 then return Duel.IsExistingTarget(s.tgfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,tp) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    Duel.SelectTarget(tp,s.tgfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,tp)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.gyop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil,tc:GetOriginalCode())
        if #g>0 then
            Duel.SendtoHand(g,nil,REASON_EFFECT)
            Duel.ConfirmCards(1-tp,g)
        end
    end
end
