-- ============================================================
-- Card Name: Dragonbone City Styxia
-- Passcode : 45128
-- Type     : Spell / Field
-- Archetype: None
-- ============================================================
-- Effect 1: Any card banished from the hand, Deck or field is
--           sent to the GY instead.
-- Effect 2: When you lose LP, place 1 counter on this card for
--           every 1000 LP lost.
-- Effect 3: Once per turn: You can target 1 monster in your GY;
--           Special Summon it, then you lose LP equal to half of
--           its ATK.
-- Effect 4: You can remove all counters from this card (min. 4);
--           Special Summon 1 "Pollux, Netherwing Husk, Ferry of
--           Souls" from your Extra Deck, and if you do, its
--           original ATK/DEF become the number of counter removed
--           x1000. This effect cannot be negated. You can only use
--           this effect of "Dragonbone City Styxia" once per turn.
-- ============================================================

local s,id=GetID()
s.counter_place_list={0x1a1}

function s.initial_effect(c)
    -- Enable counter permit
    c:EnableCounterPermit(0x1a1)

    -- Activation
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_ACTIVATE)
    e0:SetCode(EVENT_FREE_CHAIN)
    c:RegisterEffect(e0)

    -- ============================================================
    -- Effect 1 — Continuous: Redirect banished cards to GY
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EVENT_REMOVE)
    e1:SetRange(LOCATION_FZONE)
    e1:SetOperation(s.op_redirect)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — Continuous: Track LP loss and place counters
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_ADJUST)
    e2:SetRange(LOCATION_FZONE)
    e2:SetLabel(0)
    e2:SetOperation(s.op_lp_track)
    c:RegisterEffect(e2)

    -- ============================================================
    -- Effect 3 — Ignition: Special Summon from GY (Soft OPT)
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e3:SetType(EFFECT_TYPE_IGNITION)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e3:SetRange(LOCATION_FZONE)
    e3:SetCountLimit(1)
    e3:SetTarget(s.tg_revive)
    e3:SetOperation(s.op_revive)
    c:RegisterEffect(e3)

    -- ============================================================
    -- Effect 4 — Ignition: Summon Pollux from Extra Deck (HOPT)
    -- ============================================================
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,1))
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetCode(EVENT_FREE_CHAIN)
    e4:SetRange(LOCATION_FZONE)
    e4:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CANNOT_INACTIVATE)
    e4:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e4:SetCost(s.cost_pollux)
    e4:SetTarget(s.tg_pollux)
    e4:SetOperation(s.op_pollux)
    c:RegisterEffect(e4)
end

-- ============================================================
-- Effect 1: Filter — Check if card was banished from hand, Deck or field
-- ============================================================
function s.filter_redirect(c)
    local loc=c:GetPreviousLocation()
    return c:IsLocation(LOCATION_REMOVED) 
        and (loc==LOCATION_HAND or loc==LOCATION_DECK or (loc&LOCATION_ONFIELD)~=0)
end

-- ============================================================
-- Effect 1: Operation — Send to GY instead of banished zone
-- ============================================================
function s.op_redirect(e,tp,eg,ep,ev,re,r,rp)
    local g=eg:Filter(s.filter_redirect,nil)
    if #g>0 then
        Duel.Hint(HINT_CARD,0,id)
        Duel.SendtoGrave(g,REASON_EFFECT)
    end
end

