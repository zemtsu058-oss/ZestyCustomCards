---
name: vibe-card
description: Create fan-made Yu-Gi-Oh! EDOPro custom cards from effect text. Use when user provides card name, type, and effect text, or says "vibe card", "code cho tôi", "làm card", "tạo script", or provides card artwork from docs/queues/. Handles passcode assignment, template selection, Lua script generation, CDB insertion, queue tracking, and full validation. Project-scoped to TTF Custom Cards repository.
---

# Vibe Card — EDOPro Fan-Made Card Pipeline

End-to-end workflow: effect text → Lua script → CDB → queue update → validate.

## Prerequisites

- Working directory: TTF Custom Cards git root
- Read `AGENTS.md` for full rules (this skill summarizes, AGENTS.md is authoritative)
- Read `template-card/README.md` for template usage and pattern lookup
- Read `script/constants.lua` and `strings.conf` for custom setcodes/counters

## Critical Rules (from AGENTS.md — MUST FOLLOW)

1. **ALWAYS** `local s,id=GetID()` at file top
2. **ALWAYS** `function s.initial_effect(c) ... end`
3. **ALWAYS** `aux.Stringid(id,N)` for SetDescription (N=0,1,2... per effect)
4. **ALWAYS** `if chk==0 then return ... end` in target functions
5. **ALWAYS** `Duel.SetOperationInfo` if effect destroys/searches/special summons
6. **ALWAYS** `c:IsRelateToEffect(e)` check in operation when using handler
7. **ALWAYS** `Duel.GetLocationCount(tp,LOCATION_MZONE)>0` before Special Summon
8. **ALWAYS** `c:RegisterEffect(eN)` after creating each effect
9. **ALWAYS** `SetRange` for non-SINGLE effects
10. **ALWAYS** use templates from `template-card/` as base
11. **NEVER** use `chk==1` — always check `chk==0` first
12. **NEVER** reference or copy code from existing `script/*.lua` files (they contain known bugs)
13. **ALWAYS** `SetCountLimit(1, id+N, EFFECT_COUNT_CODE_OATH)` — separate code per effect for hard OPT

## Workflow

### Step 1: Receive Card Info

Extract from user input:
- Card name
- Card type (Monster type/subtype, Spell/Trap + subtype)
- For monsters: Attribute, Level/Rank/Link, ATK/DEF, Race
- Effect text (English or Vietnamese)
- Archetype (from context or queue folder)

If user provides image from `docs/queues/<archetype>/`, read image → extract card text.

### Step 2: Determine Setcode

#### Fan-made archetypes (in `script/constants.lua`)

| Archetype | Hex | Decimal | Passcode prefix |
|-----------|-----|---------|-----------------|
| TTF | `0x789` | 1929 | 192900001+ |
| Atermis | `0x780` | 1920 | 192000001+ |
| Cat | `0x781` | 1921 | 192100001+ |
| Desire HERO | `0x927` | 2343 | 234300001+ |
| Buckle | `0x315` | 789 | 78900001+ |
| Hyperdimension | `0x1291` | 4753 | 475300001+ |
| Castle of Dreams | `0x782` | 1922 | 192200001+ |

These archetypes are defined in `script/constants.lua` and `strings.conf`.

#### Official archetypes (in queue, EDOPro built-in)

| Archetype | Hex | Decimal | Passcode prefix |
|-----------|-----|---------|-----------------|
| Dragonmaid | `0x133` | 307 | 30700001+ |
| Labrynth | `0x17f` | 383 | 38300001+ |
| White Forest | `0x1aa` | 426 | 42600001+ |
| Witchcrafter | `0x128` | 296 | 29600001+ |
| Branded | `0x160` | 352 | 35200001+ |

Official archetypes do NOT need entries in `constants.lua` — EDOPro already has them.
For official archetype setcodes not listed here, look up in `docs/archetype_setcode_constants.lua`.

Related sub-archetypes:
- Diabell (`0x203`), Diabellstar (`0x1203`), Sinful Spoils (`0x204`) — for White Forest
- Welcome Labrynth (`0x117f`) — for Labrynth

#### New fan-made archetype
If the archetype doesn't exist anywhere:
1. Pick a hex code not conflicting with existing ones
2. Add `SET_XXX = 0xYYY` to `script/constants.lua`
3. Add `!setname 0xYYY ArchetypeName` to `strings.conf`

