# Changelog

## 2.0.0

- Rebuilt on the GOKZ 3.6.4 baseline instead of GOKZ 3.8.0
- All plugins are compiled with SourceMod 1.11 to match the 1.11 runtime
- GlobalAPI is now based on the official 2.0.0 plugin, with only the backend URL changed to ThRei
- GlobalAPI reads its key and convars from the flat `cfg/sourcemod/globalapi-key.cfg` / `globalapi-convars.cfg` paths used by the installer (official paths kept as fallbacks)
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
