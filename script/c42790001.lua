-- ============================================================
-- Card Name: Outer Entity Sothoth
-- Passcode : 42790001
-- Type     : Monster / Xyz / Effect
-- Attribute: DARK
-- Rank     : 5
-- ATK      : 2500
-- DEF      : 2500
-- Race     : Fiend
-- Archetype: Outer Entity (0x10b7)
-- Materials: 3+ Level 5 monsters
-- ============================================================
-- Effect 1: Can also be Xyz Summoned by overlaying an "Entity"
--           Xyz Monster you control.
-- Effect 2: Quick Effect: Attach 1 Fusion, Synchro, or Xyz Monster
--           from field, Extra Deck, or GY as material.
-- Effect 3: Quick Effect: Detach up to 3 different types of
--           materials (Fusion, Synchro, Xyz) to banish opponent's
--           cards face-down (Fusion: Hand; Synchro: Extra Deck;
--           Xyz: Field) (Your opponent cannot respond).
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- Xyz Summon Procedure
    c:EnableReviveLimit()
    Xyz.AddProcedure(c,s.xyzfilter,5,3,s.altfilter,aux.Stringid(id,0),Xyz.InfiniteMats,s.altop)

    -- ============================================================
    -- Effect 2 — Quick Effect: Attach 1 Fusion, Synchro, or Xyz
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,1))
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.atttg)
    e1:SetOperation(s.attop)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 3 — Quick Effect: Detach up to 3 different types to banish face-down
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,2))
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,id+1)
    e2:SetCost(s.detcost)
    e2:SetTarget(s.dettg)
    e2:SetOperation(s.detop)
    c:RegisterEffect(e2)
end

s.listed_series={0xb7}

-- ============================================================
-- Summon Procedure: Xyz Summon Filters
-- ============================================================
function s.xyzfilter(c,xyz,sumtype,tp)
    return c:IsLevel(5)
end

-- ============================================================
-- Summon Procedure: Alternative Xyz Summon Filter
-- ============================================================
function s.altfilter(c,tp,xyz)
    return c:IsFaceup() and c:IsSetCard(0xb7)
end

-- ============================================================
-- Summon Procedure: Alternative Xyz Summon Cost/Operation
-- ============================================================
function s.altop(e,tp,chk,mc)
    if chk==0 then return Duel.GetFlagEffect(tp,id)==0 end
    Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
    return true
end

-- ============================================================
-- Effect 2: Filter — Valid attach targets
-- ============================================================
function s.attfilter(c)
    return c:IsType(TYPE_FUSION+TYPE_SYNCHRO+TYPE_XYZ) and (not c:IsLocation(LOCATION_MZONE) or c:IsFaceup())
end

-- ============================================================
-- Effect 2: Target — Check if attach is possible
-- ============================================================
function s.atttg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then
        return c:IsType(TYPE_XYZ)
            and Duel.IsExistingMatchingCard(s.attfilter,tp,LOCATION_MZONE+LOCATION_EXTRA+LOCATION_GRAVE,0,1,c)
    end
end

-- ============================================================
-- Effect 2: Operation — Select 1 card and attach as material
-- ============================================================
function s.attop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATTACH)
    local g=Duel.SelectMatchingCard(tp,s.attfilter,tp,LOCATION_MZONE+LOCATION_EXTRA+LOCATION_GRAVE,0,1,1,c)
    if #g>0 then
        Duel.Overlay(c,g)
    end
end

-- ============================================================
-- Effect 3: Cost — Detach Fusion, Synchro, and/or Xyz materials
-- ============================================================
function s.detcost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    local og=c:GetOverlayGroup()
    if chk==0 then
        return og:IsExists(Card.IsType,1,nil,TYPE_FUSION+TYPE_SYNCHRO+TYPE_XYZ)
    end
    
    local detach_g=Group.CreateGroup()
    local selected_types=0
    local finished=false
    
    while not finished and #detach_g<3 do
        local select_filter=function(card)
            if detach_g:IsContains(card) then return false end
            if card:IsType(TYPE_FUSION) and (selected_types & TYPE_FUSION)==0 then return true end
            if card:IsType(TYPE_SYNCHRO) and (selected_types & TYPE_SYNCHRO)==0 then return true end
            if card:IsType(TYPE_XYZ) and (selected_types & TYPE_XYZ)==0 then return true end
            return false
        end
        
        if not og:IsExists(select_filter,1,nil) then break end
        
        if #detach_g>=1 then
            if not Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
                break
            end
        end
        
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVEXYZ)
        local sc=og:FilterSelect(tp,select_filter,1,1,nil):GetFirst()
        detach_g:AddCard(sc)
        if sc:IsType(TYPE_FUSION) then selected_types=selected_types | TYPE_FUSION end
        if sc:IsType(TYPE_SYNCHRO) then selected_types=selected_types | TYPE_SYNCHRO end
        if sc:IsType(TYPE_XYZ) then selected_types=selected_types | TYPE_XYZ end
    end
    
    e:SetLabel(selected_types)
    Duel.SendtoGrave(detach_g,REASON_COST)
