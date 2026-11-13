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
automatically. Your class determines which profiles are available. Armor and
weapon types your class cannot use are not scored. You can also use:

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

## Weights and limits

Each spec starts with approximate default stat weights. A stat with no weight contributes
zero; unlisted stats in the options view have weight zero. Values are relative
gear points per stat unit, with percentage stats weighted per 1 percentage
point and weapon speed per second. Negative weights are shown as-is.
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
