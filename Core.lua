local _, namespace = ...
local addon = CreateFrame("Frame")

local slotNames = {
    INVTYPE_HEAD = "Head", INVTYPE_NECK = "Neck", INVTYPE_SHOULDER = "Shoulder",
    INVTYPE_CLOAK = "Back", INVTYPE_CHEST = "Chest", INVTYPE_ROBE = "Chest",
    INVTYPE_WRIST = "Wrist", INVTYPE_HAND = "Hands", INVTYPE_WAIST = "Waist",
    INVTYPE_LEGS = "Legs", INVTYPE_FEET = "Feet", INVTYPE_FINGER = "Ring",
    INVTYPE_TRINKET = "Trinket", INVTYPE_WEAPON = "Weapon",
    INVTYPE_WEAPONMAINHAND = "Main hand", INVTYPE_2HWEAPON = "Two-hand",
    INVTYPE_WEAPONOFFHAND = "Off hand", INVTYPE_HOLDABLE = "Off hand",
    INVTYPE_RANGED = "Ranged", INVTYPE_RANGEDRIGHT = "Ranged",
}

local comparisonSlots = {
    INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 },
    INVTYPE_CLOAK = { 15 }, INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 },
    INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 }, INVTYPE_WAIST = { 6 },
    INVTYPE_LEGS = { 7 }, INVTYPE_FEET = { 8 }, INVTYPE_FINGER = { 11, 12 },
    INVTYPE_TRINKET = { 13, 14 }, INVTYPE_WEAPON = { 16 },
    INVTYPE_WEAPONMAINHAND = { 16 }, INVTYPE_2HWEAPON = { 16 },
    INVTYPE_WEAPONOFFHAND = { 17 }, INVTYPE_HOLDABLE = { 17 },
    INVTYPE_RANGED = { 18 }, INVTYPE_RANGEDRIGHT = { 18 },
}

-- ForeverUpgrade's Forever class equipment categories.
local weaponTypes = {
    WARRIOR = { [0]=true,[1]=true,[2]=true,[3]=true,[4]=true,[5]=true,[6]=true,[7]=true,[8]=true,[10]=true,[13]=true,[15]=true,[16]=true,[18]=true },
    PALADIN = { [4]=true,[5]=true,[6]=true,[7]=true,[8]=true },
    HUNTER = { [0]=true,[1]=true,[2]=true,[3]=true,[6]=true,[7]=true,[8]=true,[10]=true,[13]=true,[15]=true,[16]=true,[18]=true },
    ROGUE = { [2]=true,[3]=true,[4]=true,[7]=true,[13]=true,[15]=true,[16]=true,[18]=true },
    PRIEST = { [4]=true,[10]=true,[15]=true,[19]=true },
    SHAMAN = { [0]=true,[1]=true,[4]=true,[5]=true,[10]=true,[13]=true,[15]=true },
    MAGE = { [7]=true,[10]=true,[15]=true,[19]=true },
    WARLOCK = { [7]=true,[10]=true,[15]=true,[19]=true },
    DRUID = { [4]=true,[5]=true,[6]=true,[10]=true,[13]=true,[15]=true },
}
local armorLimit = {
    WARRIOR = 4, PALADIN = 4, HUNTER = 3, SHAMAN = 3,
    ROGUE = 2, DRUID = 2, MAGE = 1, PRIEST = 1, WARLOCK = 1,
}
local shieldClasses = { WARRIOR = true, PALADIN = true, SHAMAN = true }
local offhandWeaponClasses = { WARRIOR = true, ROGUE = true, HUNTER = true, SHAMAN = true }

