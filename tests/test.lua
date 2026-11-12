local frame = {}
function frame:RegisterEvent() end
function frame:SetScript(_, handler) self.handler = handler end
function CreateFrame() return frame end

GameTooltip = { lines = {} }
ItemRefTooltip = {}
ShoppingTooltip1 = { lines = {} }
ShoppingTooltip2 = { lines = {} }
local playerClass = "WARLOCK"
function UnitClass() return "Warlock", playerClass end
function GameTooltip:AddLine(text, r, g, b)
    self.lines[#self.lines + 1] = text
    self.colors = self.colors or {}
    self.colors[#self.lines] = { r, g, b }
end
function GameTooltip:GetProcessingTooltipInfo() return self.info end
ShoppingTooltip1.AddLine = GameTooltip.AddLine
ShoppingTooltip2.AddLine = GameTooltip.AddLine
SlashCmdList = {}
Enum = { TooltipDataType = { Item = 1 } }
TooltipDataProcessor = {}
function TooltipDataProcessor.AddTooltipPostCall(_, callback) TooltipDataProcessor.callback = callback end

local items = {
    ["item:1"] = { loc = "INVTYPE_FINGER", int = 20, spell = 10 },
    ["item:2"] = { loc = "INVTYPE_FINGER", int = 10, spell = 5 },
    ["item:3"] = { loc = "INVTYPE_2HWEAPON", int = 30, spell = 20 },
    ["item:4"] = { loc = "INVTYPE_WEAPONMAINHAND", int = 5, spell = 5 },
    ["item:5"] = { loc = "INVTYPE_HOLDABLE", int = 10, spell = 5 },
    ["item:6"] = { loc = "INVTYPE_FINGER", int = 0, spell = 0, mp5 = 10 },
    ["item:7"] = { loc = "INVTYPE_FINGER", int = 0, spell = 0, rating = 5 },
    ["item:8"] = { loc = "INVTYPE_FINGER", int = 0, spell = 0, rating = 5, hit = 1 },
    ["item:9"] = { loc = "INVTYPE_FINGER", int = 0, spell = 0, fire = 10 },
    ["item:10"] = { loc = "INVTYPE_CHEST", int = 10, spell = 5 },
    ["item:11"] = { loc = "INVTYPE_WAIST", int = 5, spell = 10 },
    ["item:12"] = { loc = "INVTYPE_HEAD", int = 0, spell = 0, str = 10, agi = 5, ap = 20, armor = 100 },
    ["item:13"] = { loc = "INVTYPE_HEAD", int = 4, spell = 0, heal = 20, mp5 = 3 },
    ["item:14"] = { loc = "INVTYPE_2HWEAPON", int = 0, spell = 0, dps = 10, speed = 3 },
    ["item:15"] = { loc = "INVTYPE_HEAD", int = 0, spell = 0, defenseRating = 5 },
    ["item:16"] = { loc = "INVTYPE_FINGER", int = 0, spell = 0, crit = 1 },
    ["item:17"] = { loc = "INVTYPE_WEAPON", int = 0, spell = 0, dps = 10, speed = 3 },
    ["item:18"] = { loc = "INVTYPE_HEAD", int = 0, spell = 0, splitHeal = true },
}
C_Item = {}
local equipped = { [5] = "item:10", [11] = "item:2", [12] = "item:1", [16] = "item:4", [17] = "item:5" }
function GetInventoryItemLink(_, slot) return equipped[slot] end
function C_Item.GetItemInfoInstant(link) return 1, nil, nil, items[link] and items[link].loc end
function C_Item.GetItemLinkByGUID(guid) if guid == "equipped-guid" then return "item:2" end end
function C_Item.GetItemStats(link)
    local item = items[link]
    return item and {
        ITEM_MOD_INTELLECT_SHORT = item.int,
        ITEM_MOD_MANA_REGENERATION_SHORT = item.mp5,
        ITEM_MOD_HIT_SPELL_RATING_SHORT = item.rating,
        ITEM_MOD_STRENGTH_SHORT = item.str,
        ITEM_MOD_AGILITY_SHORT = item.agi,
        ITEM_MOD_ATTACK_POWER_SHORT = item.ap,
        ITEM_MOD_SPELL_HEALING_DONE_SHORT = item.heal,
        ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = item.defenseRating,
    } or nil
end
C_TooltipInfo = {}
function C_TooltipInfo.GetHyperlink(link)
    local item = items[link]
    if not item then return nil end
    local lines = {
        { leftText = "Equip: Increases damage and healing done by magical spells and effects by up to " .. item.spell .. "." },
    }
    if item.hit then
        lines[#lines + 1] = { leftText = "Equip: Improves your chance to hit with spells by " .. item.hit .. "%." }
    end
    if item.crit then
        lines[#lines + 1] = { leftText = "Equip: Improves your chance to get a critical hit by " .. item.crit .. "%." }
    end
    if item.fire then
        lines[#lines + 1] = { leftText = "Equip: Increases damage done by Fire spells and effects by up to " .. item.fire .. "." }
    end
    if item.armor then lines[#lines + 1] = { leftText = item.armor .. " Armor" } end
    if item.dps then lines[#lines + 1] = { leftText = "(" .. item.dps .. " damage per second)", rightText = "Speed " .. item.speed } end
    if item.splitHeal then
        lines[#lines + 1] = { leftText = "Equip: Increases healing done by spells by up to 20 and damage done by spells by up to 10." }
    end
    return { lines = lines }
end
local namespace = {}
assert(loadfile("Profiles.lua"))("CompareDPS", namespace)
assert(loadfile("Core.lua"))("CompareDPS", namespace)
frame.handler(frame, "ADDON_LOADED", "CompareDPS")

local function tooltip(link)
    GameTooltip.lines = {}
    GameTooltip.colors = {}
    TooltipDataProcessor.callback(GameTooltip, { hyperlink = link })
    return table.concat(GameTooltip.lines, "\n")
end

assert(tooltip("item:1"):find("Choose a spec", 1, true))
assert(namespace.selectProfile("demonology"))
assert(CompareDPSDB.profile == "demonology")
local rings = tooltip("item:1")
assert(GameTooltip.lines[1] == "CompareDPS")
assert(GameTooltip.colors[1][1] == 0.8 and GameTooltip.colors[1][2] == 0.65 and GameTooltip.colors[1][3] == 0.25)
assert(GameTooltip.lines[2] == "Demonology")
assert(GameTooltip.colors[2][1] == 0.7 and GameTooltip.colors[2][2] == 0.8 and GameTooltip.colors[2][3] == 1)
assert(rings:find("Ring: 18.00 points", 1, true), rings)
assert(#GameTooltip.lines == 3, rings)
assert(not rings:find("Item:", 1, true) and not rings:find("Settings:", 1, true), rings)

local weapon = tooltip("item:3")
assert(weapon:find("Two-hand: 32.00 points", 1, true), weapon)
assert(tooltip("item:10"):find("Chest: 9.00 points", 1, true))
assert(tooltip("item:11"):find("Waist: 12.00 points", 1, true))
GameTooltip.info = { getterName = "GetBagItem" }
local baggedRing = tooltip("item:1")
assert(baggedRing:find("Ring: 18.00 points (slot 1: |cff40ff40+9.00|r, slot 2: +0.00)", 1, true), baggedRing)
equipped[12] = nil
assert(tooltip("item:1"):find("(slot 1: |cff40ff40+9.00|r, slot 2: |cff40ff40+18.00|r)", 1, true))
equipped[11] = "item:1"
equipped[12] = "item:2"
local mixed = tooltip("item:2")
assert(mixed:find("(slot 1: |cffff4040-9.00|r, slot 2: +0.00)", 1, true), mixed)
equipped[11] = "item:2"
assert(tooltip("item:10"):find("Chest: 9.00 points (+0.00)", 1, true))
assert(GameTooltip.colors[3][1] == 1 and GameTooltip.colors[3][2] == 1 and GameTooltip.colors[3][3] == 1)
equipped[5] = "item:11"
assert(tooltip("item:10"):find("Chest: 9.00 points (-3.00)", 1, true))
assert(GameTooltip.colors[3][1] == 1 and GameTooltip.colors[3][2] == 0.25)
assert(tooltip("item:3"):find("Two-hand: 32.00 points (+16.00)", 1, true))
assert(GameTooltip.colors[3][1] == 0.25 and GameTooltip.colors[3][2] == 1)
equipped[16] = "item:3"
assert(tooltip("item:5"):find("(requires a one-hand weapon)", 1, true))
equipped[11] = "item:7"
assert(tooltip("item:1"):find("slot 1: |cff40ff40+12.00|r", 1, true))
equipped[11] = "item:2"
GameTooltip.info = { getterName = "GetInventoryItem" }
local worn = tooltip("item:1")
assert(worn:find("Ring: 18.00 points", 1, true) and not worn:find("(slot", 1, true), worn)
assert(GameTooltip.colors[3][1] == 1 and GameTooltip.colors[3][2] == 1 and GameTooltip.colors[3][3] == 1)
GameTooltip.info = nil
ShoppingTooltip1.lines = {}
TooltipDataProcessor.callback(ShoppingTooltip1, { guid = "equipped-guid" })
assert(table.concat(ShoppingTooltip1.lines, "\n"):find("Ring: 9.00 points", 1, true))
ShoppingTooltip2.lines = {}
TooltipDataProcessor.callback(ShoppingTooltip2, { hyperlink = "item:1" })
assert(table.concat(ShoppingTooltip2.lines, "\n"):find("Ring: 18.00 points", 1, true))
ShoppingTooltip2.lines = {}
TooltipDataProcessor.callback(ShoppingTooltip2, { id = 1 })
assert(table.concat(ShoppingTooltip2.lines, "\n"):find("item link unavailable", 1, true))

for _, case in ipairs({
    { "affliction", "Affliction", 18, 13 },
    { "demonology", "Demonology", 18, 10 },
    { "destruction", "Destruction", 17, 8 },
}) do
    assert(namespace.selectProfile(case[1]))
    local result = tooltip("item:1")
    assert(GameTooltip.lines[2] == case[2], result)
    assert(result:find(string.format("Ring: %.2f points", case[3]), 1, true), result)
    local mana = tooltip("item:6")
    assert(mana:find(string.format("Ring: %.2f points", case[4]), 1, true), mana)
    local rating = tooltip("item:7")
    assert(rating:find("Ring: " .. (case[1] == "demonology" and "6.00" or "6.50") .. " points", 1, true), rating)
    local crit = tooltip("item:16")
    assert(crit:find(string.format("Ring: %.2f points", namespace.profiles.WARLOCK[case[1]].weights.crit), 1, true), crit)
    local hit = tooltip("item:8")
    assert(hit:find("Ring: " .. (case[1] == "demonology" and "12.00" or "13.00") .. " points", 1, true), hit)
end
SlashCmdList.COMPAREDPS("spec affliction")
assert(tooltip("item:9"):find("missing weights: fire", 1, true))
playerClass = "MAGE"
assert(tooltip("item:1"):find("Choose a spec", 1, true))
assert(not namespace.selectProfile("affliction"))
SlashCmdList.COMPAREDPS("spec affliction")
assert(tooltip("item:1"):find("Choose a spec", 1, true))
playerClass = "WARLOCK"
CompareDPSDB = { weights = { int = 0.2, spellpower = 0.5 } }
frame.handler(frame, "ADDON_LOADED", "CompareDPS")
assert(tooltip("item:1"):find("Choose a spec", 1, true))
local expected = {
    HUNTER = { "beastmastery", "marksmanship", "survival" },
    MAGE = { "arcane", "fire", "frost" },
    ROGUE = { "assassination", "combat", "subtlety" },
    WARRIOR = { "arms", "fury", "protection" },
    SHAMAN = { "elemental", "enhancement", "restoration" },
    PALADIN = { "holy", "protection", "retribution" },
    PRIEST = { "discipline", "holy", "shadow" },
    DRUID = { "balance", "feral", "feraltank", "restoration" },
    WARLOCK = { "affliction", "demonology", "destruction" },
}
for class, names in pairs(expected) do
    playerClass = class
    for _, name in ipairs(names) do
        assert(namespace.selectProfile(name), class .. " " .. name)
        assert(tooltip("item:1"):find(namespace.profiles[class][name].label, 1, true))
    end
end
playerClass = "WARRIOR"
assert(namespace.selectProfile("arms"))
local physical = tooltip("item:12")
assert(physical:find("Head: 23.40 points", 1, true), physical)
local physicalWeapon = tooltip("item:14")
assert(physicalWeapon:find("Two-hand: 73.00 points", 1, true), physicalWeapon)
assert(tooltip("item:17"):find("Main hand: 30.00 points", 1, true))
GameTooltip.info = { getterName = "GetInventoryItem", getterArgs = { "player", 17 } }
assert(tooltip("item:17"):find("Off hand: 12.00 points", 1, true))
GameTooltip.info = nil
assert(tooltip("item:3"):find("weapon DPS, weapon speed", 1, true))
assert(namespace.selectProfile("protection"))
assert(tooltip("item:15"):find("defenserating", 1, true))
playerClass = "PRIEST"
assert(namespace.selectProfile("holy"))
local healer = tooltip("item:13")
assert(healer:find("Head: 31.00 points", 1, true), healer)
assert(tooltip("item:18"):find("Head: 30.00 points", 1, true))
playerClass = "DRUID"
assert(namespace.selectProfile("feral"))
local feral = tooltip("item:12")
assert(feral:find("Head: 25.50 points", 1, true), feral)
assert(namespace.selectProfile("feraltank"))
local bear = tooltip("item:12")
assert(bear:find("Head: 19.45 points", 1, true), bear)
print("CompareDPS checks passed")
