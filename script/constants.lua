-- Custom Archetype
SET_TTF                           = 0x789
SET_ATERMIS                       = 0x780
SET_CAT                           = 0x781
SET_DESIRE_HERO                   = 0x927
SET_BUCKLE                        = 0x315
SET_HYPERDIMENSION                = 0x1291
SET_CASTLE_OF_DREAMS               = 0x782
SET_WEZAEMON                       = 0x783
-- Custom counter
COUNTER_MANA                      = 0x177

-- Global Helper Utilities
function Card.GetRelatedHandler(c, e)
    if c and c:IsRelateToEffect(e) then
        return c
    end
    return nil
end