# EDOPro Card Templates — Agent Guide

## How to Use

### 1. Pick the right template

Match the card type to the template file:

| Card Type | Template File |
|-----------|--------------|
| Effect Monster (trigger + ignition) | `template_effect_monster.lua` |
| Normal Spell | `template_normal_spell.lua` |
| Normal Trap | `template_normal_trap.lua` |
| Fusion Monster | `template_fusion_monster.lua` |
| Synchro Monster | `template_synchro_monster.lua` |
| Xyz Monster | `template_xyz_monster.lua` |
| Link Monster | `template_link_monster.lua` |
| Pendulum Monster | `template_pendulum_monster.lua` |
| Field Spell | `template_field_spell.lua` |
| Hand Trap / Quick Effect | `template_hand_trap.lua` |

### 2. Replace placeholders

Every template uses `<<PLACEHOLDER>>` markers. Replace them:

| Placeholder | Replace With |
|------------|-------------|
| `XXXXXXXXX` | Card passcode (9 digits) |
| `<<SETCODE>>` | Archetype hex code (e.g. `0x789`) |
| `<<RANK>>` | Rank number for Xyz |
| `<<MATERIAL_COUNT>>` | Number of Xyz materials |
| `<<LINK_COUNT>>` | Link rating |
| `<<MIN_MATERIAL>>` | Minimum link materials |
| `<<ATK_VALUE>>` | ATK/DEF boost number |
| `<<LP_AMOUNT>>` | LP gain/loss amount |

### 3. Extend the template

Each template has comments marking effect slots (`<< Effect 1 >>`, `<< Effect 2 >>`).

