-- ============================================================
-- Card Name: Wandering Fairy in the Castle of Dreams
-- Passcode  : 192200015
-- Type      : Monster / Link / Effect
-- Archetype : Castle of Dreams (0x782)
-- ============================================================
-- Effect 1  : Unaffected by Spell/Trap effects, except "Castle of Dreams" Spell/Traps.
-- Effect 2  : Once per Chain, if opponent Special Summons from Deck/Extra Deck:
--             Opponent chooses 1 effect for both players to apply.
-- Effect 3  : GY: Return self and 1 targeted card on field/GY to hand.
-- ============================================================

local s,id=GetID()
Duel.LoadScript("constants.lua")


function s.initial_effect(c)
    c:EnableReviveLimit()

    -- ============================================================
    -- Summon Procedure — Link Summon: 2+ monsters, including a Castle of Dreams Spellcaster
    -- ============================================================
    Link.AddProcedure(c,nil,2,3,s.lcheck)

    -- ============================================================
    -- Effect 1 — Unaffected by Spell/Trap except Castle of Dreams
    -- ============================================================
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCode(EFFECT_IMMUNE_EFFECT)
    e1:SetValue(s.efilter)
    c:RegisterEffect(e1)

    -- ============================================================
    -- Effect 2 — Once per Chain: opponent Special Summons from Deck/Extra Deck
    -- ============================================================
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCondition(s.spcon)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)

    -- ============================================================
    -- Effect 3 — GY Quick Effect: Return self and target to hand
    -- ============================================================
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,3))
    e3:SetCategory(CATEGORY_TOHAND)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e3:SetRange(LOCATION_GRAVE)
    e3:SetCountLimit(1,id)
    e3:SetTarget(s.thtg)
    e3:SetOperation(s.thop)
    c:RegisterEffect(e3)
end

-- ============================================================
-- Material Check — Link Summon materials check
-- ============================================================
function s.matfilter(c,lc,sumtype,tp)
    return c:IsSetCard(0x782,lc,sumtype,tp) and c:IsRace(RACE_SPELLCASTER,lc,sumtype,tp)
end

function s.lcheck(g,lc,sumtype,tp)
    return g:IsExists(s.matfilter,1,nil,lc,sumtype,tp)
end

-- ============================================================
-- Effect 1: Value Filter — Unaffected by non-archetype Spell/Traps
-- ============================================================
function s.efilter(e,te)
    local tc=te:GetHandler()
    return te:IsActiveType(TYPE_SPELL+TYPE_TRAP) and not tc:IsSetCard(0x782)
end

-- ============================================================
-- Effect 2: Condition — Opponent Special Summons from Deck/Extra Deck
-- ============================================================
function s.spfilter(c,tp)
    return c:IsControler(tp) and (c:IsSummonLocation(LOCATION_DECK) or c:IsSummonLocation(LOCATION_EXTRA))
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return eg:IsExists(s.spfilter,1,nil,1-tp) and Duel.GetFlagEffect(tp,id)==0
end

-- ============================================================
-- Effect 2: Target
-- ============================================================
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.RegisterFlagEffect(tp,id,RESET_CHAIN,0,1)
    -- We will determine category in operation since opponent chooses.
end

-- ============================================================
-- Effect 2: Helper Filters for Option 2 & 3
-- ============================================================
function s.spfilter2(c,e,tp)
    return c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.setfilter(c)
    return c:IsSpellTrap() and c:IsSSetable()
end

