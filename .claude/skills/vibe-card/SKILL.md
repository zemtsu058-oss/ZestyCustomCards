---
name: vibe-card
description: Create fan-made Yu-Gi-Oh! EDOPro custom cards from effect text. Use when user provides card name, type, and effect text, or says "vibe card", "code cho tôi", "làm card", "tạo script", or provides card artwork from docs/queues/. Handles passcode assignment, template selection, Lua script generation, CDB insertion, and queue status tracking. Project-scoped to TTF Custom Cards repository.
---

# Vibe Card — EDOPro Fan-Made Card Pipeline

End-to-end workflow: effect text → Lua script → CDB → queue update.

## Prerequisites

- Working directory: TTF Custom Cards git root
- Read `AGENTS.md` for rules, `template-card/README.md` for pattern lookup
- Read `script/constants.lua` for custom setcodes

## Workflow

### Step 1: Receive Card Info

Extract from user input:
- Card name
- Card type (Monster type/subtype, Spell/Trap + subtype e.g. Quick-Play, Field, Continuous)
- For monsters: Attribute, Level/Rank/Link, ATK/DEF, Race
- Effect text (English or Vietnamese)
- Archetype (from context or queue folder)

If user provides image from `docs/queues/<archetype>/`, read image → extract card text.

### Step 2: Determine Setcode

Check `references/setcode-map.md` for known archetypes.

- **Official archetype** (in the map): use setcode hex directly in script — EDOPro already has it
- **Queue archetype missing from map**: verify the official setcode from ProjectIgnis `archetype_setcode_constants.lua` or the CardScripts archetype wiki, then update `references/setcode-map.md` before assigning a passcode
- **Fan-made archetype** (not in official constants): requires new entry in `script/constants.lua` + `strings.conf`
- **No archetype**: setcode = 0

### Step 3: Assign Passcode

Use passcode convention from AGENTS.md: 9 digits = `{setcode_decimal}{5_digit_seq}`.

Run `scripts/check_passcode.py <decimal_prefix>` to find next free passcode.
Also check result against existing `script/c*.lua` files.

On Windows, if `python` is not in PATH, run skill scripts with:

```powershell
& $env:USERPROFILE\.agents\skills\.venv\Scripts\python.exe .claude\skills\vibe-card\scripts\check_passcode.py <decimal_prefix>
```

If a bundled script fails because it resolves the wrong project root, fix the script in this repository instead of bypassing the skill permanently.

For archetypes without setcode mapping, ask user for passcode.

### Step 4: Select Template

Match card type + effect patterns to template:

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

For multi-effect cards, use template with closest effect count, then add/remove effect blocks.

Quick-Play Spell CDB type is `0x10002`. If a Spell has hand triggers such as "if drawn" or "if added to your hand", keep the Spell card type in CDB but script those effects as hand trigger effects (`EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_*` or `EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_*`) instead of treating the whole card as a normal activation effect.

### Step 5: Generate Script

1. Copy template → `script/c<passcode>.lua`
2. Replace all `<<PLACEHOLDER>>` markers with actual values
3. For each effect, configure:
   - `SetDescription(aux.Stringid(id, N))` — N=0,1,2... per effect
   - `SetCategory` — bitmask from effect actions (search, destroy, summon, etc.)
   - `SetType` — EFFECT_TYPE_ACTIVATE / TRIGGER_O / QUICK_O / IGNITION / FIELD
   - `SetCode` — EVENT_FREE_CHAIN or specific trigger event
   - `SetCountLimit(1, id+N, EFFECT_COUNT_CODE_OATH)` — separate code per effect for "each effect once per turn"
   - Target function with `if chk==0 then return ... end` for legality check
   - Operation function with `c:IsRelateToEffect(e)` checks
4. Keep effect text comments in header

