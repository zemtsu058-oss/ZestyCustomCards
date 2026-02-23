--No Stealing
local s,id=GetID()
function s.initial_effect(c)

    --------------------------------------------------
    -- 1. Activate: trả control ngay
    --------------------------------------------------
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_ACTIVATE)
    e0:SetCode(EVENT_FREE_CHAIN)
    e0:SetOperation(s.activate)
    c:RegisterEffect(e0)

    --------------------------------------------------
    -- 2. Continuous auto return control
    --------------------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EVENT_ADJUST)
    e1:SetRange(LOCATION_SZONE)
    e1:SetOperation(s.adjustop)
    c:RegisterEffect(e1)

    --------------------------------------------------
    -- 3. Immune effect (không bị phá/negate dễ)
    --------------------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_ONFIELD)
    e2:SetCode(EFFECT_IMMUNE_EFFECT)
    e2:SetValue(s.efilter)
    c:RegisterEffect(e2)

    --------------------------------------------------
    -- 4. Không được tribute quái không thuộc owner
    --------------------------------------------------
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_UNRELEASABLE_SUM)
    e3:SetRange(LOCATION_SZONE)
    e3:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
    e3:SetValue(s.tributelimit)
    c:RegisterEffect(e3)

    local e4=e3:Clone()
    e4:SetCode(EFFECT_UNRELEASABLE_NONSUM)
    c:RegisterEffect(e4)

    --------------------------------------------------
    -- 5. Material Lock (CORE SAFE VERSION)
    --------------------------------------------------
    local e5=Effect.CreateEffect(c)
    e5:SetType(EFFECT_TYPE_FIELD)
    e5:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL)
    e5:SetRange(LOCATION_SZONE)
    e5:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
    e5:SetTarget(s.mattg)
    e5:SetValue(1)
    c:RegisterEffect(e5)

    local e6=e5:Clone()
    e6:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL)
    c:RegisterEffect(e6)

    local e7=e5:Clone()
    e7:SetCode(EFFECT_CANNOT_BE_XYZ_MATERIAL)
    c:RegisterEffect(e7)

    local e8=e5:Clone()
    e8:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
    c:RegisterEffect(e8)

    --------------------------------------------------
    -- 6. Không được Special Summon quái của đối phương
    --------------------------------------------------
    local e9=Effect.CreateEffect(c)
    e9:SetType(EFFECT_TYPE_FIELD)
    e9:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
    e9:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e9:SetRange(LOCATION_SZONE)
    e9:SetTargetRange(1,1)
    e9:SetTarget(s.splimit)
    c:RegisterEffect(e9)

end

--------------------------------------------------
-- Activate return control
--------------------------------------------------
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    s.returncontrol()
end

--------------------------------------------------
-- Continuous adjust return
--------------------------------------------------
function s.adjustop(e,tp,eg,ep,ev,re,r,rp)
    s.returncontrol()
end

function s.returncontrol()
    local g=Duel.GetMatchingGroup(aux.TRUE,0,LOCATION_MZONE,LOCATION_MZONE,nil)
    for tc in aux.Next(g) do
        if tc:IsFaceup() and tc:GetOwner()~=tc:GetControler() then
            Duel.GetControl(tc,tc:GetOwner())
        end
    end
end

--------------------------------------------------
-- Immune filter
--------------------------------------------------
function s.efilter(e,te)
    return te:GetOwner()~=e:GetOwner()
end

--------------------------------------------------
-- Tribute limit
--------------------------------------------------
function s.tributelimit(e,c,tp)
    return c:GetOwner()~=tp
end

--------------------------------------------------
-- Material target (core-safe)
--------------------------------------------------
function s.mattg(e,c)
    return c:GetOwner()~=c:GetControler()
end

--------------------------------------------------
-- Special Summon limit
--------------------------------------------------
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
    return c:GetOwner()~=sump
end