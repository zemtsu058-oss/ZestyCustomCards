-- ID của lá bài: 78900003
local s,id=GetID()
function s.initial_effect(c)
    -- 1. Hiệu ứng định danh: Luôn thuộc tộc "Ttf" (0x789)
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_ADD_SETCODE)
    e0:SetValue(0x789)
    c:RegisterEffect(e0)

    -- 2. Hiệu ứng kích hoạt: Fusion Summon
    local e1=Fusion.CreateSummonEff({
        handler=c,
        filter=aux.FilterBoolFunction(Card.IsSetCard,0x789),
        matfilter=Fusion.OnFieldMat(Card.IsAbleToRemove),
        extrafil=s.fextra,
        extraop=Fusion.BanishMaterial,
        extratg=s.extratg,
        stage2=nil
    })
    e1:SetCountLimit(1,id)
    c:RegisterEffect(e1)

    -- 3. Hiệu ứng bảo vệ tại Mộ
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EFFECT_DESTROY_REPLACE)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,id+100)
    e2:SetTarget(s.reptg)
    e2:SetValue(s.repval)
    e2:SetOperation(s.repop)
    c:RegisterEffect(e2)
end

-- Hỗ trợ Fusion: Lấy nguyên liệu từ Mộ
function s.fextra(e,tp,mg)
    return Duel.GetMatchingGroup(Fusion.IsMonsterFilter(Card.IsAbleToRemove),tp,LOCATION_GRAVE,0,nil)
end

function s.extratg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_ONFIELD+LOCATION_GRAVE)
end

-- Logic bảo vệ: Thay thế phá hủy/rời sân
function s.repfilter(c,tp)
    return c:IsFaceup() and c:IsControler(tp) and c:IsLocation(LOCATION_MZONE)
        and c:IsSetCard(0x789) and (c:IsReason(REASON_EFFECT) or c:IsReason(REASON_BATTLE)) and not c:IsReason(REASON_REPLACE)
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsAbleToRemove() and eg:IsExists(s.repfilter,1,nil,tp) end
    return Duel.SelectEffectYesNo(tp,e:GetHandler(),96)
end

function s.repval(e,c)
    return s.repfilter(c,e:GetHandlerPlayer())
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_EFFECT)
end
