# Broker: Coords

A featherweight [LibDataBroker](https://www.wowace.com/projects/libdatabroker-1-1) plugin that surfaces your current zone and coordinates in any broker bar.

The differentiator is the tooltip: continent, PvP status, Mythic+ key level, Delve tier, and instance item level vs. recommended — with click handlers for World Map, chat waypoint sharing, and one-key clipboard copy of coordinates or a `/way` command.

Retail only. Requires Midnight (Interface 120005+) and a broker host such as Arcana (recommended), ElvUI, Bazooka, Broker2FuBar, or TitanPanel.

## Features

- **Broker bar text**: zone name, optional subzone, coordinates, and optional 8-point compass direction (N / NE / E …)
- **Configurable precision**: 0, 1, or 2 decimal places on all coordinate displays
- **Throttled updates**: smooth coordinate refresh while moving (fast / normal / slow), event-driven when standing still
- **Minimap button**: drag-to-reposition minimap icon via LibDBIcon; right-click to show or hide
- **Minimap coordinate overlay**: optional small coordinate readout at the bottom of the minimap
- **World map cursor coordinates**: live coordinates under the cursor while the world map is open
- **Rich tooltip**: zone header, continent, PvP status, tiered difficulty (Mythic+ key level, Delve tier), instance item level vs. recommended, and interaction hints
- **Click interactions**: open world map, share waypoint in chat, copy coordinates or `/way` command to clipboard
- **Native Settings panel**: all options in WoW's built-in AddOns settings (Escape → Options → AddOns → Broker: Coords)

## Installation

The recommended path is a package manager: **CurseForge app**, **WowUp**, or the **Wago app** — search for "Broker: Coords" and one-click install.

For manual installation:

1. Download the latest release zip from [GitHub Releases](https://github.com/darktrine-addons/Broker_PlayerCoords/releases), CurseForge, or Wago.io
2. Extract the `Broker_PlayerCoords` folder into your addons directory:
   - **Windows**: `World of Warcraft\_retail_\Interface\AddOns\`
   - **macOS**: `Applications/World of Warcraft/_retail_/Interface/AddOns/`
3. Restart World of Warcraft or `/reload`

## Click Interactions

All interactions are on the broker bar button:

- **Left-click** — Toggle the World Map
- **Shift-Left-click** — Insert a waypoint hyperlink into the active chat box
- **Ctrl-Left-click** — Copy `Zone X.XX, Y.YY` to the system clipboard (dialog fallback if `C_Clipboard` is unavailable)
- **Ctrl-Shift-Left-click** — Copy a `/way` command to the system clipboard (Blizzard waypoint / TomTom-compatible format)
- **Shift-Right-click** — Open the Settings panel

## Configuration

Open the settings panel via **Shift-Right-click** on the broker button, or via **Escape → Options → AddOns → Broker: Coords**.

### Broker Bar

- **Coordinate precision** *(default: 2 decimals)* — Number of decimal places shown everywhere (0, 1, or 2)
- **Show zone name** *(default: On)* — Display the current zone in the broker text
- **Show subzone name** *(default: Off)* — Append the subzone (e.g. "Stormwind: Trade District")
- **Show facing direction** *(default: Off)* — Append an 8-point compass label after the coordinates
- **Update rate while moving** *(default: Normal, 2×/sec)* — How often coordinates refresh during movement

### Minimap

- **Show coordinates near minimap** *(default: Off)* — Small coordinate overlay at the bottom of the minimap
- **Show cursor coordinates on world map** *(default: On)* — Live coordinates under your cursor on the world map

### Tooltip

- **Show continent** *(default: On)* — Continent name row in the tooltip
- **Show difficulty** *(default: On)* — Zone or instance difficulty row (with M+ key level / Delve tier)
- **Show item level** *(default: On)* — Equipped iLvl vs. recommended (instances only, when data is available)

## Technical Details

### File Structure

- `Broker_PlayerCoords.toc` — Addon metadata and load order
- `Core.lua` — Broker object, event handling, tooltip, click logic
- `Settings.lua` — Saved-variable defaults and Settings panel registration
- `Locales/Locales.xml` — Locale file manifest (enUS baseline)
- `Libs/` — bundled libraries: LibStub, CallbackHandler-1.0, LibDataBroker-1.1, LibDBIcon-1.0

### Events Handled

- `ADDON_LOADED` — Initialize saved variables, register LibDBIcon, build Settings panel
- `PLAYER_ENTERING_WORLD` — Force coordinate refresh on login / instance transitions
- `ZONE_CHANGED` / `ZONE_CHANGED_INDOORS` / `ZONE_CHANGED_NEW_AREA` — Refresh zone text and coordinates
- `PLAYER_STARTED_MOVING` / `PLAYER_STOPPED_MOVING` — Switch between throttled OnUpdate polling and immediate refresh

### Saved Variables

- `Broker_PlayerCoordsDB` — all settings plus the LibDBIcon minimap position sub-table (`minimapIcon`)

## Compatibility

- **WoW Version**: Retail (Midnight, Interface 120005+)
- **Dependencies**: LibStub, CallbackHandler-1.0, LibDataBroker-1.1, LibDBIcon-1.0 (all bundled)
- **Broker display**: any LDB-compatible display (ElvUI, Bazooka, Broker2FuBar, TitanPanel, etc.)

## Contributing

Issues and pull requests are welcome.

## License

Licensed under [GPL-2.0](https://www.gnu.org/licenses/gpl-2.0.html). The full license text is in the `LICENSE` file in the source distribution.

## Changelog

### v1.0.0

First stable release. No functional changes from v0.9.2-beta.

- Publishing pipeline: CurseForge and Wago.io automated via BigWigsMods packager on tag push

### v0.9.2-beta

Visual polish.

- Broker text: coordinates now wrapped in parentheses — `Zone (X.XX, Y.YY)` — for clearer separation from the zone label
- Minimap coordinate overlay: anchored below the minimap frame instead of inside it; uses the default `GameFontNormalSmall` size cleanly

### v0.9.0-beta

Initial public beta.

- Broker bar: zone, subzone, coordinates (0/1/2 dp), 8-point compass facing direction
- Configurable update throttle (fast / normal / slow)
- LibDBIcon minimap button with drag-to-reposition
- Minimap coordinate text overlay (off by default)
- World map cursor coordinate overlay (on by default)
- Tooltip: continent, PvP status, tiered difficulty (M+ key level, Delve tier), instance iLvl vs. recommended, interaction hints
- Click handlers: world map toggle, chat waypoint, copy coordinates, copy `/way` command
- Native WoW Settings panel with three sections (Broker Bar, Minimap, Tooltip)
