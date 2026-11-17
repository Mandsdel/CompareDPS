local _, addon = ...

local bossLevel, bossSkill = 63, 315
local modeled = { hit = true, crit = true, defense = true, dodge = true,
    parry = true, block = true, armor = true, spellpen = true }
local schools = { arcane = 7, fire = 3, frost = 5, elemental = 4, restoration = 4,
    balance = 4, shadow = 6, affliction = 6, demonology = 6, destruction = 3 }
local weaponSkills = { axes = true, swords = true, maces = true, daggers = true,
    ["two-handed axes"] = true, ["two-handed swords"] = true, ["two-handed maces"] = true,
    ["fist weapons"] = true, unarmed = true, polearms = true, staves = true,
    bows = true, guns = true, crossbows = true, thrown = true, wands = true }

function addon.isWeaponSkillBonus(text)
    return text:find("skill with", 1, true) or text:find("weapon skill", 1, true)
        or weaponSkills[text:match("^equip:%s+increased (.-) %+%d+")]
end

function addon.isDynamicLocked(key)
    return modeled[key] == true
end

local function number(value)
    return not (type(issecretvalue) == "function" and issecretvalue(value))
        and type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

local function read(name, ...)
    if type(_G[name]) ~= "function" then return nil, name .. " unavailable" end
    local value = _G[name](...)
    if not number(value) then return nil, name .. " returned unavailable/restricted data" end
    return value
end

local function skill(name, hand)
    if type(_G[name]) ~= "function" then return nil, name .. " unavailable" end
    local base, modifier, offBase, offModifier = _G[name]("player")
    if hand == 17 then base, modifier = offBase, offModifier end
    if not number(base) or not number(modifier) then
        return nil, name .. " returned unavailable/restricted skill data"
    end
    return base + modifier, nil, base
end

function addon.dynamicRatingPerPercent(key)
    local constants = { hit = "CR_HIT_MELEE", hitMelee = "CR_HIT_MELEE",
        hitRanged = "CR_HIT_RANGED", hitSpell = "CR_HIT_SPELL",
        crit = "CR_CRIT_MELEE", critMelee = "CR_CRIT_MELEE",
        critRanged = "CR_CRIT_RANGED", critSpell = "CR_CRIT_SPELL",
        dodge = "CR_DODGE", parry = "CR_PARRY", block = "CR_BLOCK", haste = "CR_HASTE_MELEE" }
    local id = _G[constants[key] or ""]
    if not number(id) or type(GetCombatRating) ~= "function"
        or type(GetCombatRatingBonus) ~= "function" then return nil end
    local rating, bonus = GetCombatRating(id), GetCombatRatingBonus(id)
    if number(rating) and number(bonus) and rating > 0 and bonus > 0 then return rating / bonus end
end

local function hitBonus(domain)
    local value, reason = read(domain == "Spell" and "GetSpellHitModifier" or "GetHitModifier")
    if not value then return nil, reason end
    local constant = _G["CR_HIT_" .. domain:upper()]
    if type(GetCombatRatingBonus) == "function" and not number(constant) then
        return nil, "CR_HIT_" .. domain:upper() .. " unavailable"
    end
    if number(constant) and type(GetCombatRatingBonus) == "function" then
        local bonus
        bonus, reason = read("GetCombatRatingBonus", constant)
        if not bonus then return nil, reason end
        value = value + bonus
    end
    return value
end