#### No archetype
Set setcode = 0 in both script and CDB.

### Step 3: Assign Passcode

Convention: 9 digits = `{setcode_decimal}{5_digit_seq}` (see table above).

Run `check_passcode.py` to find the next free passcode:

```powershell
python .claude\skills\vibe-card\scripts\check_passcode.py <decimal_prefix>
```

On Windows, if `python` is not in PATH:
```powershell
& $env:USERPROFILE\.agents\skills\.venv\Scripts\python.exe .claude\skills\vibe-card\scripts\check_passcode.py <decimal_prefix>
```

Also verify against existing `script/c*.lua` files. If a bundled script fails because it resolves the wrong project root, fix the script in this repository.

### Step 4: Select Template

All templates live in `template-card/`. Match card type to template:

| Card Type | Template |
|-----------|----------|
| Effect Monster (trigger/ignition) | `template_effect_monster.lua` |
| Normal Spell | `template_normal_spell.lua` |
| Quick-Play Spell | `template_normal_spell.lua` (adjust type constant) |
| Normal Trap | `template_normal_trap.lua` |
| Fusion Monster | `template_fusion_monster.lua` |
| Synchro Monster | `template_synchro_monster.lua` |
| Xyz Monster | `template_xyz_monster.lua` |
| Link Monster | `template_link_monster.lua` |
| Pendulum Monster | `template_pendulum_monster.lua` |
| Field Spell | `template_field_spell.lua` |
| Hand Trap / Quick Effect | `template_hand_trap.lua` |

For multi-effect cards, use the template with the closest effect count, then add/remove effect blocks.

Quick-Play Spell CDB type is `0x10002`. If a Spell has hand triggers ("if drawn", "if added to your hand"), keep the Spell card type in CDB but script those effects as hand trigger effects.

### Step 5: Generate Script

1. Copy template → `script/c<passcode>.lua`
2. Replace all `<<PLACEHOLDER>>` markers with actual values:
   - `XXXXXXXXX` → passcode
   - `<<SETCODE>>` → archetype hex (e.g. `0x789`)
   - `<<RANK>>`, `<<LEVEL>>`, `<<ATK_VALUE>>`, `<<DEF>>` → stats
   - `<<LINK_COUNT>>`, `<<MIN_MATERIAL>>`, `<<MATERIAL_COUNT>>` → summon params
   - `<<LP_AMOUNT>>` → LP values
3. For each effect, configure:
   - `SetDescription(aux.Stringid(id, N))` — N=0,1,2... per effect
   - `SetCategory` — bitmask from effect actions
   - `SetType` — correct effect type constant
   - `SetCode` — trigger event or `EVENT_FREE_CHAIN`
   - `SetCountLimit(1, id+N, EFFECT_COUNT_CODE_OATH)` — separate code per effect for hard OPT
   - Target function with `if chk==0 then return ... end`
   - Operation function with `c:IsRelateToEffect(e)` checks
4. Keep effect text in header comment
5. Effect adjustments:
   - 1 effect only → delete unused effect blocks + their functions
   - 3+ effects → copy `Effect.CreateEffect` → `RegisterEffect` blocks, increment (`e3`, `e4`)
   - Function naming: `filter_search`, `tg_destroy`, `op_revive`, etc.
   - Function order: filter → target → operation

### Step 6: Insert CDB

Use `insert_cdb.py`. **ALWAYS set `ot=32`** (Custom format).

#### Option A: CLI
```powershell
python .claude\skills\vibe-card\scripts\insert_cdb.py `
  --passcode 42600001 `
  --name "Card Name" `
  --type 0x10002 `
  --setcode 426 `
  --desc "Effect text..." `
  --effect-strs "Effect 1 desc" "Effect 2 desc" `
  --atk 2500 --def 2000 --level 7 `
  --race 0x1 --attribute 0x20 `
  --category 0x4020008 `
  --overwrite
```

#### Option B: JSON file (recommended for complex text)
```powershell
python .claude\skills\vibe-card\scripts\insert_cdb.py --json-file card_data.json
```

