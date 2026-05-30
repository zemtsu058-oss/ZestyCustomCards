# Setcode Map — Quick Reference

Cache of archetype setcodes used in the TTF Custom Cards project.
For full official archetype list, see `docs/archetype_setcode_constants.lua`.

## Fan-Made Archetypes (in `script/constants.lua`)

| Archetype | Hex | Decimal | Passcode Range | Constant |
|-----------|-----|---------|----------------|----------|
| TTF | `0x789` | 1929 | 192900001–192999999 | `SET_TTF` |
| Atermis | `0x780` | 1920 | 192000001–192099999 | `SET_ATERMIS` |
| Cat | `0x781` | 1921 | 192100001–192199999 | `SET_CAT` |
| Desire HERO | `0x927` | 2343 | 234300001–234399999 | `SET_DESIRE_HERO` |
| Buckle | `0x315` | 789 | 78900001–78999999 | `SET_BUCKLE` |
| Hyperdimension | `0x1291` | 4753 | 475300001–475399999 | `SET_HYPERDIMENSION` |
| Castle of Dreams | `0x782` | 1922 | 192200001–192299999 | `SET_CASTLE_OF_DREAMS` |

These require entries in both `script/constants.lua` and `strings.conf`.

## Official Archetypes (in queue — EDOPro built-in)

| Archetype | Hex | Decimal | Passcode Range | Queue Folder |
|-----------|-----|---------|----------------|--------------|
| Dragonmaid | `0x133` | 307 | 30700001–30799999 | `Dragonmaid` |
| Labrynth | `0x17f` | 383 | 38300001–38399999 | `Labrynth` |
| White Forest | `0x1aa` | 426 | 42600001–42699999 | `White_Forest` |
| Witchcrafter | `0x128` | 296 | 29600001–29699999 | `Witchcrafter` |
| Branded | `0x160` | 352 | 35200001–35299999 | `Brandeds` |

Official archetypes do NOT need entries in `constants.lua` — EDOPro has them built-in.

## Related Sub-Archetypes

| Archetype | Hex | Related To |
|-----------|-----|------------|
| Diabell | `0x203` | White Forest |
| Diabellstar | `0x1203` | White Forest |
| Sinful Spoils | `0x204` | White Forest |
| Welcome Labrynth | `0x117f` | Labrynth |

## Special Queue Folders

| Folder | Notes |
|--------|-------|
| `Common` | Cards not tied to a specific archetype |
| `Castel_of_dreams` | Fan-made archetype (Castle of Dreams) |

## Custom Counter

| Counter | Hex | Constant |
|---------|-----|----------|
| Mana | `0x177` | `COUNTER_MANA` |

## Passcode Convention

```
passcode = {setcode_hex_to_decimal} × 100000 + {5-digit sequential}
```

Example: White Forest (`0x1aa` = 426) → first card = `42600001`, next = `42600002`.

Use `check_passcode.py` to find the next free passcode automatically.
