local _, namespace = ...
local addon = CreateFrame("Frame")

local slots = {
    INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 },
    INVTYPE_CLOAK = { 15 }, INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 },
    INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 }, INVTYPE_WAIST = { 6 },
    INVTYPE_LEGS = { 7 }, INVTYPE_FEET = { 8 }, INVTYPE_FINGER = { 11, 12 },
    INVTYPE_TRINKET = { 13, 14 }, INVTYPE_WEAPON = { 16 },
    INVTYPE_WEAPONMAINHAND = { 16 }, INVTYPE_2HWEAPON = { 16 },
    INVTYPE_WEAPONOFFHAND = { 17 }, INVTYPE_HOLDABLE = { 17 },
    INVTYPE_RANGED = { 18 }, INVTYPE_RANGEDRIGHT = { 18 },
}

local slotNames = {
    [1] = "Head", [2] = "Neck", [3] = "Shoulder", [5] = "Chest",
    [6] = "Waist", [7] = "Legs", [8] = "Feet", [9] = "Wrist",
    [10] = "Hands", [11] = "Ring 1", [12] = "Ring 2", [13] = "Trinket 1",
    [14] = "Trinket 2", [15] = "Back", [16] = "Main hand",
    [17] = "Off hand", [18] = "Ranged",
}

local statKeys = {
    ITEM_MOD_INTELLECT_SHORT = "int",
    ITEM_MOD_SPIRIT_SHORT = "spirit",
    ITEM_MOD_STAMINA_SHORT = "stamina",
    ITEM_MOD_SPELL_POWER_SHORT = "spellpower",
    ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = "spellpower",
    ITEM_MOD_SHADOW_DAMAGE_DONE_SHORT = "shadow",
    ITEM_MOD_FIRE_DAMAGE_DONE_SHORT = "fire",
    ITEM_MOD_HIT_SPELL_RATING_SHORT = "hitrating",
    ITEM_MOD_CRIT_SPELL_RATING_SHORT = "critrating",
    ITEM_MOD_HASTE_SPELL_RATING_SHORT = "hasterating",
    ITEM_MOD_MANA_REGENERATION_SHORT = "mp5",
    ITEM_MOD_POWER_REGEN0_SHORT = "mp5",
}

local statOrder = {
    "spellpower", "shadow", "fire", "int", "spirit", "stamina",
    "hit", "crit", "haste", "hitrating", "critrating", "hasterating", "mp5",
}
local function secret(value)
    return type(issecretvalue) == "function" and issecretvalue(value)
end

local function message(text)
    print("|cff80cfffCompareDPS:|r " .. text)
end

local function classProfiles()
    if type(UnitClass) ~= "function" then return nil end
    local _, class = UnitClass("player")
    if secret(class) or type(class) ~= "string" then return nil end
    return namespace.profiles[class]
end

local function activeWeights()
    local profiles = classProfiles()
    local profile = profiles and profiles[CompareDPSDB.profile]
    if profile then
        return profile.weights, profile.label
    end
end