function addon.readDynamicState(domain, profile)
    local state = { domain = domain, tank = profile == "protection" or profile == "feraltank",
        healer = profile == "holy" or profile == "discipline" or profile == "restoration",
        feral = profile == "feral" or profile == "feraltank" }
    local reason
    state.level, reason = read("UnitLevel", "player")
    if not state.level then return nil, reason end
    if state.level < 1 or state.level > 60 then return nil, "Classic fallback supports player levels 1-60 only" end
    if state.healer then state.hit = 0 else state.hit, reason = hitBonus(domain) end
    if not state.hit then return nil, reason end
    if domain == "Spell" then
        state.crit, reason = read("GetSpellCritChance", schools[profile] or 2)
    else
        state.crit, reason = read(domain == "Ranged" and "GetRangedCritChance" or "GetCritChance")
        if not state.crit then return nil, reason end
        if state.feral then
            state.skill, state.offSkill, state.dual = state.level * 5, state.level * 5, false
        elseif domain == "Melee" then
            state.skill, reason = skill("UnitAttackBothHands")
            if not state.skill then return nil, reason end
            if type(UnitAttackSpeed) ~= "function" then return nil, "UnitAttackSpeed unavailable" end
            local _, speed = UnitAttackSpeed("player")
            if type(issecretvalue) == "function" and issecretvalue(speed) then
                return nil, "off-hand attack speed is restricted"
            end
            if speed ~= nil and not number(speed) then return nil, "off-hand attack speed unavailable" end
            state.dual = number(speed) and speed > 0
            if state.dual then
                state.offSkill, reason = skill("UnitAttackBothHands", 17)
                if not state.offSkill or state.offSkill <= 0 then return nil, reason or "off-hand skill unavailable" end
            else
                state.offSkill = state.skill
            end
        else
            state.skill, reason = skill("UnitRangedAttack")
            if not state.skill then return nil, reason end
        end
    end
    if not state.crit then return nil, reason end
    if state.skill and state.skill <= 0 then return nil, "equipped weapon skill unavailable; equip a weapon first" end
    if type(UnitArmor) ~= "function" then return nil, "UnitArmor unavailable" end
    local _, armor = UnitArmor("player")
    if not number(armor) then return nil, "effective armor unavailable/restricted" end
    state.armor = armor
    if state.tank then
        state.defense, reason, state.baseDefense = skill("UnitDefense")
        if not state.defense then return nil, reason end
        for key, api in pairs({ dodge = "GetDodgeChance", parry = "GetParryChance", block = "GetBlockChance" }) do
            state[key], reason = read(api)
            if not state[key] then return nil, reason end
        end
        state.canParry = state.parry > 0
        state.canBlock = state.block > 0
    end
    return state
end

function addon.dynamicCaps(state, hand)
    if state.domain == "Spell" then
        local difference = bossLevel - state.level
        local miss = difference > 2 and (17 + (difference - 3) * 11) or (4 + difference)
        return { hit = clamp(miss - 1, 0, 98), whiteHit = clamp(miss - 1, 0, 98), crit = 100 }
    end
    local weaponSkill = hand == 17 and state.offSkill or state.skill
    local difference = bossSkill - weaponSkill
    local miss = difference > 10 and (5 + difference * 0.2)
        or (difference >= 0 and (5 + difference * 0.1) or (5 + difference * 0.04))
    local ignoredHit = difference > 10 and 1 or 0
    local special = math.max(0, miss + ignoredHit)
    local white = special + (state.domain == "Melee" and state.dual and 19 or 0)
    local dodge = state.domain == "Melee" and math.max(0, 5 + difference * (difference >= 0 and 0.1 or 0.04)) or 0
    local parry = state.tank and math.max(0, 14 - (weaponSkill - state.level * 5) * 0.1) or 0
    local glance = state.domain == "Melee" and clamp(10 + 2 * (bossSkill - math.min(state.level * 5, weaponSkill)), 0, 40) or 0
    local suppression = math.max(0, bossLevel - state.level) * 1.6
    local whiteMiss = math.max(0, white - ignoredHit - math.max(0, state.hit - ignoredHit))
    return { hit = special, whiteHit = white, crit = math.max(0, 100 - whiteMiss - dodge - parry - glance + suppression),
        ignoredHit = ignoredHit, suppression = suppression, dodge = dodge, parry = parry, glance = glance }
end

