local _, addon = ...

local window, optionsPanel, minimapButton
local views = {}

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

local function closeMenu()
    for _, view in ipairs(views) do view.menu:Hide() end
end

function addon.refreshOptions()
    local profiles = addon.classProfiles()
    local profile = profiles and profiles[CompareDPSDB.profile]
    local keys = {}
    if profile then
        for key in pairs(profile.weights) do keys[#keys + 1] = key end
        table.sort(keys, function(a, b)
            return (statLabels[a] or a) < (statLabels[b] or b)
        end)
    end
    local rowCount = math.ceil(#keys / 2)
    for _, view in ipairs(views) do
        view.dropdown:SetText(profile and (profile.label .. "  v")
            or (profiles and "Select specialization  v" or "No supported specializations"))
        view.heading:SetText(profile and (profile.label .. " stat weights")
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
                view.rows[i] = row
            end
            local column = i > rowCount and 1 or 0
            local index = column == 1 and (i - rowCount) or i
            row.label:ClearAllPoints()
            row.value:ClearAllPoints()
            row.label:SetPoint("TOPLEFT", view.parent, "TOPLEFT", 20 + column * 280, -164 - (index - 1) * 20)
            row.value:SetPoint("TOPLEFT", view.parent, "TOPLEFT", 230 + column * 280, -164 - (index - 1) * 20)
            row.label:SetText(statLabels[key] or key)
            row.value:SetText(tostring(profile.weights[key]))
            row.label:Show()
            row.value:Show()
        end
        for i = #keys + 1, #view.rows do
            view.rows[i].label:Hide()
            view.rows[i].value:Hide()
        end
        view.note:ClearAllPoints()
        view.note:SetPoint("TOPLEFT", view.parent, "TOPLEFT", 20, -math.max(220, 184 + rowCount * 20))
        view.note:SetPoint("RIGHT", view.parent, "RIGHT", -20, 0)
    end
    if window then window:SetHeight(math.max(320, 264 + rowCount * 20)) end
end

local function makeContent(parent)
    local view = { parent = parent, rows = {} }
    local items = {}
    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 18, -16)
    title:SetText("CompareDPS")

    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", 20, -58)
    label:SetText("Specialization:")

    local dropdown = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    dropdown:SetSize(210, 24)
    dropdown:SetPoint("LEFT", label, "RIGHT", 12, 0)

    local menu = CreateFrame("Frame", nil, parent)
    menu:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    menu:SetWidth(210)
    menu:SetFrameLevel(dropdown:GetFrameLevel() + 2)
    menu:Hide()
    view.dropdown, view.menu = dropdown, menu
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
                items[i] = choice
            end
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
    view.heading:SetPoint("TOPLEFT", 20, -104)
    local units = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    units:SetPoint("TOPLEFT", 20, -130)
    units:SetText("Relative gear points per unit; percentages are per 1 percentage point.")
    view.empty = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    view.empty:SetPoint("TOPLEFT", 20, -164)

    local note = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetJustifyH("LEFT")
    note:SetText("Unlisted stats have weight 0. Weights are read-only presets for the selected specialization.\nClass detected automatically; specialization selected manually. Scores are approximate, not simulated DPS, and do not account for all item effects.")
    view.note = note
    parent:SetScript("OnShow", addon.refreshOptions)
    parent:SetScript("OnHide", closeMenu)
end

local function makeWindow()
    if window then return end
    window = CreateFrame("Frame", "CompareDPSOptions", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    window:SetSize(580, 440)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetClampedToScreen(true)
    if window.SetBackdrop then
        window:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 14,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        window:SetBackdropColor(0.05, 0.04, 0.08, 0.98)
        window:SetBackdropBorderColor(0.58, 0.51, 0.79, 1)
    else
        local background = window:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints()
        background:SetColorTexture(0.05, 0.04, 0.08, 0.98)
    end
    makeContent(window)
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
