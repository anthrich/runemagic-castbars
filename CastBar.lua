----------------------------------------------------------------------
-- RuneMagic Castbars - CastBar
-- Rune-shaped castbar: strokes are revealed left-to-right as cast
-- progresses, forming a Dwarven glyph.
----------------------------------------------------------------------

local AddonName, NS = ...

local OnUpdate, OnEvent, StartCast, StartChannel, StopCast, FinishCast
local InterruptCast, BuildRuneStrokes, SetStrokeColor, RevealStrokes

----------------------------------------------------------------------
-- BuildRuneStrokes(bar) - create texture lines for the chosen rune
----------------------------------------------------------------------
BuildRuneStrokes = function(bar)
    -- Clean up old strokes
    if bar.strokes then
        for _, s in ipairs(bar.strokes) do
            s.tex:Hide()
            s.tex:SetParent(nil)
        end
    end
    bar.strokes = {}

    local runeIndex = bar.cfg.runeIndex or NS.defaultRuneIndex
    local rune = NS.RuneShapes[runeIndex]
    if not rune then return end

    local w, h = bar.cfg.width, bar.cfg.height

    for i, stroke in ipairs(rune) do
        local tex = bar.canvas:CreateTexture(nil, "ARTWORK")
        tex:SetColorTexture(1, 1, 1, 1)

        -- Convert normalized coords to pixel positions
        local px1 = stroke.x1 * w
        local py1 = (1 - stroke.y1) * h  -- flip y: 0=top in WoW
        local px2 = stroke.x2 * w
        local py2 = (1 - stroke.y2) * h

        local dx = px2 - px1
        local dy = py2 - py1
        local len = math.sqrt(dx * dx + dy * dy)
        local thick = stroke.thickness or 3

        if len < 1 then len = 1 end

        -- WoW textures are axis-aligned rectangles, so we approximate
        -- angled strokes with a rotated texture via SetRotation.
        local angle = math.atan2(dy, dx)

        tex:SetSize(len, thick)
        -- Anchor at midpoint of the stroke
        local mx = (px1 + px2) / 2
        local my = (py1 + py2) / 2
        tex:SetPoint("CENTER", bar.canvas, "BOTTOMLEFT", mx, my)
        tex:SetRotation(-angle)
        tex:Hide()

        -- revealX = leftmost x coord, used to decide when to show
        local revealX = math.min(stroke.x1, stroke.x2)

        bar.strokes[i] = {
            tex = tex,
            revealX = revealX,
            visible = false,
        }
    end
end

----------------------------------------------------------------------
-- SetStrokeColor(bar, r, g, b, a) - recolor all strokes
----------------------------------------------------------------------
SetStrokeColor = function(bar, r, g, b, a)
    if not bar.strokes then return end
    for _, s in ipairs(bar.strokes) do
        s.tex:SetColorTexture(r, g, b, a or 1)
    end
end

----------------------------------------------------------------------
-- RevealStrokes(bar, progress) - show strokes up to progress (0-1)
----------------------------------------------------------------------
RevealStrokes = function(bar, progress)
    if not bar.strokes then return end
    for _, s in ipairs(bar.strokes) do
        if s.revealX <= progress then
            if not s.visible then
                s.tex:Show()
                s.visible = true
            end
        else
            if s.visible then
                s.tex:Hide()
                s.visible = false
            end
        end
    end
end

----------------------------------------------------------------------
-- HideAllStrokes(bar)
----------------------------------------------------------------------
local function HideAllStrokes(bar)
    if not bar.strokes then return end
    for _, s in ipairs(bar.strokes) do
        s.tex:Hide()
        s.visible = false
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

    -- Dim background
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetColorTexture(
        cfg.bgColor.r, cfg.bgColor.g, cfg.bgColor.b, cfg.bgColor.a
    )

    -- Canvas for rune strokes (child frame so strokes layer properly)
    bar.canvas = CreateFrame("Frame", nil, bar)
    bar.canvas:SetAllPoints()

    -- Build rune stroke textures
    BuildRuneStrokes(bar)

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

    if bar.bg then
        bar.bg:SetColorTexture(
            cfg.bgColor.r, cfg.bgColor.g, cfg.bgColor.b, cfg.bgColor.a
        )
    end

    BuildRuneStrokes(bar)
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
    SetStrokeColor(bar, c.r, c.g, c.b, c.a)
    HideAllStrokes(bar)
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
    SetStrokeColor(bar, c.r, c.g, c.b, c.a)
    HideAllStrokes(bar)
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
    SetStrokeColor(bar, c.r, c.g, c.b, c.a)
    RevealStrokes(bar, 1)  -- channels start full
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
    RevealStrokes(bar, 1)
    SetStrokeColor(bar, 0.0, 1.0, 0.0, 1.0)
    bar.holdTime = GetTime() + 0.5
end

----------------------------------------------------------------------
-- InterruptCast - flash red
----------------------------------------------------------------------
InterruptCast = function(bar)
    bar.casting = false
    bar.channeling = false

    local c = bar.cfg.interruptedColor
    SetStrokeColor(bar, c.r, c.g, c.b, c.a)
    RevealStrokes(bar, 1)
    bar.text:SetText("Interrupted")
    bar.holdTime = GetTime() + 0.8
end

----------------------------------------------------------------------
-- OnUpdate - reveal strokes based on cast progress
----------------------------------------------------------------------
OnUpdate = function(bar, elapsed)
    local now = GetTime()

    -- Hold phase: wait then hide
    if bar.holdTime > 0 and not bar.casting and not bar.channeling then
        if now >= bar.holdTime then
            bar:Hide()
            bar.holdTime = 0
            HideAllStrokes(bar)
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

        RevealStrokes(bar, progress)

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

        RevealStrokes(bar, progress)

        if bar.cfg.showTimer then
            bar.timer:SetFormattedText("%.1f", bar.endTime - now)
        end
    end
end
