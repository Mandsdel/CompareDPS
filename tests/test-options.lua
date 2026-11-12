local frames = {}
local methods = {}
function methods:SetScript(event, handler) self.scripts[event] = handler end
function methods:SetText(text) self.text = text end
function methods:Show() self.shown = true end
function methods:Hide()
    self.shown = false
    if self.scripts.OnHide then self.scripts.OnHide(self) end
end
function methods:IsShown() return self.shown end
function methods:GetFrameLevel() return 1 end
function methods:CreateFontString() return CreateFrame("FontString", nil, self) end
function methods:CreateTexture() return CreateFrame("Texture", nil, self) end
for _, name in ipairs({
    "SetSize", "SetPoint", "SetWidth", "SetHeight", "SetFrameLevel",
    "SetFrameStrata", "SetClampedToScreen", "SetAllPoints", "SetColorTexture",
    "SetTexture", "SetTexCoord", "SetHighlightTexture", "RegisterForClicks",
    "SetJustifyH",
}) do methods[name] = function() end end
function CreateFrame(kind, name, parent, template)
    local frame = setmetatable({
        kind = kind, name = name, parent = parent, template = template,
        scripts = {}, shown = true,
    }, { __index = methods })
    frames[#frames + 1] = frame
    return frame
end
UIParent = CreateFrame("Frame")
Minimap = CreateFrame("Frame")
GameTooltip = { SetOwner = function() end, SetText = function() end,
    AddLine = function() end, Show = function() end, Hide = function() end }
CompareDPSDB = {}
local class = "WARLOCK"
local addon = {}
assert(loadfile("Profiles.lua"))("CompareDPS", addon)
function addon.classProfiles() return addon.profiles[class] end
function addon.selectProfile(key)
    assert(addon.classProfiles()[key])
    CompareDPSDB.profile = key
    addon.refreshOptions()
end
assert(loadfile("Options.lua"))("CompareDPS", addon)
addon.initializeOptions()
local icon = frames[#frames - 2]
for _, frame in ipairs(frames) do
    if frame.name == "CompareDPSMinimapButton" then icon = frame end
end
assert(icon and icon.parent == Minimap)
icon.scripts.OnClick()
local dropdown
for _, frame in ipairs(frames) do
    if frame.template == "UIPanelButtonTemplate" and frame.text == "Select specialization  v" then
        dropdown = frame
    end
end
assert(dropdown)
dropdown.scripts.OnClick()
local labels = {}
for _, frame in ipairs(frames) do
    if frame.template == "UIPanelButtonTemplate" and frame ~= dropdown then
        labels[frame.text] = frame
    end
end
assert(labels.Affliction and labels.Demonology and labels.Destruction)
labels.Demonology.scripts.OnClick()
assert(CompareDPSDB.profile == "demonology")
assert(dropdown.text == "Demonology  v")
dropdown.scripts.OnClick()
labels.Destruction.scripts.OnClick()
assert(CompareDPSDB.profile == "destruction")
assert(dropdown.text == "Destruction  v")
addon.toggleOptions()
addon.toggleOptions()
assert(dropdown.text == "Destruction  v")
class = "DRUID"
addon.refreshOptions()
dropdown.scripts.OnClick()
labels = {}
for _, frame in ipairs(frames) do
    if frame.template == "UIPanelButtonTemplate" and frame ~= dropdown and frame.shown then
        labels[frame.text] = frame
    end
end
assert(labels["Feral (DPS)"] and labels["Feral (Tanking)"] and labels.Balance and labels["Restoration (Healing)"])
labels["Feral (Tanking)"].scripts.OnClick()
assert(CompareDPSDB.profile == "feraltank" and dropdown.text == "Feral (Tanking)  v")
class = "UNSUPPORTED"
addon.refreshOptions()
dropdown.scripts.OnClick()
assert(dropdown.text == "No supported specializations")
assert(CompareDPSDB.profile == "feraltank")
print("CompareDPS options checks passed")