local function availableProfiles()
    local profiles = classProfiles()
    local names = {}
    if profiles then
        for key in pairs(profiles) do names[#names + 1] = key end
        table.sort(names)
    end
    return #names > 0 and table.concat(names, ", ") or "none for your class"
end

namespace.classProfiles = classProfiles
namespace.activeWeights = activeWeights

function namespace.selectProfile(key)
    local profiles = classProfiles()
    if not profiles or not profiles[key] then return false end
    CompareDPSDB.profile = key
    if namespace.refreshOptions then namespace.refreshOptions() end
    return true
end

local function getLink(tooltip, data)
    local link = type(data) == "table" and data.hyperlink
    if not secret(link) and type(link) == "string" and link:find("item:", 1, true) then
        return link
    end
    if type(tooltip.GetItem) == "function" then
        local _, itemLink = tooltip:GetItem()
        if not secret(itemLink) and type(itemLink) == "string" and itemLink:find("item:", 1, true) then
            return itemLink
        end
    end
end

local function itemLocation(link)
    local _, _, _, location = C_Item.GetItemInfoInstant(link)
    if secret(location) or type(location) ~= "string" then
        return nil
    end
    return location
end

local function add(stats, key, value)
    stats[key] = (stats[key] or 0) + value
end

-- The API stat table can omit classic-style Equip lines. Parse only known English
-- lines and prefer the API when both sources report the same stat.
local function tooltipStats(link)
    local values = {}
    if not C_TooltipInfo or type(C_TooltipInfo.GetHyperlink) ~= "function" then
        return nil
    end
    local data = C_TooltipInfo.GetHyperlink(link)
    if secret(data) or type(data) ~= "table" or secret(data.lines) or type(data.lines) ~= "table" then
        return nil
    end
    for _, line in ipairs(data.lines) do
        local text = type(line) == "table" and line.leftText
        if not secret(text) and type(text) == "string" then
            text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):lower()
            local value
            if text:find("equip:", 1, true) then
                if text:find("damage and healing", 1, true)
                    and text:find("spell", 1, true) then
                    value = text:match("up to (%d+)")
                    if value then add(values, "spellpower", tonumber(value)) end
                elseif text:find("shadow spells", 1, true) then
                    value = text:match("up to (%d+)")
                    if value then add(values, "shadow", tonumber(value)) end
                elseif text:find("fire spells", 1, true) then
                    value = text:match("up to (%d+)")
                    if value then add(values, "fire", tonumber(value)) end
                end
                if text:find("spell", 1, true) then
                    value = text:match("hit.-by (%d+%.?%d*)%%")
                    if value then add(values, "hit", tonumber(value)) end
                    value = text:match("critical.-by (%d+%.?%d*)%%")
                    if value then add(values, "crit", tonumber(value)) end
                    value = text:match("haste.-by (%d+%.?%d*)%%")
                    if value then add(values, "haste", tonumber(value)) end
                end
            end
        end
    end
    return values
end

local function readStats(link)
    local api = C_Item.GetItemStats(link)
    if secret(api) or type(api) ~= "table" then
        return nil
    end
    local stats = {}
    for key, value in pairs(api) do
        local stat = statKeys[key]
        if stat and not secret(value) and type(value) == "number" then
            add(stats, stat, value)
        end
    end
    local extra = tooltipStats(link)
    if not extra then return nil end
    for key, value in pairs(extra) do
        if stats[key] == nil then
            stats[key] = value
        end
    end
    -- A percentage on the tooltip and an API rating can describe the same stat.
    for _, key in ipairs({ "hit", "crit", "haste" }) do
        if stats[key] ~= nil then
            stats[key .. "rating"] = nil
        end
    end
    return stats
end