-- ============================================================
-- Effect 2: Operation — Track LP loss and place counters
-- ============================================================
function s.op_lp_track(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local lp=Duel.GetLP(tp)
    local prev=e:GetLabel()

    -- First run (sentinel = 0): initialize stored LP
    if prev==0 then
        e:SetLabel(lp)
        return
    end

    if lp<prev then
        local lost=prev-lp
        local ct=math.floor(lost/1000)
        if ct>0 then
            c:AddCounter(0x1a1,ct)
            e:SetLabel(prev-ct*1000)
        end
    elseif lp>prev then
        e:SetLabel(lp)
    end
end

-- ============================================================
-- Effect 3: Filter — Monster in GY can be Special Summoned
-- ============================================================
function s.filter_revive(c,e,tp)
    return c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- ============================================================
-- Effect 3: Target — Target 1 monster in your GY
-- ============================================================
function s.tg_revive(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.filter_revive(chkc,e,tp) end
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingTarget(s.filter_revive,tp,LOCATION_GRAVE,0,1,nil,e,tp)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectTarget(tp,s.filter_revive,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end

-- ============================================================
-- Effect 3: Operation — Special Summon, then lose LP equal to 1/2 ATK
-- ============================================================
function s.op_revive(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
        local atk=tc:GetAttack()
        if atk>0 then
            local lp_loss=math.floor(atk/2)
            -- Check if player controls face-up Pollux (92047) with sufficient DEF to replace LP loss
            local pollux=Duel.GetFirstMatchingCard(function(ec) return ec:IsFaceup() and ec:IsCode(92047) and ec:GetDefense()>=math.floor(lp_loss/2) end,tp,LOCATION_MZONE,0,nil)
            if pollux and Duel.SelectYesNo(tp,aux.Stringid(92047,0)) then
                Duel.Hint(HINT_CARD,0,92047)
                local e1=Effect.CreateEffect(pollux)
                e1:SetType(EFFECT_TYPE_SINGLE)
                e1:SetCode(EFFECT_UPDATE_DEFENSE)
                e1:SetValue(-math.floor(lp_loss/2))
                e1:SetReset(RESET_EVENT+RESETS_STANDARD)
                pollux:RegisterEffect(e1)
            else
                Duel.SetLP(tp,Duel.GetLP(tp)-lp_loss)
            end
        end
    end
end

-- ============================================================
-- Effect 4: Filter — Pollux in Extra Deck
-- ============================================================
function s.filter_pollux(c,e,tp)
    return c:IsCode(92047) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SPECIAL,tp,false,false)
end

-- ============================================================
-- Effect 4: Cost — Remove all counters (min. 4)
-- ============================================================
function s.cost_pollux(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:GetCounter(0x1a1)>=4 end
    local ct=c:GetCounter(0x1a1)
    c:RemoveCounter(tp,0x1a1,ct,REASON_COST)
    e:SetLabel(ct)
end

-- ============================================================
-- Effect 4: Target — Check space and existence of Pollux in Extra Deck
-- ============================================================
function s.tg_pollux(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        local tc=Duel.GetFirstMatchingCard(s.filter_pollux,tp,LOCATION_EXTRA,0,nil,e,tp)
        return tc and Duel.GetLocationCountFromEx(tp,tp,nil,tc)>0
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

-- ============================================================
-- Effect 4: Operation — Special Summon Pollux, set original ATK/DEF
-- ============================================================
function s.op_pollux(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    if Duel.GetLocationCountFromEx(tp)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local tc=Duel.SelectMatchingCard(tp,s.filter_pollux,tp,LOCATION_EXTRA,0,1,1,nil,e,tp):GetFirst()
    if tc and Duel.SpecialSummon(tc,SUMMON_TYPE_SPECIAL,tp,tp,false,false,POS_FACEUP)>0 then
        local ct=e:GetLabel()
        local val=ct*1000
        -- Original ATK
        local e2=Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_SET_BASE_ATTACK)
        e2:SetValue(val)
        e2:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e2)
        -- Original DEF
        local e3=e2:Clone()
        e3:SetCode(EFFECT_SET_BASE_DEFENSE)
        tc:RegisterEffect(e3)

        -- Register flag effects for leaving field stats
        tc:ResetFlagEffect(92047)
        tc:ResetFlagEffect(92047+100)
        tc:RegisterFlagEffect(92047,0,0,1,val)
        tc:RegisterFlagEffect(92047+100,0,0,1,val)
    end
end
