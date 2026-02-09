----------------------------------------------------------------------
-- RuneMagic Castbars - Config
-- Lightweight config helpers and future options panel hook.
----------------------------------------------------------------------

local AddonName, NS = ...

----------------------------------------------------------------------
-- Re-apply all saved positions after a UI reload
----------------------------------------------------------------------
local reloadFrame = CreateFrame("Frame")
reloadFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
reloadFrame:SetScript("OnEvent", function(self, event)
    self:UnregisterEvent(event)

    -- Ensure bars exist before touching them
    if NS.playerBar and NS.db then
        NS.ApplySettings(NS.playerBar, NS.db.playerBar)
    end
    if NS.targetBar and NS.db then
        NS.ApplySettings(NS.targetBar, NS.db.targetBar)
    end
end)
