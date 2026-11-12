local frame = {}
function frame:RegisterEvent() end
function frame:SetScript(_, handler) self.handler = handler end
function CreateFrame() return frame end

GameTooltip = { lines = {} }
ItemRefTooltip = {}
function GameTooltip:AddLine(text) self.lines[#self.lines + 1] = text end
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
}
local equipped = { [11] = "item:2", [16] = "item:4", [17] = "item:5" }
C_Item = {}
function C_Item.GetItemInfoInstant(link) return 1, nil, nil, items[link] and items[link].loc end
function C_Item.GetItemStats(link)
    local item = items[link]
    return item and { ITEM_MOD_INTELLECT_SHORT = item.int } or nil
end
C_TooltipInfo = {}
function C_TooltipInfo.GetHyperlink(link)
    local item = items[link]
    if not item then return nil end
    return { lines = { { leftText = "Equip: Increases damage and healing done by magical spells and effects by up to " .. item.spell .. "." } } }
end
function GetInventoryItemLink(_, slot) return equipped[slot] end

dofile("Core.lua")
frame.handler(frame, "ADDON_LOADED", "CompareDPS")

local function tooltip(link)
    GameTooltip.lines = {}
    TooltipDataProcessor.callback(GameTooltip, { hyperlink = link })
    return table.concat(GameTooltip.lines, "\n")
end

assert(tooltip("item:1"):find("No weights configured", 1, true))
SlashCmdList.COMPAREDPS("set int 0.2")
assert(tooltip("item:1"):find("set weights for spellpower", 1, true))
SlashCmdList.COMPAREDPS("set spellpower 0.5")
local rings = tooltip("item:1")
assert(rings:find("Ring 1: +4.50 DPS", 1, true), rings)
assert(rings:find("Ring 2: +9.00 DPS", 1, true), rings)

local weapon = tooltip("item:3")
assert(weapon:find("Main hand: +8.00 DPS", 1, true), weapon)
equipped[16] = "item:3"
assert(tooltip("item:5"):find("requires a one-hand weapon", 1, true))
SlashCmdList.COMPAREDPS("clear int")
assert(tooltip("item:1"):find("set weights for int", 1, true))
print("CompareDPS checks passed")
