# CompareDPS

An experimental **WoW Forever** addon that scores items using stat weights and
compares them with equipped gear. Presets cover the nine Forever classes,
including separate Feral DPS and tank profiles. Each character has its own
selection. The additional class profiles have not yet been tested in-game.

## Install

On the desktop, pull this repository and run from the `CompareDPS` folder:

```powershell
git pull --ff-only origin main
.\Install-CompareDPS.ps1
```

The installer copies the addon files to
`D:\World of Warcraft\_forever_\Interface\AddOns\CompareDPS` by default.
It overwrites those files in an existing installation without creating a
backup. For a different AddOns directory, use:

```powershell
.\Install-CompareDPS.ps1 -AddOnsPath 'X:\World of Warcraft\_forever_\Interface\AddOns'
```

If PowerShell blocks scripts, use
`powershell -NoProfile -ExecutionPolicy Bypass -File .\Install-CompareDPS.ps1`.
Enable CompareDPS at character selection. If it is already enabled and the
game is running, use `/reload` to load the updated files.

## Specialization presets

Your class is detected automatically. Click the **CompareDPS minimap icon**
to open its options, then choose your spec from the **Specialization** dropdown.
The selection is saved per character and takes effect on the next tooltip.
The addon does not inspect talents or automatically detect your specialization.
If your class has no profiles, the dropdown reports that none are available.

CompareDPS hides scores for armor and weapon types the class cannot learn, and
for items restricted to other classes or races when those lists are available.
Level, learned proficiency, profession and reputation requirements do not
prevent a score. Other item-specific restrictions may not be detected.

The following commands are also available (for example):

```text
/comparedps spec affliction
/comparedps spec demonology
/comparedps spec destruction
/comparedps list
```

Each item tooltip shows its own score beside its slot name. Compare it with
the score shown on the equipped item's comparison tooltip. Higher means more
weighted value **among the stats counted**.
These are relative points, not actual DPS. The first time you use the addon,
select a spec; no preset is automatically chosen.

When hovering over an item in your bags, quest rewards or the Dungeon Journal,
or opening a linked item, the number in parentheses is its score difference
from the equipped item. Positive means a higher score,
negative a lower score. Rings and trinkets show differences for both equipped
slots; an empty slot has a score of zero. Equipped-item tooltips do not show
a difference, including the equipped-item tooltip beside a linked item.
Other tooltip sources display the item score without a difference.
Gains are green, losses are red, and equal scores and equipped items are white.
For rings and trinkets, each slot's difference is colored independently.

The approximate weights come from [ForeverUpgrade's Warlock scales](https://github.com/DemiAutomatic/ForeverUpgrade/blob/main/Scales.lua).
The same source provides the scales for all other classes. They are general
spec-level starting points, not verified meta builds, character-specific
simulations, or exact DPS. Stats without a weight in the selected profile
contribute zero to the score.

| Stat | Affliction | Demonology | Destruction |
|---|---:|---:|---:|
| Spell power | 1 | 1 | 1 |
| Shadow damage | 0.95 | 0.8 | 0.65 |
| Fire damage | not specified | 0.35 | 0.9 |
| Intellect | 0.4 | 0.4 | 0.35 |
| Stamina | 0.35 | 0.5 | 0.2 |
| Spirit | 0.25 | 0.15 | 0.1 |
| Spell hit per 1% | 13 | 12 | 13 |
| Spell crit per 1% | 6 | 8 | 11 |
| Mana per 5 seconds | 1.3 | 1 | 0.8 |

These are relative gear-value weights: stamina and mana regeneration may
include survivability or resource value, not just damage. In particular,
fixed hit weights do not account for the hit cap. When the client returns
Forever points instead of percentages, the source's approximate conversions
are used: 10 hit, 14 crit, 12 dodge or 15 parry points per 1%. Its source
notes that the character-sheet formula is unpublished. Defense points use the
source's one-point-per-defense convention. Block chance in percentage form
and block value are weighted; block rating is not converted because the source
does not document its conversion. Haste and block ratings contribute zero.

## How it works and limitations

Scores are the sum of supported stat amounts multiplied by their weights.
Each ring and trinket has its own score. A bagged two-handed weapon is compared
against the combined main-hand and off-hand scores. A bagged off-hand item
cannot be compared when a two-handed weapon is equipped without choosing a
replacement main-hand weapon.

The source weights weapon DPS and speed according to the weapon slot; speed is
measured relative to 2.0 seconds. For classes that can dual wield, a generic
one-handed item displays separate main-hand and off-hand scores and comparisons.
Equipped weapon tooltips use the equipped hand when it can be identified.
English tooltip text supplies weapon DPS and speed; when a required value
cannot be read, the score is unavailable.

This is **not a combat simulation**. All results are explicitly partial: item
procs and on-use effects, set bonuses, weapon effects, gem/socket changes,
enchantments, combat interactions, caps, usability restrictions and unsupported
stats or tooltip formats may be omitted. An apparently positive or zero result
does not guarantee an upgrade. English classic-style spell-damage and
spell-percentage Equip lines and armor are recognized on a best-effort basis in addition
to the client item-stat API; other locales and text formats can miss stats.
Percentage values are preferred over point values when both appear for the
same stat. Item data can be unavailable until cached; hover again.

The tooltip hook and item APIs are used by existing Forever addons, but this
implementation needs real-client testing. Start by comparing simple items
with known stats, then test rings, enchanted items and weapons. Share tooltip
output and errors before relying on the result.

## Adding presets

`Profiles.lua` contains profiles indexed by the player's class token and a
lowercase profile name. Add a label and weights using the stat keys in
`Core.lua`. `hit`, `crit` and `haste` are per percentage point; `hitrating`,
`critrating` and `hasterating` are per rating point; `mp5` is per mana
regenerated per 5 seconds; other weights are per stat point.
Unspecified weights count as zero. Document each source and its units.
Presets are manually selected with `/comparedps spec <name>`.
