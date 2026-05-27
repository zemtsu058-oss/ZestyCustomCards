# Setcode Map — Official Archetypes in Queue

All values from `archetype_setcode_constants.lua` (ProjectIgnis/CardScripts).

## Queue Archetypes

| Archetype | Setcode Hex | Decimal | Passcode Range |
|-----------|------------|---------|----------------|
| Dragonmaid | `0x133` | 307 | 30700001 ~ 30799999 |
| Witchcrafter | `0x128` | 296 | 29600001 ~ 29699999 |
| Branded | `0x160` | 352 | 35200001 ~ 35299999 |
| Labrynth | `0x17f` | 383 | 38300001 ~ 38399999 |
| White Forest | `0x1aa` | 426 | 42600001 ~ 42699999 |

## Related Archetypes (support cards)

| Archetype | Setcode Hex | Decimal | Used by |
|-----------|------------|---------|---------|
| Diabell | `0x203` | 515 | White Forest |
| Diabellstar | `0x1203` | 4611 | White Forest |
| Sinful Spoils | `0x204` | 516 | White Forest |
| Welcome Labrynth | `0x117f` | 4479 | Labrynth |

## Custom (fan-made) Archetypes

Fan-made archetypes need setcodes created in `script/constants.lua` and `strings.conf`.

| Archetype | Status | Setcode |
|-----------|--------|---------|
| Castel of Dreams | Needs setcode | TBD |

## Passcode Convention

```
passcode = {setcode_decimal}{5_digit_sequential}
```

- Always 9 digits (avoids collisions with official 8-digit passcodes)
- Check `script/c*.lua` and `custom_cards_zesty.cdb:datas` for existing passcodes
- Existing custom archetypes (TTF, Desire HERO, etc.) keep their own patterns
