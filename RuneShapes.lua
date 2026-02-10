----------------------------------------------------------------------
-- RuneMagic Castbars - RuneShapes
-- Each rune has a full texture (for dim bg) and an ordered list of
-- path segments that define the drawing order for the glow wave.
-- Coordinates are normalized 0-1 within the bar dimensions.
----------------------------------------------------------------------

local AddonName, NS = ...

local MEDIA = "Interface\\AddOns\\RuneMagicCastbars\\Media\\"

NS.RuneShapes = {
    [1] = {
        name = "Thurisaz",
        texture = MEDIA .. "Rune_Thurisaz",
        -- diagonal up, flat top, down to mid, right, diagonal up
        path = {
            { 0.05, 0.85,  0.20, 0.15 },
            { 0.20, 0.15,  0.55, 0.15 },
            { 0.55, 0.15,  0.55, 0.50 },
            { 0.55, 0.50,  0.75, 0.50 },
            { 0.75, 0.50,  0.90, 0.15 },
        },
    },
    [2] = {
        name = "Kenaz",
        texture = MEDIA .. "Rune_Kenaz",
        -- gate shape: up, across, down, step, down, right
        path = {
            { 0.05, 0.85,  0.05, 0.15 },
            { 0.05, 0.15,  0.45, 0.15 },
            { 0.45, 0.15,  0.45, 0.55 },
            { 0.45, 0.55,  0.55, 0.55 },
            { 0.55, 0.55,  0.55, 0.85 },
            { 0.55, 0.85,  0.90, 0.85 },
        },
    },
    [3] = {
        name = "Dagaz",
        texture = MEDIA .. "Rune_Dagaz",
        -- zigzag: diagonal up, flat, down, step right, diagonal up
        path = {
            { 0.05, 0.85,  0.25, 0.15 },
            { 0.25, 0.15,  0.50, 0.15 },
            { 0.50, 0.15,  0.50, 0.55 },
            { 0.50, 0.55,  0.65, 0.55 },
            { 0.65, 0.55,  0.90, 0.15 },
        },
    },
    [4] = {
        name = "Algiz",
        texture = MEDIA .. "Rune_Algiz",
        -- check/arrow: diagonal down, flat, diagonal up
        path = {
            { 0.05, 0.15,  0.30, 0.85 },
            { 0.30, 0.85,  0.55, 0.85 },
            { 0.55, 0.85,  0.90, 0.15 },
        },
    },
}

NS.defaultRuneIndex = 3
