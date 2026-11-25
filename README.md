# CompareDPS

CompareDPS is a **WoW Forever** addon that scores items from their supported
stats and compares them with equipped gear. Scores are relative gear points,
not simulated DPS or a guarantee that an item is an upgrade.

## Install

Run `Install-CompareDPS.ps1` from this folder on the computer with WoW Forever
installed. By default it copies the addon to
`D:\World of Warcraft\_forever_\Interface\AddOns\CompareDPS`. To use another
AddOns folder:

```powershell
.\Install-CompareDPS.ps1 -AddOnsPath 'X:\World of Warcraft\_forever_\Interface\AddOns'
```

Enable the addon or use `/reload` if the game is already running.

## Use

Open the CompareDPS window with **`/compare`** (or `/comparedps`) or the
**CompareDPS minimap button**. The same options are available under
**Options > AddOns > CompareDPS**. Choose a specialization from the dropdown
to see its current stat weights. Both views update immediately
when the selection changes, including changes made with the `spec` command.
All class profiles are supported; only your class's specializations are listed.
The choice is
saved per character; CompareDPS does not detect talents or select a profile
automatically. The standalone window uses classic WoW dialog artwork and a
framed specialization icon. Both views show your class and built-in Classic
spell/talent artwork for each specialization, including icons in the selector.
No external artwork or UI libraries are downloaded. Your class determines which
profiles are available. Armor and weapon types your class cannot use are not
scored. You can also use:

```text
/comparedps spec <name>
/comparedps list
```

Item tooltips show a score. Bag, vendor, buyback, profession, quest, loot,
mail, trade, guild bank, auction house and item-link tooltips also show the
difference from equipped gear; positive is higher, negative is lower.
Rings and trinkets are compared against each equipped slot. Weapon scores
account for weapon DPS and speed where the selected profile has weights.

Recipe item tooltips attempt to compare the crafted equipment, including when
the profession is not trained. This is experimental: it relies on the Forever
client exposing the crafted item in the recipe's nested tooltip data. If that
data is unavailable, the tooltip reports that the crafted item is unavailable.
Recipes for non-equipment do not receive a gear score.

Profession trainer tooltips also attempt to score the equipment a taught recipe
creates and compare it with equipped gear. This uses the trainer's nested item
data, or the recipe spell's nested item data when available; it does not require
learning the recipe first. Trainer services without an exposed crafted item,
including ordinary enchants and profession ranks, do not receive a score.
The Greater Mystic Wand trainer entry has been confirmed in WoW Forever to
show both the combined score and equipped-gear comparison. Other trainer
entries still depend on the item data exposed by the client.

## Weights and limits

Each spec starts with approximate default stat weights. A stat with no weight contributes
zero; unlisted stats in the options view have weight zero. Values are relative
gear points per stat unit, with percentage stats weighted per 1 percentage
point and weapon speed per second. Negative weights are shown as-is.
Displayed weights use one decimal place in both modes, including the `list`
command. Edit fields retain the full saved value so saving unrelated edits
does not round existing custom weights; calculations also retain full precision.
In both options views, stats are grouped consistently across all specs: primary
attributes, hit/crit/haste, attack power, spell/healing power and spell schools,
weapon stats, defenses, then health/mana and regeneration. Read down the left
column, then the right; related groups never split across columns, and weapon
DPS stays beside its matching speed.
For healing profiles, the spell power weight applies to spell damage and the
healing power weight applies separately to healing. A combined damage-and-healing
bonus contributes to both; a split bonus contributes its respective amounts.
The score only reflects stats CompareDPS can read. By default, spell penetration
is weighted at **0.1 per point** for Mage, Warlock, Shadow Priest, Balance
Druid and Elemental Shaman profiles; it is **0.05 per point** for Hunter and
Enhancement Shaman profiles. It has no weight on other specs. Thus, 4 spell
penetration adds 0.4 or 0.2 points, respectively.

Click **Edit** to change the weights already listed for the selected spec,
then **Save** to apply them to gear scoring and both options views. Zero,
decimal and negative values are allowed; invalid or empty fields must be
corrected before saving. Custom weights are saved per character and spec.
**Cancel**, Escape in a weight field, closing the editing view, or switching
spec discards unsaved changes. **Reset to Default** immediately restores the
selected spec's built-in weights and discards any edits for it, without
affecting custom weights saved for other specs.

### Dynamic weights (experimental)

The **Dynamic weights** checkbox is available in both the minimap-button window
and **Options > AddOns > CompareDPS**. It is off by default and saved per
character. Both views stay in sync. While a view is open, its numbers refresh
every half-second; each item tooltip reads a fresh stat snapshot.

Dynamic mode uses the character's current hit, crit, equipped weapon skill
(separate hands when dual-wielding), and, for tanks, defense, avoidance and
block chances. Current effective armor is also read. It assumes a fixed
**level-63 raid boss**, attacking from behind for DPS and from the front for
tanks. Feral attack skill uses level x 5 rather than the equipped weapon's
trained skill. Other weapon skills use the equipped weapon's skill line and its
current modifier; an empty main hand uses the unarmed skill.

