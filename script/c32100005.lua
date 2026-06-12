-- ============================================================
-- Card Name: Rikka Foliage
-- Passcode  : 32100005
-- Type      : Spell / Continuous
-- Archetype : Rikka (0x141)
-- ============================================================
-- Effect 1  : On activation: Search 1 Rikka monster from Deck/GY (HOPT).
-- Effect 2  : Sent to GY: target 2 Rikka monsters in GY, shuffle to Deck, return self to hand (HOPT).
-- Effect 3  : All Plant monsters you control gain 1200 ATK and 1000 DEF.
-- Effect 4  : Quick Effect: Tribute self, target 1 Rikka monster; SS 1 same Level from Deck,
--             then can Xyz Summon 1 Rikka monster (which is unaffected by card effects).
-- ============================================================

local s,id=GetID()

function s.initial_effect(c)
    -- Activate: Search Rikka monster
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.acttg)
    e1:SetOperation(s.actop)
    c:RegisterEffect(e1)

    -- Sent to GY: Recycle
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TODECK+CATEGORY_TOHAND)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
    e2:SetCode(EVENT_TO_GRAVE)
    e2:SetCountLimit(1,id+100)
    e2:SetTarget(s.gytg)
    e2:SetOperation(s.gyop)
    c:RegisterEffect(e2)

    -- Stat Boost
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_UPDATE_ATTACK)
    e3:SetRange(LOCATION_SZONE)
    e3:SetTargetRange(LOCATION_MZONE,0)
    e3:SetTarget(aux.TargetBoolFunction(Card.IsRace,RACE_PLANT))
    e3:SetValue(1200)
    c:RegisterEffect(e3)
    local e4=e3:Clone()
    e4:SetCode(EFFECT_UPDATE_DEFENSE)
    e4:SetValue(1000)
    c:RegisterEffect(e4)

    -- Quick Effect: Tribute self, SS & Xyz Summon
    local e5=Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id,2))
    e5:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e5:SetType(EFFECT_TYPE_QUICK_O)
    e5:SetCode(EVENT_FREE_CHAIN)
    e5:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e5:SetRange(LOCATION_SZONE)
    e5:SetCost(s.spcost)
    e5:SetTarget(s.sptg)
    e5:SetOperation(s.spop)
    c:RegisterEffect(e5)
end

-- ============================================================
-- Effect 1 Logic: Search on activation
-- ============================================================
function s.actfilter(c)
    return c:IsSetCard(0x141) and c:IsMonster() and c:IsAbleToHand()
end

function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.actop(e,tp,eg,ep,ev,re,r,rp)
    if not e:GetHandler():IsRelateToEffect(e) then return end
    local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.actfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,nil)
    if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local sg=g:Select(tp,1,1,nil)
        local sc=sg:GetFirst()
        if sc then
            local in_deck=sc:IsLocation(LOCATION_DECK)
            if Duel.SendtoHand(sc,nil,REASON_EFFECT)>0 and sc:IsLocation(LOCATION_HAND) then
                Duel.ConfirmCards(1-tp,sc)
                if in_deck then Duel.ShuffleDeck(tp) end
            end
        end
    end
end

-- ============================================================
-- Effect 2 Logic: GY Recycle
-- ============================================================
function s.gyfilter(c)
    return c:IsSetCard(0x141) and c:IsMonster() and c:IsAbleToDeck()
end

function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.gyfilter(chkc) end
    local c=e:GetHandler()
    if chk==0 then
        return c:IsAbleToHand()
            and Duel.IsExistingTarget(s.gyfilter,tp,LOCATION_GRAVE,0,2,nil)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local g=Duel.SelectTarget(tp,s.gyfilter,tp,LOCATION_GRAVE,0,2,2,nil)
    Duel.SetOperationInfo(0,CATEGORY_TODECK,g,2,0,0)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,c,1,0,0)
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tg=Duel.GetTargetCards(e)
    if #tg==2 and Duel.SendtoDeck(tg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
        local og=Duel.GetOperatedGroup()
        if og:IsExists(Card.IsLocation,1,nil,LOCATION_DECK+LOCATION_EXTRA) and c:IsRelateToEffect(e) then
            Duel.SendtoHand(c,nil,REASON_EFFECT)
            Duel.ConfirmCards(1-tp,c)
        end
    end
end

-- ============================================================
-- Effect 5 Logic: Quick Effect Tribute, SS & Xyz
-- ============================================================
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsAbleToGraveAsCost() end
    Duel.SendtoGrave(c,REASON_COST)
end

function s.filter(c,e,tp)
    local lv=c:GetLevel()
    return c:IsFaceup() and c:IsSetCard(0x141) and lv>0
        and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,lv,e,tp)
end

function s.spfilter(c,lv,e,tp)
    return c:IsSetCard(0x141) and c:IsLevel(lv) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.filter(chkc,e,tp) end
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingTarget(s.filter,tp,LOCATION_MZONE,0,1,nil,e,tp)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
    local g=Duel.SelectTarget(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil,e,tp)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

function s.xyzfilter(c)
    return c:IsSetCard(0x141) and c:IsType(TYPE_XYZ) and c:IsXyzSummonable(nil)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if not tc or not tc:IsRelateToEffect(e) or tc:IsFacedown() then return end
    local lv=tc:GetLevel()
    if lv==0 then return end
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,lv,e,tp)
    if #g>0 and Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)>0 then
        -- then you can xyz summon a Rikka monster
        local xyzg=Duel.GetMatchingGroup(s.xyzfilter,tp,LOCATION_EXTRA,0,nil)
        if #xyzg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
            Duel.BreakEffect()
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
            local xg=xyzg:Select(tp,1,1,nil)
            local xc=xg:GetFirst()
            if xc then
                Duel.XyzSummon(tp,xc,nil)
                -- immune to card effects this turn
                local e1=Effect.CreateEffect(e:GetHandler())
                e1:SetType(EFFECT_TYPE_FIELD)
                e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
                e1:SetCode(EFFECT_IMMUNE_EFFECT)
                e1:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
                e1:SetTarget(function(e,c) return c==e:GetLabelObject() end)
                e1:SetLabelObject(xc)
                e1:SetValue(function(e,te) return te:GetOwner()~=e:GetLabelObject() end)
                e1:SetReset(RESET_PHASE+PHASE_END)
                Duel.RegisterEffect(e1,tp)
            end
        end
    end
end
