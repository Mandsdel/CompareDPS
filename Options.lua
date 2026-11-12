local _, addon = ...

local window, dropdown, menu, minimapButton
local items = {}

local function closeMenu()
    if menu then menu:Hide() end
end

function addon.refreshOptions()
    if not dropdown then return end
    local profiles = addon.classProfiles()
    local profile = profiles and profiles[CompareDPSDB.profile]
    dropdown:SetText(profile and (profile.label .. "  v") or "Select specialization  v")
end

local function makeWindow()
    if window then return end
    window = CreateFrame("Frame", "CompareDPSOptions", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    window:SetSize(380, 190)
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

    local title = window:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 18, -16)
    title:SetText("CompareDPS")
    local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 0, 0)
    close:SetScript("OnClick", function() window:Hide() end)
    window:SetScript("OnHide", closeMenu)

    local label = window:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", 20, -58)
    label:SetText("Specialization:")

    dropdown = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
    dropdown:SetSize(210, 24)
    dropdown:SetPoint("LEFT", label, "RIGHT", 12, 0)

    menu = CreateFrame("Frame", nil, window)
    menu:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    menu:SetWidth(210)
    menu:SetFrameLevel(dropdown:GetFrameLevel() + 2)
    menu:Hide()

    dropdown:SetScript("OnClick", function()
        if menu:IsShown() then closeMenu(); return end
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

    local note = window:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", 20, -108)
    note:SetPoint("RIGHT", window, "RIGHT", -20, 0)
    note:SetJustifyH("LEFT")
    note:SetText("Class detected automatically. Scores are approximate and do not account for all item effects.")
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
    if minimapButton then return end
    local minimap = Minimap or (MinimapCluster and MinimapCluster.Minimap)
    if not minimap then
        print("|cff80cfffCompareDPS:|r Minimap unavailable; use /comparedps to choose a spec.")
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
        GameTooltip:AddLine("Click to choose a specialization.", 1, 1, 1)
        GameTooltip:Show()
    end)
    minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
end
