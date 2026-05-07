# Broker: Coords

A lean [LibDataBroker](https://www.wowace.com/projects/libdatabroker-1-1) plugin for World of Warcraft that displays your current zone, coordinates, and facing direction in any broker bar. Requires a broker display addon such as ElvUI, Bazooka, or TitanPanel.

**Requires retail WoW (Midnight, Interface 120005+). Does not support Classic or older retail builds.**

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

1. Download the latest release zip from the [Releases](../../releases) page
2. Extract the `Broker_PlayerCoords` folder into your addons directory:
   - **Windows**: `World of Warcraft\_retail_\Interface\AddOns\`
   - **macOS**: `Applications/World of Warcraft/_retail_/Interface/AddOns/`
3. Restart World of Warcraft or `/reload`

## Click Interactions

All interactions are on the broker bar button:

| Input | Action |
|---|---|
| Left-click | Toggle the World Map |
| Shift-Left-click | Insert a waypoint hyperlink into the active chat box |
| Ctrl-Left-click | Open a "Copy Coordinates" dialog (pre-selected text, Ctrl-C to copy) |
| Ctrl-Shift-Left-click | Open a "Copy /way Command" dialog (TomTom-compatible format) |
| Shift-Right-click | Open the Settings panel |

## Configuration

Open the settings panel via **Shift-Right-click** on the broker button, or via **Escape → Options → AddOns → Broker: Coords**.

### Broker Bar

| Setting | Default | Description |
|---|---|---|
| Coordinate precision | 2 decimals | Number of decimal places shown everywhere (0, 1, or 2) |
| Show zone name | On | Display the current zone in the broker text |
| Show subzone name | Off | Append the subzone (e.g. "Stormwind: Trade District") |
| Show facing direction | Off | Append an 8-point compass label after the coordinates |
| Update rate while moving | Normal (2×/sec) | How often coordinates refresh during movement |

### Minimap

| Setting | Default | Description |
|---|---|---|
| Show coordinates near minimap | Off | Small coordinate overlay at the bottom of the minimap |
| Show cursor coordinates on world map | On | Live coordinates under your cursor on the world map |

### Tooltip

| Setting | Default | Description |
|---|---|---|
| Show continent | On | Continent name row in the tooltip |
| Show difficulty | On | Zone or instance difficulty row (with M+ key level / Delve tier) |
| Show item level | On | Equipped iLvl vs. recommended (instances only, when data is available) |

## Technical Details

### File Structure

```text
Broker_PlayerCoords/
├── Broker_PlayerCoords.toc     # Addon metadata and load order
├── Core.lua                    # Broker object, event handling, tooltip, click logic
├── Settings.lua                # Saved-variable defaults and Settings panel registration
├── Locales/
│   └── Locales.xml             # Locale file manifest (enUS baseline)
└── Libs/
    ├── LibStub/
    ├── CallbackHandler-1.0/
    ├── LibDataBroker-1.1/
    └── LibDBIcon-1.0/
```

### Events Handled

| Event | Purpose |
|---|---|
| `ADDON_LOADED` | Initialize saved variables, register LibDBIcon, build Settings panel |
| `PLAYER_ENTERING_WORLD` | Force coordinate refresh on login / instance transitions |
| `ZONE_CHANGED` / `ZONE_CHANGED_INDOORS` / `ZONE_CHANGED_NEW_AREA` | Refresh zone text and coordinates |
| `PLAYER_STARTED_MOVING` / `PLAYER_STOPPED_MOVING` | Switch between throttled OnUpdate polling and immediate refresh |

### Saved Variables

- `Broker_PlayerCoordsDB` — all settings plus the LibDBIcon minimap position sub-table (`minimapIcon`)

## Compatibility

- **WoW Version**: Retail (Midnight, Interface 120005+)
- **Dependencies**: LibStub, CallbackHandler-1.0, LibDataBroker-1.1, LibDBIcon-1.0 (all bundled)
- **Broker display**: any LDB-compatible display (ElvUI, Bazooka, Broker2FuBar, TitanPanel, etc.)

## Contributing

Issues and pull requests are welcome.

## License

[GPL-2.0](LICENSE)

## Changelog

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