local statKeys = {
    ITEM_MOD_STRENGTH_SHORT = "str",
    ITEM_MOD_AGILITY_SHORT = "agi",
    ITEM_MOD_ATTACK_POWER_SHORT = "ap",
    ITEM_MOD_RANGED_ATTACK_POWER_SHORT = "rap",
    ITEM_MOD_FERAL_ATTACK_POWER_SHORT = "fap",
    ITEM_MOD_DAMAGE_PER_SECOND_SHORT = "weaponDps",
    ITEM_MOD_MANA_SHORT = "mana",
    ITEM_MOD_HEALTH_SHORT = "health",
    ITEM_MOD_INTELLECT_SHORT = "int",
    ITEM_MOD_SPIRIT_SHORT = "spirit",
    ITEM_MOD_STAMINA_SHORT = "stamina",
    ITEM_MOD_SPELL_POWER_SHORT = "spellpower",
    ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = "spellpower",
    ITEM_MOD_SHADOW_DAMAGE_DONE_SHORT = "shadow",
    ITEM_MOD_FIRE_DAMAGE_DONE_SHORT = "fire",
    ITEM_MOD_FIRE_SPELL_POWER_SHORT = "fire",
    ITEM_MOD_SHADOW_SPELL_POWER_SHORT = "shadow",
    ITEM_MOD_FROST_SPELL_POWER_SHORT = "frost",
    ITEM_MOD_ARCANE_SPELL_POWER_SHORT = "arcane",
    ITEM_MOD_NATURE_SPELL_POWER_SHORT = "nature",
    ITEM_MOD_HOLY_SPELL_POWER_SHORT = "holy",
    ITEM_MOD_SPELL_HEALING_DONE_SHORT = "heal",
    ITEM_MOD_HIT_RATING_SHORT = "hitrating",
    ITEM_MOD_HIT_MELEE_RATING_SHORT = "hitrating",
    ITEM_MOD_HIT_RANGED_RATING_SHORT = "hitrating",
    ITEM_MOD_HIT_SPELL_RATING_SHORT = "hitrating",
    ITEM_MOD_CRIT_SPELL_RATING_SHORT = "critrating",
    ITEM_MOD_CRIT_RATING_SHORT = "critrating",
    ITEM_MOD_CRIT_MELEE_RATING_SHORT = "critrating",
    ITEM_MOD_CRIT_RANGED_RATING_SHORT = "critrating",
    ITEM_MOD_HASTE_SPELL_RATING_SHORT = "hasterating",
    ITEM_MOD_HASTE_RATING_SHORT = "hasterating",
    ITEM_MOD_MANA_REGENERATION_SHORT = "mp5",
    ITEM_MOD_POWER_REGEN0_SHORT = "mp5",
    ITEM_MOD_HEALTH_REGENERATION_SHORT = "hp5",
    ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = "defenserating",
    ITEM_MOD_DODGE_RATING_SHORT = "dodgerating",
    ITEM_MOD_PARRY_RATING_SHORT = "parryrating",
    ITEM_MOD_BLOCK_RATING_SHORT = "blockrating",
    ITEM_MOD_BLOCK_VALUE_SHORT = "blockValue",
    ITEM_MOD_EXTRA_ARMOR_SHORT = "armor",
    RESISTANCE0_NAME = "armor",
}

