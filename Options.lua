local _, addon = ...

local window, optionsPanel, minimapButton
local views = {}
local editingView, editingProfile

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

local function cancelEditing()
    if editingView then
        for _, row in ipairs(editingView.rows) do row.input:ClearFocus() end
    end
    editingView, editingProfile = nil, nil
end

function addon.refreshOptions()
    local profiles = addon.classProfiles()
    local profile = profiles and profiles[CompareDPSDB.profile]
    local weights = addon.activeWeights()
    if editingProfile and editingProfile ~= profile then cancelEditing() end
    local keys = {}
    if profile then
        for key in pairs(profile.weights) do keys[#keys + 1] = key end
        table.sort(keys, function(a, b)
            return (statLabels[a] or a) < (statLabels[b] or b)
        end)
    end
    local rowCount = math.ceil(#keys / 2)
    for _, view in ipairs(views) do
        local editing = editingView == view
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
                row.input = CreateFrame("EditBox", nil, view.parent, "InputBoxTemplate")
                row.input:SetSize(60, 20)
                row.input:SetAutoFocus(false)
                row.input:SetScript("OnEscapePressed", function()
                    cancelEditing()
                    addon.refreshOptions()
                end)
                view.rows[i] = row
            end
            local column = i > rowCount and 1 or 0
            local index = column == 1 and (i - rowCount) or i
            row.label:ClearAllPoints()
            row.value:ClearAllPoints()
            row.input:ClearAllPoints()
            row.label:SetPoint("TOPLEFT", view.parent, "TOPLEFT", 20 + column * 280, -164 - (index - 1) * 20)
            row.value:SetPoint("TOPLEFT", view.parent, "TOPLEFT", 230 + column * 280, -164 - (index - 1) * 20)
            row.input:SetPoint("TOPLEFT", view.parent, "TOPLEFT", 224 + column * 280, -160 - (index - 1) * 20)
            row.key = key
            row.label:SetText(statLabels[key] or key)
            row.value:SetText(tostring(weights[key]))
            row.label:Show()
            if editing then
                if not row.input:IsShown() then row.input:SetText(tostring(weights[key])) end
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
        local buttonY = -math.max(220, 184 + rowCount * 20)
        for i, button in ipairs({ view.edit, view.save, view.cancel, view.reset }) do
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", view.parent, "TOPLEFT", 20 + (i - 1) * 132, buttonY)
        end
        if profile then
            view.reset:Show()
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
        view.status:SetText(editing and "Editing: changes apply only after Save." or "")
        view.status:ClearAllPoints()
        view.status:SetPoint("TOPLEFT", view.parent, "TOPLEFT", 20, buttonY - 32)
        view.note:ClearAllPoints()
        view.note:SetPoint("TOPLEFT", view.parent, "TOPLEFT", 20, buttonY - 56)
        view.note:SetPoint("RIGHT", view.parent, "RIGHT", -20, 0)
    end
    if window then window:SetHeight(math.max(376, 320 + rowCount * 20)) end
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
    note:SetText("Unlisted stats have weight 0. Custom weights are saved per character and specialization.\nClosing this view or switching specialization discards unsaved edits. Scores are approximate, not simulated DPS, and do not account for all item effects.")
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
