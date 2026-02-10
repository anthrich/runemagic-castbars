----------------------------------------------------------------------
-- RuneMagic Castbars - CastBar
-- Rune-shaped castbar with segment glow wave animation.
-- The full rune is always visible (dim). A glow wave travels along
-- the path, leaving lit segments behind as the cast progresses.
----------------------------------------------------------------------

local AddonName, NS = ...

local math_sqrt = math.sqrt
local math_atan2 = math.atan2
local math_min = math.min
local math_max = math.max

local OnUpdate, OnEvent, StartCast, StartChannel, StopCast, FinishCast
local InterruptCast, BuildSegments, UpdateSegments, SetAllSegmentsColor

----------------------------------------------------------------------
-- BuildSegments(bar) - subdivide each path segment into small chunks
-- so the fill travels smoothly within each stroke.
----------------------------------------------------------------------
local CHUNK_PX = 6  -- approximate pixel length per sub-segment

BuildSegments = function(bar)
    -- Clean up old chunks
    if bar.segs then
        for _, s in ipairs(bar.segs) do
            s.tex:Hide()
        end
    end
    bar.segs = {}

    local runeIndex = bar.cfg.runeIndex or NS.defaultRuneIndex
    local runeData = NS.RuneShapes[runeIndex]
    if not runeData or not runeData.path then return end

    local w, h = bar.cfg.width, bar.cfg.height
    local thick = bar.cfg.strokeThickness or 5

    -- First pass: calculate total path length
    local totalLen = 0
    local pathSegLens = {}
    for i, seg in ipairs(runeData.path) do
        local dx = (seg[3] - seg[1]) * w
        local dy = (seg[4] - seg[2]) * h
        pathSegLens[i] = math_sqrt(dx * dx + dy * dy)
        totalLen = totalLen + pathSegLens[i]
    end
    bar.totalLen = totalLen
    if totalLen < 1 then return end

    -- Second pass: subdivide each path segment into chunks
    local cumLen = 0
    for i, seg in ipairs(runeData.path) do
        local px1 = seg[1] * w
        local py1 = (1 - seg[2]) * h
        local px2 = seg[3] * w
        local py2 = (1 - seg[4]) * h

        local segLen = pathSegLens[i]
        if segLen < 1 then segLen = 1 end

        local numChunks = math_max(1, math.floor(segLen / CHUNK_PX + 0.5))
        local chunkLen = segLen / numChunks

        local dx = (px2 - px1) / numChunks
        local dy = (py2 - py1) / numChunks
        local angle = math_atan2(py2 - py1, px2 - px1)

        for j = 0, numChunks - 1 do
            local cx = px1 + dx * (j + 0.5)
            local cy = py1 + dy * (j + 0.5)

            local tex = bar.canvas:CreateTexture(nil, "ARTWORK")
            tex:SetColorTexture(1, 1, 1, 1)
            -- Slightly overlap chunks to avoid gaps at joints
            tex:SetSize(chunkLen + 1, thick)
            tex:SetPoint("CENTER", bar.canvas, "BOTTOMLEFT", cx, cy)
            tex:SetRotation(-angle)

            local startProg = cumLen / totalLen
            cumLen = cumLen + chunkLen
            local endProg = cumLen / totalLen

            local dc = bar.cfg.dimColor or { r = 0.15, g = 0.15, b = 0.15 }
            tex:SetVertexColor(dc.r, dc.g, dc.b, 0.5)

            bar.segs[#bar.segs + 1] = {
                tex = tex,
                startProg = startProg,
                endProg = endProg,
            }
        end
    end
end

----------------------------------------------------------------------
-- UpdateSegments(bar, progress) - glow wave along path
-- Chunks behind progress are lit. The leading chunk glows brighter.
----------------------------------------------------------------------
UpdateSegments = function(bar, progress)
    if not bar.segs then return end
    local c = bar.cfg.barColor
    local dc = bar.cfg.dimColor or { r = 0.15, g = 0.15, b = 0.15 }
    local glowMul = 1.5

    for _, s in ipairs(bar.segs) do
        if progress >= s.endProg then
            -- Fully past: lit
            s.tex:SetVertexColor(c.r, c.g, c.b, c.a)
        elseif progress > s.startProg then
            -- Leading chunk: bright glow
            local gr = math_min(1.0, c.r * glowMul)
            local gg = math_min(1.0, c.g * glowMul)
            local gb = math_min(1.0, c.b * glowMul)
            s.tex:SetVertexColor(gr, gg, gb, 1.0)
        else
            -- Not reached: dim
            s.tex:SetVertexColor(dc.r, dc.g, dc.b, 0.5)
        end
    end
end

----------------------------------------------------------------------
-- SetAllSegmentsColor(bar, r, g, b, a) - override all segment colors
----------------------------------------------------------------------
SetAllSegmentsColor = function(bar, r, g, b, a)
    if not bar.segs then return end
    for _, s in ipairs(bar.segs) do
        s.tex:SetVertexColor(r, g, b, a or 1)
    end
end

----------------------------------------------------------------------
-- ResetSegmentsDim(bar) - set all chunks to dim
----------------------------------------------------------------------
local function ResetSegmentsDim(bar)
    if not bar.segs then return end
    local dc = bar.cfg.dimColor or { r = 0.15, g = 0.15, b = 0.15 }
    for _, s in ipairs(bar.segs) do
        s.tex:SetVertexColor(dc.r, dc.g, dc.b, 0.5)
    end
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

    -- Canvas for segment textures
    bar.canvas = CreateFrame("Frame", nil, bar)
    bar.canvas:SetAllPoints()

    -- Build path segment textures
    BuildSegments(bar)

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

    BuildSegments(bar)
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

    ResetSegmentsDim(bar)
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

    ResetSegmentsDim(bar)
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

    -- Channels start fully lit
    UpdateSegments(bar, 1)
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
    SetAllSegmentsColor(bar, 0.0, 1.0, 0.0, 1.0)
    bar.holdTime = GetTime() + 0.5
end

----------------------------------------------------------------------
-- InterruptCast - flash red
----------------------------------------------------------------------
InterruptCast = function(bar)
    bar.casting = false
    bar.channeling = false

    local c = bar.cfg.interruptedColor
    SetAllSegmentsColor(bar, c.r, c.g, c.b, c.a)
    bar.text:SetText("Interrupted")
    bar.holdTime = GetTime() + 0.8
end

----------------------------------------------------------------------
-- OnUpdate - glow wave along path based on cast progress
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

        UpdateSegments(bar, progress)

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

        UpdateSegments(bar, progress)

        if bar.cfg.showTimer then
            bar.timer:SetFormattedText("%.1f", bar.endTime - now)
        end
    end
end