local statOrder = {
    "str", "agi", "ap", "rap", "fap", "spellpower", "heal",
    "shadow", "fire", "frost", "arcane", "nature", "holy", "int", "spirit", "stamina", "mana", "health",
    "hit", "crit", "haste", "hitrating", "critrating", "hasterating", "mp5",
    "hp5", "armor", "defense", "defenserating", "dodge", "dodgerating",
    "parry", "parryrating", "block", "blockrating", "blockValue",
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
    local info = type(tooltip.GetProcessingTooltipInfo) == "function" and tooltip:GetProcessingTooltipInfo()
    if not secret(info) and type(info) == "table" and not secret(info.getterName)
        and info.getterName == "GetHyperlink" and not secret(info.getterArgs)
        and type(info.getterArgs) == "table" then
        link = info.getterArgs[1]
        if not secret(link) and type(link) == "string" and link:find("item:", 1, true) then
            return link
        end
    end
    if type(tooltip.GetItem) == "function" then
        local _, itemLink = tooltip:GetItem()
        if not secret(itemLink) and type(itemLink) == "string" and itemLink:find("item:", 1, true) then
            return itemLink
        end
    end
    local guid = type(data) == "table" and data.guid
    if guid and not secret(guid) and C_Item and type(C_Item.GetItemLinkByGUID) == "function" then
        local itemLink = C_Item.GetItemLinkByGUID(guid)
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

local function matchesRestriction(data, format, playerName)
    if secret(format) or type(format) ~= "string" or secret(playerName) or type(playerName) ~= "string" then return true end
    local placeholder = format:find("%%s")
    if not placeholder then return true end
    local prefix = format:sub(1, placeholder - 1):lower()
    if prefix == "" then return true end
    for _, line in ipairs(data.lines) do
        local text = type(line) == "table" and line.leftText
        if not secret(text) and type(text) == "string" then
            text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):lower()
            if text:sub(1, #prefix) == prefix then
                for name in text:sub(#prefix + 1):gmatch("[^,]+") do
                    if name:match("^%s*(.-)%s*$") == playerName:lower() then return true end
                end
                return false
            end
        end
    end
    return true
end

local function canEquipForClass(link, location)
    if type(UnitClass) ~= "function" then return nil end
    local className, class = UnitClass("player")
    if secret(class) or type(class) ~= "string" or not armorLimit[class] then return nil end
    local _, _, _, _, _, itemClass, subclass = C_Item.GetItemInfoInstant(link)
    if secret(itemClass) or secret(subclass) or type(itemClass) ~= "number"
        or type(subclass) ~= "number" then return nil end
    if itemClass == 2 then
        if not weaponTypes[class][subclass] then return false end
        if location == "INVTYPE_WEAPONOFFHAND" and not offhandWeaponClasses[class] then return false end
    elseif itemClass == 4 then
        if subclass >= 1 and subclass <= 4 and subclass > armorLimit[class] then return false end
        if subclass == 6 and not shieldClasses[class] then return false end
    end

    local data = C_TooltipInfo.GetHyperlink(link)
    if secret(data) or type(data) ~= "table" or secret(data.lines) or type(data.lines) ~= "table" then return nil end
    if not matchesRestriction(data, ITEM_CLASSES_ALLOWED, className) then return false end
    local race = type(UnitRace) == "function" and UnitRace("player")
    return matchesRestriction(data, ITEM_RACES_ALLOWED, race)
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
            value = text:match("([%d%.]+)%s+damage per second")
            if value then values.weaponDps = tonumber(value) end
            local speed = text:match("speed%s+([%d%.]+)")
            if speed and not text:find("attack speed", 1, true) then values.weaponSpeed = tonumber(speed) end
            local right = type(line) == "table" and line.rightText
            if not secret(right) and type(right) == "string" then
                local speed = right:lower():match("speed%s+([%d%.]+)")
                if speed then values.weaponSpeed = tonumber(speed) end
            end
            local armor = text:match("^(%d+)%s+armor$")
            if armor then values.armor = tonumber(armor) end
            if text:find("equip:", 1, true) then
                local healing, damage = text:match("healing.-up to (%d+).-damage.-up to (%d+)")
                if healing and damage then
                    add(values, "heal", tonumber(healing))
                    add(values, "spellpower", tonumber(damage))
                elseif text:find("damage and healing", 1, true)
                    and text:find("spell", 1, true) then
                    value = text:match("up to (%d+)")
                    if value then add(values, "spellpower", tonumber(value)) end
                elseif text:find("shadow spells", 1, true) then
                    value = text:match("up to (%d+)")
                    if value then add(values, "shadow", tonumber(value)) end
                elseif text:find("fire spells", 1, true) then
                    value = text:match("up to (%d+)")
                    if value then add(values, "fire", tonumber(value)) end
                elseif text:find("frost spells", 1, true) then
                    value = text:match("up to (%d+)")
                    if value then add(values, "frost", tonumber(value)) end
                elseif text:find("arcane spells", 1, true) then
                    value = text:match("up to (%d+)")
                    if value then add(values, "arcane", tonumber(value)) end
                elseif text:find("nature spells", 1, true) then
                    value = text:match("up to (%d+)")
                    if value then add(values, "nature", tonumber(value)) end
                elseif text:find("holy spells", 1, true) then
                    value = text:match("up to (%d+)")
                    if value then add(values, "holy", tonumber(value)) end
                elseif text:find("healing", 1, true) then
                    value = text:match("up to (%d+)")
                    if value then add(values, "heal", tonumber(value)) end
                end
                if not text:find("critical", 1, true) then
                    value = text:match("hit.-by (%d+%.?%d*)%%")
                    if value then add(values, "hit", tonumber(value)) end
                end
                value = text:match("critical.-by (%d+%.?%d*)%%")
                if value then add(values, "crit", tonumber(value)) end
                value = text:match("haste.-by (%d+%.?%d*)%%")
                if value then add(values, "haste", tonumber(value)) end
                for _, key in ipairs({ "dodge", "parry", "block" }) do
                    value = text:match(key .. ".-by (%d+%.?%d*)%%")
                    if value then add(values, key, tonumber(value)) end
                end
                value = text:match("defense skill.-by (%d+)")
                if value then add(values, "defense", tonumber(value)) end
                value = text:match("restores (%d+) mana per 5 sec")
                if value then add(values, "mp5", tonumber(value)) end
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
        if stats[key] == nil or key == "armor" then
            stats[key] = value
        end
    end
    -- A percentage on the tooltip and an API rating can describe the same stat.
    for _, key in ipairs({ "hit", "crit", "haste", "dodge", "parry", "block" }) do
        if stats[key] ~= nil then
            stats[key .. "rating"] = nil
        end
    end
    for key, perPercent in pairs({ hit = 10, crit = 14, dodge = 12, parry = 15 }) do
        local ratingKey = key .. "rating"
        if stats[ratingKey] ~= nil then
            stats[key] = stats[ratingKey] / perPercent
            stats[ratingKey] = nil
        end
    end
    return stats
end

local function weaponKeys(location, slot)
    if location == "INVTYPE_2HWEAPON" then return "dps2h", "speed2h" end
    if location == "INVTYPE_RANGED" or location == "INVTYPE_RANGEDRIGHT" then
        return "dpsRanged", "speedRanged"
    end
    if location == "INVTYPE_WEAPONOFFHAND" or (location == "INVTYPE_WEAPON" and slot == 17) then
        return "dpsOH", "speedOH"
    end
    if location == "INVTYPE_WEAPON" or location == "INVTYPE_WEAPONMAINHAND" then
        return "dpsMH", "speedMH"
    end
end

local function scoreItem(stats, weights, location, slot)
    local score, unavailable = 0, {}
    for _, key in ipairs(statOrder) do
        local value = stats[key]
        if value and value ~= 0 then
            score = score + value * (weights[key] or 0)
        end
    end
    local dpsKey, speedKey = weaponKeys(location, slot)
    if dpsKey and weights[dpsKey] then
        if stats.weaponDps then
            score = score + stats.weaponDps * weights[dpsKey]
        else
            unavailable[#unavailable + 1] = "weapon DPS"
        end
    end
    if speedKey and weights[speedKey] then
        if stats.weaponSpeed then
            score = score + (stats.weaponSpeed - 2) * weights[speedKey]
        else
            unavailable[#unavailable + 1] = "weapon speed"
        end
    end
    if #unavailable > 0 then
        return nil, table.concat(unavailable, ", ") .. " unavailable"
    end
    return score
end

local function itemComparison(tooltip, location, candidateScore, weights)
    if tooltip ~= ItemRefTooltip then
        if tooltip ~= GameTooltip or type(tooltip.GetProcessingTooltipInfo) ~= "function" then return nil end
        local info = tooltip:GetProcessingTooltipInfo()
        if secret(info) or type(info) ~= "table" or secret(info.getterName) then
            return nil
        end
        local journalItem = info.getterName == "GetHyperlink" and not secret(info.compareItem)
            and info.compareItem == true
        if info.getterName ~= "GetBagItem" and not journalItem then
            return nil
        end
    end
    if type(GetInventoryItemLink) ~= "function" then return "equipped items unavailable" end

    local slots = comparisonSlots[location]
    local results = {}
    for _, slot in ipairs(slots) do
        local equipped = GetInventoryItemLink("player", slot)
        if secret(equipped) then return "equipped item unavailable" end
        local oldScore = 0
        if equipped then
            local stats = readStats(equipped)
            if not stats then return "equipped stats unavailable" end
            local missing
            oldScore, missing = scoreItem(stats, weights, itemLocation(equipped), slot)
            if missing then return "equipped item " .. missing end
        end

        if slot == 17 then
            local main = GetInventoryItemLink("player", 16)
            if secret(main) then return "main hand unavailable" end
            if main then
                local mainLocation = itemLocation(main)
                if not mainLocation then return "main hand data unavailable" end
                if mainLocation == "INVTYPE_2HWEAPON" then return "requires a one-hand weapon" end
            end
        elseif location == "INVTYPE_2HWEAPON" then
            local offhand = GetInventoryItemLink("player", 17)
            if secret(offhand) then return "off hand unavailable" end
            if offhand then
                local stats = readStats(offhand)
                if not stats then return "off-hand stats unavailable" end
                local offScore, missing = scoreItem(stats, weights, itemLocation(offhand), 17)
                if missing then return "off hand " .. missing end
                oldScore = oldScore + offScore
            end
        end

        local delta = candidateScore - oldScore
        local formatted = string.format("%+.2f", delta)
        local color
        if formatted ~= "+0.00" and formatted ~= "-0.00" then
            color = delta > 0 and "ff40ff40" or "ffff4040"
        end
        if #slots == 2 then
            local value = color and ("|c" .. color .. formatted .. "|r") or formatted
            results[#results + 1] = string.format("slot %d: %s", #results + 1, value)
        else
            return formatted, color
        end
    end
    return table.concat(results, ", ")
end

local function compare(tooltip, data)
    if not CompareDPSDB then return end
    local link = getLink(tooltip, data)
    if not link then
        local id = type(data) == "table" and data.id
        if not secret(id) and type(id) == "number" and id > 0 then
            tooltip:AddLine("CompareDPS: item link unavailable", 1, 0.7, 0.2)
        end
        return
    end
    local location = itemLocation(link)
    local slotName = location and slotNames[location]
    if not slotName then return end
    local compatible = canEquipForClass(link, location)
    if compatible == false then return end

    local weights, label = activeWeights()
    tooltip:AddLine("CompareDPS", 0.8, 0.65, 0.25)
    if compatible == nil then
        tooltip:AddLine("Item compatibility unavailable; try again.", 1, 0.7, 0.2)
        return
    end
    if not weights or not next(weights) then
        tooltip:AddLine("Choose a spec using the minimap button.", 1, 0.7, 0.2)
        return
    end
    tooltip:AddLine(label, 0.7, 0.8, 1)
    local candidate = readStats(link)
    if not candidate then
        tooltip:AddLine("Item stats unavailable; try again.", 1, 0.7, 0.2)
        return
    end
    local info = type(tooltip.GetProcessingTooltipInfo) == "function" and tooltip:GetProcessingTooltipInfo()
    local slot
    if not secret(info) and type(info) == "table" and info.getterName == "GetInventoryItem"
        and type(info.getterArgs) == "table" then
        local inventorySlot = info.getterArgs[2]
        if not secret(inventorySlot) and type(inventorySlot) == "number" then slot = inventorySlot end
    end
    if location == "INVTYPE_WEAPON" then
        slotName = slot == 17 and "Off hand" or "Main hand"
    end
    local candidateScore, candidateMissing = scoreItem(candidate, weights, location, slot)
    if candidateMissing then
        tooltip:AddLine(slotName .. ": " .. candidateMissing, 1, 0.7, 0.2)
    else
        local comparison, color = itemComparison(tooltip, location, candidateScore, weights)
        local suffix = comparison and (" (" .. comparison .. ")") or ""
        local r, g, b = 1, 1, 1
        if color == "ff40ff40" then r, g, b = 0.25, 1, 0.25 end
        if color == "ffff4040" then r, g, b = 1, 0.25, 0.25 end
        tooltip:AddLine(string.format("%s: %.2f points%s", slotName, candidateScore, suffix), r, g, b, true)
    end
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
            message(name .. ": " .. tostring(weight or 0))
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
        if tooltip == GameTooltip or tooltip == ItemRefTooltip
            or tooltip == ShoppingTooltip1 or tooltip == ShoppingTooltip2
            or tooltip == ItemRefShoppingTooltip1 or tooltip == ItemRefShoppingTooltip2 then
            compare(tooltip, data)
        end
    end)
end)
