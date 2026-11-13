local frames = {}
local methods = {}
function methods:SetScript(event, handler) self.scripts[event] = handler end
function methods:SetText(text) self.text = text end
function methods:GetText() return self.text end
function methods:Show()
    self.shown = true
    if self.scripts.OnShow then self.scripts.OnShow(self) end
end
function methods:SetWidth(width) self.width = width end
function methods:Hide()
    self.shown = false
    if self.scripts.OnHide then self.scripts.OnHide(self) end
end
function methods:IsShown() return self.shown end
function methods:GetFrameLevel() return 1 end
function methods:CreateFontString() return CreateFrame("FontString", nil, self) end
function methods:CreateTexture() return CreateFrame("Texture", nil, self) end
for _, name in ipairs({
    "SetSize", "SetPoint", "ClearAllPoints", "SetHeight", "SetFrameLevel",
    "SetFrameStrata", "SetClampedToScreen", "SetAllPoints", "SetColorTexture",
    "SetTexture", "SetTexCoord", "SetHighlightTexture", "RegisterForClicks",
    "SetJustifyH", "SetAutoFocus", "ClearFocus", "SetFocus", "RegisterEvent",
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
local registeredPanel, registrationCount = nil, 0
local function register(panel)
    assert(panel.name == "CompareDPS")
    registeredPanel = panel
    registrationCount = registrationCount + 1
end
if arg and arg[1] == "legacy" then
    InterfaceOptions_AddCategory = register
else
    Settings = {
        RegisterCanvasLayoutCategory = function(panel, name)
            assert(name == "CompareDPS")
            return { panel = panel }
        end,
        RegisterAddOnCategory = function(category) register(category.panel) end,
    }
end
local class = "WARLOCK"
function UnitClass() return class, class end
SlashCmdList = {}
local addon = {}
assert(loadfile("Profiles.lua"))("CompareDPS", addon)
assert(loadfile("Core.lua"))("CompareDPS", addon)
assert(loadfile("Options.lua"))("CompareDPS", addon)
addon.initializeOptions()
addon.initializeOptions()
assert(registeredPanel and registrationCount == 1)
registeredPanel:Show()
local icon = frames[#frames - 2]
for _, frame in ipairs(frames) do
    if frame.name == "CompareDPSMinimapButton" then icon = frame end
end
assert(icon and icon.parent == Minimap)
icon.scripts.OnClick()
local dropdown
for _, frame in ipairs(frames) do
    if frame.template == "UIPanelButtonTemplate" and frame.text == "Select specialization  v"
        and frame.parent.name == "CompareDPSOptions" then
        dropdown = frame
    end
end
assert(dropdown)
local settingsDropdown
for _, frame in ipairs(frames) do
    if frame.parent == registeredPanel and frame.template == "UIPanelButtonTemplate"
        and frame.text == "Select specialization  v" then
        settingsDropdown = frame
    end
end
assert(settingsDropdown)
local function displayedWeights(parent)
    local values = {}
    for i, frame in ipairs(frames) do
        if frame.parent == parent and frame.kind == "FontString" and frame.width == 210 and frame.shown then
            local value = frames[i + 1]
            assert(value.parent == parent and value.width == 48 and value.shown)
            values[frame.text] = value.text
        end
    end
    return values
end
assert(next(displayedWeights(dropdown.parent)) == nil)
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
assert(settingsDropdown.text == "Demonology  v")
assert(displayedWeights(dropdown.parent)["Fire spell power"] == "0.35")
settingsDropdown.scripts.OnClick()
for _, frame in ipairs(frames) do
    if frame.parent and frame.parent.parent == registeredPanel and frame.text == "Affliction" then
        frame.scripts.OnClick()
        break
    end
end
assert(CompareDPSDB.profile == "affliction")
assert(dropdown.text == "Affliction  v" and settingsDropdown.text == "Affliction  v")
assert(displayedWeights(dropdown.parent)["Fire spell power"] == nil)
assert(displayedWeights(registeredPanel)["Shadow spell power"] == "0.95")
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
local labelsByKey = {
    str = "Strength", agi = "Agility", ap = "Attack power",
    rap = "Ranged attack power", fap = "Feral attack power",
    spellpower = "Spell power", heal = "Healing power", spellpen = "Spell penetration",
    shadow = "Shadow spell power", fire = "Fire spell power", frost = "Frost spell power",
    arcane = "Arcane spell power", nature = "Nature spell power", holy = "Holy spell power",
    int = "Intellect", spirit = "Spirit", stamina = "Stamina", mana = "Mana",
    hit = "Hit (1%)", crit = "Crit (1%)", mp5 = "Mana per 5 seconds",
    hp5 = "Health per 5 seconds", armor = "Armor", defense = "Defense skill",
    dodge = "Dodge (1%)", parry = "Parry (1%)", block = "Block (1%)", blockValue = "Block value",
    dpsMH = "Main-hand DPS", dpsOH = "Off-hand DPS", dps2h = "Two-hand DPS",
    dpsRanged = "Ranged / wand DPS", speedMH = "Main-hand speed (seconds)",
    speedOH = "Off-hand speed (seconds)", speed2h = "Two-hand speed (seconds)",
    speedRanged = "Ranged speed (seconds)",
}
for classKey, profiles in pairs(addon.profiles) do
    class = classKey
    for key, profile in pairs(profiles) do
        addon.selectProfile(key)
        assert(dropdown.text == profile.label .. "  v")
        assert(settingsDropdown.text == dropdown.text)
        for _, parent in ipairs({ dropdown.parent, registeredPanel }) do
            local values = displayedWeights(parent)
            local count, expectedCount = 0, 0
            for _ in pairs(values) do count = count + 1 end
            for stat, weight in pairs(profile.weights) do
                assert(labelsByKey[stat], "Missing readable label for " .. stat)
                assert(values[labelsByKey[stat]] == tostring(weight), classKey .. "/" .. key .. "/" .. stat)
                expectedCount = expectedCount + 1
            end
            assert(count == expectedCount, "Stale weight rows")
        end
    end
end
class = "DRUID"
addon.selectProfile("feraltank")
local function control(parent, text)
    for _, frame in ipairs(frames) do
        if frame.parent == parent and frame.kind == "Button" and frame.text == text then return frame end
    end
    error("Missing button " .. text)
end
local function input(parent, label)
    for i, frame in ipairs(frames) do
        if frame.parent == parent and frame.kind == "FontString" and frame.text == label and frame.shown then
            local editBox = frames[i + 2]
            assert(editBox.kind == "EditBox" and editBox.shown)
            return editBox
        end
    end
    error("Missing editable weight " .. label)
end
class = "WARLOCK"
addon.selectProfile("demonology")
local baseline = addon.profiles.WARLOCK.demonology.weights.spellpower
local edit = control(dropdown.parent, "Edit")
local save = control(dropdown.parent, "Save")
local cancel = control(dropdown.parent, "Cancel")
edit.scripts.OnClick()
assert(save.shown and cancel.shown and not edit.shown)
input(dropdown.parent, "Spell power"):SetText("2.5")
input(dropdown.parent, "Fire spell power"):SetText("0")
input(dropdown.parent, "Spirit"):SetText("-0.25")
assert(addon.activeWeights().spellpower == baseline)
save.scripts.OnClick()
assert(addon.activeWeights().spellpower == 2.5)
assert(addon.activeWeights().fire == 0 and addon.activeWeights().spirit == -0.25)
assert(addon.profiles.WARLOCK.demonology.weights.spellpower == baseline)
assert(displayedWeights(registeredPanel)["Spell power"] == "2.5")
addon.selectProfile("affliction")
assert(addon.activeWeights().spellpower == 1)
addon.selectProfile("demonology")
assert(addon.activeWeights().spellpower == 2.5)
edit.scripts.OnClick()
input(dropdown.parent, "Spell power"):SetText("99")
cancel.scripts.OnClick()
assert(displayedWeights(dropdown.parent)["Spell power"] == "2.5")
for _, invalid in ipairs({ "", "abc", "1e999" }) do
    edit.scripts.OnClick()
    input(dropdown.parent, "Spell power"):SetText(invalid)
    save.scripts.OnClick()
    assert(save.shown and addon.activeWeights().spellpower == 2.5)
    local reported = false
    for _, frame in ipairs(frames) do
        if frame.parent == dropdown.parent and frame.text and frame.text:find("Invalid weight", 1, true) then
            reported = true
        end
    end
    assert(reported)
    cancel.scripts.OnClick()
end
edit.scripts.OnClick()
input(dropdown.parent, "Spell power"):SetText("99")
addon.selectProfile("affliction")
assert(not save.shown and addon.activeWeights().spellpower == 1)
addon.selectProfile("demonology")
assert(addon.activeWeights().spellpower == 2.5)
edit.scripts.OnClick()
input(dropdown.parent, "Spell power"):SetText("99")
addon.toggleOptions()
addon.toggleOptions()
assert(not save.shown and displayedWeights(dropdown.parent)["Spell power"] == "2.5")
edit.scripts.OnClick()
input(dropdown.parent, "Spell power"):SetText("99")
control(registeredPanel, "Edit").scripts.OnClick()
assert(not save.shown)
assert(input(registeredPanel, "Spell power"):GetText() == "2.5")
input(registeredPanel, "Spell power"):SetText("3")
control(registeredPanel, "Save").scripts.OnClick()
assert(displayedWeights(dropdown.parent)["Spell power"] == "3")
addon.selectProfile("affliction")
control(registeredPanel, "Edit").scripts.OnClick()
input(registeredPanel, "Spell power"):SetText("4")
control(registeredPanel, "Save").scripts.OnClick()
addon.selectProfile("demonology")
edit.scripts.OnClick()
input(dropdown.parent, "Spell power"):SetText("99")
control(dropdown.parent, "Reset to Default").scripts.OnClick()
assert(not save.shown and addon.activeWeights().spellpower == baseline)
assert(CompareDPSDB.customWeights.demonology == nil)
addon.selectProfile("affliction")
assert(addon.activeWeights().spellpower == 4)
edit.scripts.OnClick()
input(dropdown.parent, "Spell power").scripts.OnEscapePressed()
assert(not save.shown)
edit.scripts.OnClick()
registeredPanel:Hide()
assert(save.shown)
cancel.scripts.OnClick()
class = "DRUID"
addon.selectProfile("feraltank")
class = "UNSUPPORTED"
addon.refreshOptions()
dropdown.scripts.OnClick()
assert(dropdown.text == "No supported specializations")
assert(CompareDPSDB.profile == "feraltank")
assert(next(displayedWeights(dropdown.parent)) == nil)
assert(next(displayedWeights(registeredPanel)) == nil)
print("CompareDPS options checks passed")
