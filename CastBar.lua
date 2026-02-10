----------------------------------------------------------------------
-- RuneMagic Castbars - CastBar
-- Rune-shaped castbar using TGA textures. Cast progress is shown
-- by cropping the texture left-to-right via SetTexCoord.
----------------------------------------------------------------------

local AddonName, NS = ...

local OnUpdate, OnEvent, StartCast, StartChannel, StopCast, FinishCast
local InterruptCast, SetRuneProgress, SetRuneColor

----------------------------------------------------------------------
-- SetRuneProgress(bar, progress) - reveal rune from 0 to progress
-- For a normal cast progress goes 0 -> 1 (left to right).
-- For a channel progress goes 1 -> 0 (right to left disappearing).
----------------------------------------------------------------------
SetRuneProgress = function(bar, progress)
    if progress < 0 then progress = 0 end
    if progress > 1 then progress = 1 end

    -- Crop the texture to show only the left 'progress' portion
    bar.rune:SetTexCoord(0, progress, 0, 1)
    bar.rune:SetWidth(bar.cfg.width * progress)
end

----------------------------------------------------------------------
-- SetRuneColor(bar, r, g, b, a)
----------------------------------------------------------------------
SetRuneColor = function(bar, r, g, b, a)
    bar.rune:SetVertexColor(r, g, b, a or 1)
end

----------------------------------------------------------------------
-- CreateCastBar(unit, cfg) -> frame
----------------------------------------------------------------------
function NS.CreateCastBar(unit, cfg)
    local bar = CreateFrame("Frame", "RuneMagicCastbar_" .. unit, UIParent)
    bar.unit = unit
    bar.cfg = cfg
    bar.casting = false
    bar.channeling = false
    bar.holdTime = 0

    bar:SetSize(cfg.width, cfg.height)
    bar:SetPoint(cfg.point, UIParent, cfg.point, cfg.x, cfg.y)

    -- Load the rune texture path
    local runeIndex = cfg.runeIndex or NS.defaultRuneIndex
    local runeData = NS.RuneShapes[runeIndex]
    local runeTexPath = runeData and runeData.texture

    -- Bottom layer: dim rune outline (shows full shape as "unfilled")
    bar.runeBg = bar:CreateTexture(nil, "BACKGROUND")
    bar.runeBg:SetAllPoints()
    if runeTexPath then
        bar.runeBg:SetTexture(runeTexPath)
    end
    bar.runeBg:SetVertexColor(0.2, 0.2, 0.2, 0.6)

    -- Top layer: bright rune (cropped left-to-right to show progress)
    bar.rune = bar:CreateTexture(nil, "ARTWORK")
    bar.rune:SetPoint("LEFT", bar, "LEFT", 0, 0)
    bar.rune:SetSize(cfg.width, cfg.height)
    if runeTexPath then
        bar.rune:SetTexture(runeTexPath)
    end
    bar.rune:SetTexCoord(0, 0, 0, 1)  -- start hidden
    bar.rune:SetWidth(0)

    -- Spell name text (below the rune)
    bar.text = bar:CreateFontString(nil, "OVERLAY")
    bar.text:SetFont(cfg.font, cfg.fontSize, "OUTLINE")
    bar.text:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -2)
    bar.text:SetJustifyH("LEFT")
    bar.text:SetTextColor(1, 1, 1, 1)

    -- Timer text (below the rune, right side)
    bar.timer = bar:CreateFontString(nil, "OVERLAY")
    bar.timer:SetFont(cfg.font, cfg.fontSize, "OUTLINE")
    bar.timer:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, -2)
    bar.timer:SetJustifyH("RIGHT")
    bar.timer:SetTextColor(1, 1, 1, 1)
    if not cfg.showTimer then bar.timer:Hide() end

    -- Spell icon
    bar.icon = bar:CreateTexture(nil, "OVERLAY")
    bar.icon:SetSize(cfg.height + 2, cfg.height + 2)
    bar.icon:SetPoint("RIGHT", bar, "LEFT", -4, 0)
    bar.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    if not cfg.showIcon then bar.icon:Hide() end

    -- Dragging support
    bar:SetMovable(true)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function(self)
        if not NS.db.locked then self:StartMoving() end
    end)
    bar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        self.cfg.point = point
        self.cfg.x = x
        self.cfg.y = y
    end)
    bar:SetClampedToScreen(true)

    -- Events
    bar:SetScript("OnUpdate", OnUpdate)
    bar:SetScript("OnEvent", OnEvent)

    local castEvents = {
        "UNIT_SPELLCAST_START",
        "UNIT_SPELLCAST_STOP",
        "UNIT_SPELLCAST_FAILED",
        "UNIT_SPELLCAST_INTERRUPTED",
        "UNIT_SPELLCAST_SUCCEEDED",
        "UNIT_SPELLCAST_CHANNEL_START",
        "UNIT_SPELLCAST_CHANNEL_STOP",
        "UNIT_SPELLCAST_CHANNEL_UPDATE",
    }
    for _, ev in ipairs(castEvents) do
        bar:RegisterEvent(ev)
    end
    if unit == "target" then
        bar:RegisterEvent("PLAYER_TARGET_CHANGED")
    end

    bar:Hide()
    return bar
end

