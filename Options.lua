local _, addon = ...

local window, optionsPanel, minimapButton
local views = {}
local editingView, editingProfile, editingDynamic

local specIcons = {
    HUNTER = { beastmastery = "Ability_Hunter_BeastTaming", marksmanship = "Ability_Marksmanship",
        survival = "Ability_Hunter_SwiftStrike" },
    MAGE = { arcane = "Spell_Holy_MagicalSentry", fire = "Spell_Fire_FireBolt02", frost = "Spell_Frost_FrostBolt02" },
    ROGUE = { assassination = "Ability_Rogue_Eviscerate", combat = "Ability_BackStab", subtlety = "Ability_Stealth" },
    WARRIOR = { arms = "Ability_Warrior_SavageBlow", fury = "Ability_Warrior_InnerRage",
        protection = "Ability_Warrior_DefensiveStance" },
    SHAMAN = { elemental = "Spell_Nature_Lightning", enhancement = "Spell_Nature_LightningShield",
        restoration = "Spell_Nature_MagicImmunity" },
    PALADIN = { holy = "Spell_Holy_HolyBolt", protection = "Spell_Holy_DevotionAura", retribution = "Spell_Holy_AuraOfLight" },
    PRIEST = { discipline = "Spell_Holy_WordFortitude", holy = "Spell_Holy_HolyBolt", shadow = "Spell_Shadow_ShadowWordPain" },
    DRUID = { balance = "Spell_Nature_StarFall", feral = "Ability_Druid_CatForm", feraltank = "Ability_Racial_BearForm",
        restoration = "Spell_Nature_HealingTouch" },
    WARLOCK = { affliction = "Spell_Shadow_DeathCoil", demonology = "Spell_Shadow_Metamorphosis",
        destruction = "Spell_Shadow_RainOfFire" },
}

local function profileIcon(key)
    local _, class = UnitClass("player")
    local name = specIcons[class] and specIcons[class][key]
    return "Interface\\Icons\\" .. (name or "INV_Misc_Book_09")
end

local function dialogBackground(frame)
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
    else
        local texture = frame:CreateTexture(nil, "BACKGROUND")
        texture:SetPoint("TOPLEFT", 4, -4)
        texture:SetPoint("BOTTOMRIGHT", -4, 4)
        texture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    end
end

local statLabels = {
    str = "Strength", agi = "Agility", ap = "Attack power",
    rap = "Ranged attack power", fap = "Feral attack power",
    spellpower = "Spell power", heal = "Healing power", spellpen = "Spell penetration",
    shadow = "Shadow spell power", fire = "Fire spell power", frost = "Frost spell power",
    arcane = "Arcane spell power", nature = "Nature spell power", holy = "Holy spell power",
    int = "Intellect", spirit = "Spirit", stamina = "Stamina", mana = "Mana", health = "Health",
    hit = "Hit (1%)", crit = "Crit (1%)", haste = "Haste (1%)",
    hitrating = "Hit rating", critrating = "Crit rating", hasterating = "Haste rating",
    mp5 = "Mana per 5 seconds", hp5 = "Health per 5 seconds", armor = "Armor",
    defense = "Defense skill", defenserating = "Defense rating",
    dodge = "Dodge (1%)", dodgerating = "Dodge rating",
    parry = "Parry (1%)", parryrating = "Parry rating",
    block = "Block (1%)", blockrating = "Block rating", blockValue = "Block value",
    weaponDps = "Weapon DPS", dpsMH = "Main-hand DPS", dpsOH = "Off-hand DPS",
    dps2h = "Two-hand DPS", dpsRanged = "Ranged / wand DPS",
    speedMH = "Main-hand speed (seconds)", speedOH = "Off-hand speed (seconds)",
    speed2h = "Two-hand speed (seconds)", speedRanged = "Ranged speed (seconds)",
}

