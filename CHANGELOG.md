# Broker: Coords — Changelog

User-facing changes, newest first. Internal and dev-tooling work lives in the
git history, not here.

## [v1.1.4](https://github.com/darktrine-addons/Broker_PlayerCoords/releases/tag/v1.1.4) — 2026-07-11

- chore: updated for WoW patch **12.0.7** (Interface 120007). No functional changes — every API the addon uses is unchanged in 12.0.7.

## [v1.1.3](https://github.com/darktrine-addons/Broker_PlayerCoords/releases/tag/v1.1.3) — 2026-06-03

- chore: release notes are now posted per-version to CurseForge and Wago; the full history lives in this file.

## [v1.1.2](https://github.com/darktrine-addons/Broker_PlayerCoords/releases/tag/v1.1.2) — 2026-05-29

- feat: the copy/paste dialog adopts a dark **smoke-glass** look — solid backdrop, thin amber border, amber title, and an `esc`-to-close hint — matching Broker: MidnightEvents. (This is the fallback copy path when your client lacks `C_Clipboard`.)
- feat: ESC closes the copy dialog, alongside the existing Enter binding.
- fix: tooltip footer no longer shows a doubled `v` in the version string.

## [v1.1.1](https://github.com/darktrine-addons/Broker_PlayerCoords/releases/tag/v1.1.1) — 2026-05-17

- fix: tooltip footer renders the version cleanly (`Broker: Coords v1.1.1` instead of `vv1.1.1`).
- fix: source checkouts show `Broker: Coords dev` instead of the unsubstituted `@project-version@` placeholder.

## [v1.1.0](https://github.com/darktrine-addons/Broker_PlayerCoords/releases/tag/v1.1.0) — 2026-05-15

- feat: the minimap button is now toggleable in *Settings → Minimap* (on by default) — turn it off if you run a broker bar. Existing users keep their current visibility.

## [v1.0.1](https://github.com/darktrine-addons/Broker_PlayerCoords/releases/tag/v1.0.1) — 2026-05-13

- fix: the coordinate tooltip is now drawn in a private frame so it no longer taints Blizzard's shared tooltip.

## [v1.0.0](https://github.com/darktrine-addons/Broker_PlayerCoords/releases/tag/v1.0.0) — 2026-05-09

First stable release. No functional changes from v0.9.2-beta.

- chore: automated CurseForge + Wago publishing via the BigWigs packager on tag push.

## [v0.9.2-beta](https://github.com/darktrine-addons/Broker_PlayerCoords/releases/tag/v0.9.2-beta) — 2026-05-08

- feat: broker text wraps coordinates in parentheses — `Zone (X.XX, Y.YY)` — for clearer separation from the zone label.
- fix: the minimap coordinate overlay is anchored cleanly below the minimap frame.

## [v0.9.0-beta](https://github.com/darktrine-addons/Broker_PlayerCoords/releases/tag/v0.9.0-beta) — 2026-05-07

Initial public beta.

- feat: broker bar shows zone, optional subzone, coordinates (0/1/2 decimals), and an optional 8-point compass facing.
- feat: configurable update throttle (fast / normal / slow) while moving, event-driven when still.
- feat: LibDBIcon minimap button with drag-to-reposition; optional minimap and world-map cursor coordinate overlays.
- feat: rich tooltip — continent, PvP status, tiered difficulty (Mythic+ key level, Delve tier), and instance item level vs. recommended.
- feat: click handlers (toggle world map, share chat waypoint, copy coordinates, copy `/way` command) and a native WoW Settings panel.