local function difference(candidate, oldItems, weights)
    local delta = {}
    for key, value in pairs(candidate) do delta[key] = value end
    for _, item in ipairs(oldItems) do
        for key, value in pairs(item) do add(delta, key, -value) end
    end
    local score, missing = 0, {}
    for _, key in ipairs(statOrder) do
        local value = delta[key]
        if value and value ~= 0 then
            local weight = weights[key]
            if weight == nil then
                missing[#missing + 1] = key
            else
                score = score + value * weight
            end
        end
    end
    if #missing > 0 then
        return nil, table.concat(missing, ", ")
    end
    return score
end

local function compare(tooltip, data)
    if not CompareDPSDB then return end
    local link = getLink(tooltip, data)
    if not link then return end
    local location = itemLocation(link)
    local targets = location and slots[location]
    if not targets then return end

    local weights, label = activeWeights()
    tooltip:AddLine("CompareDPS (partial estimate)", 0.5, 0.8, 1)
    if not weights or not next(weights) then
        tooltip:AddLine("Choose a spec using the minimap button.", 1, 0.7, 0.2)
        return
    end
    tooltip:AddLine(label .. " - relative score", 0.7, 0.8, 1)
    local candidate = readStats(link)
    if not candidate then
        tooltip:AddLine("Item stats unavailable; try again.", 1, 0.7, 0.2)
        return
    end
    local candidateScore, candidateMissing = difference(candidate, {}, weights)
    if candidateMissing then
        tooltip:AddLine("Item score unavailable; missing weights: " .. candidateMissing, 1, 0.7, 0.2)
    else
        tooltip:AddLine(string.format("Item: %.2f points", candidateScore), 1, 1, 1)
    end

    for _, slot in ipairs(targets) do
        local equipped = GetInventoryItemLink("player", slot)
        local oldItems = {}
        local problem
        if secret(equipped) then
            problem = "equipped item unavailable"
        elseif equipped then
            local old = readStats(equipped)
            if old then oldItems[#oldItems + 1] = old else problem = "equipped stats unavailable" end
        end

        if slot == 17 then
            local main = GetInventoryItemLink("player", 16)
            if secret(main) then
                problem = "main hand unavailable"
            elseif main then
                local mainLocation = itemLocation(main)
                if not mainLocation then
                    problem = "main hand data unavailable"
                elseif mainLocation == "INVTYPE_2HWEAPON" then
                    problem = "requires a one-hand weapon"
                end
            end
        elseif slot == 16 and location == "INVTYPE_2HWEAPON" then
            local offhand = GetInventoryItemLink("player", 17)
            if secret(offhand) then
                problem = "off hand unavailable"
            elseif offhand then
                local old = readStats(offhand)
                if old then oldItems[#oldItems + 1] = old else problem = "off-hand stats unavailable" end
            end
        end

        local score, missing, oldScore, oldMissing
        if not problem then
            score, missing = difference(candidate, oldItems, weights)
            oldScore, oldMissing = difference({}, oldItems, weights)
        end
        if problem then
            tooltip:AddLine(slotNames[slot] .. ": " .. problem, 1, 0.7, 0.2)
        elseif missing then
            tooltip:AddLine(slotNames[slot] .. ": missing weights: " .. missing, 1, 0.7, 0.2)
        else
            local r, g = 1, 0.82
            if score > 0 then r, g = 0.3, 1 elseif score < 0 then r, g = 1, 0.3 end
            if oldMissing then
                tooltip:AddLine(string.format("%s: %+.2f points (equipped score unavailable: %s)", slotNames[slot], score, oldMissing), r, g, 0.3, true)
            else
                tooltip:AddLine(string.format("%s: %.2f points (%+.2f)", slotNames[slot], -oldScore, score), r, g, 0.3)
            end
        end
    end
    tooltip:AddLine("Only supported stats; effects and enchants may be missing.", 1, 0.7, 0.2, true)
    tooltip:AddLine("Settings: minimap button", 0.7, 0.7, 0.7)
end

local function command(input)
    local action, key = input:lower():match("^%s*(%S+)%s*(%S*)%s*$")
    if action == "spec" then
        local profiles = classProfiles()
        if not profiles or not profiles[key] then
            message("Unknown spec for your class. Available: " .. availableProfiles() .. ".")
            return
        end
        namespace.selectProfile(key)
        message("Using " .. profiles[key].label .. " relative score weights.")
    elseif action == "list" then
        local weights, label = activeWeights()
        if not weights then
            message("No profile selected. Use /comparedps spec <name>.")
            return
        end
        message(label .. " weights (points per unit):")
        for _, name in ipairs(statOrder) do
            local weight = weights[name]
            message(name .. ": " .. (weight == nil and "not set" or tostring(weight)))
        end
    else
        message("/comparedps spec <name> | list")
        message("Available specs: " .. availableProfiles())
        message("Presets are relative scores, not DPS. See the README for limitations.")
    end
end

addon:RegisterEvent("ADDON_LOADED")
addon:RegisterEvent("PLAYER_LOGIN")
addon:SetScript("OnEvent", function(_, event, name)
    if event == "PLAYER_LOGIN" then
        if namespace.initializeOptions then namespace.initializeOptions() end
        return
    end
    if name ~= "CompareDPS" then return end
    if type(CompareDPSDB) ~= "table" then CompareDPSDB = {} end
    SLASH_COMPAREDPS1 = "/comparedps"
    SlashCmdList.COMPAREDPS = command
    if not C_Item or type(C_Item.GetItemInfoInstant) ~= "function"
        or type(C_Item.GetItemStats) ~= "function"
        or not C_TooltipInfo or type(C_TooltipInfo.GetHyperlink) ~= "function"
        or not TooltipDataProcessor or type(TooltipDataProcessor.AddTooltipPostCall) ~= "function"
        or not Enum or not Enum.TooltipDataType or not Enum.TooltipDataType.Item then
        message("Required item or tooltip APIs are unavailable; comparisons are disabled.")
        return
    end
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
        if tooltip == GameTooltip or tooltip == ItemRefTooltip then
            compare(tooltip, data)
        end
    end)
end)