**Critical rules (from AGENTS.md):**
- ALWAYS `local s,id=GetID()` at top
- ALWAYS check `chk==0` (never `chk==1`) in target functions
- ALWAYS `Duel.SetOperationInfo` if effect destroys/searches/special summons
- NEVER copy from existing `script/*.lua` — use templates only

**When template is insufficient**, research patterns (in order):
1. `docs/card-scripting-guide.md` — full API reference
2. Existing project scripts for GY effects, field triggers (e.g. `script/c90177.lua`, `script/c90188.lua`)
3. Official CardScripts wiki via WebFetch
4. Raw source: `utility.lua`, `constant.lua` from ProjectIgnis/CardScripts

**Common GY trigger pattern:**
```lua
local e2=Effect.CreateEffect(c)
e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
e2:SetCode(EVENT_TO_GRAVE)
e2:SetRange(LOCATION_GRAVE)
e2:SetCondition(s.condition_gy)
e2:SetCost(s.cost_gy)
e2:SetTarget(s.target_gy)
e2:SetOperation(s.operation_gy)
c:RegisterEffect(e2)
```

### Step 6: Insert CDB

Use the `.claude/skills/vibe-card/scripts/insert_cdb.py` script.

#### Option A: Command Line Interface (CLI)
You can run the script directly from the terminal. Hexadecimal string values (e.g. `0x21`, `0x4020008`) are automatically parsed:

```powershell
python .claude/skills/vibe-card/scripts/insert_cdb.py `
  --passcode 42600001 `
  --name "Card Name" `
  --type 0x10002 `
  --setcode 426 `
  --desc "Effect text..." `
  --effect-strs "Effect 1 desc" "Effect 2 desc" `
  --category 0x4020008 `
  --overwrite
```

#### Option B: JSON Config File (Recommended for complex text)
To avoid terminal quote-escaping bugs, write a JSON config file and pass it to the script:

```powershell
python .claude/skills/vibe-card/scripts/insert_cdb.py --json-file card_data.json
```

**JSON Schema:**
```json
{
  "passcode": 42600001,
  "name": "Card Name",
  "type": "0x10002",
  "setcode": 426,
  "desc": "Effect text...",
  "effect_strs": ["Effect 1 desc", "Effect 2 desc"],
  "atk": 0,
  "def": 0,
  "level": 0,
  "lscale": 8,
  "rscale": 8,
  "race": "0",
  "attribute": "0",
  "category": "0x4020008",
  "overwrite": true
}
```

- `setcode` is the decimal value of the hex setcode (e.g. 426 for `0x1aa`).
- `type`, `race`, `attribute`, `category` can be hex strings (e.g. `"0x21"`) or integers.
- `lscale` and `rscale` automatically encode Pendulum scales into the database `level` column.
- `overwrite` (or `--overwrite` in CLI) deletes the existing database records before inserting to support card updates.


### Step 7: Update Queue

If card artwork exists in `docs/queues/<archetype>/p_<name>.png`:
- Rename to `d_<name>.png` when script + CDB done
- Use status prefixes: `p_` (pending), `w_` (working), `r_` (review), `d_` (done), `x_` (skipped)

### Step 8: Validate

Run `script-test/validate_scripts.ps1` if available, otherwise manually verify:
- All `<<PLACEHOLDER>>` replaced
- Each effect has `c:RegisterEffect(eN)`
- Filter → Target → Operation function order
- `SetRange` for non-SINGLE effects
- Correct passcode in filename
- Temporary files such as `.tmp_*.py` and generated `__pycache__/` folders are removed

## Reference Files

- `references/setcode-map.md` — Cache of official archetype setcodes used in queue
- `references/cdb-schema.md` — CDB SQLite schema, setcode encoding, type/category bitmasks
- `AGENTS.md` — Master project rules, passcode convention, template selection table
- `template-card/README.md` — Template usage, pattern lookup, critical rules
- `docs/card-scripting-guide.md` — Full EDOPro Lua API reference
