# RuneMagic Castbars

## Project Overview

A World of Warcraft addon that replaces the default Blizzard castbars with clean, customizable alternatives for both the player and target units.

## File Structure

```
RuneMagicCastbars.toc   -- Addon metadata and load order (Interface 11.1.0 / Retail)
Core.lua                -- Initialization, saved variables, slash commands, Blizzard bar suppression
CastBar.lua             -- Castbar frame creation, event handling, and animation
Config.lua              -- Settings re-application on reload; future options panel
```

## Architecture

- **Namespace:** All files share a private namespace table (`NS`) via the `...` vararg pattern. Global state lives in `NS`; avoid polluting `_G`.
- **Saved Variables:** Persisted in `RuneMagicCastbarsDB` (declared in the `.toc`). On first load, defaults from `NS.defaults` are deep-copied in. On subsequent loads, missing keys are merged non-destructively.
- **Load Order:** `Core.lua` → `CastBar.lua` → `Config.lua` (as listed in the `.toc`). Core sets up the namespace and defaults; CastBar defines `NS.CreateCastBar`; Config hooks post-login settings refresh.

## Key Conventions

- **Lua version:** WoW uses Lua 5.1. Do not use features from later Lua versions (e.g., `goto`, integer division `//`, bitwise operators).
- **API surface:** Use the Blizzard WoW API (`CreateFrame`, `UnitCastingInfo`, `UnitChannelInfo`, etc.). Do not assume libraries like LibStub or Ace3 are present unless explicitly added.
- **No external dependencies.** The addon is self-contained.
- **Local everything:** Prefer `local` variables and functions. Only expose things through the shared `NS` table or when the WoW API requires a global (like `SlashCmdList`).
- **Indentation:** 4 spaces, no tabs.
- **String style:** Double quotes for WoW paths/textures (`"Interface\\..."`), double quotes elsewhere for consistency.

## How the Castbar Works

1. On `ADDON_LOADED`, the default Blizzard cast bars are hidden by unregistering their events.
2. Two `StatusBar` frames are created — one for `"player"`, one for `"target"`.
3. Spell cast events (`UNIT_SPELLCAST_START`, `_CHANNEL_START`, `_STOP`, `_INTERRUPTED`, etc.) drive state transitions (`bar.casting`, `bar.channeling`).
4. An `OnUpdate` script animates the bar fill each frame based on `GetTime()` relative to `startTime`/`endTime`.
5. Channels fill in reverse (1 → 0). Normal casts fill forward (0 → 1).
6. On completion: bar flashes green. On interrupt: bar turns red. Both hold briefly then hide.

## Slash Commands

| Command         | Effect                               |
|-----------------|--------------------------------------|
| `/rmcb`         | Print help                           |
| `/rmcb lock`    | Lock bar positions                   |
| `/rmcb unlock`  | Unlock bars for drag-repositioning   |
| `/rmcb reset`   | Reset all settings to defaults       |
| `/rmcb test`    | Show a fake 3-second cast for preview|

## Testing

There is no automated test harness — WoW addons run inside the game client. To test:

1. Copy (or symlink) the `runemagic-castbars` folder into your WoW `Interface/AddOns/` directory, renamed to `RuneMagicCastbars`.
2. Launch WoW, enable the addon in the character select screen.
3. Use `/rmcb test` to visually verify the player castbar.
4. Cast a spell and confirm the bar animates correctly.
5. Target a casting mob and confirm the target bar appears.

## Extending the Addon

- **New bar types** (focus, pet): call `NS.CreateCastBar("focus", cfgTable)` and register appropriate events.
- **Options panel:** Build an `InterfaceOptions` frame in `Config.lua` that reads/writes `NS.db`.
- **Textures/media:** Add files under a `Media/` directory and reference them with `"Interface\\AddOns\\RuneMagicCastbars\\Media\\<file>"`.
