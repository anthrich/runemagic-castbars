----------------------------------------------------------------------
-- RuneMagic Castbars - RuneShapes
-- Maps rune indices to TGA texture paths in Media/.
----------------------------------------------------------------------

local AddonName, NS = ...

local MEDIA = "Interface\\AddOns\\RuneMagicCastbars\\Media\\"

NS.RuneShapes = {
    [1] = { name = "Thurisaz", texture = MEDIA .. "Rune_Thurisaz" },
    [2] = { name = "Kenaz",    texture = MEDIA .. "Rune_Kenaz" },
    [3] = { name = "Dagaz",    texture = MEDIA .. "Rune_Dagaz" },
    [4] = { name = "Algiz",    texture = MEDIA .. "Rune_Algiz" },
}

NS.stoneBgTexture = MEDIA .. "StoneBg"
NS.defaultRuneIndex = 3