-- ============================================================
-- Effect 2: Operation
-- ============================================================
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=Card.GetRelatedHandler(e:GetHandler(),e)
    
    -- Opponent makes the choice
    Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_EFFECT)
    local choice=Duel.SelectOption(1-tp,aux.Stringid(id,0),aux.Stringid(id,1),aux.Stringid(id,2))
    
    if choice==0 then
        -- (1) Hand manipulation & Draw
        local g1=Duel.GetFieldGroup(tp,LOCATION_HAND,0)
        local rg1=Group.CreateGroup()
        if #g1>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
            rg1=g1:Select(tp,1,#g1,nil)
        end
        
        local g2=Duel.GetFieldGroup(1-tp,LOCATION_HAND,0)
        local rg2=Group.CreateGroup()
        if #g2>0 and Duel.SelectYesNo(1-tp,aux.Stringid(id,0)) then
            Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_TODECK)
            rg2=g2:Select(1-tp,1,#g2,nil)
        end
        
        local rg=Group.CreateGroup()
        rg:Merge(rg1)
        rg:Merge(rg2)
        if #rg>0 then
            Duel.SendtoDeck(rg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
        end
        
        local d1=6-Duel.GetFieldGroupCount(tp,LOCATION_HAND,0)
        if d1>0 then Duel.Draw(tp,d1,REASON_EFFECT) end
        
        local d2=3-Duel.GetFieldGroupCount(1-tp,LOCATION_HAND,0)
        if d2>0 then Duel.Draw(1-tp,d2,REASON_EFFECT) end
        
    elseif choice==1 then
        -- (2) Special Summon from GY/banishment
        local g1=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.spfilter2),tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil,e,tp)
        local g2=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.spfilter2),1-tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil,e,1-tp)
        
        local can_tp=Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and #g1>0
        local can_op=Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0 and #g2>0
        
        local tc1=nil
        if can_tp then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
            local sg1=g1:Select(tp,1,1,nil)
            tc1=sg1:GetFirst()
        end
        
        local tc2=nil
        if can_op then
            Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_SPSUMMON)
            local sg2=g2:Select(1-tp,1,1,nil)
            tc2=sg2:GetFirst()
        end
        
        if tc1 then
            Duel.SpecialSummonStep(tc1,0,tp,tp,false,false,POS_FACEUP)
        end
        if tc2 then
            Duel.SpecialSummonStep(tc2,0,1-tp,1-tp,false,false,POS_FACEUP)
            -- Negate the effects of the opponent's monster
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_DISABLE)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD)
            tc2:RegisterEffect(e1)
            local e2=e1:Clone()
            e2:SetCode(EFFECT_DISABLE_EFFECT)
            tc2:RegisterEffect(e2)
        end
        Duel.SpecialSummonComplete()
        
    else
        -- (3) Set 1 Spell/Trap from Deck/GY/banishment
        local g1=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.setfilter),tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
        local g2=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.setfilter),1-tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
        
        local can_tp=Duel.GetLocationCount(tp,LOCATION_SZONE)>0 and #g1>0
        local can_op=Duel.GetLocationCount(1-tp,LOCATION_SZONE)>0 and #g2>0
        
        local tc1=nil
        if can_tp then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
            local sg1=g1:Select(tp,1,1,nil)
            tc1=sg1:GetFirst()
        end
        
        local tc2=nil
        if can_op then
            Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_SET)
            local sg2=g2:Select(1-tp,1,1,nil)
            tc2=sg2:GetFirst()
        end
        
        if tc1 then
            Duel.SSet(tp,tc1)
            -- Can activate this turn
            if tc1:IsType(TYPE_QUICKPLAY) then
                local e1=Effect.CreateEffect(e:GetHandler())
                e1:SetType(EFFECT_TYPE_SINGLE)
                e1:SetCode(EFFECT_QP_ACT_IN_SET_TURN)
                e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
                tc1:RegisterEffect(e1)
            elseif tc1:IsType(TYPE_TRAP) then
                local e1=Effect.CreateEffect(e:GetHandler())
                e1:SetType(EFFECT_TYPE_SINGLE)
                e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
                e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
                tc1:RegisterEffect(e1)
            end
        end
        
        if tc2 then
            Duel.SSet(1-tp,tc2)
            -- Cannot activate this turn
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_CANNOT_TRIGGER)
            e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
            tc2:RegisterEffect(e1)
        end
    end
end

-- ============================================================
-- Effect 3: Target — GY return self and target to hand
-- ============================================================
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_ONFIELD+LOCATION_GRAVE) and chkc:IsAbleToHand() end
    local c=e:GetHandler()
    if chk==0 then
        return c:IsAbleToHand()
            and Duel.IsExistingTarget(Card.IsAbleToHand,tp,LOCATION_ONFIELD+LOCATION_GRAVE,LOCATION_ONFIELD+LOCATION_GRAVE,1,c)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
    local g=Duel.SelectTarget(tp,Card.IsAbleToHand,tp,LOCATION_ONFIELD+LOCATION_GRAVE,LOCATION_ONFIELD+LOCATION_GRAVE,1,1,c)
    g:AddCard(c)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,2,0,0)
end

-- ============================================================
-- Effect 3: Operation
-- ============================================================
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local c=Card.GetRelatedHandler(e:GetHandler(),e)
    local tc=Duel.GetFirstTarget()
    if c:IsRelateToEffect(e) and tc and tc:IsRelateToEffect(e) then
        local g=Group.FromCards(c,tc)
        Duel.SendtoHand(g,nil,REASON_EFFECT)
    end
end