local statGroups = {
    { "str", "agi", "stamina", "int", "spirit" },
    { "hit", "hitrating", "crit", "critrating", "haste", "hasterating" },
    { "ap", "rap", "fap" },
    { "spellpower", "heal", "arcane", "fire", "frost", "holy", "nature", "shadow", "spellpen" },
    { "weaponDps" },
    { "dpsMH", "speedMH" },
    { "dpsOH", "speedOH" },
    { "dps2h", "speed2h" },
    { "dpsRanged", "speedRanged" },
    { "armor", "defense", "defenserating", "dodge", "dodgerating",
        "parry", "parryrating", "block", "blockrating", "blockValue" },
    { "health", "hp5", "mana", "mp5" },
}

local function orderedStats(weights)
    local keys, boundaries, seen = {}, {}, {}
    for _, group in ipairs(statGroups) do
        local count = #keys
        for _, key in ipairs(group) do
            seen[key] = true
            if weights[key] ~= nil then keys[#keys + 1] = key end
        end
        if #keys > count then boundaries[#boundaries + 1] = #keys end
    end
    local extra = {}
    for key in pairs(weights) do
        if not seen[key] then extra[#extra + 1] = key end
    end
    table.sort(extra, function(a, b) return (statLabels[a] or a) < (statLabels[b] or b) end)
    for _, key in ipairs(extra) do
        keys[#keys + 1] = key
        boundaries[#boundaries + 1] = #keys
    end
    -- Balance columns only at group boundaries so related stats stay together.
    local split = #keys
    for _, boundary in ipairs(boundaries) do
        if math.abs(boundary - #keys / 2) < math.abs(split - #keys / 2) then split = boundary end
    end
    return keys, split
end

local function closeMenu()
    for _, view in ipairs(views) do view.menu:Hide() end
end

local function cancelEditing()
    if editingView then
        for _, row in ipairs(editingView.rows) do row.input:ClearFocus() end
    end
    editingView, editingProfile, editingDynamic = nil, nil, nil
end

function addon.refreshOptions()
    local profiles = addon.classProfiles()
    local profile = profiles and profiles[CompareDPSDB.profile]
    local baseWeights = profile and (CompareDPSDB.customWeights and CompareDPSDB.customWeights[CompareDPSDB.profile] or profile.weights)
    local weights, _, dynamicError = addon.activeWeights()
    local dynamic = CompareDPSDB.dynamicWeights == true
    if editingProfile and (editingProfile ~= profile or editingDynamic ~= dynamic) then cancelEditing() end
    local keys, split, editableCount = {}, 0, 0
    if profile then
        keys, split = orderedStats(profile.weights)
        for _, key in ipairs(keys) do
            if not dynamic or not addon.isDynamicLocked(key) then editableCount = editableCount + 1 end
        end
    end
    local rowCount = math.max(split, #keys - split)
    for _, view in ipairs(views) do
        local editing = editingView == view
        view.portrait:SetTexture(profileIcon(CompareDPSDB.profile))
        local className, class = UnitClass("player")
        view.className:SetText(className or "")
        local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if color then view.className:SetTextColor(color.r, color.g, color.b) end
        view.dynamic:SetChecked(dynamic)
        view.dropdown:SetText(profile and (profile.label .. "  v")
            or (profiles and "Select specialization  v" or "No supported specializations"))
        view.heading:SetText(profile and (profile.label .. (dynamic and " dynamic weights" or " stat weights"))
            or "No specialization selected")
        view.empty:SetText(profiles and "Select a specialization to see its stat weights."
            or "No profiles are available for your class.")
        if profile then view.empty:Hide() else view.empty:Show() end
        for i, key in ipairs(keys) do
            local row = view.rows[i]
            if not row then
                row = {
                    label = view.parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall"),
                    value = view.parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall"),
                }
                row.label:SetJustifyH("LEFT")
                row.label:SetWidth(210)
                row.value:SetJustifyH("RIGHT")
                row.value:SetWidth(48)
                row.input = CreateFrame("EditBox", nil, view.parent, "InputBoxTemplate")
                row.input:SetSize(60, 20)
                row.input:SetAutoFocus(false)
                row.input:SetScript("OnEscapePressed", function()
                    cancelEditing()
                    addon.refreshOptions()
                end)
                view.rows[i] = row
            end
            local column = i > split and 1 or 0
            local index = column == 1 and (i - split) or i
            row.label:ClearAllPoints()
            row.value:ClearAllPoints()
            row.input:ClearAllPoints()
            row.label:SetPoint("TOPLEFT", view.parent, "TOPLEFT", 20 + column * 280, -188 - (index - 1) * 20)
            row.value:SetPoint("TOPLEFT", view.parent, "TOPLEFT", 230 + column * 280, -188 - (index - 1) * 20)
            row.input:SetPoint("TOPLEFT", view.parent, "TOPLEFT", 224 + column * 280, -184 - (index - 1) * 20)
            row.key = key
            local locked = dynamic and addon.isDynamicLocked(key)
            row.label:SetText((statLabels[key] or key) .. (locked and " (locked)" or ""))
            local shade = locked and 0.55 or 1
            row.label:SetTextColor(shade, shade, shade)
            row.value:SetTextColor(shade, shade, shade)
            local value = weights and weights[key] or (not locked and baseWeights[key])
            row.value:SetText(value and string.format("%.1f", value) or "N/A")
            row.label:Show()
            if editing and not locked then
                if not row.input:IsShown() then row.input:SetText(tostring(baseWeights[key])) end
                row.input:Show()
                row.value:Hide()
            else
                row.input:Hide()
                row.value:Show()
            end
        end
        for i = #keys + 1, #view.rows do
            view.rows[i].label:Hide()
            view.rows[i].value:Hide()
            view.rows[i].input:Hide()
        end
        local buttonY = -math.max(244, 208 + rowCount * 20)
        for i, button in ipairs({ view.edit, view.save, view.cancel, view.reset }) do
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", view.parent, "TOPLEFT", 20 + (i - 1) * 132, buttonY)
        end
        if profile then
            view.reset:Show()
            if editableCount > 0 then view.edit:Enable(); view.reset:Enable()
            else view.edit:Disable(); view.reset:Disable() end
            if editing then
                view.edit:Hide()
                view.save:Show()
                view.cancel:Show()
            else
                view.edit:Show()
                view.save:Hide()
                view.cancel:Hide()
            end
        else
            view.edit:Hide()
            view.save:Hide()
            view.cancel:Hide()
            view.reset:Hide()
        end
        view.status:SetText(dynamicError and ("Dynamic weights unavailable: " .. dynamicError)
            or addon.dynamicSummary(weights) or (editing and "Editing: changes apply only after Save." or ""))
        view.status:ClearAllPoints()
        view.status:SetPoint("TOPLEFT", view.parent, "TOPLEFT", 20, buttonY - 32)
        view.status:SetPoint("RIGHT", view.parent, "RIGHT", -20, 0)
        view.note:ClearAllPoints()
        view.note:SetPoint("TOPLEFT", view.parent, "TOPLEFT", 20, buttonY - 140)
        view.note:SetPoint("RIGHT", view.parent, "RIGHT", -20, 0)
    end
    if window then window:SetHeight(math.max(484, 428 + rowCount * 20)) end
end

local function makeContent(parent, standalone)
    local view = { parent = parent, rows = {} }
    local items = {}
    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    if standalone then title:SetPoint("TOP", 0, -3)
    else title:SetPoint("TOPLEFT", 18, -16) end
    title:SetText("CompareDPS")

    view.portrait = parent:CreateTexture(nil, "ARTWORK")
    view.portrait:SetSize(44, 44)
    view.portrait:SetPoint("TOPLEFT", 22, -46)
    local portraitBorder = parent:CreateTexture(nil, "OVERLAY")
    portraitBorder:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    portraitBorder:SetSize(72, 72)
    portraitBorder:SetPoint("CENTER", view.portrait, "CENTER", 0, 0)
    view.className = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    view.className:SetPoint("TOPRIGHT", -26, -55)

    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", 84, -44)
    label:SetText("Specialization:")

    local dropdown = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    dropdown:SetSize(210, 24)
    dropdown:SetPoint("TOPLEFT", 84, -64)

    local menu = CreateFrame("Frame", nil, parent)
    menu:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    menu:SetWidth(210)
    menu:SetFrameLevel(dropdown:GetFrameLevel() + 2)
    menu:Hide()
    view.dropdown, view.menu = dropdown, menu
    view.dynamic = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    view.dynamic:SetSize(26, 26)
    view.dynamic:SetPoint("TOPLEFT", 18, -94)
    local dynamicLabel = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    dynamicLabel:SetPoint("LEFT", view.dynamic, "RIGHT", 4, 0)
    dynamicLabel:SetText("Dynamic weights")
    view.dynamic:SetScript("OnClick", function(self)
        closeMenu()
        cancelEditing()
        addon.setDynamicWeights(not not self:GetChecked())
    end)
    views[#views + 1] = view

    dropdown:SetScript("OnClick", function()
        if menu:IsShown() then closeMenu(); return end
        closeMenu()
        local profiles = addon.classProfiles()
        local keys = {}
        if profiles then
            for key in pairs(profiles) do keys[#keys + 1] = key end
            table.sort(keys)
        end
        if #keys == 0 then
            dropdown:SetText("No supported specializations")
            return
        end
        for i, key in ipairs(keys) do
            local choice = items[i]
            if not choice then
                choice = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
                choice:SetSize(210, 24)
                choice:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, -(i - 1) * 24)
                choice.icon = choice:CreateTexture(nil, "ARTWORK")
                choice.icon:SetSize(18, 18)
                choice.icon:SetPoint("LEFT", 5, 0)
                items[i] = choice
            end
            choice.icon:SetTexture(profileIcon(key))
            choice:SetText(profiles[key].label)
            choice:SetScript("OnClick", function()
                addon.selectProfile(key)
                closeMenu()
            end)
            choice:Show()
        end
        for i = #keys + 1, #items do items[i]:Hide() end
        menu:SetHeight(#keys * 24)
        menu:Show()
    end)

    view.heading = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    view.heading:SetPoint("TOPLEFT", 20, -128)
    local units = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    units:SetPoint("TOPLEFT", 20, -154)
    units:SetText("Relative gear points per unit; percentages are per 1 percentage point.")
    view.empty = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    view.empty:SetPoint("TOPLEFT", 20, -188)

    local note = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetJustifyH("LEFT")
    note:SetText("Unlisted stats have weight 0. Settings are saved per character. Dynamic uses experimental Classic caps, not verified Forever formulas.\nIn Dynamic mode, Edit and Reset affect uncapped stats only; locked weights ignore custom overrides. Item deltas account for crossing caps. See README for limits.")
    view.note = note
    view.status = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    view.status:SetJustifyH("LEFT")
    local function button(text, handler)
        local control = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        control:SetSize(124, 24)
        control:SetText(text)
        control:SetScript("OnClick", handler)
        return control
    end
    view.edit = button("Edit", function()
        closeMenu()
        cancelEditing()
        addon.refreshOptions()
        editingView = view
        local profiles = addon.classProfiles()
        editingProfile = profiles and profiles[CompareDPSDB.profile]
        editingDynamic = CompareDPSDB.dynamicWeights == true
        addon.refreshOptions()
    end)
    view.save = button("Save", function()
        local values = {}
        for _, row in ipairs(view.rows) do
            if row.input:IsShown() then
                local value = tonumber(row.input:GetText())
                if not value or value ~= value or value == math.huge or value == -math.huge then
                    view.status:SetText("Invalid weight for " .. (statLabels[row.key] or row.key) .. ": enter a finite number.")
                    row.input:SetFocus()
                    return
                end
                values[row.key] = value
            end
        end
        local saved, errorMessage = addon.saveWeights(values)
        if not saved then view.status:SetText(errorMessage); return end
        cancelEditing()
        addon.refreshOptions()
    end)
    view.cancel = button("Cancel", function()
        cancelEditing()
        addon.refreshOptions()
    end)
    view.reset = button("Reset to Default", function()
        local reset, errorMessage = addon.resetWeights()
        if not reset then view.status:SetText(errorMessage); return end
        cancelEditing()
        addon.refreshOptions()
    end)
    parent:SetScript("OnShow", addon.refreshOptions)
    local elapsed = 0
    parent:SetScript("OnUpdate", function(_, seconds)
        if not CompareDPSDB.dynamicWeights then return end
        elapsed = elapsed + seconds
        if elapsed >= 0.5 then
            elapsed = 0
            addon.refreshOptions()
        end
    end)
    parent:SetScript("OnHide", function()
        closeMenu()
        if editingView == view then
            cancelEditing()
            addon.refreshOptions()
        end
    end)
end

local function makeWindow()
    if window then return end
    window = CreateFrame("Frame", "CompareDPSOptions", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    window:SetSize(580, 440)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetClampedToScreen(true)
    dialogBackground(window)
    local header = window:CreateTexture(nil, "ARTWORK")
    header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    header:SetSize(256, 64)
    header:SetPoint("TOP", 0, 16)
    makeContent(window, true)
    local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 0, 0)
    close:SetScript("OnClick", function() window:Hide() end)
    window:Hide()
    addon.refreshOptions()
end

function addon.toggleOptions()
    makeWindow()
    if window:IsShown() then
        window:Hide()
    else
        addon.refreshOptions()
        window:Show()
    end
end

function addon.initializeOptions()
    if not optionsPanel then
        optionsPanel = CreateFrame("Frame", "CompareDPSSettingsPanel", UIParent)
        optionsPanel.name = "CompareDPS"
        optionsPanel:Hide()
        makeContent(optionsPanel)
        if Settings and type(Settings.RegisterCanvasLayoutCategory) == "function"
            and type(Settings.RegisterAddOnCategory) == "function" then
            local category = Settings.RegisterCanvasLayoutCategory(optionsPanel, "CompareDPS")
            Settings.RegisterAddOnCategory(category)
        elseif type(InterfaceOptions_AddCategory) == "function" then
            InterfaceOptions_AddCategory(optionsPanel)
        else
            print("|cff80cfffCompareDPS:|r AddOns options registration unavailable; use /compare.")
        end
        addon.refreshOptions()
    end
    if minimapButton then return end
    local minimap = Minimap or (MinimapCluster and MinimapCluster.Minimap)
    if not minimap then
        print("|cff80cfffCompareDPS:|r Minimap unavailable; use /compare to choose a spec.")
        return
    end
    minimapButton = CreateFrame("Button", "CompareDPSMinimapButton", minimap)
    minimapButton:SetSize(31, 31)
    minimapButton:SetFrameStrata("MEDIUM")
    minimapButton:SetFrameLevel(minimap:GetFrameLevel() + 8)
    minimapButton:SetPoint("TOPRIGHT", minimap, "TOPRIGHT", 0, 0)
    minimapButton:RegisterForClicks("LeftButtonUp")
    local icon = minimapButton:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\Spell_Shadow_ShadowBolt")
    icon:SetSize(17, 17)
    icon:SetPoint("TOPLEFT", 7, -6)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local border = minimapButton:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT", 0, 0)
    minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    minimapButton:SetScript("OnClick", addon.toggleOptions)
    minimapButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("CompareDPS")
        GameTooltip:AddLine("Click to choose a specialization and view stat weights.", 1, 1, 1)
        GameTooltip:Show()
    end)
    minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
end
