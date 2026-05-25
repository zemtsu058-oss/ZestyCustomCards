# TTF Custom Cards

Custom card project by Zesty and friends for [EDOPro](https://github.com/ProjectIgnis/edopro) (Yu-Gi-Oh! auto duel simulator).

Repository chứa Lua script, SQLite database, artwork của các custom card.

---

## Project Structure

```
/
├── script/                       # Lua card scripts (57 cards)
│   └── constants.lua             # Custom archetypes, setcodes, counters
├── pics/                         # Card artwork (.png/.jpg, named by passcode)
│   └── field/                    # Field spell background artwork
├── template-card/                # Reusable script templates (10 types)
│   ├── README.md                 # Template usage guide + pattern lookup
│   ├── template_effect_monster.lua
│   ├── template_normal_spell.lua
│   ├── template_normal_trap.lua
│   ├── template_fusion_monster.lua
│   ├── template_synchro_monster.lua
│   ├── template_xyz_monster.lua
│   ├── template_link_monster.lua
│   ├── template_pendulum_monster.lua
│   ├── template_field_spell.lua
│   └── template_hand_trap.lua
├── docs/                         # Internal documentation
│   ├── card-scripting-guide.md   # EDOPro Lua API reference & patterns
│   └── testing-guide.md          # Validation, debugging, common bugs
├── scripts/                      # Automation tools
│   ├── validate_scripts.ps1      # Syntax + structure validation
│   └── lint_scripts.ps1          # Lua linter (luacheck)
├── custom_cards_zesty.cdb        # Card database (SQLite, edit with DataEditorX)
├── strings.conf                  # Archetype/counter display name strings
├── AGENTS.md                     # Agent guide (workflow, rules, template selection)
├── LICENSE                       # MIT
└── README.md                     # This file
```

## Card Statistics

| Type | Count |
|------|-------|
| Effect Monster | 15 |
| Fusion Monster | 9 |
| Synchro Monster | 2 |
| Xyz Monster | 1 |
| Link Monster | 7 |
| Spell Card | 22 |
| Trap Card | 1 |
| **Total** | **57** |

**Extra Deck:** 19 | **Main Deck:** 38

## Custom Archetypes

| Hex | Setcode | Name |
|-----|---------|------|
| `0x789` | `SET_TTF` | TTF |
| `0x780` | `SET_ATERMIS` | Atermis |
| `0x781` | `SET_CAT` | Cat |
| `0x927` | `SET_DESIRE_HERO` | Desire HERO |
| `0x315` | `SET_BUCKLE` | Buckle |
| `0x1291` | `SET_HYPERDIMENSION` | Hyperdimension |
| `0x177` | `COUNTER_MANA` | Mana Counter |

Also includes support cards for official archetypes: Witchcrafter (`0x128`), Labrynth (`0x17f`).

## Quick Start

### Create a new card

```powershell
# 1. Copy template
Copy-Item template-card\template_effect_monster.lua script\c<PASSCODE>.lua

# 2. Replace all <<PLACEHOLDER>> markers with actual values

# 3. Validate
.\scripts\validate_scripts.ps1

# 4. Add to database via DataEditorX (custom_cards_zesty.cdb)
```

### Validate existing scripts

```powershell
.\scripts\validate_scripts.ps1          # Validate all scripts
.\scripts\lint_scripts.ps1              # Run linter
```

## EDOPro Documentation Resources

### Internal Docs
- `docs/card-scripting-guide.md` — Full Lua API reference, effect types, filter functions, summon procedures, cost patterns, common pitfalls
- `docs/testing-guide.md` — Validation workflow, EDOPro test deck setup, debug console commands, common bug patterns
- `template-card/README.md` — Template selection guide, placeholder reference, pattern lookup table, 10 critical scripting rules
- `AGENTS.md` — Master workflow guide for card creation and bug fixing

### EDOPro / ProjectIgnis Sources

| Resource | URL |
|----------|-----|
| EDOPro GitHub | https://github.com/ProjectIgnis/edopro |
| CardScripts Wiki | https://github.com/ProjectIgnis/CardScripts/wiki |
| Scripting Library (API) | https://github.com/ProjectIgnis/CardScripts/wiki/1-%E2%80%90-Scripting-Library |
| Understanding a Script | https://github.com/ProjectIgnis/CardScripts/wiki/4-%E2%80%90-Understanding-a-card-script |
| Filter Functions | https://github.com/ProjectIgnis/CardScripts/wiki/5-%E2%80%90-Filter-Functions |
| Archetypes & Setcodes | https://github.com/ProjectIgnis/CardScripts/wiki/6-%E2%80%90-How-archetypes-and-their-values-work |
| `utility.lua` (all `aux.*` helpers) | https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/utility.lua |
| `constant.lua` (all constants) | https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/constant.lua |
| Summon procedures | `proc_fusion.lua`, `proc_synchro.lua`, `proc_xyz.lua`, `proc_link.lua`, `proc_ritual.lua`, `proc_pendulum.lua` (under same repo) |
| Official card scripts | https://github.com/ProjectIgnis/CardScripts/tree/master/official |
| Konami DB (passcode lookup) | https://www.db.yugioh-card.com/yugiohdb/card_search.action |
| Yugipedia (card info) | https://yugipedia.com/wiki/ |

### Tools
- **DataEditorX** — GUI editor for `custom_cards_zesty.cdb` (included with EDOPro)
- **Lua 5.3+** — Required for `validate_scripts.ps1` (optional, falls back to basic checks)

## License

MIT — see [LICENSE](./LICENSE)
