local addon = {}
assert(loadfile("DynamicWeights.lua"))("CompareDPS", addon)

local function close(actual, expected)
    assert(math.abs(actual - expected) < 0.00001, string.format("expected %.6f, got %.6f", expected, actual))
end
local function state(overrides)
    local result = { domain = "Melee", level = 60, hit = 0, crit = 20,
        skill = 300, offSkill = 300, armor = 0, defense = 300,
        dodge = 10, parry = 10, block = 5, canParry = true, canBlock = true }
    for key, value in pairs(overrides or {}) do result[key] = value end
    return result
end
local base = { hit = 16, crit = 12, defense = 1.3, dodge = 12, parry = 10,
    block = 5, armor = 0.008, spellpen = 0.1, str = 1 }

-- Given trained skill variants, the Classic fallback changes both physical hit caps.
for _, case in ipairs({ {300, 9, 28}, {304, 8.2, 27.2}, {305, 6, 25},
    {308, 5.7, 24.7}, {315, 5, 24}, {320, 4.8, 23.8} }) do
    local caps = addon.dynamicCaps(state({ skill = case[1], dual = true }))
    close(caps.hit, case[2])
    close(caps.whiteHit, case[3])
end

-- Given hit around soft/hard caps, only the affected attack channel loses value.
for _, case in ipairs({ {8, true, 16}, {9, true, 8}, {27.99, true, 8},
    {28, true, 0}, {8, false, 16}, {9, false, 0}, {0, true, 0} }) do
    local weights = addon.makeDynamicWeights(base, state({ hit = case[1], dual = case[2] }))
    close(weights.hit, case[3])
end
local mixed = addon.makeDynamicWeights(base, state({ hit = 25, dual = true, offSkill = 305 }))
close(mixed.hit, 4)
local spell = state({ domain = "Spell", hit = 16, crit = 99 })
local weights = addon.makeDynamicWeights(base, spell)
close(weights.hit, 0)
close(weights.crit, 12)
spell.crit = 100
close(addon.makeDynamicWeights(base, spell).crit, 0)
close(addon.dynamicCaps(state({ domain = "Spell", level = 59 })).hit, 27)
spell.healer, spell.hit = true, 0
close(addon.makeDynamicWeights(base, spell).hit, 0)

-- Given a saturated white table, specials retain crit value and hit opens crit space.
weights = addon.makeDynamicWeights(base, state({ hit = 9, dual = true, crit = 60 }))
close(weights.crit, 6)
close(weights.hit, 14)
close(addon.makeDynamicWeights(base, state({ hit = 28, dual = true, crit = 105 })).crit, 0)
weights = addon.makeDynamicWeights(base, state({ domain = "Ranged", hit = 9, crit = 40 }))
close(weights.hit, 0)
close(weights.crit, 12)

-- Given replacements crossing caps, value is integrated over the actual stat change.
local context = addon.makeDynamicWeights(base, state({ hit = 9, dual = false })).dynamicContext
close(addon.dynamicScore(context, { hit = 2 }, 32), 0)
close(addon.dynamicScore(context, { hit = -2 }, -32), -32)
context = addon.makeDynamicWeights(base, state({ hit = 8, dual = false })).dynamicContext
close(addon.dynamicScore(context, { hit = 2 }, 32), 16)
context = addon.makeDynamicWeights(base, state({ domain = "Spell", hit = 15.5 })).dynamicContext
close(addon.dynamicScore(context, { hit = 1, str = 4 }, 20), 12)
close(addon.dynamicScore(context, { spellpen = 10 }, 1), 1)
close(addon.dynamicScore(context, { spellpen = -10 }, -1), -1)
close(addon.makeDynamicWeights(base, spell).spellpen, 0.1)
close(base.hit, 16)

-- Given defense crit immunity, defense retains avoidance value rather than hard-capping.
local before = addon.makeDynamicWeights(base, state({ tank = true, defense = 439 }))
local after = addon.makeDynamicWeights(base, state({ tank = true, defense = 440 }))
assert(before.defense > after.defense and after.defense > 0)
close(before.defense, 2.29)
assert(addon.dynamicSummary(after):find("crush vulnerable", 1, true))
local crushBoundary = state({ tank = true, defense = 440, dodge = 30, parry = 30, block = 16.79 })
close(addon.makeDynamicWeights(base, crushBoundary).block, 5)
crushBoundary.block = 16.8
close(addon.makeDynamicWeights(base, crushBoundary).block, 11)
local covered = state({ tank = true, defense = 300, dodge = 30, parry = 30, block = 37.4 })
weights = addon.makeDynamicWeights(base, covered)
close(weights.block, 0)
assert(weights.dodge > 0 and weights.parry > 0 and weights.defense > 0)
assert(addon.dynamicSummary(weights):find("crush table covered", 1, true))
covered.block = 37.39
context = addon.makeDynamicWeights(base, covered).dynamicContext
-- The final 0.01% coverage also pushes the final crit chance off the table.
close(addon.dynamicScore(context, { block = 1 }, 5), 0.2125)
covered.canBlock, covered.canParry = false, false
weights = addon.makeDynamicWeights(base, covered)
close(weights.block, 0)
close(weights.parry, 0)
assert(weights.defense > 0)
weights = addon.makeDynamicWeights(base, state({ tank = true, defense = 440, dodge = 100, parry = 100, block = 100 }))
close(weights.defense, 0)
close(weights.dodge, 0)
close(weights.parry, 0)
close(weights.block, 0)
for _, armor in ipairs({ 17265, 20000 }) do
    close(addon.makeDynamicWeights(base, state({ armor = armor })).armor, 0)