local function defensive(state, changes)
    local defense = state.defense + (changes.defense or 0)
    local defenseDelta = (changes.defense or 0) * 0.04
    local levelPenalty = (bossLevel - state.level) * 0.2
    local miss = clamp(5 + (defense - bossSkill) * 0.04, 0, 100)
    local dodge = clamp(state.dodge + (changes.dodge or 0) + defenseDelta - levelPenalty, 0, 100 - miss)
    local parry = state.canParry and clamp(state.parry + (changes.parry or 0) + defenseDelta - levelPenalty, 0, 100 - miss - dodge) or 0
    local block = state.canBlock and clamp(state.block + (changes.block or 0) + defenseDelta - levelPenalty, 0, 100 - miss - dodge - parry) or 0
    local coverage = math.min(100, miss + dodge + parry + block)
    local crit = math.min(math.max(0, 5 + (bossSkill - defense) * 0.04), 100 - coverage)
    local baseDefense = math.min(state.baseDefense or state.level * 5, state.level * 5)
    local baseCrush = clamp(2 * (bossSkill - baseDefense) - 15, 0, 100)
    return { miss = miss, dodge = dodge, parry = parry, block = block, coverage = coverage,
        crit = crit, crush = math.min(baseCrush, math.max(0, 100 - coverage - crit)) }
end

local function potential(context, changes)
    local state, base = context.state, context.base
    local projected = {}
    for key, value in pairs(state) do projected[key] = value end
    projected.hit = state.hit + (changes.hit or 0)
    projected.crit = state.crit + (changes.crit or 0)
    local caps = addon.dynamicCaps(projected)
    local result = 0
    if state.domain == "Spell" then
        if not state.healer then result = math.min(projected.hit, caps.hit) * (base.hit or 0) end
        result = result + clamp(projected.crit, 0, 100) * (base.crit or 0)
    else
        -- Equal white/special shares are a declared estimate, not a rotation simulation.
        local whiteShare = state.domain == "Melee" and 0.5 or 0
        local function usefulHit(attackCaps, cap)
            return math.min(math.max(0, projected.hit - attackCaps.ignoredHit), cap - attackCaps.ignoredHit)
        end
        local crit = math.max(0, projected.crit - caps.suppression)
        local whiteHit = usefulHit(caps, caps.whiteHit)
        local whiteCrit = math.min(crit, math.max(0, caps.crit - caps.suppression))
        if state.dual then
            local offCaps = addon.dynamicCaps(projected, 17)
            whiteHit = (whiteHit + usefulHit(offCaps, offCaps.whiteHit)) / 2
            whiteCrit = (whiteCrit + math.min(crit, math.max(0, offCaps.crit - offCaps.suppression))) / 2
        end
        result = ((1 - whiteShare) * usefulHit(caps, caps.hit)
            + whiteShare * whiteHit) * (base.hit or 0)
        result = result + ((1 - whiteShare) * math.min(crit, 100)
            + whiteShare * whiteCrit) * (base.crit or 0)
    end
    if state.tank then
        local defense = defensive(state, changes)
        -- All full-avoidance outcomes prevent the same hit. Different prices would
        -- incorrectly penalize defense when miss pushes dodge off a full table.
        local avoidanceWeight = math.max(base.dodge or 0, state.canParry and (base.parry or 0) or 0)
        result = result + (defense.miss + defense.dodge + defense.parry) * avoidanceWeight
            + defense.block * (base.block or 0) - defense.crit * (base.defense or 0) / 0.08
            - defense.crush * avoidanceWeight / 2
    else
        for _, key in ipairs({ "defense", "dodge", "parry", "block" }) do
            result = result + (changes[key] or 0) * (base[key] or 0)
        end
    end
    result = result + clamp(state.armor + (changes.armor or 0), 0, 3 * (400 + 85 * bossLevel)) * (base.armor or 0)
    return result
end

