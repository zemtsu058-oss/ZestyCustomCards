-- Witchcrafter Hisho - Madame
local s,id=GetID()
local SET_WITCHCRAFTER = 0x128

function s.initial_effect(c)
    c:EnableReviveLimit()

    -- Fusion: 2 Spellcasters, include WIND
    -- Nguyên liệu 1: WIND Spellcaster | Nguyên liệu 2: Any Spellcaster
    Fusion.AddProcMix(c,true,true,s.matfilter_wind,s.matfilter_any)

    -- 1. On Fusion Summon: Copy Witchcrafter Spell
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOGRAVE)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.sptg)
    e1:SetOperation(s.spop)
    c:RegisterEffect(e1)

    -- 2. Quick Bounce Effect
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,id+100)
    e2:SetTarget(s.bntg)
    e2:SetOperation(s.bnop)
    c:RegisterEffect(e2)
end

-- Filter nguyên liệu
function s.matfilter_wind(c,fc,sumtype,tp)
    return c:IsRace(RACE_SPELLCASTER,fc,sumtype,tp) and c:IsAttribute(ATTRIBUTE_WIND,fc,sumtype,tp)
end
function s.matfilter_any(c,fc,sumtype,tp)
    return c:IsRace(RACE_SPELLCASTER,fc,sumtype,tp)
end

-- Logic Copy Effect
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

function s.spfilter(c)
    return c:IsSetCard(SET_WITCHCRAFTER) and c:IsType(TYPE_SPELL) and c:IsAbleToGrave()
        and c:CheckActivateEffect(false,true,false)~=nil
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler() -- Lấy lá bài Madame
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil)
    local tc=g:GetFirst()
    
    if tc and Duel.SendtoGrave(tc,REASON_EFFECT)>0 and tc:IsLocation(LOCATION_GRAVE) then
        local te=tc:GetActivateEffect()
        if not te then return end
        
        -- Copy thuộc tính của Spell
        e:SetCategory(te:GetCategory())
        e:SetProperty(te:GetProperty())
        
        local tg=te:GetTarget()
        local op=te:GetOperation()
        
        -- Thực hiện chọn Target (nếu Spell có yêu cầu)
        Duel.ClearTargetCard()
        if tg then tg(e,tp,Group.CreateGroup(),0,0,e,0,0,1) end
        
        -- FIX LỖI: Liên kết các target với lá bài Madame (c) thay vì Effect (e)
        local targets=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
        if targets then
            for etc in aux.Next(targets) do
                etc:CreateRelation(c,RESET_EVENT+RESETS_STANDARD)
            end
        end
        
        Duel.BreakEffect()
        -- Thực hiện hiệu ứng thực tế
        if op then op(e,tp,Group.CreateGroup(),0,0,e,0,0) end
    end
end

-- Logic Bounce
function s.stfilter(c)
    return c:IsSetCard(SET_WITCHCRAFTER) and c:IsType(TYPE_SPELL+TYPE_TRAP)
end

function s.bntg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsOnField() and chkc:IsAbleToHand() and chkc~=e:GetHandler() end
    local ct=Duel.GetMatchingGroupCount(s.stfilter,tp,LOCATION_GRAVE,0,nil)
    if chk==0 then return ct>0 and Duel.IsExistingTarget(Card.IsAbleToHand,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,e:GetHandler()) end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
    local g=Duel.SelectTarget(tp,Card.IsAbleToHand,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,ct,e:GetHandler())
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,#g,0,0)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end

function s.bnop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local g=Duel.GetTargetCards(e)
    if #g>0 then
        Duel.SendtoHand(g,nil,REASON_EFFECT)
    end
    if c:IsRelateToEffect(e) then
        Duel.SendtoHand(c,nil,REASON_EFFECT)
    end
end