end
context = addon.makeDynamicWeights(base, state({ armor = 17260 })).dynamicContext
close(addon.dynamicScore(context, { armor = 10 }, 0.08), 0.04)

-- Given absent or restricted APIs, dynamic mode reports an explicit reason.
local snapshot, reason = addon.readDynamicState("Spell", "affliction")
assert(not snapshot and reason:find("UnitLevel", 1, true))
function UnitLevel() return 60 end
function GetSpellHitModifier() return 15 end
function GetHitModifier() return 6 end
function GetSpellCritChance() return 20 end
function GetCritChance() return 25 end
function GetRangedCritChance() return 30 end
function UnitArmor() return 1000, 2000 end
Enum = { ItemClass = { Weapon = 2 }, ItemWeaponSubclass = { Sword1H = 7, Axe1H = 0, Bows = 2 } }
local equipped = { [16] = 100, [17] = 101, [18] = 102 }
function GetInventoryItemID(_, slot) return equipped[slot] end
C_Item = { GetItemInfoInstant = function(id)
    local subclasses = { [100] = 7, [101] = 0, [102] = 2 }
    return id, nil, nil, nil, nil, 2, subclasses[id]
end }
C_SkillInfo = { GetSkillLineInfoByID = function(id)
    local modifiers = { [43] = 5, [44] = 8, [45] = 5, [162] = 0 }
    if modifiers[id] then return { rank = 300, modifier = modifiers[id] } end
end }
function UnitAttackSpeed() return 2, 1.5 end
function UnitDefenseSkill() return 300, 140 end
function GetDodgeChance() return 10 end
function GetParryChance() return 10 end
function GetBlockChance() return 20 end
snapshot = assert(addon.readDynamicState("Melee", "protection"))
close(snapshot.skill, 305)
close(snapshot.offSkill, 308)
close(snapshot.defense, 440)
close(snapshot.armor, 2000)
assert(snapshot.dual and snapshot.tank)
close(assert(addon.readDynamicState("Ranged", "marksmanship")).skill, 305)
close(assert(addon.readDynamicState("Melee", "feral")).skill, 300)
equipped[16] = nil
close(assert(addon.readDynamicState("Melee", "arms")).skill, 300)
equipped[16] = 100
equipped[17] = nil
snapshot, reason = addon.readDynamicState("Melee", "fury")
assert(not snapshot and reason:find("equipped weapon data unavailable", 1, true))
equipped[17] = 101
local getSkill = C_SkillInfo.GetSkillLineInfoByID
C_SkillInfo.GetSkillLineInfoByID = function() return { rank = 300 } end
snapshot, reason = addon.readDynamicState("Melee", "arms")
assert(not snapshot and reason:find("weapon skill data unavailable", 1, true))
C_SkillInfo.GetSkillLineInfoByID = getSkill
local getDefense = UnitDefenseSkill
UnitDefenseSkill = nil
snapshot, reason = addon.readDynamicState("Melee", "protection")
assert(not snapshot and reason:find("UnitDefenseSkill unavailable", 1, true))
UnitDefenseSkill = getDefense
snapshot = assert(addon.readDynamicState("Spell", "affliction"))
close(snapshot.hit, 15)
CR_HIT_SPELL, CR_CRIT_SPELL = 8, 11
function GetCombatRatingBonus() return 1 end
function GetCombatRating() return 14 end
snapshot = assert(addon.readDynamicState("Spell", "affliction"))
close(snapshot.hit, 16)
close(addon.dynamicRatingPerPercent("critSpell"), 14)
function issecretvalue(value) return value == 60 end
snapshot, reason = addon.readDynamicState("Spell", "affliction")
assert(not snapshot and reason:find("restricted", 1, true))
issecretvalue = nil
GetHitModifier = nil
snapshot, reason = addon.readDynamicState("Melee", "combat")
assert(not snapshot and reason:find("GetHitModifier", 1, true))
function UnitLevel() return 61 end
snapshot, reason = addon.readDynamicState("Spell", "affliction")
assert(not snapshot and reason:find("levels 1-60", 1, true))
assert(addon.isDynamicLocked("hit") and addon.isDynamicLocked("crit")
    and addon.isDynamicLocked("defense") and addon.isDynamicLocked("block"))
assert(not addon.isDynamicLocked("str") and not addon.isDynamicLocked("spellpower")
    and not addon.isDynamicLocked("spellpen"))
print("CompareDPS dynamic weight checks passed")
