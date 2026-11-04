#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-.}"
if [ ! -d "$TARGET/addons/sourcemod" ]; then
  echo "Usage: $0 /path/to/csgo"
  echo "Example: $0 /home/csgo/serverfiles/csgo"
  exit 1
fi

PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$TARGET/addons/sourcemod/plugins/disabled/threi-backup-$STAMP"
mkdir -p "$BACKUP/plugins" "$BACKUP/gamedata" "$BACKUP/translations" "$BACKUP/cfg"

echo "[ThRei] target: $TARGET"
echo "[ThRei] backup: $BACKUP"

# Back up all current GOKZ files before replacing the whole stack.
find "$TARGET/addons/sourcemod/plugins" -maxdepth 1 -type f -name '*.smx' -exec cp -a {} "$BACKUP/plugins/" \; 2>/dev/null || true
find "$TARGET/addons/sourcemod/gamedata" -maxdepth 1 -type f -exec cp -a {} "$BACKUP/gamedata/" \; 2>/dev/null || true
find "$TARGET/addons/sourcemod/translations" -maxdepth 1 -type f -name '*.txt' -exec cp -a {} "$BACKUP/translations/" \; 2>/dev/null || true
if [ -d "$TARGET/cfg/sourcemod/gokz" ]; then
  cp -a "$TARGET/cfg/sourcemod/gokz" "$BACKUP/cfg/"
fi

# These old plugins have different filenames, so extraction cannot remove them.
for file in GlobalAPI-Core.smx GlobalAPI-Jumpstats.smx; do
  if [ -f "$TARGET/addons/sourcemod/plugins/$file" ]; then
    mv "$TARGET/addons/sourcemod/plugins/$file" "$BACKUP/plugins/"
    echo "[ThRei] disabled old plugin: $file"
  fi
done

# GOKZ uploads directly now. Keeping the uploader loaded would upload the same
# run twice with different client run IDs.
if [ -f "$TARGET/addons/sourcemod/plugins/threi-kz-uploader.smx" ]; then
  mv "$TARGET/addons/sourcemod/plugins/threi-kz-uploader.smx" "$BACKUP/plugins/"
  echo "[ThRei] disabled uploader: threi-kz-uploader.smx (use it only for manual backfill)"
fi

cp -a "$PKG_DIR/addons/." "$TARGET/addons/"

# Full package also contains GOKZ game assets and default configs.
for dir in materials models sound maps; do
  if [ -d "$PKG_DIR/$dir" ]; then
    mkdir -p "$TARGET/$dir"
    cp -a "$PKG_DIR/$dir/." "$TARGET/$dir/"
  fi
done

if [ -d "$PKG_DIR/cfg/sourcemod/gokz" ]; then
  mkdir -p "$TARGET/cfg/sourcemod/gokz"
  cp -a "$PKG_DIR/cfg/sourcemod/gokz/." "$TARGET/cfg/sourcemod/gokz/"
fi

if [ -f "$PKG_DIR/cfg/sourcemod/globalapi-convars.cfg.example" ] \
  && [ ! -f "$TARGET/cfg/sourcemod/globalapi-convars.cfg" ]; then
  cp "$PKG_DIR/cfg/sourcemod/globalapi-convars.cfg.example" "$TARGET/cfg/sourcemod/globalapi-convars.cfg"
fi

KEY_FILE="$TARGET/cfg/sourcemod/globalapi-key.cfg"
if [ ! -f "$KEY_FILE" ]; then
  mkdir -p "$(dirname "$KEY_FILE")"
  cp "$PKG_DIR/cfg/sourcemod/globalapi-key.cfg.example" "$KEY_FILE"
  echo "[ThRei] created $KEY_FILE"
fi

echo
echo "[ThRei] installed."
echo "[ThRei] edit $KEY_FILE and put your ThRei server key on the first line."
echo "[ThRei] then change map or restart the server, and run !gc in game."
