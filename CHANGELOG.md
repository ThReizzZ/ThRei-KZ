# Changelog

## 2.1.0

- Added jumpstat PB history, per-strafe details, route visualization and jump replay upload
- `gokz-global` now keeps the detailed GOKZ Jump data for the API and uploads jump PB replays
- `GlobalAPI` adds `GlobalAPI_CreateJumpstatReplay`; existing requests are unchanged
- Bundled the custom `ThReizzZ/replays` build with `GOKZ_RP_OnJumpReplaySaved`
- Existing run replay storage, menus and playback behaviour are unchanged

## 2.0.2

- GlobalAPI now uploads `player_name` with record submissions again, fixing "未知玩家" on the website after the 2.0.0 rebuild

## 2.0.1

- GlobalAPI now reads its key and convars only from the flat `cfg/sourcemod/globalapi-key.cfg` / `globalapi-convars.cfg` paths used by the installer
- Fixed the bundled sm-json `JSON_Object.SetString` recursion that caused GlobalAPI request stack overflows and blocked all API checks
- `sm_globalapi_reload_apikey` now re-runs the GlobalAPI checks immediately
- Installer and docs now state that a key change requires a server restart; changing map alone does not reload the key

## 2.0.0

- Rebuilt on the GOKZ 3.6.4 baseline instead of GOKZ 3.8.0
- All plugins are compiled with SourceMod 1.11 to match the 1.11 runtime
- GlobalAPI is now based on the official 2.0.0 plugin, with only the backend URL changed to ThRei
- Only one full installation package is published; the separate upgrade package was removed
- Kept ThRei changes: profile clan tag, MapCheck unknown filesize handling, ThRei API backend
- Updated install scripts to back up all GOKZ plugins, gamedata and translations

## 1.1.0

- Public repository now contains only the GOKZ plugin package
- Plugin package unchanged from 1.0.8, including `maps/gokz-replays.nav`

## 1.0.8

- Add `maps/gokz-replays.nav` to the full and upgrade packages
- Install scripts now copy the `maps/` directory

## 1.0.7

- Scoreboard clan tag now uses the mode initial by default: `[K CN Amateur+]`
- Add `{mode_initial}` placeholder: K = KZTimer, S = SimpleKZ, V = Vanilla
- Automatically drop outer brackets when the tag exceeds 15 characters
- Chat tag still uses the full `KZT` / `SKZ` / `VNL` abbreviation

## 1.0.6

- Configurable scoreboard clan tag format via `sm_threi_clan_format`
- Default `[CN {rank}]`; supports `{cn}`, `{rank}`, `{mode}`, `{mode_short}`

## 1.0.5

- Shorten scoreboard clan tag to "CN Rank" so it fits in the TAB scoreboard

## 1.0.4

- Upload player alias with ThRei record submissions (fixes unknown player names)
- PRO/BONUS record announcements now say "ThRei纪录" instead of "世界纪录"

## 1.0.3

- Full package for fresh servers (all GOKZ plugins, assets, cfg, translations)
- Upgrade package for existing GOKZ servers
- One-click install scripts for Linux and Windows
- GitHub Actions publishes full and upgrade packages on tag push

## 1.0.2

- One-click install scripts for Linux and Windows

## 1.0.1

- GitHub release workflow and download links

## 1.0.0

- ThRei GOKZ plugin package
- GlobalAPI backend replaced by a ThRei-compatible `GlobalAPI.smx`
- Original GOKZ upload/query/profile/filter/ban/replay/announcement behaviour preserved
- Red `CN` prefix and ThRei rank in chat/scoreboard
- Official map pool validation; unknown maps are rejected instead of being created
