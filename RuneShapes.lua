----------------------------------------------------------------------
-- RuneMagic Castbars - RuneShapes
-- Defines Dwarven-style rune glyphs as stroke segments.
--
-- Each rune is a list of strokes. Each stroke is a table:
--   { x1, y1, x2, y2, thickness }
-- Coordinates are normalized 0-1 within the bar area.
-- x1,y1 = start point; x2,y2 = end point.
-- Strokes are revealed left-to-right based on their leftmost x.
----------------------------------------------------------------------

local AddonName, NS = ...

NS.RuneShapes = {}

-- Rune 1: "Thurisaz" (thorn) — angular ᚦ shape
-- A vertical spine with two angular strokes branching right
NS.RuneShapes[1] = {
    -- Vertical spine
    { x1 = 0.15, y1 = 0.05, x2 = 0.15, y2 = 0.95, thickness = 3 },
    -- Upper branch right
    { x1 = 0.15, y1 = 0.20, x2 = 0.45, y2 = 0.50, thickness = 3 },
    -- Lower branch back
    { x1 = 0.45, y1 = 0.50, x2 = 0.15, y2 = 0.75, thickness = 3 },
    -- Horizontal cross-bar
    { x1 = 0.50, y1 = 0.50, x2 = 0.85, y2 = 0.50, thickness = 3 },
    -- Right diagonal down
    { x1 = 0.85, y1 = 0.50, x2 = 0.85, y2 = 0.95, thickness = 3 },
    -- Right diagonal up
    { x1 = 0.85, y1 = 0.50, x2 = 0.85, y2 = 0.05, thickness = 3 },
}

-- Rune 2: "Kenaz" (torch) — < shape with tail
NS.RuneShapes[2] = {
    -- Upper diagonal
    { x1 = 0.10, y1 = 0.50, x2 = 0.40, y2 = 0.05, thickness = 3 },
    -- Lower diagonal
    { x1 = 0.10, y1 = 0.50, x2 = 0.40, y2 = 0.95, thickness = 3 },
    -- Horizontal bar
    { x1 = 0.40, y1 = 0.50, x2 = 0.90, y2 = 0.50, thickness = 3 },
}

-- Rune 3: "Dagaz" (day) — hourglass / butterfly
NS.RuneShapes[3] = {
    -- Left vertical
    { x1 = 0.10, y1 = 0.05, x2 = 0.10, y2 = 0.95, thickness = 3 },
    -- Top-left to center
    { x1 = 0.10, y1 = 0.05, x2 = 0.50, y2 = 0.50, thickness = 3 },
    -- Bottom-left to center
    { x1 = 0.10, y1 = 0.95, x2 = 0.50, y2 = 0.50, thickness = 3 },
    -- Center to top-right
    { x1 = 0.50, y1 = 0.50, x2 = 0.90, y2 = 0.05, thickness = 3 },
    -- Center to bottom-right
    { x1 = 0.50, y1 = 0.50, x2 = 0.90, y2 = 0.95, thickness = 3 },
    -- Right vertical
    { x1 = 0.90, y1 = 0.05, x2 = 0.90, y2 = 0.95, thickness = 3 },
}

-- Rune 4: "Algiz" (protection) — upward fork ᛉ
NS.RuneShapes[4] = {
    -- Vertical spine
    { x1 = 0.50, y1 = 0.95, x2 = 0.50, y2 = 0.10, thickness = 3 },
    -- Left branch
    { x1 = 0.50, y1 = 0.35, x2 = 0.15, y2 = 0.05, thickness = 3 },
    -- Right branch
    { x1 = 0.50, y1 = 0.35, x2 = 0.85, y2 = 0.05, thickness = 3 },
}

-- Default rune index
NS.defaultRuneIndex = 3