----------------------------------------------------------------------
-- ApplySettings
----------------------------------------------------------------------
function NS.ApplySettings(bar, cfg)
    bar.cfg = cfg
    bar:SetSize(cfg.width, cfg.height)
    bar:ClearAllPoints()
    bar:SetPoint(cfg.point, UIParent, cfg.point, cfg.x, cfg.y)

    -- Update rune textures if index changed
    local runeIndex = cfg.runeIndex or NS.defaultRuneIndex
    local runeData = NS.RuneShapes[runeIndex]
    if runeData then
        if bar.runeBg then
            bar.runeBg:SetTexture(runeData.texture)
        end
        if bar.rune then
            bar.rune:SetTexture(runeData.texture)
            bar.rune:SetSize(cfg.width, cfg.height)
        end
    end
end

----------------------------------------------------------------------
-- SetLock
----------------------------------------------------------------------
function NS.SetLock(locked)
    -- Drag handlers already check NS.db.locked
end

----------------------------------------------------------------------
-- TestCastBar
----------------------------------------------------------------------
function NS.TestCastBar(bar)
    if not bar then return end
    bar.casting = true
    bar.channeling = false
    bar.startTime = GetTime()
    bar.endTime = GetTime() + 3
    bar.holdTime = 0
    bar.text:SetText("Test Cast")
    bar.timer:SetText("3.0")
    bar.icon:SetTexture("Interface\\Icons\\Spell_Nature_Healing")

    local c = bar.cfg.barColor
    SetRuneColor(bar, c.r, c.g, c.b, c.a)
    SetRuneProgress(bar, 0)
    bar:SetAlpha(1)
    bar:Show()
end

----------------------------------------------------------------------
-- Event handler
----------------------------------------------------------------------
OnEvent = function(self, event, ...)
    local unit = select(1, ...)

    if event == "PLAYER_TARGET_CHANGED" then
        StartCast(self)
        if not self.casting then
            StartChannel(self)
        end
        if not self.casting and not self.channeling then
            self:Hide()
        end
        return
    end

    if unit ~= self.unit then return end

    if event == "UNIT_SPELLCAST_START" then
        StartCast(self)
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        StartChannel(self)
    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        StopCast(self)
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        if self.casting then
            FinishCast(self)
        end
    elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        InterruptCast(self)
    elseif event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
        StartChannel(self)
    end
end

----------------------------------------------------------------------
-- StartCast
----------------------------------------------------------------------
StartCast = function(bar)
    local name, _, texture, startTimeMS, endTimeMS = UnitCastingInfo(bar.unit)

    if not name then
        bar.casting = false
        return
    end

    bar.casting = true
    bar.channeling = false
    bar.startTime = startTimeMS / 1000
    bar.endTime = endTimeMS / 1000
    bar.holdTime = 0

    bar.text:SetText(name)
    if texture then bar.icon:SetTexture(texture) end

    local c = bar.cfg.barColor
    SetRuneColor(bar, c.r, c.g, c.b, c.a)
    SetRuneProgress(bar, 0)
    bar:SetAlpha(1)
    bar:Show()
end

----------------------------------------------------------------------
-- StartChannel
----------------------------------------------------------------------
StartChannel = function(bar)
    local name, _, texture, startTimeMS, endTimeMS = UnitChannelInfo(bar.unit)

    if not name then
        bar.channeling = false
        return
    end

    bar.channeling = true
    bar.casting = false
    bar.startTime = startTimeMS / 1000
    bar.endTime = endTimeMS / 1000
    bar.holdTime = 0

    bar.text:SetText(name)
    if texture then bar.icon:SetTexture(texture) end

    local c = bar.cfg.barColor
    SetRuneColor(bar, c.r, c.g, c.b, c.a)
    SetRuneProgress(bar, 1)
    bar:SetAlpha(1)
    bar:Show()
end

----------------------------------------------------------------------
-- StopCast
----------------------------------------------------------------------
StopCast = function(bar)
    bar.casting = false
    bar.channeling = false
    bar.holdTime = GetTime() + 0.5
end

----------------------------------------------------------------------
-- FinishCast - flash green
----------------------------------------------------------------------
FinishCast = function(bar)
    bar.casting = false
    SetRuneProgress(bar, 1)
    SetRuneColor(bar, 0.0, 1.0, 0.0, 1.0)
    bar.holdTime = GetTime() + 0.5
end

----------------------------------------------------------------------
-- InterruptCast - flash red
----------------------------------------------------------------------
InterruptCast = function(bar)
    bar.casting = false
    bar.channeling = false

    local c = bar.cfg.interruptedColor
    SetRuneColor(bar, c.r, c.g, c.b, c.a)
    SetRuneProgress(bar, 1)
    bar.text:SetText("Interrupted")
    bar.holdTime = GetTime() + 0.8
end

----------------------------------------------------------------------
-- OnUpdate - animate rune reveal based on cast progress
----------------------------------------------------------------------
OnUpdate = function(bar, elapsed)
    local now = GetTime()

    -- Hold phase: wait then hide
    if bar.holdTime > 0 and not bar.casting and not bar.channeling then
        if now >= bar.holdTime then
            bar:Hide()
            bar.holdTime = 0
        end
        return
    end

    if bar.casting then
        local duration = bar.endTime - bar.startTime
        if duration <= 0 then return end
        local progress = (now - bar.startTime) / duration

        if progress >= 1 then
            FinishCast(bar)
            return
        end

        SetRuneProgress(bar, progress)

        if bar.cfg.showTimer then
            bar.timer:SetFormattedText("%.1f", bar.endTime - now)
        end

    elseif bar.channeling then
        local duration = bar.endTime - bar.startTime
        if duration <= 0 then return end
        local progress = (bar.endTime - now) / duration

        if progress <= 0 then
            StopCast(bar)
            return
        end

        SetRuneProgress(bar, progress)

        if bar.cfg.showTimer then
            bar.timer:SetFormattedText("%.1f", bar.endTime - now)
        end
    end
end