- **Add more effects**: Copy the entire effect block (CreateEffect → RegisterEffect) and change the local variable name (`e2` → `e3`, etc.)
- **Remove unused effects**: Delete the entire effect block + its filter/target/operation functions
- **Change effect type**: Look at the [Effect Types](#effect-types-reference) section below

### 4. Script file naming

```
script/c + passcode + .lua
Example: script/c789000001.lua
```

### 5. After generating

Run validation:
```powershell
.\script-test\validate_scripts.ps1
```

---

## Effect Types Reference

### By activation pattern

| Pattern | Type Constant |
|---------|--------------|
| "When/If ... is Normal/Special Summoned" | `EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O` |
| "Once per turn: You can..." (Main Phase only) | `EFFECT_TYPE_IGNITION` |
| "(Quick Effect): You can..." | `EFFECT_TYPE_QUICK_O` |
| "When your opponent activates..." (respond) | `EFFECT_TYPE_QUICK_O` |
| "All ... gain/lose ..." (always active) | `EFFECT_TYPE_FIELD` |
| "Cannot be destroyed by..." (continuous protection) | `EFFECT_TYPE_FIELD` |
| Spell/Trap card activation | `EFFECT_TYPE_ACTIVATE` |
| Mandatory trigger ("If ...: do X", no "you can") | `EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F` |

### Events for Trigger Effects

| Game Event | Constant |
|-----------|---------|
| Normal Summoned | `EVENT_SUMMON_SUCCESS` |
| Special Summoned | `EVENT_SPSUMMON_SUCCESS` |
| Sent to GY | `EVENT_TO_GRAVE` |
| Destroyed | `EVENT_DESTROYED` |
| Banished | `EVENT_REMOVE` |
| Added to hand | `EVENT_TO_HAND` |
| Draw Phase | `EVENT_PHASE+PHASE_DRAW` |
| Standby Phase | `EVENT_PHASE+PHASE_STANDBY` |
| Main Phase 1 | `EVENT_PHASE+PHASE_MAIN1` |
| Battle Phase | `EVENT_PHASE+PHASE_BATTLE` |
| Main Phase 2 | `EVENT_PHASE+PHASE_MAIN2` |
| End Phase | `EVENT_PHASE+PHASE_END` |
| Destroys by battle | `EVENT_BATTLE_DESTROYING` |
| Destroyed by battle | `EVENT_BATTLE_DESTROYED` |
| Chain link activated | `EVENT_CHAINING` |
| Chain resolves | `EVENT_CHAIN_SOLVED` |
| Chain ends | `EVENT_CHAIN_END` |
| Free chain (response window) | `EVENT_FREE_CHAIN` |

### Categories (for SetCategory)

| Category | Use When |
|---------|---------|
| `CATEGORY_DESTROY` | Card destroys |
| `CATEGORY_TOHAND` | Returns to hand |
| `CATEGORY_TODECK` | Returns to Deck |
| `CATEGORY_REMOVE` | Banishes |
| `CATEGORY_TOGRAVE` | Sends to GY |
| `CATEGORY_SPECIAL_SUMMON` | Special Summons |
| `CATEGORY_SEARCH` | Searches deck |
| `CATEGORY_DRAW` | Draws cards |
| `CATEGORY_RECOVER` | Gains LP |
| `CATEGORY_DAMAGE` | Inflicts damage |
| `CATEGORY_NEGATE` | Negates activation |
| `CATEGORY_DISABLE` | Negates effects |
| `CATEGORY_ATKCHANGE` | Changes ATK |
| `CATEGORY_DEFCHANGE` | Changes DEF |
| `CATEGORY_DICE` | Rolls dice |
| `CATEGORY_COIN` | Tosses coin |
| `CATEGORY_CONTROL` | Takes control |
| `CATEGORY_EQUIP` | Equips card |
| `CATEGORY_RELEASE` | Tributes |
| `CATEGORY_SUMMON` | Normal Summons |
| `CATEGORY_TOKEN` | Summons tokens |

---

## Reference Sources (search order)

When the templates don't cover what you need, search these sources **in order**:

### 1. Local project docs
```
docs/card-scripting-guide.md     — Full API reference & patterns
docs/testing-guide.md            — Debugging & validation
```

### 2. Local constants
```
script/constants.lua             — Custom archetypes, setcodes, counters
strings.conf                     — Archetype name strings
```

### 3. EDOPro official wiki (text search via WebFetch)
```
https://github.com/ProjectIgnis/CardScripts/wiki/1-%E2%80%90-Scripting-Library
    — Complete API: Card.*, Duel.*, Effect.*, Group.* methods
https://github.com/ProjectIgnis/CardScripts/wiki/5-%E2%80%90-Filter-Functions
    — Filter function patterns & usage
https://github.com/ProjectIgnis/CardScripts/wiki/A-basic-scripting-tutorial
    — Beginner tutorial with examples
https://github.com/ProjectIgnis/CardScripts/wiki/4-%E2%80%90-Understanding-a-card-script
    — How to read existing scripts
https://github.com/ProjectIgnis/CardScripts/wiki/3-%E2%80%90-Parameter-naming-convention
    — Parameter naming conventions
https://github.com/ProjectIgnis/CardScripts/wiki/6-%E2%80%90-How-archetypes-and-their-values-work
    — Archetype system & setcodes
https://github.com/ProjectIgnis/CardScripts/wiki/7-%E2%80%90-Counters
    — Counter system
```

### 4. Scrapi-book (new API docs)
```
https://projectignis.github.io/scrapi-book/
    — Modern, searchable API documentation
```

### 5. Raw source files (for function signatures & implementations)
```
https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/utility.lua
    — All aux.* helper functions (Card.IsXxx, Summon procedures, costs)
https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/constant.lua
    — All constants (TYPE_*, RACE_*, ATTRIBUTE_*, LOCATION_*, EVENT_*, EFFECT_*, etc.)
https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/proc_fusion.lua
https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/proc_synchro.lua
https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/proc_xyz.lua
https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/proc_link.lua
https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/proc_ritual.lua
https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/proc_pendulum.lua
    — Summon procedure implementations
```

### 6. Official card scripts (for real examples)
```
Search in: https://github.com/ProjectIgnis/CardScripts/tree/master/official
Pattern: Find a card with similar effect text and study its cXXXXXXXXX.lua
Use WebFetch on: https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/official/c{code}.lua
```

### 7. Search TCG/OCG card passcodes
```
https://www.db.yugioh-card.com/yugiohdb/card_search.action
    — Official Konami database (find passcode to look up script)
https://yugipedia.com/wiki/
    — Community wiki (passcode listed in card infobox)
```

---

## Common Pattern Lookup

| I need to script... | Check template... | Then search source... |
|---------------------|-------------------|----------------------|
| Monster negates + destroys | `template_hand_trap.lua` | official scripts with `EFFECT_TYPE_QUICK_O` + `Duel.NegateActivation` |
| Special Summon from Deck | `template_synchro_monster.lua` (e1) | `Duel.SpecialSummon` in wiki |
| Search/add from Deck to hand | `template_effect_monster.lua` (e1) | `CATEGORY_SEARCH+CATEGORY_TOHAND` in wiki |
| Target + destroy | `template_effect_monster.lua` (e2) | `Duel.SelectTarget` + `Duel.Destroy` in wiki |
| Continuous ATK/DEF boost | `template_synchro_monster.lua` (e2) | `EFFECT_UPDATE_ATTACK` in wiki |
| Fusion Summon (contact/alt) | `template_fusion_monster.lua` | `proc_fusion.lua` raw source |
| Banish from GY | See `LOCATION_GRAVE` filter | `Duel.Remove` in wiki, official scripts |
| Return to Deck | See `CATEGORY_TODECK` | `Duel.SendtoDeck` in wiki |
| Tribute opponent's monster | No template | Search "Kaiju" or "Lava Golem" in official scripts |
| Equip card | No template | `proc_equip.lua` raw source |
| Gemini monster | No template | `proc_gemini.lua` raw source |
| Union monster | No template | `proc_union.lua` raw source |
| Spirit monster | No template | `proc_spirit.lua` raw source |
| Flip effect | `template_effect_monster.lua` (use EVENT_FLIP) | Official Flip monsters |
| Ritual Spell + Ritual Monster | No template | `proc_ritual.lua` raw source |

---

## Critical Rules (MUST FOLLOW)

1. **ALWAYS** start with `local s,id=GetID()`
2. **ALWAYS** have `function s.initial_effect(c) ... end`
3. **ALWAYS** use `aux.Stringid(id,N)` for SetDescription (use incrementing N: 0,1,2...)
4. **ALWAYS** check `if chk==0 then return ... end` in target functions
5. **ALWAYS** call `Duel.SetOperationInfo` in target if effect destroys/searches/SS
6. **ALWAYS** check `c:IsRelateToEffect(e)` at the start of operation functions that use `c:IsFaceup()` or `c:IsLocation()`
7. **ALWAYS** check `Duel.GetLocationCount(tp,LOCATION_MZONE)>0` before Special Summon
8. **NEVER** use `chk==1` — always `chk==0` check first
9. **NEVER** forget `e1:SetRange(LOCATION_xxx)` for non-SINGLE effects
10. **NEVER** omit `c:RegisterEffect(e1)` after creating an effect