function addon.dynamicWeaponCheck(context, link, location, slot)
    local state = context.state
    if state.feral or state.domain == "Spell" then return nil end
    if state.domain == "Ranged" then
        if location ~= "INVTYPE_RANGED" and location ~= "INVTYPE_RANGEDRIGHT" then return nil end
        slot = 18
    else
        if location == "INVTYPE_WEAPON" then slot = slot or 16 end
        if location == "INVTYPE_2HWEAPON" or location == "INVTYPE_WEAPONMAINHAND" then slot = 16 end
        if location == "INVTYPE_WEAPONOFFHAND" or location == "INVTYPE_HOLDABLE" or location == "INVTYPE_SHIELD" then slot = 17 end
        if slot ~= 16 and slot ~= 17 then return nil end
    end
    if type(GetInventoryItemLink) ~= "function" then return "equipped weapon data unavailable" end
    local equipped = GetInventoryItemLink("player", slot)
    if type(issecretvalue) == "function" and issecretvalue(equipped) then return "equipped weapon data is restricted" end
    if not equipped then return "weapon setup changes require equipping first to read live skills/caps" end
    local _, _, _, oldLocation, _, oldClass, oldType = C_Item.GetItemInfoInstant(equipped)
    local _, _, _, _, _, newClass, newType = C_Item.GetItemInfoInstant(link)
    for _, value in ipairs({ oldLocation, oldClass, oldType, newClass, newType }) do
        if type(issecretvalue) == "function" and issecretvalue(value) then return "weapon type data is restricted" end
    end
    if not number(oldClass) or not number(oldType) or not number(newClass) or not number(newType) then
        return "weapon type data unavailable"
    end
    if oldClass ~= newClass or oldType ~= newType
        or (oldLocation == "INVTYPE_2HWEAPON") ~= (location == "INVTYPE_2HWEAPON") then
        return "weapon setup changes require equipping first to read live skills/caps"
    end
end

function addon.dynamicScore(context, changes, linearScore)
    for key in pairs(modeled) do
        linearScore = linearScore - (changes[key] or 0) * (context.base[key] or 0)
    end
    return linearScore + potential(context, changes) - potential(context, {})
end

function addon.makeDynamicWeights(base, state)
    local context = { base = base, state = state }
    local weights = { dynamicContext = context }
    for key, value in pairs(base) do
        weights[key] = modeled[key] and addon.dynamicScore(context, { [key] = 0.01 }, value * 0.01) / 0.01 or value
        if math.abs(weights[key]) < 0.000001 then weights[key] = 0 end
    end
    return weights
end

function addon.dynamicWeights(base, domain, profile)
    local state, reason = addon.readDynamicState(domain, profile)
    if not state then return nil, reason end
    return addon.makeDynamicWeights(base, state)
end

function addon.dynamicSummary(weights)
    local context = weights and weights.dynamicContext
    if not context then return nil end
    local state = context.state
    local caps = addon.dynamicCaps(state)
    local text = string.format("Experimental Classic fallback vs level 63. Hit %.1f%% / %.1f%%", state.hit, caps.hit)
    if state.dual then text = text .. string.format(" special, %.1f%% white", caps.whiteHit) end
    text = text .. string.format("; crit %.1f%%", state.crit)
    if state.skill then
        text = text .. string.format("; weapon skill %.0f; white crit cap %.1f%%", state.skill, caps.crit)
        if state.dual and state.offSkill ~= state.skill then
            local offCaps = addon.dynamicCaps(state, 17)
            text = text .. string.format(" (off-hand skill %.0f, hit %.1f%%, crit %.1f%%)",
                state.offSkill, offCaps.whiteHit, offCaps.crit)
        end
    end
    if state.tank then
        local defense = defensive(state, {})
        text = text .. string.format(". Defense %.0f / 440 (%s); boss coverage %.1f%% / 100%% (%s); armor %.0f / 17265",
            state.defense, defense.crit < 0.000001 and "crit immune" or "crit vulnerable", defense.coverage,
            defense.crush < 0.000001 and "crush table covered" or "crush vulnerable", state.armor)
    end
    return text .. ". Snapshot includes active buffs; not simulated DPS."
end
