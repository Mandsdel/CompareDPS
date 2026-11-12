# CompareDPS

An experimental **WoW Forever** addon that adds a weighted DPS difference to
item tooltips. It is intended initially for a Demonology Warlock, but does not
detect talents or provide built-in weights. Each character has its own weights.
The Forever client has not yet been tested with this addon.

## Install

Place the `CompareDPS` folder containing `CompareDPS.toc` and `Core.lua` in
your Forever `Interface\AddOns` folder, or use the shared
`wow-forever-addon-development` desktop installer. Restart the game or reload
the UI, then enable CompareDPS.

## Configure

Enter **DPS gained per unit of each stat** for your build:

```text
/comparedps set spellpower 0.5
/comparedps set int 0.1
/comparedps list
/comparedps clear int
```

The numbers above are **examples only**, not recommended weights. Enter `0`
explicitly for a stat you want to ignore. If a stat changes and has no weight,
the addon reports the missing weight rather than inventing a DPS result.

Supported names are `spellpower`, `shadow`, `fire`, `int`, `spirit`, `stamina`,
`hit`, `crit`, `haste`, `hitrating`, `critrating`, and `hasterating`. The first
three percentage stats use DPS **per 1 percentage point**, while the rating
stats use DPS **per rating point**. The others use DPS per point. Weights can
be negative and are saved per character.

If a source reports stat weights relative to spell power, rather than actual
DPS per unit, multiply each relative value by the DPS gained from one spell
power. For example, relative intellect weight 0.2 times 0.5 DPS per spell
power gives 0.1 DPS per intellect. Use compatible units, and redo weights when
your gear, talents, target or fight assumptions change.

## How it works and limitations

For each applicable equipped slot, the addon computes the item's supported stat
changes multiplied by the supplied weights. Rings and trinkets are compared
against both slots. A two-handed item is compared against both the main hand
and off hand together. An off-hand item cannot be compared against a currently
equipped two-hander without choosing a replacement main hand.

This is **not a combat simulation**. All results are explicitly partial: item
procs and on-use effects, set bonuses, weapon damage, gem/socket changes,
enchantments, combat interactions, caps, usability restrictions and unsupported
stats or tooltip formats may be omitted. An apparently positive or zero result
does not guarantee an upgrade. English classic-style spell-damage and
spell-percentage Equip lines are recognized on a best-effort basis in addition
to the client item-stat API; other locales and text formats can miss stats.
Percentage values are preferred over rating values when both appear for the
same stat. Item data can be unavailable until cached; hover again.

No estimation is shown if required APIs or item data are unavailable. API
availability, tooltip formatting, the item-stat units and comparison behavior
must be checked in the Forever client.

## Investigation and next steps

- Forever uses interface `16001` and has its own rebalanced classes; weights
  from other WoW versions should not be assumed valid.
- [Xn's Warlock Sim](https://github.com/XNWLK/WarlockSIMAddon) describes an
  in-game Forever Warlock simulator and reports character-specific stat
  weights. Its website [documents the mechanics and assumptions](https://github.com/XNWLK/WarlockSIM/blob/main/MECHANICS.md).
  It is an optional source of estimates, not a dependency, and its results
  can differ from the game. CompareDPS does not reuse its code.
- The tooltip hook and item-stat APIs are used by existing Forever addons,
  but this implementation needs real-client testing. Start by configuring
  known weights and comparing a pair of simple items with known stats; then
  test rings, enchanted items and weapons. Share tooltip output and errors
  before relying on the result.
