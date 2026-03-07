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

-- Điều kiện: Có quái vật khác trên Tay/Sân (Trừ handler)
function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return Duel.IsExistingMatchingCard(Card.IsType,tp,LOCATION_HAND+LOCATION_MZONE,0,1,e:GetHandler(),TYPE_MONSTER)
end

function s.ffilter(c,e,tp,mg)
    return c:IsRace(RACE_SPELLCASTER) and c:IsType(TYPE_FUSION) 
        and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
        and Duel.GetLocationCountFromEx(tp,tp,mg,c)>0
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then 
        local mg=Duel.GetMatchingGroup(Card.IsCanBeFusionMaterial,tp,LOCATION_HAND+LOCATION_MZONE,0,c)
        local res=Duel.IsExistingMatchingCard(Card.CheckFusionMaterial,tp,LOCATION_EXTRA,0,1,nil,mg,nil,tp)
        if res then return true end
        
        local sg=Duel.GetMatchingGroup(Card.IsType,tp,LOCATION_HAND,0,c,TYPE_SPELL)
        if #sg>0 and Duel.IsExistingMatchingCard(Card.IsSetCard,tp,LOCATION_EXTRA,0,1,nil,SET_WITCHCRAFTER) then
            if #mg>0 then return true end
        end
        return false
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    -- Lấy group quái vật thực sự từ TAY và SÂN (Loại trừ lá bài này)
    local mg=Duel.GetMatchingGroup(Card.IsCanBeFusionMaterial,tp,LOCATION_HAND+LOCATION_MZONE,0,c)
    
    local fgc=Duel.GetMatchingGroup(s.ffilter,tp,LOCATION_EXTRA,0,nil,e,tp,mg)
    if #fgc==0 then return end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local tc=fgc:Select(tp,1,1,nil):GetFirst()
    if not tc then return end

    local sub_effects={}

    -- BƯỚC 1: CHỌN SPELL TRÊN TAY ĐỂ THẾ THÂN (KHÔNG HỎI YES/NO)
    if tc:IsSetCard(SET_WITCHCRAFTER) then
        local sg=Duel.GetMatchingGroup(Card.IsType,tp,LOCATION_HAND,0,c,TYPE_SPELL)
        if #sg>0 then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
            local g=sg:Select(tp,0,1,nil) -- Cho phép chọn 0 lá (nhấn Finish) để không dùng Spell
            
            if #g>0 then
                local mat_spell=g:GetFirst()
                -- 6 hiệu ứng biến hình giả
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
                e3:SetValue(ATTRIBUTE_LIGHT+ATTRIBUTE_WIND)
                mat_spell:RegisterEffect(e3)

                local e4=e1:Clone()
                e4:SetCode(EFFECT_SET_ATTACK)
                e4:SetValue(1000)
                mat_spell:RegisterEffect(e4)

                local e5=e1:Clone()
                e5:SetCode(EFFECT_SET_DEFENSE)
                e5:SetValue(2800)
                mat_spell:RegisterEffect(e5)

                local e6=e1:Clone()
                e6:SetCode(EFFECT_FUSION_SUBSTITUTE)
                mat_spell:RegisterEffect(e6)

                table.insert(sub_effects,{e1,e2,e3,e4,e5,e6,mat_spell})
                mg:AddCard(mat_spell) -- Đưa lá Spell đã biến hình vào group nguyên liệu
            end
        end
    end

    -- BƯỚC 2: CHỌN NGUYÊN LIỆU (QUÁI TRÊN TAY/SÂN + SPELL TRÊN TAY NẾU ĐÃ CHỌN)
    local mat=Duel.SelectFusionMaterial(tp,tc,mg,nil,tp)
    if #mat>0 then
        tc:SetMaterial(mat)
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

-- PHẦN GY GIỮ NGUYÊN
function s.gycon(e,tp,eg,ep,ev,re,r,rp)
    return rp==tp and (r&REASON_DISCARD)>0 and eg:IsExists(Card.IsType,1,nil,TYPE_SPELL)
end
function s.tgfilter(c,tp)
    return c:IsType(TYPE_SPELL) and (c:IsLocation(LOCATION_GRAVE) or (c:IsFaceup() and c:IsLocation(LOCATION_REMOVED)))
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
