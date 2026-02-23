-- Verre Magic: Transformation
local s,id=GetID()
function s.initial_effect(c)
    -- Thẻ bài luôn là "Witchcrafter" (0x128) và "Magistus" (0x152)
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_ADD_SETCODE)
    e0:SetValue(0x128) -- Witchcrafter theo ảnh của bạn
    c:RegisterEffect(e0)
    local e1=e0:Clone()
    e1:SetValue(0x152) -- Magistus theo ảnh của bạn
    c:RegisterEffect(e1)

    -- Hiệu ứng kích hoạt
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,0))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK+CATEGORY_TOHAND+CATEGORY_SEARCH)
    e2:SetType(EFFECT_TYPE_ACTIVATE)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e2:SetTarget(s.target)
    e2:SetOperation(s.activate)
    c:RegisterEffect(e2)
end

-- ID Card của bạn
local ID_MADAME_VERRE = 21522601
local ID_RILLIONA_MAIN = 72498838
local ID_RILLIONA_XYZ  = 74689476

-- Filter check Rilliona
function s.rill_filter(c)
    return c:IsFaceup() 
        and (c:IsCode(ID_RILLIONA_MAIN) or c:IsCode(ID_RILLIONA_XYZ) or c:IsSetCard(0x152)) 
        and c:IsAbleToDeck()
end

-- Filter Witchcrafter S/T (Mã 0x128)
function s.st_filter(c)
    return c:IsSetCard(0x128) and c:IsType(TYPE_SPELL+TYPE_TRAP) 
        and (c:IsAbleToHand() or c:IsSSetable())
end

-- Hiệu ứng chính
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
    local b1=Duel.IsExistingMatchingCard(s.rill_filter,tp,LOCATION_MZONE,0,1,nil)
        and Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,ID_MADAME_VERRE)
    local b2=Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,ID_MADAME_VERRE),tp,LOCATION_MZONE,0,1,nil)
        and Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,ID_RILLIONA_MAIN)
        and Duel.IsExistingMatchingCard(s.lv4_filter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp)
        and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
    if chk==0 then return b1 or b2 end
    local op=Duel.SelectEffect(tp,{b1,aux.Stringid(id,1)},{b2,aux.Stringid(id,2)})
    e:SetLabel(op)
    e:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK)
    if op==1 then e:SetCategory(e:GetCategory()+CATEGORY_SEARCH+CATEGORY_TOHAND) end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local op=e:GetLabel()
    if op==1 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
        local g=Duel.SelectMatchingCard(tp,s.rill_filter,tp,LOCATION_MZONE,0,1,1,nil)
        if #g>0 and Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
            local sp=Duel.SelectMatchingCard(tp,Card.IsCode,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,ID_MADAME_VERRE)
            if #sp>0 and Duel.SpecialSummon(sp,0,tp,tp,false,false,POS_FACEUP)>0 then
                local stg=Duel.GetMatchingGroup(s.st_filter,tp,LOCATION_DECK,0,nil)
                if #stg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
                    local tc=stg:Select(tp,1,1,nil):GetFirst()
                    local b1,b2=tc:IsAbleToHand(),tc:IsSSetable()
                    local sel=(b1 and b2) and Duel.SelectOption(tp,1190,1153) or (b1 and 0 or 1)
                    if sel==0 then Duel.SendtoHand(tc,nil,REASON_EFFECT) Duel.ConfirmCards(1-tp,tc)
                    else Duel.SSet(tp,tc) end
                end
            end
        end
    elseif op==2 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
        local g=Duel.SelectMatchingCard(tp,aux.FaceupFilter(Card.IsCode,ID_MADAME_VERRE),tp,LOCATION_MZONE,0,1,1,nil)
        if #g>0 and Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
            if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 or Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then return end
            local g1=Duel.GetFirstMatchingCard(Card.IsCode,tp,LOCATION_HAND+LOCATION_DECK,0,nil,ID_RILLIONA_MAIN)
            local g2=Duel.GetFirstMatchingCard(s.lv4_filter,tp,LOCATION_HAND+LOCATION_DECK,0,g1,e,tp)
            if g1 and g2 then Duel.SpecialSummon(Group.FromCards(g1,g2),0,tp,tp,false,false,POS_FACEUP) end
        end
    end
end
function s.lv4_filter(c,e,tp) return c:IsLevel(4) and c:IsRace(RACE_SPELLCASTER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
