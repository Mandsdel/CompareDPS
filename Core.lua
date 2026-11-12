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
}

local statOrder = {
    "spellpower", "shadow", "fire", "int", "spirit", "stamina",
    "hit", "crit", "haste", "hitrating", "critrating", "hasterating",
}
local validStat = {}
for _, key in ipairs(statOrder) do
    validStat[key] = true
end

local function secret(value)
    return type(issecretvalue) == "function" and issecretvalue(value)
end

local function message(text)
    print("|cff80cfffCompareDPS:|r " .. text)
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

local function difference(candidate, oldItems)
    local delta = {}
    for key, value in pairs(candidate) do delta[key] = value end
    for _, item in ipairs(oldItems) do
        for key, value in pairs(item) do add(delta, key, -value) end
    end
    local score, missing = 0, {}
    for _, key in ipairs(statOrder) do
        local value = delta[key]
        if value and value ~= 0 then
            local weight = CompareDPSDB.weights[key]
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
    if not CompareDPSDB or type(CompareDPSDB.weights) ~= "table" then return end
    local link = getLink(tooltip, data)
    if not link then return end
    local location = itemLocation(link)
    local targets = location and slots[location]
    if not targets then return end

    local candidate = readStats(link)
    tooltip:AddLine("CompareDPS (partial estimate)", 0.5, 0.8, 1)
    if not next(CompareDPSDB.weights) then
        tooltip:AddLine("No weights configured. Type /comparedps.", 1, 0.7, 0.2)
        return
    end
    if not candidate then
        tooltip:AddLine("Item stats unavailable; try again.", 1, 0.7, 0.2)
        return
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

        local score, missing
        if not problem then score, missing = difference(candidate, oldItems) end
        if problem then
            tooltip:AddLine(slotNames[slot] .. ": " .. problem, 1, 0.7, 0.2)
        elseif missing then
            tooltip:AddLine(slotNames[slot] .. ": set weights for " .. missing, 1, 0.7, 0.2)
        else
            local r, g = 1, 0.82
            if score > 0 then r, g = 0.3, 1 elseif score < 0 then r, g = 1, 0.3 end
            tooltip:AddLine(string.format("%s: %+.2f DPS", slotNames[slot], score), r, g, 0.3)
        end
    end
    tooltip:AddLine("Only supported stats; effects and enchants may be missing.", 1, 0.7, 0.2, true)
    tooltip:AddLine("Weights: /comparedps", 0.7, 0.7, 0.7)
end

local function command(input)
    local action, key, value = input:lower():match("^%s*(%S+)%s*(%S*)%s*(%S*)%s*$")
    if action == "set" then
        local number = tonumber(value)
        if not validStat[key] or not number or number ~= number or number == math.huge or number == -math.huge then
            message("Usage: /comparedps set <stat> <DPS per stat unit>")
            return
        end
        CompareDPSDB.weights[key] = number
        message(key .. " = " .. number .. " DPS per unit.")
    elseif action == "clear" then
        if not validStat[key] then
            message("Usage: /comparedps clear <stat>")
            return
        end
        CompareDPSDB.weights[key] = nil
        message("Cleared " .. key .. ".")
    elseif action == "list" then
        for _, name in ipairs(statOrder) do
            local weight = CompareDPSDB.weights[name]
            message(name .. ": " .. (weight == nil and "not set" or tostring(weight)))
        end
    else
        message("/comparedps set <stat> <DPS per unit> | clear <stat> | list")
        message("Stats: " .. table.concat(statOrder, ", "))
        message("No default weights. See the README for units and limitations.")
    end
end

addon:RegisterEvent("ADDON_LOADED")
addon:SetScript("OnEvent", function(_, _, name)
    if name ~= "CompareDPS" then return end
    if type(CompareDPSDB) ~= "table" then CompareDPSDB = {} end
    if type(CompareDPSDB.weights) ~= "table" then CompareDPSDB.weights = {} end
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
