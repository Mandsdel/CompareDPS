local frames = {}
local methods = {}
function methods:SetScript(event, handler) self.scripts[event] = handler end
function methods:SetText(text) self.text = text end
function methods:GetText() return self.text end
function methods:SetChecked(value) self.checked = value end
function methods:GetChecked() return self.checked end
function methods:Enable() self.enabled = true end
function methods:Disable() self.enabled = false end
function methods:Show()
    self.shown = true
    if self.scripts.OnShow then self.scripts.OnShow(self) end
end
function methods:SetWidth(width) self.width = width end
function methods:SetPoint(...) self.point = { ... } end
function methods:Hide()
    self.shown = false
    if self.scripts.OnHide then self.scripts.OnHide(self) end
end
function methods:IsShown() return self.shown end
function methods:GetFrameLevel() return 1 end
function methods:CreateFontString() return CreateFrame("FontString", nil, self) end
function methods:CreateTexture() return CreateFrame("Texture", nil, self) end
function methods:SetTexture(texture) self.texture = texture end
function methods:SetBackdrop(backdrop) self.backdrop = backdrop end
for _, name in ipairs({
    "SetSize", "ClearAllPoints", "SetHeight", "SetFrameLevel",
    "SetFrameStrata", "SetClampedToScreen", "SetAllPoints", "SetColorTexture",
    "SetTexCoord", "SetHighlightTexture", "RegisterForClicks",
    "SetJustifyH", "SetAutoFocus", "ClearFocus", "SetFocus", "RegisterEvent", "SetTextColor",
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
assert(loadfile("DynamicWeights.lua"))("CompareDPS", addon)
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
assert(dropdown.parent.backdrop.bgFile == "Interface\\DialogFrame\\UI-DialogBox-Background")
assert(dropdown.parent.backdrop.edgeFile == "Interface\\DialogFrame\\UI-DialogBox-Border")
local windowTitle
for _, frame in ipairs(frames) do
    if frame.parent == dropdown.parent and frame.kind == "FontString" and frame.text == "CompareDPS" then
        windowTitle = frame
    end
end
assert(windowTitle and windowTitle.point[1] == "CENTER")
assert(windowTitle.point[2].texture == "Interface\\DialogFrame\\UI-DialogBox-Header")
assert(windowTitle.point[3] == "TOP" and windowTitle.point[4] == 0 and windowTitle.point[5] == -20)
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
assert(displayedWeights(dropdown.parent)["Fire spell power"] == string.format("%.1f", 0.35))
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
assert(displayedWeights(registeredPanel)["Shadow spell power"] == string.format("%.1f", 0.95))
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
local expectedGroups = {
    { "str", "agi", "stamina", "int", "spirit" },
    { "hit", "crit" },
    { "ap", "rap", "fap" },
    { "spellpower", "heal", "arcane", "fire", "frost", "holy", "nature", "shadow", "spellpen" },
    { "dpsMH", "speedMH" }, { "dpsOH", "speedOH" },
    { "dps2h", "speed2h" }, { "dpsRanged", "speedRanged" },
    { "armor", "defense", "dodge", "parry", "block", "blockValue" },
    { "hp5", "mana", "mp5" },
}
local function assertGroupedLayout(parent, profile)
    local rows = {}
    for _, frame in ipairs(frames) do
        if frame.parent == parent and frame.kind == "FontString" and frame.width == 210 and frame.shown then
            rows[#rows + 1] = frame
        end
    end
    local index, previousX, previousY = 0, 20, -168
    for _, group in ipairs(expectedGroups) do
        local groupX
        for _, stat in ipairs(group) do
            if profile.weights[stat] ~= nil then
                index = index + 1
                local row = assert(rows[index])
                local locked = CompareDPSDB.dynamicWeights and addon.isDynamicLocked(stat)
                assert(row.text == labelsByKey[stat] .. (locked and " (locked)" or ""), "Unexpected stat order")
                local x, y = row.point[4], row.point[5]
                groupX = groupX or x
                assert(x == groupX, "Related stats split across columns")
                if x == previousX then
                    assert(y == previousY - 20, "Incorrect row spacing")
                else
                    assert(previousX == 20 and x == 300 and y == -188, "Incorrect column transition")
                end
                previousX, previousY = x, y
            end
        end
    end
    assert(index == #rows, "Ungrouped stat")
end
for classKey, profiles in pairs(addon.profiles) do
    class = classKey
    for key, profile in pairs(profiles) do
        addon.selectProfile(key)
        assert(dropdown.text == profile.label .. "  v")
        assert(settingsDropdown.text == dropdown.text)
        local expectedIcon
        for _, parent in ipairs({ dropdown.parent, registeredPanel }) do
            local portrait
            for _, frame in ipairs(frames) do
                if frame.parent == parent and frame.kind == "Texture"
                    and frame.point and frame.point[1] == "TOPLEFT"
                    and frame.point[2] == 22 then portrait = frame end
            end
            assert(portrait and portrait.texture:find("Interface\\Icons\\", 1, true) == 1)
            assert(not portrait.texture:find("INV_Misc_Book_09", 1, true), "Missing icon for " .. classKey .. "/" .. key)
            if expectedIcon then assert(portrait.texture == expectedIcon) end
            expectedIcon = portrait.texture
        end
        for _, parent in ipairs({ dropdown.parent, registeredPanel }) do
            local values = displayedWeights(parent)
            local count, expectedCount = 0, 0
            for _ in pairs(values) do count = count + 1 end
            for stat, weight in pairs(profile.weights) do
                assert(labelsByKey[stat], "Missing readable label for " .. stat)
                assert(values[labelsByKey[stat]] == string.format("%.1f", weight), classKey .. "/" .. key .. "/" .. stat)
                expectedCount = expectedCount + 1
            end
            assert(count == expectedCount, "Stale weight rows")
            assertGroupedLayout(parent, profile)
        end
        CompareDPSDB.dynamicWeights = true
        addon.refreshOptions()
        assertGroupedLayout(dropdown.parent, profile)
        assertGroupedLayout(registeredPanel, profile)
        CompareDPSDB.dynamicWeights = false
        addon.refreshOptions()
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
assert(displayedWeights(dropdown.parent)["Fire spell power"] == "0.0")
assert(displayedWeights(dropdown.parent)["Spirit"] == string.format("%.1f", -0.25))
assert(addon.profiles.WARLOCK.demonology.weights.spellpower == baseline)
assert(displayedWeights(registeredPanel)["Spell power"] == "2.5")
addon.selectProfile("affliction")
assert(addon.activeWeights().spellpower == 1)
addon.selectProfile("demonology")
assert(addon.activeWeights().spellpower == 2.5)
edit.scripts.OnClick()
assert(input(dropdown.parent, "Spirit"):GetText() == "-0.25")
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
assert(displayedWeights(dropdown.parent)["Spell power"] == "3.0")
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
-- Static overrides survive Dynamic mode; uncapped edits are shared between modes.
class = "WARLOCK"
addon.selectProfile("demonology")
edit.scripts.OnClick()
input(dropdown.parent, "Hit (1%)"):SetText("77")
input(dropdown.parent, "Crit (1%)"):SetText("88")
input(dropdown.parent, "Spell penetration"):SetText("9")
input(dropdown.parent, "Spell power"):SetText("5")
save.scripts.OnClick()
assert(addon.activeWeights().hit == 77 and addon.activeWeights().crit == 88)
function UnitLevel() return 60 end
local liveHit = 16
function GetSpellHitModifier() return liveHit end
function GetSpellCritChance() return 20 end
function UnitArmor() return 1000, 1000 end
local toggle, settingsToggle
for _, frame in ipairs(frames) do
    if frame.kind == "CheckButton" and frame.parent == dropdown.parent then toggle = frame end
    if frame.kind == "CheckButton" and frame.parent == registeredPanel then settingsToggle = frame end
end
assert(toggle and settingsToggle and not toggle:GetChecked())
toggle:SetChecked(true)
toggle.scripts.OnClick(toggle)
assert(CompareDPSDB.dynamicWeights and settingsToggle:GetChecked())
assert(addon.activeWeights().hit == 0)
assert(math.abs(addon.activeWeights().crit - 8) < 0.00001)
assert(addon.activeWeights().spellpen == 9 and addon.activeWeights().spellpower == 5)
assert(CompareDPSDB.customWeights.demonology.hit == 77)
assert(displayedWeights(dropdown.parent)["Hit (1%) (locked)"] == "0.0")
assert(displayedWeights(registeredPanel)["Spell power"] == "5.0")
assert(displayedWeights(registeredPanel)["Spell penetration"] == "9.0")
function UnitLevel() return 20 end
dropdown.parent.scripts.OnUpdate(dropdown.parent, 0.5)
local summaries = 0
for _, view in ipairs({ dropdown.parent, registeredPanel }) do
    for _, frame in ipairs(frames) do
        if frame.parent == view and frame.kind == "FontString"
            and frame.text and frame.text:find("player level 20 vs level 23", 1, true) then
            summaries = summaries + 1
        end
    end
end
assert(summaries == 2)
function UnitLevel() return 60 end
edit.scripts.OnClick()
assert(save.shown and edit.enabled and control(dropdown.parent, "Reset to Default").enabled)
for i, frame in ipairs(frames) do
    if frame.parent == dropdown.parent and frame.kind == "FontString" and frame.shown
        and frame.text:find(" (locked)", 1, true) then
        assert(frames[i + 2].kind == "EditBox" and not frames[i + 2].shown)
    end
end
input(dropdown.parent, "Spell power"):SetText("6")
input(dropdown.parent, "Spell penetration"):SetText("3")
save.scripts.OnClick()
assert(addon.activeWeights().spellpower == 6 and addon.activeWeights().spellpen == 3
    and CompareDPSDB.customWeights.demonology.hit == 77)
local badSave = {}
for key, value in pairs(addon.profiles.WARLOCK.demonology.weights) do
    if not addon.isDynamicLocked(key) then badSave[key] = value end
end
badSave.hit = 123
local saved, errorMessage = addon.saveWeights(badSave)
assert(not saved and errorMessage:find("locked", 1, true))
assert(CompareDPSDB.customWeights.demonology.hit == 77)
liveHit = 15
dropdown.parent.scripts.OnUpdate(dropdown.parent, 0.5)
assert(displayedWeights(dropdown.parent)["Hit (1%) (locked)"] == "12.0")
settingsToggle:SetChecked(false)
settingsToggle.scripts.OnClick(settingsToggle)
assert(not CompareDPSDB.dynamicWeights and not toggle:GetChecked())
assert(addon.activeWeights().hit == 77 and addon.activeWeights().crit == 88)
assert(addon.activeWeights().spellpen == 3 and addon.activeWeights().spellpower == 6)
addon.setDynamicWeights(true)
control(dropdown.parent, "Reset to Default").scripts.OnClick()
assert(addon.activeWeights().spellpower == baseline)
addon.setDynamicWeights(false)
assert(addon.activeWeights().hit == 77 and addon.activeWeights().crit == 88)
assert(addon.activeWeights().spellpower == baseline)
-- Unavailable live APIs never masquerade as working dynamic weights.
GetSpellHitModifier = nil
addon.setDynamicWeights(true)
assert(displayedWeights(dropdown.parent)["Hit (1%) (locked)"] == "N/A")
edit.scripts.OnClick()
input(dropdown.parent, "Spell power"):SetText("7")
save.scripts.OnClick()
addon.setDynamicWeights(false)
assert(addon.activeWeights().spellpower == 7 and addon.activeWeights().hit == 77)
class = "WARRIOR"
addon.selectProfile("protection")
local tankCustom = {}
for key, value in pairs(addon.activeWeights()) do tankCustom[key] = value end
tankCustom.defense, tankCustom.block, tankCustom.str = 91, 92, 10
assert(addon.saveWeights(tankCustom))
function GetHitModifier() return 9 end
function GetCritChance() return 20 end
function GetInventoryItemID() return nil end
C_SkillInfo = { GetSkillLineInfoByID = function() return { rank = 300, modifier = 0 } end }
function UnitAttackSpeed() return 2 end
function UnitDefenseSkill() return 300, 140 end
function GetDodgeChance() return 20 end
function GetParryChance() return 20 end
function GetBlockChance() return 20 end
addon.setDynamicWeights(true)
assert(addon.activeWeights().defense ~= 91 and addon.activeWeights().block ~= 92)
edit.scripts.OnClick()
input(dropdown.parent, "Strength"):SetText("11")
save.scripts.OnClick()
addon.setDynamicWeights(false)
assert(addon.activeWeights().defense == 91 and addon.activeWeights().block == 92)
assert(addon.activeWeights().str == 11)
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
