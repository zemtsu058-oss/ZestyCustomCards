# CDB Schema Reference

EDOPro card database is SQLite3 (`custom_cards_zesty.cdb`).

## Tables

### datas — Card metadata

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PK | Card passcode |
| ot | INTEGER | 1=OCG, 2=TCG, 3=Anime, **32=Custom** (MUST use 32 for this project) |
| alias | INTEGER | If this is an alt art, passcode of original (0 = none) |
| setcode | INTEGER | Archetype code (see encoding below) |
| type | INTEGER | Card type bitmask (TYPE_* constants) |
| atk | INTEGER | ATK value (0 for spells/traps, -2 = ? ATK) |
| def | INTEGER | DEF value (0 for spells/traps, -2 = ? DEF, 0 for Links) |
| level | INTEGER | Level/Rank/Link rating (also encodes Pendulum scales — see below) |
| race | INTEGER | Monster type/race (0 for spells/traps) |
| attribute | INTEGER | Monster attribute (0 for spells/traps) |
| category | INTEGER | Effect category bitmask |

### texts — Card text

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PK | Card passcode |
| name | TEXT | Card name |
| desc | TEXT | Effect text |
| str1..str16 | TEXT | aux.Stringid strings (strN = Stringid(id, N-1)) |

## Setcode Encoding

Setcode is stored **not** as the raw hex constant, but as the **ASCII bytes** of its decimal representation interpreted as a **big-endian integer**.

```python
def encode_setcode(decimal_value: int) -> int:
    decimal_str = str(decimal_value)
    raw_bytes = decimal_str.encode('ascii')
    return int.from_bytes(raw_bytes, 'big', signed=False)
```

Example: White Forest `0x1aa` = 426 decimal → "426" → `0x343236` = **3420726**

**Note:** The `insert_cdb.py` script handles this encoding automatically. Just pass the decimal value of the setcode.

## Level Column Encoding (with Pendulum Scales)

For non-Pendulum cards, `level` is simply the Level/Rank/Link rating.

For Pendulum cards, scales are encoded into the same column:
```
level = base_level + (left_scale << 24) + (right_scale << 16)
```

Example: Level 4, Scale 8/8 → `4 + (8 << 24) + (8 << 16)` = `134742020`

**Note:** The `insert_cdb.py` script handles this via `--lscale` and `--rscale` arguments.

## Type Bitmask

### Base Types

| Value | Constant |
|-------|----------|
| 0x1 | TYPE_MONSTER |
| 0x2 | TYPE_SPELL |
| 0x4 | TYPE_TRAP |

### Monster Sub-Types

| Value | Constant |
|-------|----------|
| 0x10 | TYPE_NORMAL |
| 0x20 | TYPE_EFFECT |
| 0x40 | TYPE_FUSION |
| 0x80 | TYPE_RITUAL |
| 0x1000 | TYPE_TUNER |
| 0x2000 | TYPE_SYNCHRO |
| 0x4000 | TYPE_TOKEN |
| 0x200000 | TYPE_SPIRIT |
| 0x400000 | TYPE_FLIP |
| 0x800000 | TYPE_XYZ |
| 0x1000000 | TYPE_PENDULUM |
| 0x4000000 | TYPE_LINK |

### Spell/Trap Sub-Types

| Value | Constant |
|-------|----------|
| 0x10000 | TYPE_QUICKPLAY |
| 0x20000 | TYPE_CONTINUOUS |
| 0x40000 | TYPE_EQUIP |
| 0x80000 | TYPE_FIELD |
| 0x100000 | TYPE_COUNTER |

### Quick Reference (combined bitmasks)