**These are Classic fallback mechanics, not confirmed Forever formulas.**
Forever-specific formulas were not available when this experimental model
was implemented. Historical mechanics are reference material only:
[weapon skill](https://warcraft.wiki.gg/wiki/Weapon_skill),
[defense](https://warcraft.wiki.gg/wiki/Defense), and
[glancing blows](https://warcraft.wiki.gg/wiki/Glancing_blow).
Those pages also discuss later expansions; this model deliberately uses the
pre-expansion conventions below, not their current-retail formulas.

| Mechanic | Implemented fallback |
| --- | --- |
| Spell hit | 16% bonus hit at level 60, leaving the Classic 1% unavoidable miss chance. Healing does not need hit. |
| Physical hit | At 300 weapon skill, 9% special/single-wield hit cap; at 305, 6%. The first 1% bonus hit is ignored when the boss defense exceeds weapon skill by more than 10. |
| Dual-wield hit | White swings retain hit value after specials are capped; the assumed white cap is the special cap + 19 percentage points. |
| Physical crit | The white-attack table accounts for misses, dodge, 40% boss glancing blows at trained level-60 skill, frontal parry for tanks, and assumed 4.8-point boss crit suppression at level 60. Crit retains value for specials after the white soft cap. More hit can also open space for white crits. |
| Spell crit | Capped at 100% in the chosen primary school's character-sheet chance. |
| Defense | 440 skill removes normal boss melee crits. This is a soft cap: defense still improves miss/dodge/parry/block until their table is saturated. |
| Block/avoidance | Boss-adjusted miss + dodge + parry + block saturates at 100%: equivalent to the usual 102.4% equal-level sheet coverage at level 60. Block chance then has no additional table value; full avoidance can still replace blocked hits. Before saturation, pushing crushing blows off the table has extra value. The assumed base crush chance is 15% with trained level-60 defense; bonus defense does not directly reduce it. This is separate from the 440 defense threshold. |
| Armor | 75% physical mitigation, at 17,265 effective armor against level 63. |
| Spell penetration | Zero value: this generic boss model assumes no reducible magical resistance. It cannot remove level-based resistance. |

Caps do not generate accurate DPS weights by themselves. This mode adjusts the
built-in reference weights, using an explicit **50% white / 50% special**
approximation for melee, with equal main/off-hand white shares when dual-wielding.
It is not a measured rotation breakdown. Full-avoidance outcomes use a common
value; defense also receives a crit-prevention premium until crits are removed.
These are scoring choices, not simulated damage or survival probabilities.
The model is primarily intended for level-60 characters; lower-level estimates
against the same level-63 boss are particularly approximate.

Cap-controlled rows (**Hit, Crit, Defense, Dodge, Parry, Block, Armor and Spell
penetration**, where present in the profile) are grey and marked **(locked)**.
They use built-in reference weights and ignore saved custom overrides in
Dynamic mode. **Edit** and **Reset to Default** remain available for the other
stats only; neither action changes the saved static values of locked rows.
Unsupported attempts to save locked weights are rejected.

For example, set custom Hit and Spell Power in static mode, save, then enable
Dynamic: Hit becomes automatic, but Spell Power retains your custom value.
Change Spell Power while Dynamic is enabled, then disable Dynamic: your
original custom Hit returns, together with the latest Spell Power value.
Changing modes discards unsaved edits; saved static cap overrides are never
replaced with the calculated dynamic numbers.

Displayed dynamic weights estimate the value of the *next small increase*.
Dynamic weights and summary percentages display one decimal place; calculations
and saved custom values retain their full precision.
Dynamic tooltip points represent adding that item's stats to the current
snapshot; the parenthesized comparison instead removes the old item(s) and
adds the candidate. A replacement that loses required hit therefore scores
negatively even if the currently displayed hit weight is zero. Rings and
trinkets are evaluated independently against each occupied slot.

Important limitations:

- Active buffs are included, including temporary block/avoidance. A covered
  attack table is only a snapshot, not guaranteed crushing immunity after a
  charge is consumed or a buff expires.
- School-specific talent hit, spell-specific crit rules, queued attacks,
  special attack exceptions, boss mechanics, target armor/resistances and
  actual rotation shares are not inferred. Mixed-school specs use the profile's
  primary school. Hybrid spell/melee damage is not modeled separately.
- Uncapped stats keep their static/custom weights. Their indirect effects on
  capped stats (for example Agility granting crit/dodge), and form/talent
  multipliers on replacement armor, are not projected.
- Added weapon-skill bonuses on items are not modeled; recognized skill-bonus
  tooltips report this explicitly. Changing weapon type, filling an empty
  weapon hand, or changing hand configuration requires equipping first so the
  model can read the correct live skill/caps. It does not guess another
  weapon type's skill.
- Required APIs and values are checked. Missing/restricted data produces
  **Dynamic weights unavailable** or a specific item-comparison warning, not
  a silent static fallback. Rating-only items require a live rating conversion;
  the old fixed conversions below are used only in static mode. Defense-rating
  items require a tooltip giving actual defense skill.

### Static scoring limitations

Spell penetration reduces a target's existing magical resistance; it is not
spell hit and does not remove resistance from a target's higher level. Its
value is situational, mainly against resistance in PvP or specific encounters,
so the fixed weights are only a rough gear-scoring compromise.

CompareDPS is not a combat simulator. It may omit procs, on-use effects, set
bonuses, enchants, caps, unsupported stats and tooltip formats. English
classic-style item text is parsed on a best-effort basis, and item data may
need to load before it can be scored. Verify upgrades in the game.

Percentage bonuses are recognized only for supported tooltip wording about the
player's own stats; effects such as resistance to Sleep are not hit bonuses.
The hit and critical weights use the profile's primary combat type: ranged for
Hunters, melee for Warriors, Rogues, Enhancement Shamans, Protection and
Retribution Paladins, and Feral Druids, and spells for the remaining profiles.
Bonuses limited to another type contribute zero, even for hybrid specs. Generic
bonuses apply to the primary type. When both generic and type-specific API
ratings are reported, the generic value takes precedence to avoid double counting.
When only an API rating is available, the current estimates use 10 hit, 14
critical strike, 12 dodge or 15 parry rating per percentage point. These fixed
conversions are approximations, not verified level-dependent Forever values.
Haste and block rating are not converted to percentages. Defense skill rating
is currently scored as defense skill.
