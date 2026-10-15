# Redridge Recipe Planner

A WoW **Forever (1.60.1)** addon for planning recipes sold for **Merchant's Favor** at the Alliance **Azeroth Commerce Authority** in Redridge Mountains and the Horde **Durotar Supply and Logistics** camp.

**Status:** 0.1.0 beta. Code and initial recipe catalog are published; **in-game testing is still required**.

## Installation

1. Download this repository from GitHub (**Code → Download ZIP**), or clone it.
2. Copy **only** the \`RedridgeRecipePlanner\` folder into your Forever install:

   \`World of Warcraft/_classic_beta_/Interface/AddOns/RedridgeRecipePlanner/\`

3. The final folder must contain \`RedridgeRecipePlanner_Camelot.toc\`, \`Catalog.lua\`, \`Core.lua\`, and \`UI.lua\`.
4. Restart WoW, enable **Redridge Recipe Planner** at the AddOns screen, and type **\`/rrp\`**.

The addon targets interface **16001**, corresponding to the observed Forever 1.60.1 beta. If an update changes the interface, check \`/run print(select(4,GetBuildInfo()))\` before changing the TOC.

## Features

- A static catalog of **309 beta-listed recipes across 7 professions**, with required level, profession skill, Merchant's Favor and reputation. The Alliance and Horde camps sell the same recipes.
- Choose a profession and combine Tank, Melee, Healer, Caster, Hunter, Paladin and Utility role tags. The selected character's class supplies initial defaults; **you decide the filters**. **Show All Builds** bypasses relevance filtering.
- Plan how many times to craft each selected recipe. Merchant's Favor is counted **once per chosen recipe**, not once per craft.
- Each character remembers its build filters, profession and craft quantities.
- With a profession window open, **Scan Profession** (or \`/rrp scan\`) attempts to save the player's learned recipes and exposed reagent schematics. Materials shown without a schematic are explicitly **unknown**, never zero.
- Required reagents are consolidated across chosen crafts and compared with bag quantities. Known intermediate recipes can be expanded into their ingredients (toggle via **Intermediate**).
- **Scan Open Vendor** (or \`/rrp vendor\`) can associate scroll item IDs with catalog recipes or import additional recipe scrolls. Choose the relevant profession before scanning the merchant.
- Trainer comparison defaults to **not verified**. Individual recipes can be *user-marked* as also available from trainers; this is a personal annotation, not an automatic verification. The alchemy comparison *Elixir of Lesser Intellect* versus *Elixir of Wisdom* is shown as a similar-effect alternative, **not** as identical recipes.

## Controls

| Command / control | Action |
| --- | --- |
| \`/rrp\`, \`/redridge\` | Open/close planner |
| \`/rrp scan\` | Scan currently opened profession |
| \`/rrp vendor\` | Scan currently open camp vendor after selecting profession |
| \`/rrp resetview\` | Reset visible filters and pagination |
| \`+\` / \`-\` on a recipe row | Increase/decrease planned craft count |
| Role buttons | Toggle one or more desired builds |
| Show All Builds | View every recipe in the chosen profession |
| Mark trainer match | Toggle user-supplied, unverified trainer note |

## Data provenance and limitations

- Catalog names, basic requirements and prices were transcribed as factual records from [WoW Professions' Forever Merchant's Favor guide](https://www.wow-professions.com/forever/merchants-favor-durotar-supply-azeroth-commerce), consulted **15 October 2026**. This is **beta data** and may change; the vendor scan should be used to double-check local listings.
- **No pre-populated reagent amounts, trainer duplicates or item IDs are invented.** Reagent information is collected from the in-game API when accessible. Scanning a trainer's recipes remotely is not supported.
- The planner currently matches the catalog's **English** recipe names against the profession UI. Non-English game locales may have incomplete matches.
- Material expansion only uses recipes for which the current user has captured a reliable schematic. Unresolved alternative reagent slots remain partial, and ownership counts cover **bags, not bank, guild bank or auction house**.
- There is no verified currency-wallet detection in this first version; Merchant's Favor values represent **purchase requirements**, not a subtraction from the character's balance.
- Recipe item links and live profession state depend on the Forever beta client. In-game compatibility has **not** been independently confirmed.
- The window's combined-material preview shows the five largest entries; more complete browsing is planned.
- A recipe yielding an apparently weaker item may still use cheaper materials. This addon never automatically labels it worthless.

## Development

Code is Lua 5.1 compatible and intentionally has no external libraries.

The GitHub Actions workflow checks syntax and runs catalog invariants and planner math tests. For a local syntax check:

\`\`\`bash
luac5.1 -p RedridgeRecipePlanner/*.lua
lua5.1 tests/catalog.lua
\`\`\`

Do not rename the installed addon folder; its name must match \`RedridgeRecipePlanner.toc\`.

## License

See [LICENSE](LICENSE) in this repository.