| Card Type | Value |
|-----------|-------|
| Effect Monster | `0x21` |
| Fusion Monster | `0x61` (Fusion+Effect) |
| Synchro Monster | `0x2021` |
| Xyz Monster | `0x800021` |
| Link Monster | `0x4000021` |
| Pendulum Effect Monster | `0x1000021` |
| Pendulum Normal Monster | `0x1000011` |
| Tuner Effect Monster | `0x1021` |
| Normal Spell | `0x2` |
| Quick-Play Spell | `0x10002` |
| Continuous Spell | `0x20002` |
| Field Spell | `0x80002` |
| Equip Spell | `0x40002` |
| Ritual Spell | `0x82` |
| Normal Trap | `0x4` |
| Continuous Trap | `0x20004` |
| Counter Trap | `0x100004` |

## Race Bitmask (Monster Type)

| Value | Race |
|-------|------|
| 0x1 | Warrior |
| 0x2 | Spellcaster |
| 0x4 | Fairy |
| 0x8 | Fiend |
| 0x10 | Zombie |
| 0x20 | Machine |
| 0x40 | Aqua |
| 0x80 | Pyro |
| 0x100 | Rock |
| 0x200 | Winged Beast |
| 0x400 | Plant |
| 0x800 | Insect |
| 0x1000 | Thunder |
| 0x2000 | Dragon |
| 0x4000 | Beast |
| 0x8000 | Beast-Warrior |
| 0x10000 | Dinosaur |
| 0x20000 | Fish |
| 0x40000 | Sea Serpent |
| 0x80000 | Reptile |
| 0x100000 | Psychic |
| 0x200000 | Divine-Beast |
| 0x400000 | Creator God |
| 0x800000 | Wyrm |
| 0x1000000 | Cyberse |
| 0x2000000 | Illusion |

## Attribute Bitmask

| Value | Attribute |
|-------|-----------|
| 0x1 | EARTH |
| 0x2 | WATER |
| 0x4 | FIRE |
| 0x8 | WIND |
| 0x10 | LIGHT |
| 0x20 | DARK |
| 0x40 | DIVINE |

## Category Bitmask

| Value | Constant | Use When |
|-------|----------|----------|
| 0x1 | CATEGORY_DESTROY | Card destroys |
| 0x2 | CATEGORY_RELEASE | Tributes |
| 0x4 | CATEGORY_REMOVE | Banishes |
| 0x8 | CATEGORY_TOHAND | Returns to hand |
| 0x10 | CATEGORY_TODECK | Returns to Deck |
| 0x20 | CATEGORY_TOGRAVE | Sends to GY |
| 0x40 | CATEGORY_DECKDES | Sends from Deck to GY |
| 0x80 | CATEGORY_HANDES | Discards from hand |
| 0x100 | CATEGORY_SUMMON | Normal Summons |
| 0x200 | CATEGORY_SPECIAL_SUMMON | Special Summons |
| 0x400 | CATEGORY_POSITION | Changes position |
| 0x800 | CATEGORY_DISABLE | Negates effects |
| 0x1000 | CATEGORY_EQUIP | Equips card |
| 0x2000 | CATEGORY_CONTROL | Takes control |
| 0x4000 | CATEGORY_DICE | Rolls dice |
| 0x8000 | CATEGORY_COIN | Tosses coin |
| 0x10000 | CATEGORY_DRAW | Draws cards |
| 0x20000 | CATEGORY_SEARCH | Searches deck |
| 0x40000 | CATEGORY_LVCHANGE | Changes Level |
| 0x80000 | CATEGORY_DAMAGE | Inflicts damage |
| 0x100000 | CATEGORY_RECOVER | Gains LP |
| 0x200000 | CATEGORY_ATKCHANGE | Changes ATK |
| 0x400000 | CATEGORY_DEFCHANGE | Changes DEF |
| 0x800000 | CATEGORY_COUNTER | Places/removes counters |
| 0x1000000 | CATEGORY_TOKEN | Summons tokens |
| 0x2000000 | CATEGORY_FUSION_SUMMON | Fusion Summons |
| 0x4000000 | CATEGORY_LEAVE_GRAVE | Leaves GY (for GY-related effects) |
| 0x10000000 | CATEGORY_NEGATE | Negates activation |
