----------------------------------------------------------------------
-- RuneMagic Castbars - RuneShapes
-- Each rune has a full texture (for dim bg) and an ordered list of
-- path segments that define the drawing order for the glow wave.
-- Coordinates are normalized 0-1 within the bar dimensions.
-- y=0 is top, y=1 is bottom (CastBar.lua flips for WoW coords).
----------------------------------------------------------------------

local AddonName, NS = ...

local MEDIA = "Interface\\AddOns\\RuneMagicCastbars\\Media\\"

NS.RuneShapes = {
    -- 1. Birth: circle atop a vertical line with horizontal crossbar
    [1] = {
        name = "Birth",
        texture = MEDIA .. "Rune_Birth",
        path = {
            -- Shaft: bottom up to circle base
            { 0.50, 0.92,  0.50, 0.33 },
            -- Circle (4 quarter-arc straight segments, clockwise from bottom)
            { 0.50, 0.33,  0.555, 0.22 },
            { 0.555, 0.22,  0.50, 0.11 },
            { 0.50, 0.11,  0.445, 0.22 },
            { 0.445, 0.22,  0.50, 0.33 },
            -- Horizontal crossbar through circle
            { 0.42, 0.22,  0.58, 0.22 },
        },
    },
    -- 2. Protection: diamond atop a vertical line with horizontal bar
    [2] = {
        name = "Protection",
        texture = MEDIA .. "Rune_Protection",
        path = {
            -- Shaft: bottom up to diamond base
            { 0.50, 0.92,  0.50, 0.38 },
            -- Diamond edges (clockwise from bottom)
            { 0.50, 0.38,  0.563, 0.25 },
            { 0.563, 0.25,  0.50, 0.12 },
            { 0.50, 0.12,  0.437, 0.25 },
            { 0.437, 0.25,  0.50, 0.38 },
            -- Horizontal bar through diamond center
            { 0.35, 0.25,  0.65, 0.25 },
        },
    },
    -- 3. War: upward arrow atop a vertical shaft
    [3] = {
        name = "War",
        texture = MEDIA .. "Rune_War",
        path = {
            -- Shaft: bottom up to arrowhead tip
            { 0.50, 0.92,  0.50, 0.25 },
            -- Arrowhead left
            { 0.50, 0.25,  0.32, 0.42 },
            -- Arrowhead right
            { 0.50, 0.25,  0.68, 0.42 },
            -- Horizontal bar connecting arrowhead bases
            { 0.35, 0.40,  0.65, 0.40 },
        },
    },
    -- 4. Healing: T-fork with prongs and crescent arc
    [4] = {
        name = "Healing",
        texture = MEDIA .. "Rune_Healing",
        path = {
            -- Shaft: bottom up to horizontal bar
            { 0.50, 0.92,  0.50, 0.18 },
            -- Horizontal bar left
            { 0.50, 0.18,  0.32, 0.18 },
            -- Horizontal bar right
            { 0.50, 0.18,  0.68, 0.18 },
            -- Left prong up
            { 0.35, 0.18,  0.35, 0.10 },
            -- Right prong up
            { 0.65, 0.18,  0.65, 0.10 },
            -- Crescent arc (semicircle above, left to right)
            { 0.46, 0.10,  0.50, 0.02 },
            { 0.50, 0.02,  0.54, 0.10 },
        },
    },
    -- 5. Love: two circles (eyes) with vertical line and bar
    [5] = {
        name = "Love",
        texture = MEDIA .. "Rune_Love",
        path = {
            -- Shaft: bottom up
            { 0.50, 0.92,  0.50, 0.32 },
            -- Horizontal bar
            { 0.38, 0.38,  0.62, 0.38 },
            -- Left circle (clockwise from bottom, r=8 -> rx~0.031, ry~0.063)
            { 0.38, 0.28,  0.411, 0.22 },
            { 0.411, 0.22,  0.38, 0.16 },
            { 0.38, 0.16,  0.349, 0.22 },
            { 0.349, 0.22,  0.38, 0.28 },
            -- Right circle (clockwise from bottom)
            { 0.62, 0.28,  0.651, 0.22 },
            { 0.651, 0.22,  0.62, 0.16 },
            { 0.62, 0.16,  0.589, 0.22 },
            { 0.589, 0.22,  0.62, 0.28 },
        },
    },
    -- 6. Strength: asterisk / X cross with vertical line
    [6] = {
        name = "Strength",
        texture = MEDIA .. "Rune_Strength",
        -- Center at (0.50, 0.35), size 18px -> sx~0.070, sy~0.141
        path = {
            -- Full vertical shaft
            { 0.50, 0.92,  0.50, 0.10 },
            -- X diagonal: top-left to bottom-right
            { 0.43, 0.21,  0.57, 0.49 },
            -- X diagonal: bottom-left to top-right
            { 0.43, 0.49,  0.57, 0.21 },
            -- Horizontal through center
            { 0.43, 0.35,  0.57, 0.35 },
        },
    },
    -- 7. Return: trident, three prongs spreading upward from base
    [7] = {
        name = "Return",
        texture = MEDIA .. "Rune_Return",
        path = {
            -- Center vertical shaft (bottom to top)
            { 0.50, 0.92,  0.50, 0.10 },
            -- Left prong diverging upward
            { 0.50, 0.50,  0.30, 0.10 },
            -- Right prong diverging upward
            { 0.50, 0.50,  0.70, 0.10 },
        },
    },
    -- 8. Death: vertical line with cross bar, hash marks, and circle
    [8] = {
        name = "Death",
        texture = MEDIA .. "Rune_Death",
        path = {
            -- Full vertical shaft
            { 0.50, 0.92,  0.50, 0.10 },
            -- Top horizontal bar
            { 0.35, 0.22,  0.65, 0.22 },
            -- Three hash marks on right side
            { 0.55, 0.42,  0.70, 0.42 },
            { 0.55, 0.52,  0.70, 0.52 },
            { 0.55, 0.62,  0.70, 0.62 },
            -- Small circle near top (r=6 -> rx~0.023, ry~0.047)
            { 0.50, 0.20,  0.523, 0.15 },
            { 0.523, 0.15,  0.50, 0.10 },
            { 0.50, 0.10,  0.477, 0.15 },
            { 0.477, 0.15,  0.50, 0.20 },
        },
    },
}

NS.defaultRuneIndex = 1
