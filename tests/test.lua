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
function GameTooltip:AddLine(text) self.lines[#self.lines + 1] = text end
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
}
C_Item = {}
function C_Item.GetItemInfoInstant(link) return 1, nil, nil, items[link] and items[link].loc end
function C_Item.GetItemLinkByGUID(guid) if guid == "equipped-guid" then return "item:2" end end
function C_Item.GetItemStats(link)
    local item = items[link]
    return item and {
        ITEM_MOD_INTELLECT_SHORT = item.int,
        ITEM_MOD_MANA_REGENERATION_SHORT = item.mp5,
        ITEM_MOD_HIT_SPELL_RATING_SHORT = item.rating,
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
    if item.fire then
        lines[#lines + 1] = { leftText = "Equip: Increases damage done by Fire spells and effects by up to " .. item.fire .. "." }
    end
    return { lines = lines }
end
local namespace = {}
assert(loadfile("Profiles.lua"))("CompareDPS", namespace)
assert(loadfile("Core.lua"))("CompareDPS", namespace)
frame.handler(frame, "ADDON_LOADED", "CompareDPS")

local function tooltip(link)
    GameTooltip.lines = {}
    TooltipDataProcessor.callback(GameTooltip, { hyperlink = link })
    return table.concat(GameTooltip.lines, "\n")
end

assert(tooltip("item:1"):find("Choose a spec", 1, true))
assert(namespace.selectProfile("demonology"))
assert(CompareDPSDB.profile == "demonology")
local rings = tooltip("item:1")
assert(rings:find("Ring: 18.00 points", 1, true), rings)
assert(#GameTooltip.lines == 3, rings)
assert(not rings:find("Item:", 1, true) and not rings:find("Settings:", 1, true), rings)

local weapon = tooltip("item:3")
assert(weapon:find("Two-hand: 32.00 points", 1, true), weapon)
assert(tooltip("item:10"):find("Chest: 9.00 points", 1, true))
assert(tooltip("item:11"):find("Waist: 12.00 points", 1, true))
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
    assert(result:find(case[2] .. " - relative score", 1, true), result)
    assert(result:find(string.format("Ring: %.2f points", case[3]), 1, true), result)
    local mana = tooltip("item:6")
    assert(mana:find(string.format("Ring: %.2f points", case[4]), 1, true), mana)
    assert(tooltip("item:7"):find("missing weights: hitrating", 1, true))
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
print("CompareDPS checks passed")