end

-- ============================================================
-- Effect 3: Target — Apply chain response lock
-- ============================================================
function s.dettg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetChainLimit(s.chlimit)
end

-- ============================================================
-- Effect 3: Chain Limit — Force no response
-- ============================================================
function s.chlimit(e,ep,tp)
    return tp==ep
end

-- ============================================================
-- Effect 3: Operation — Apply banish effects based on detached types
-- ============================================================
function s.detop(e,tp,eg,ep,ev,re,r,rp)
    local types=e:GetLabel()
    
    -- Fusion: Banish opponent's hand card face-down
    if (types & TYPE_FUSION)~=0 then
        local hg=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
        if #hg>0 then
            Duel.ConfirmCards(tp,hg)
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
            local sg=hg:Select(tp,1,1,nil)
            local tc=sg:GetFirst()
            if tc and Duel.Remove(tc,POS_FACEDOWN,REASON_EFFECT)>0 then
                local e1=Effect.CreateEffect(e:GetHandler())
                e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
                e1:SetCode(EVENT_PHASE+PHASE_END)
                e1:SetCountLimit(1)
                e1:SetLabelObject(tc)
                e1:SetCondition(s.retcon)
                e1:SetOperation(s.retop_hand)
                e1:SetReset(RESET_PHASE+PHASE_END)
                Duel.RegisterEffect(e1,tp)
            end
        end
    end

    -- Synchro: Banish opponent's Extra Deck monster face-down
    if (types & TYPE_SYNCHRO)~=0 then
        local exg=Duel.GetFieldGroup(tp,0,LOCATION_EXTRA)
        if #exg>0 then
            Duel.ConfirmCards(tp,exg)
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
            local sg=exg:FilterSelect(tp,Card.IsType,1,1,nil,TYPE_MONSTER)
            local tc=sg:GetFirst()
            if tc and Duel.Remove(tc,POS_FACEDOWN,REASON_EFFECT)>0 then
                local e2=Effect.CreateEffect(e:GetHandler())
                e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
                e2:SetCode(EVENT_PHASE+PHASE_END)
                e2:SetCountLimit(1)
                e2:SetLabelObject(tc)
                e2:SetCondition(s.retcon)
                e2:SetOperation(s.retop_extra)
                e2:SetReset(RESET_PHASE+PHASE_END)
                Duel.RegisterEffect(e2,tp)
            end
        end
    end

    -- Xyz: Banish 1 card on the field face-down
    if (types & TYPE_XYZ)~=0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
        local sg=Duel.SelectMatchingCard(tp,nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
        local tc=sg:GetFirst()
        if tc and Duel.Remove(tc,POS_FACEDOWN,REASON_EFFECT+REASON_TEMPORARY)>0 then
            local e3=Effect.CreateEffect(e:GetHandler())
            e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
            e3:SetCode(EVENT_PHASE+PHASE_END)
            e3:SetCountLimit(1)
            e3:SetLabelObject(tc)
            e3:SetCondition(s.retcon)
            e3:SetOperation(s.retop_field)
            e3:SetReset(RESET_PHASE+PHASE_END)
            Duel.RegisterEffect(e3,tp)
        end
    end
end

-- ============================================================
-- Return Helpers: Condition — Card must be in banish zone
-- ============================================================
function s.retcon(e,tp,eg,ep,ev,re,r,rp)
    local tc=e:GetLabelObject()
    return tc and tc:IsLocation(LOCATION_REMOVED)
end

-- ============================================================
-- Return Helpers: Operation — Return card to opponent's hand
-- ============================================================
function s.retop_hand(e,tp,eg,ep,ev,re,r,rp)
    local tc=e:GetLabelObject()
    Duel.SendtoHand(tc,nil,REASON_EFFECT)
end

-- ============================================================
-- Return Helpers: Operation — Return card to opponent's Extra
-- ============================================================
function s.retop_extra(e,tp,eg,ep,ev,re,r,rp)
    local tc=e:GetLabelObject()
    Duel.SendtoDeck(tc,nil,SEQ_DECKTOP,REASON_EFFECT)
end

-- ============================================================
-- Return Helpers: Operation — Return card to field
-- ============================================================
function s.retop_field(e,tp,eg,ep,ev,re,r,rp)
    local tc=e:GetLabelObject()
    Duel.ReturnToField(tc)
end
