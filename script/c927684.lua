local s,id=GetID()
function s.initial_effect(c)
    -- Activate (Đã bỏ CountLimit)
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    -- e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH) -- Dòng này đã bị xóa
    e1:SetCondition(s.condition)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)
end

s.listed_names={927681} 
s.listed_series={0x927} 

function s.condition(e,tp,eg,ep,ev,re,r,rp)
    return Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
end

function s.invfilter(c,tp)
    return c:IsCode(927681) and c:GetActivateEffect():IsActivatable(tp,true,true)
end

function s.spfilter(c,e,tp)
    return c:IsSetCard(0x927) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        -- Kiểm tra Invitation trên sân
        local inv_on_field=Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,927681),tp,LOCATION_ONFIELD,0,1,nil)
        
        -- Kiểm tra Invitation còn trong Deck không
        local inv_in_deck=Duel.IsExistingMatchingCard(s.invfilter,tp,LOCATION_DECK,0,1,nil,tp)
        
        -- Logic: Nếu đã có Invitation trên sân thì check triệu hồi quái, nếu chưa có thì check Invitation trong Deck
        if inv_on_field then
            return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp)
        else
            return inv_in_deck
        end
    end
    Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    -- Khóa triệu hồi (Giữ nguyên lock Desire Hero để cân bằng game)
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
    e1:SetDescription(aux.Stringid(id,1)) 
    e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e1:SetTargetRange(1,0)
    e1:SetTarget(function(e,c) return not c:IsSetCard(0x927) end)
    e1:SetReset(RESET_PHASE+PHASE_END)
    Duel.RegisterEffect(e1,tp)

    local inv_on_field=Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,927681),tp,LOCATION_ONFIELD,0,1,nil)
    local tc=Duel.GetFirstMatchingCard(s.invfilter,tp,LOCATION_DECK,0,nil,tp)

    -- Xử lý Operation
    if not inv_on_field and tc then
        Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
        local te=tc:GetActivateEffect()
        local tep=tc:GetControler()
        tc:CreateEffectRelation(te)
        local cost=te:GetCost()
        local target=te:GetTarget()
        local operation=te:GetOperation()
        if cost then cost(te,tep,eg,ep,ev,re,r,rp,1) end
        if target then target(te,tep,eg,ep,ev,re,r,rp,1) end
        if operation then operation(te,tep,eg,ep,ev,re,r,rp) end
        tc:RegisterEffect(te)
        Duel.RaiseEvent(tc,EVENT_CHAIN_SOLVED,te,0,tp,tp,Duel.GetCurrentChain())
    else
        if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
        if #g>0 then
            Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
        end
    end
end
