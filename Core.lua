----------------------------------------------------------------------
-- RuneMagic Castbars - Core
-- Addon initialization and shared utilities.
----------------------------------------------------------------------

local AddonName, NS = ...

-- Namespace table shared across all files
NS.frames = {}

-- Default settings applied on first load or reset
NS.defaults = {
    playerBar = {
        width = 280,
        height = 64,
        x = 0,
        y = -200,
        point = "CENTER",
        runeIndex = 1,
        barColor = { r = 0.25, g = 0.5, b = 1.0, a = 1.0 },
        interruptedColor = { r = 1.0, g = 0.0, b = 0.0, a = 1.0 },
        showIcon = true,
        showTimer = true,
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 12,
    },
    targetBar = {
        width = 280,
        height = 64,
        x = 0,
        y = -275,
        point = "CENTER",
        runeIndex = 1,
        barColor = { r = 0.25, g = 0.5, b = 1.0, a = 1.0 },
        interruptedColor = { r = 1.0, g = 0.0, b = 0.0, a = 1.0 },
        showIcon = true,
        showTimer = true,
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 12,
    },
    locked = true,
}

----------------------------------------------------------------------
-- Deep-copy a table (used for defaults)
----------------------------------------------------------------------
local function DeepCopy(src)
    if type(src) ~= "table" then return src end
    local copy = {}
    for k, v in pairs(src) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

----------------------------------------------------------------------
-- Merge missing keys from src into dst (non-destructive)
----------------------------------------------------------------------
local function MergeDefaults(dst, src)
    for k, v in pairs(src) do
        if dst[k] == nil then
            dst[k] = DeepCopy(v)
        elseif type(v) == "table" and type(dst[k]) == "table" then
            MergeDefaults(dst[k], v)
        end
    end
end

NS.DeepCopy = DeepCopy
NS.MergeDefaults = MergeDefaults

----------------------------------------------------------------------
-- Initialization
----------------------------------------------------------------------
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon ~= AddonName then return end
    self:UnregisterEvent("ADDON_LOADED")

    -- Initialise saved variables
    if not RuneMagicCastbarsDB then
        RuneMagicCastbarsDB = DeepCopy(NS.defaults)
    else
        MergeDefaults(RuneMagicCastbarsDB, NS.defaults)
    end
    NS.db = RuneMagicCastbarsDB

    -- Hide the default Blizzard cast bars (Classic frame names)
    if CastingBarFrame then
        CastingBarFrame:UnregisterAllEvents()
        CastingBarFrame:Hide()
    end
    if TargetFrameSpellBar then
        TargetFrameSpellBar:UnregisterAllEvents()
        TargetFrameSpellBar:Hide()
    end

    -- Create castbars (defined in CastBar.lua)
    NS.playerBar = NS.CreateCastBar("player", NS.db.playerBar)
    NS.targetBar = NS.CreateCastBar("target", NS.db.targetBar)

    print("|cff00ccffRuneMagic Castbars|r loaded. Type |cff00ccff/rmcb|r for options.")
end)

----------------------------------------------------------------------
-- Slash command
----------------------------------------------------------------------
SLASH_RUNEMAGICCASTBARS1 = "/rmcb"
SLASH_RUNEMAGICCASTBARS2 = "/runemagiccastbars"
SlashCmdList["RUNEMAGICCASTBARS"] = function(msg)
    local cmd = strlower(strtrim(msg))
    if cmd == "lock" then
        NS.db.locked = true
        print("|cff00ccffRuneMagic Castbars|r: Bars locked.")
        NS.SetLock(true)
    elseif cmd == "unlock" then
        NS.db.locked = false
        print("|cff00ccffRuneMagic Castbars|r: Bars unlocked. Drag to reposition.")
        NS.SetLock(false)
    elseif cmd == "reset" then
        RuneMagicCastbarsDB = NS.DeepCopy(NS.defaults)
        NS.db = RuneMagicCastbarsDB
        NS.ApplySettings(NS.playerBar, NS.db.playerBar)
        NS.ApplySettings(NS.targetBar, NS.db.targetBar)
        print("|cff00ccffRuneMagic Castbars|r: Settings reset to defaults.")
    elseif cmd == "test" then
        NS.TestCastBar(NS.playerBar)
    else
        print("|cff00ccffRuneMagic Castbars|r commands:")
        print("  /rmcb lock   - Lock bar positions")
        print("  /rmcb unlock - Unlock bars for dragging")
        print("  /rmcb reset  - Reset all settings to defaults")
        print("  /rmcb test   - Show a test cast bar")
    end
end
