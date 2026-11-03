# NOTICE

This repository contains modified GOKZ code and a modified GlobalAPI SM plugin.

## GOKZ

- Source: https://github.com/KZGlobalTeam/gokz
- License: GPL (see `LICENSE`)
- Changes:
  - `gokz-profile`: red `CN` tag + ThRei rank display
  - `gokz-global`: `MapCheck()` accepts unknown filesize (`0`) so maps without
    a central filesize entry can still be uploaded
  - translations: display text says ThRei instead of Global

## GlobalAPI SM plugin

- Source: https://github.com/KZGlobalTeam/csgo-sm-globalapi
- The plugin is built with its backend URL changed to the ThRei KZ API:
  `https://api.threi.cn/api/v2.0`
- The library/plugin name remains `GlobalAPI` because GOKZ depends on it.

## ThRei

- This repository contains the GOKZ plugin package only.

If you redistribute the compiled plugins, keep the corresponding source and
this notice available, as required by the GPL.
