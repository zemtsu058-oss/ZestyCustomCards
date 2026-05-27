# CDB Schema Reference

EDOPro card database is SQLite3 (`custom_cards_zesty.cdb`).

## Tables

### datas — Card metadata

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PK | Card passcode |
| ot | INTEGER | 1=OCG, 2=TCG, 3=Anime, 32=Custom (restricts to custom format) |
| alias | INTEGER | If this is an alt art, passcode of original |
| setcode | INTEGER | Archetype code (see encoding below) |
| type | INTEGER | Card type bitmask (TYPE_* constants) |
| atk | INTEGER | ATK value (0 for spells/traps) |
| def | INTEGER | DEF value (0 for spells/traps) |
| level | INTEGER | Level/Rank/Link rating (0 for spells/traps) |
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

### Setcode Encoding

Setcode is stored **not** as the raw hex constant, but as the **ASCII bytes** of its decimal representation interpreted as a **big-endian integer**.

```
encode_setcode(hex_value):
    decimal_str = str(int(hex_value, 16)) if isinstance(hex_value, str) else str(hex_value)
    raw_bytes = decimal_str.encode('ascii')
    return int.from_bytes(raw_bytes, 'big', signed=False)
```

Example: White Forest `0x1aa` = 426 decimal → "426" → `0x343236` = **3420726**

### Type Bitmask (common)

| Value | Constant |
|-------|----------|
| 0x1 | TYPE_MONSTER |
| 0x2 | TYPE_SPELL |
| 0x4 | TYPE_TRAP |
| 0x20 | TYPE_EFFECT |
| 0x40 | TYPE_FUSION |
| 0x2000 | TYPE_SYNCHRO |
| 0x800000 | TYPE_XYZ |
| 0x4000000 | TYPE_LINK |
| 0x1000000 | TYPE_PENDULUM |
| 0x10000 | TYPE_QUICKPLAY |
| 0x20000 | TYPE_CONTINUOUS |
| 0x40000 | TYPE_EQUIP |
| 0x80000 | TYPE_FIELD |
| 0x10 | TYPE_NORMAL |
| 0x1000 | TYPE_TUNER |

Quick references:
- Normal Spell: `0x2`
- Quick-Play Spell: `0x10002`
- Normal Trap: `0x4`
- Effect Monster: `0x21`
- Link Monster: `0x4000021`
- Xyz Monster: `0x800021`
- Synchro Monster: `0x2021`
- Fusion Monster: `0x41`

### Category Bitmask (common)

| Value | Constant |
|-------|----------|
| 0x1 | CATEGORY_DESTROY |
| 0x8 | CATEGORY_TOHAND |
| 0x10 | CATEGORY_TODECK |
| 0x20000 | CATEGORY_SEARCH |
| 0x10000 | CATEGORY_DRAW |
| 0x200 | CATEGORY_SPECIAL_SUMMON |
| 0x4 | CATEGORY_REMOVE |
| 0x4000000 | CATEGORY_LEAVE_GRAVE |
| 0x80000 | CATEGORY_DAMAGE |
| 0x100000 | CATEGORY_RECOVER |
| 0x10000000 | CATEGORY_NEGATE |
| 0x200000 | CATEGORY_ATKCHANGE |
| 0x20 | CATEGORY_TOGRAVE |
