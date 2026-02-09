----------------------------------------------------------------------
-- RuneMagic Castbars - CastBar
-- Creates and manages individual castbar frames.
----------------------------------------------------------------------

local AddonName, NS = ...

----------------------------------------------------------------------
-- Forward declarations
----------------------------------------------------------------------
local OnUpdate, OnEvent, StartCast, StartChannel, StopCast, FinishCast
local InterruptCast, UpdateBarVisuals

----------------------------------------------------------------------
-- CreateCastBar(unit, cfg) -> frame
-- Builds a movable castbar frame for the given unit ("player"/"target").
----------------------------------------------------------------------
function NS.CreateCastBar(unit, cfg)
    local bar = CreateFrame("StatusBar", "RuneMagicCastbar_" .. unit, UIParent, "BackdropTemplate")
    bar.unit = unit
    bar.cfg = cfg
    bar.casting = false
    bar.channeling = false
    bar.holdTime = 0

    -- Backdrop (background)
    bar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })

    -- Status bar texture
    bar:SetStatusBarTexture(cfg.texture)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)

    -- Apply size, position, colors
    NS.ApplySettings(bar, cfg)

    -- Border frame (renders on top)
    bar.border = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    bar.border:SetAllPoints()
    bar.border:SetFrameLevel(bar:GetFrameLevel() + 2)

    -- Spell name text
    bar.text = bar:CreateFontString(nil, "OVERLAY")
    bar.text:SetFont(cfg.font, cfg.fontSize, "OUTLINE")
    bar.text:SetPoint("LEFT", bar, "LEFT", 4, 0)
    bar.text:SetJustifyH("LEFT")
    bar.text:SetTextColor(1, 1, 1, 1)

    -- Timer text
    bar.timer = bar:CreateFontString(nil, "OVERLAY")
    bar.timer:SetFont(cfg.font, cfg.fontSize, "OUTLINE")
    bar.timer:SetPoint("RIGHT", bar, "RIGHT", -4, 0)
    bar.timer:SetJustifyH("RIGHT")
    bar.timer:SetTextColor(1, 1, 1, 1)
    if not cfg.showTimer then bar.timer:Hide() end

    -- Spark (glow on leading edge)
    bar.spark = bar:CreateTexture(nil, "OVERLAY")
    bar.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    bar.spark:SetSize(20, cfg.height * 2.5)
    bar.spark:SetBlendMode("ADD")
    if not cfg.showSpark then bar.spark:Hide() end

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

    if unit == "player" then
        bar:RegisterEvent("UNIT_SPELLCAST_START")
        bar:RegisterEvent("UNIT_SPELLCAST_STOP")
        bar:RegisterEvent("UNIT_SPELLCAST_FAILED")
        bar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
        bar:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        bar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
        bar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
        bar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
        bar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
        bar:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
    elseif unit == "target" then
        bar:RegisterEvent("UNIT_SPELLCAST_START")
        bar:RegisterEvent("UNIT_SPELLCAST_STOP")
        bar:RegisterEvent("UNIT_SPELLCAST_FAILED")
        bar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
        bar:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        bar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
        bar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
        bar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
        bar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
        bar:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
        bar:RegisterEvent("PLAYER_TARGET_CHANGED")
    end

    bar:Hide()
    return bar
end

----------------------------------------------------------------------
-- ApplySettings(bar, cfg) - resize / reposition / recolor a bar
----------------------------------------------------------------------
function NS.ApplySettings(bar, cfg)
    bar.cfg = cfg
    bar:SetSize(cfg.width, cfg.height)
    bar:ClearAllPoints()
    bar:SetPoint(cfg.point, UIParent, cfg.point, cfg.x, cfg.y)

    bar:SetBackdropColor(cfg.bgColor.r, cfg.bgColor.g, cfg.bgColor.b, cfg.bgColor.a)
    bar:SetBackdropBorderColor(0, 0, 0, 0.8)

    bar:SetStatusBarColor(cfg.barColor.r, cfg.barColor.g, cfg.barColor.b, cfg.barColor.a)
end

----------------------------------------------------------------------
-- SetLock(locked) - enable / disable dragging on all bars
----------------------------------------------------------------------
function NS.SetLock(locked)
    -- Nothing extra needed; drag handlers already check NS.db.locked
end

----------------------------------------------------------------------
-- TestCastBar(bar) - show a fake 3-second cast for previewing
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
    bar:SetStatusBarColor(c.r, c.g, c.b, c.a)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    bar:SetAlpha(1)
    bar:Show()
end

----------------------------------------------------------------------
-- Event handler
----------------------------------------------------------------------
OnEvent = function(self, event, ...)
    local unit = select(1, ...)

    if event == "PLAYER_TARGET_CHANGED" then
        -- Re-check target cast on target switch
        StartCast(self)
        if not self.casting then
            StartChannel(self)
        end
        if not self.casting and not self.channeling then
            self:Hide()
        end
        return
    end

    -- Only handle events for our unit
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
    elseif event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
        if self.channeling or self.casting then
            bar.notInterruptible = true
        end
    elseif event == "UNIT_SPELLCAST_INTERRUPTIBLE" then
        if self.channeling or self.casting then
            bar.notInterruptible = false
        end
    end
