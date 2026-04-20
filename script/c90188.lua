--Drytron Supernova
local s,id=GetID()

function s.initial_effect(c)

    --Activate
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetTarget(s.target)
    e1:SetOperation(s.activate)
    c:RegisterEffect(e1)

    --GY set
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,id)
    e2:SetCondition(s.setcon)
    e2:SetTarget(s.settg)
    e2:SetOperation(s.setop)
    c:RegisterEffect(e2)

end

---------------------------------------------------
-- TARGET
---------------------------------------------------

function s.filter(c)
    return (c:IsSetCard(0x151) or c:IsType(TYPE_RITUAL))
        and c:IsFaceup()
        and c:IsDestructable()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.filter(chkc) end
    if chk==0 then return Duel.IsExistingTarget(s.filter,tp,LOCATION_MZONE,0,1,nil) end

    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    Duel.SelectTarget(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil)

end

---------------------------------------------------
-- ACTIVATE
---------------------------------------------------

function s.spfilter(c,e,tp)
    return c:IsSetCard(0x151) and c:IsAttack(2000)
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)

    local tc=Duel.GetFirstTarget()
    if not tc or not tc:IsRelateToEffect(e) then return end

    local atk=tc:GetAttack()

    if Duel.Destroy(tc,REASON_EFFECT)==0 then return end

    -----------------------------------------
    -- RITUAL EFFECT
    -----------------------------------------
    if tc:IsType(TYPE_RITUAL) then

        local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
        local dg=g:Filter(function(c) return c:GetAttack()<=atk end,nil)

        if #dg>0 then
            Duel.Destroy(dg,REASON_EFFECT)
        end

    end

    -----------------------------------------
    -- DRYTRON EFFECT (FIX SELECT)
    -----------------------------------------
    if tc:IsSetCard(0x151) then

        local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,nil,e,tp)
        if #g==0 then return end

        local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
        if ft<=0 then return end

        local sum=0
        local sg=Group.CreateGroup()

        while true do
            local valid=g:Filter(function(c) return sum+2000<=atk end,nil)
            if #valid==0 or #sg>=ft then break end

            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
            local tc2=valid:Select(tp,1,1,nil):GetFirst()

            sg:AddCard(tc2)
            sum=sum+2000
            g:RemoveCard(tc2)

            if sum>=atk then break end

            if not Duel.SelectYesNo(tp,aux.Stringid(id,0)) then break end
        end

        if #sg>0 then
            Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
        end

    end

end

---------------------------------------------------
-- GY EFFECT
---------------------------------------------------

function s.setcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(function(c,tp) return c:IsSummonType(SUMMON_TYPE_RITUAL) and c:IsControler(tp) end,1,nil,tp)
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsSSetable() end
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)

    local c=e:GetHandler()
    if Duel.SSet(tp,c)>0 then

        --banish when leaves field
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
        e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
        e1:SetReset(RESET_EVENT+RESETS_REDIRECT)
        e1:SetValue(LOCATION_REMOVED)
        c:RegisterEffect(e1)

    end

end