JSON schema:
```json
{
  "passcode": 42600001,
  "name": "Card Name",
  "type": "0x10002",
  "setcode": 426,
  "desc": "Effect text...",
  "effect_strs": ["Effect 1 desc", "Effect 2 desc"],
  "atk": 2500,
  "def": 2000,
  "level": 7,
  "lscale": 8,
  "rscale": 8,
  "race": "0x1",
  "attribute": "0x20",
  "category": "0x4020008",
  "ot": 32,
  "overwrite": true
}
```

Key notes:
- `setcode` = decimal value of hex setcode (e.g. 426 for `0x1aa`)
- `type`, `race`, `attribute`, `category` accept hex strings or integers
- `lscale`/`rscale` automatically encode Pendulum scales into the `level` column
- `ot` **MUST be 32** for custom cards
- `--overwrite` deletes existing records before inserting (for updates)

### Step 7: Update Queue

If card artwork exists in `docs/queues/<archetype>/`:
- Rename `p_<name>.png` → `d_<name>.png` when script + CDB done
- Status prefixes: `p_` (pending), `w_` (working), `r_` (review), `d_` (done), `x_` (skipped)

Current queue folders: `Brandeds`, `Castel_of_dreams`, `Common`, `Dragonmaid`, `Labrynth`, `White_Forest`, `Witchcrafter`

### Step 8: Validate (MANDATORY before reporting DONE)

Run ALL of these checks:

```powershell
# 1. Validate syntax + structure
.\script-test\validate_scripts.ps1

# 2. Lint code style (trailing whitespace, line length)
.\script-test\lint_scripts.ps1

# 3. Check database ↔ script sync
python .\script-test\manage_db.py check-sync

# 4. Confirm file exists
Test-Path script\c<PASSCODE>.lua
```

Manual checks:
- All `<<PLACEHOLDER>>` replaced
- Each effect has `c:RegisterEffect(eN)`
- Filter → Target → Operation function order
- `SetRange` for non-SINGLE effects
- Correct passcode in filename
- Clean up temp files (`.tmp_*.py`, `__pycache__/`, scratch JSON)

**If any validation fails → fix immediately. Do NOT report DONE.**

## Research Sources (when template is insufficient)

Search these sources **in order**:

### 1. Local project docs
```
docs/card-scripting-guide.md     — Full API reference & patterns
docs/testing-guide.md            — Debugging & validation
template-card/README.md          — Template usage, pattern lookup, effect types
```

### 2. Local constants
```
script/constants.lua                        — Custom archetypes, setcodes, counters
strings.conf                                — Archetype name strings
docs/archetype_setcode_constants.lua        — All official archetype setcodes
```

### 3. Official card scripts (local cache)
```
docs/official-reference/     — Previously fetched official scripts
```
To fetch a new official card script:
```powershell
.\script-test\fetch_official.ps1 <passcode>
```
This saves to `docs/official-reference/c<passcode>.lua` for future reuse.

### 4. EDOPro official wiki (via WebFetch)
```
https://github.com/ProjectIgnis/CardScripts/wiki/1-%E2%80%90-Scripting-Library
https://github.com/ProjectIgnis/CardScripts/wiki/5-%E2%80%90-Filter-Functions
https://github.com/ProjectIgnis/CardScripts/wiki/A-basic-scripting-tutorial
https://github.com/ProjectIgnis/CardScripts/wiki/4-%E2%80%90-Understanding-a-card-script
https://github.com/ProjectIgnis/CardScripts/wiki/3-%E2%80%90-Parameter-naming-convention
https://github.com/ProjectIgnis/CardScripts/wiki/6-%E2%80%90-How-archetypes-and-their-values-work
https://github.com/ProjectIgnis/CardScripts/wiki/7-%E2%80%90-Counters
```

### 5. Scrapi-book (modern API docs)
```
https://projectignis.github.io/scrapi-book/
```

### 6. Raw source files (function signatures & implementations)
```
https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/utility.lua
https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/constant.lua
https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/proc_fusion.lua
https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/proc_synchro.lua
https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/proc_xyz.lua
https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/proc_link.lua
https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/proc_ritual.lua
https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/proc_pendulum.lua
```

### 7. Official card scripts (remote — find similar effects)
```
Search: https://github.com/ProjectIgnis/CardScripts/tree/master/official
Fetch:  https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/official/c{code}.lua
```

### 8. TCG/OCG card passcode lookup
```
https://www.db.yugioh-card.com/yugiohdb/card_search.action
https://yugipedia.com/wiki/
```