end

----------------------------------------------------------------------
-- StartCast - begin showing a normal cast
----------------------------------------------------------------------
StartCast = function(bar)
    local name, _, texture, startTimeMS, endTimeMS, _, _, notInterruptible, spellID
    if bar.unit == "player" then
        local info = UnitCastingInfo("player")
        if not info then
            bar.casting = false
            return
        end
        name, _, texture, startTimeMS, endTimeMS, _, _, notInterruptible, spellID =
            UnitCastingInfo(bar.unit)
    else
        name, _, texture, startTimeMS, endTimeMS, _, _, notInterruptible, spellID =
            UnitCastingInfo(bar.unit)
    end

    if not name then
        bar.casting = false
        return
    end

    bar.casting = true
    bar.channeling = false
    bar.startTime = startTimeMS / 1000
    bar.endTime = endTimeMS / 1000
    bar.holdTime = 0
    bar.notInterruptible = notInterruptible

    bar.text:SetText(name)
    if texture then
        bar.icon:SetTexture(texture)
    end

    local c = bar.cfg.barColor
    bar:SetStatusBarColor(c.r, c.g, c.b, c.a)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    bar:SetAlpha(1)
    bar:Show()
end

----------------------------------------------------------------------
-- StartChannel - begin showing a channeled cast
----------------------------------------------------------------------
StartChannel = function(bar)
    local name, _, texture, startTimeMS, endTimeMS, _, notInterruptible, spellID =
        UnitChannelInfo(bar.unit)

    if not name then
        bar.channeling = false
        return
    end

    bar.channeling = true
    bar.casting = false
    bar.startTime = startTimeMS / 1000
    bar.endTime = endTimeMS / 1000
    bar.holdTime = 0
    bar.notInterruptible = notInterruptible

    bar.text:SetText(name)
    if texture then
        bar.icon:SetTexture(texture)
    end

    local c = bar.cfg.barColor
    bar:SetStatusBarColor(c.r, c.g, c.b, c.a)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(1)
    bar:SetAlpha(1)
    bar:Show()
end

----------------------------------------------------------------------
-- StopCast - hide after a brief hold
----------------------------------------------------------------------
StopCast = function(bar)
    bar.casting = false
    bar.channeling = false
    bar.holdTime = GetTime() + 0.5
end

----------------------------------------------------------------------
-- FinishCast - flash and fade on successful cast
----------------------------------------------------------------------
FinishCast = function(bar)
    bar.casting = false
    bar:SetValue(1)
    bar:SetStatusBarColor(0.0, 1.0, 0.0, 1.0)
    bar.holdTime = GetTime() + 0.5
    if bar.spark then bar.spark:Hide() end
end

----------------------------------------------------------------------
-- InterruptCast - show red bar briefly
----------------------------------------------------------------------
InterruptCast = function(bar)
    bar.casting = false
    bar.channeling = false

    local c = bar.cfg.interruptedColor
    bar:SetStatusBarColor(c.r, c.g, c.b, c.a)
    bar:SetValue(1)
    bar.text:SetText("Interrupted")
    bar.holdTime = GetTime() + 0.8
    if bar.spark then bar.spark:Hide() end
end

----------------------------------------------------------------------
-- OnUpdate - animate the bar each frame
----------------------------------------------------------------------
OnUpdate = function(bar, elapsed)
    local now = GetTime()

    -- Fade out after holdTime expires
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
            bar:SetValue(1)
            FinishCast(bar)
            return
        end

        bar:SetValue(progress)

        -- Update spark position
        if bar.spark and bar.cfg.showSpark then
            bar.spark:Show()
            bar.spark:SetPoint("CENTER", bar, "LEFT", progress * bar.cfg.width, 0)
        end

        -- Update timer
        if bar.cfg.showTimer then
            local remaining = bar.endTime - now
            bar.timer:SetFormattedText("%.1f", remaining)
        end

    elseif bar.channeling then
        local duration = bar.endTime - bar.startTime
        if duration <= 0 then return end
        local progress = (bar.endTime - now) / duration

        if progress <= 0 then
            StopCast(bar)
            return
        end

        bar:SetValue(progress)

        -- Update spark position
        if bar.spark and bar.cfg.showSpark then
            bar.spark:Show()
            bar.spark:SetPoint("CENTER", bar, "LEFT", progress * bar.cfg.width, 0)
        end

        -- Update timer
        if bar.cfg.showTimer then
            local remaining = bar.endTime - now
            bar.timer:SetFormattedText("%.1f", remaining)
        end
    end
end
