---
name: vibe-card
description: Create fan-made Yu-Gi-Oh! EDOPro custom cards from effect text. Use when user provides card name, type, and effect text, or says "vibe card", "code cho tôi", "làm card", "tạo script", or provides card artwork from docs/queues/. Handles passcode assignment, template selection, Lua script generation, CDB insertion, queue tracking, and full validation. Project-scoped to TTF Custom Cards repository.
---

# Vibe Card — EDOPro Fan-Made Card Pipeline

Effect text → Lua script → CDB → queue update → validate.

**Before starting**: Read `AGENTS.md` (authoritative rules), `template-card/README.md`, `script/constants.lua`.

## Step 1: Receive Card Info

Extract: card name, type/subtype, attribute, level/rank/link, ATK/DEF, race, effect text, archetype.
If user provides image from `docs/queues/<archetype>/`, read image → extract card text.

## Step 2: Determine Setcode

Check `references/setcode-map.md` for archetype → setcode → passcode prefix mapping.

- **Official archetype**: use hex setcode directly (EDOPro built-in, no `constants.lua` entry needed)
- **Fan-made archetype**: must exist in `script/constants.lua` + `strings.conf`
- **New fan-made**: add `SET_XXX = 0xYYY` to `constants.lua`, `!setname 0xYYY Name` to `strings.conf`
- **No archetype**: setcode = 0

For official setcodes not in `setcode-map.md`, look up `docs/archetype_setcode_constants.lua`.

## Step 3: Assign Passcode

Convention: 9 digits = `{setcode_decimal}{5_digit_seq}` (see `references/setcode-map.md`).

```powershell
python .claude\skills\vibe-card\scripts\check_passcode.py <decimal_prefix>
```

## Step 4: Select Template

See `template-card/README.md` for template selection table and placeholder guide.

Quick-Play Spell CDB type = `0x10002`. Spell with hand triggers → keep Spell type in CDB, script hand effects separately.

## Step 5: Generate Script

1. Copy template → `script/c<passcode>.lua`
2. Replace all `<<PLACEHOLDER>>` markers (see `template-card/README.md`)
3. Configure each effect: `SetDescription(aux.Stringid(id,N))`, `SetCategory`, `SetType`, `SetCode`, `SetCountLimit(1,id+N,EFFECT_COUNT_CODE_OATH)`
4. Target function: `if chk==0 then return ... end` + `Duel.SetOperationInfo`
5. Operation function: `c:IsRelateToEffect(e)` check
6. Function naming: `filter_search`, `tg_destroy`, `op_revive` — order: filter → target → operation
7. Keep effect text in header comment

**Full rules**: `AGENTS.md` Critical Rules section.
**API reference**: `docs/card-scripting-guide.md`.

## Step 6: Insert CDB

**ALWAYS set `ot=32`** (Custom format). Use JSON method for complex text:

```powershell
python .claude\skills\vibe-card\scripts\insert_cdb.py --json-file card_data.json
```

JSON schema — see `references/cdb-schema.md` for type/race/attribute/category bitmasks:
```json
{
  "passcode": 42600001, "name": "Card Name", "type": "0x21",
  "setcode": 426, "desc": "Effect text...",
  "effect_strs": ["Effect 1", "Effect 2"],
  "atk": 2500, "def": 2000, "level": 7,
  "race": "0x2000", "attribute": "0x20",
  "category": "0x4020008", "ot": 32, "overwrite": true
}
```

Pendulum: add `"lscale": 8, "rscale": 8` (auto-encodes into level column).

## Step 7: Update Queue

If artwork in `docs/queues/<archetype>/`: rename `p_<name>.png` → `d_<name>.png` when done.
Prefixes: `p_` pending, `w_` working, `r_` review, `d_` done, `x_` skipped.

## Step 8: Validate (MANDATORY)

```powershell
.\script-test\validate_scripts.ps1        # syntax + structure
.\script-test\lint_scripts.ps1             # code style
python .\script-test\manage_db.py check-sync  # DB ↔ script sync
Test-Path script\c<PASSCODE>.lua           # file exists
```

**If any check fails → fix immediately. Do NOT report DONE.**

## Research Sources (when template is insufficient)

Search in order — details in `AGENTS.md` "Khi template không đủ":

1. `docs/card-scripting-guide.md` — API reference
2. `docs/official-reference/` — cached official scripts (fetch new: `.\script-test\fetch_official.ps1 <passcode>`)
3. CardScripts Wiki — `https://github.com/ProjectIgnis/CardScripts/wiki/`
4. Scrapi-book — `https://projectignis.github.io/scrapi-book/`
5. Raw source — `utility.lua`, `constant.lua`, `proc_*.lua` from ProjectIgnis/CardScripts

## Reference Files

| File | Purpose |
|------|---------|
| `AGENTS.md` | Master rules (authoritative) |
| `references/setcode-map.md` | Archetype → setcode → passcode mapping |
| `references/cdb-schema.md` | CDB schema, type/race/attribute/category bitmasks |
| `template-card/README.md` | Template selection & placeholder guide |
| `docs/card-scripting-guide.md` | Full EDOPro Lua API |
| `docs/testing-guide.md` | Debug & common bugs |