## Common Pattern Lookup

| I need to script... | Template | Source |
|---------------------|----------|--------|
| Monster negates + destroys | `template_hand_trap.lua` | `Duel.NegateActivation` in wiki |
| Special Summon from Deck | `template_synchro_monster.lua` (e1) | `Duel.SpecialSummon` in wiki |
| Search/add from Deck to hand | `template_effect_monster.lua` (e1) | `CATEGORY_SEARCH+CATEGORY_TOHAND` |
| Target + destroy | `template_effect_monster.lua` (e2) | `Duel.SelectTarget` + `Duel.Destroy` |
| Continuous ATK/DEF boost | `template_synchro_monster.lua` (e2) | `EFFECT_UPDATE_ATTACK` |
| Fusion Summon (contact/alt) | `template_fusion_monster.lua` | `proc_fusion.lua` raw source |
| Banish from GY | — | `Duel.Remove` in wiki |
| Return to Deck | — | `Duel.SendtoDeck` in wiki |
| Tribute opponent's monster | — | Search "Kaiju"/"Lava Golem" official scripts |
| Equip card | — | `proc_equip.lua` raw source |
| Flip effect | `template_effect_monster.lua` (EVENT_FLIP) | Official Flip monsters |
| Ritual Spell + Monster | — | `proc_ritual.lua` raw source |
| GY trigger (sent to GY) | `template_effect_monster.lua` adapt | See GY pattern below |
| Pendulum (scale + monster) | `template_pendulum_monster.lua` | `proc_pendulum.lua` |

### Common GY trigger pattern
```lua
local e2=Effect.CreateEffect(c)
e2:SetDescription(aux.Stringid(id,1))
e2:SetCategory(...)
e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
e2:SetCode(EVENT_TO_GRAVE)
e2:SetProperty(EFFECT_FLAG_DELAY)
e2:SetCountLimit(1,id+1,EFFECT_COUNT_CODE_OATH)
e2:SetTarget(s.tg_gy)
e2:SetOperation(s.op_gy)
c:RegisterEffect(e2)
```

For field-wide GY triggers (watching other cards go to GY):
```lua
e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
e2:SetCode(EVENT_TO_GRAVE)
e2:SetRange(LOCATION_MZONE)  -- or LOCATION_GRAVE
e2:SetCondition(s.con_gy)
```

## Quick Reference: Effect Types

| Pattern | Type Constant |
|---------|---------------|
| "When/If ... is Summoned" | `EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O` |
| "Once per turn: You can..." (Main Phase) | `EFFECT_TYPE_IGNITION` |
| "(Quick Effect): You can..." | `EFFECT_TYPE_QUICK_O` |
| "When opponent activates..." (respond) | `EFFECT_TYPE_QUICK_O` |
| "All ... gain/lose ..." (always) | `EFFECT_TYPE_FIELD` |
| Spell/Trap card activation | `EFFECT_TYPE_ACTIVATE` |
| Mandatory ("If ...: do X", no "you can") | `EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F` |

## Quick Reference: CDB Type Bitmask

| Card | Value |
|------|-------|
| Effect Monster | `0x21` |
| Fusion Monster | `0x41` |
| Synchro Monster | `0x2021` |
| Xyz Monster | `0x800021` |
| Link Monster | `0x4000021` |
| Pendulum Effect Monster | `0x1000021` |
| Normal Spell | `0x2` |
| Quick-Play Spell | `0x10002` |
| Continuous Spell | `0x20002` |
| Field Spell | `0x80002` |
| Equip Spell | `0x40002` |
| Normal Trap | `0x4` |
| Continuous Trap | `0x20004` |

## Reference Files

| File | Purpose |
|------|---------|
| `AGENTS.md` | Master project rules (authoritative) |
| `template-card/README.md` | Template usage, pattern lookup, effect types reference |
| `references/cdb-schema.md` | CDB SQLite schema, setcode encoding, type/category bitmasks |
| `docs/card-scripting-guide.md` | Full EDOPro Lua API reference |
| `docs/testing-guide.md` | Debugging, validation, common bugs |
| `docs/archetype_setcode_constants.lua` | All official archetype setcodes |
| `docs/official-reference/` | Cached official card scripts |
| `script/constants.lua` | Custom archetypes & counters |
| `strings.conf` | Archetype name strings |
