#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAGE="$DIR/.release-upgrade"

rm -rf "$STAGE"
mkdir -p \
  "$STAGE/addons/sourcemod/plugins" \
  "$STAGE/addons/sourcemod/gamedata" \
  "$STAGE/addons/sourcemod/translations" \
  "$STAGE/cfg/sourcemod/gokz" \
  "$STAGE/maps"

cp "$DIR/addons/sourcemod/plugins/"*.smx "$STAGE/addons/sourcemod/plugins/"
cp "$DIR/addons/sourcemod/gamedata/"* "$STAGE/addons/sourcemod/gamedata/"
cp "$DIR/addons/sourcemod/translations/"*.txt "$STAGE/addons/sourcemod/translations/"

cp "$DIR/cfg/sourcemod/globalapi-key.cfg.example" "$STAGE/cfg/sourcemod/"
cp "$DIR/cfg/sourcemod/globalapi-convars.cfg.example" "$STAGE/cfg/sourcemod/"
cp "$DIR/cfg/sourcemod/gokz/"* "$STAGE/cfg/sourcemod/gokz/"
cp "$DIR/maps/gokz-replays.nav" "$STAGE/maps/"
cp "$DIR/INSTALL.md" "$DIR/LICENSE" "$DIR/NOTICE.md" "$STAGE/"
cp "$DIR/install.sh" "$DIR/install.ps1" "$DIR/install.bat" "$STAGE/"

mkdir -p "$DIR/release"
tar -czf "$DIR/release/threi-kz-upgrade.tar.gz" -C "$STAGE" .
cp "$DIR/release/threi-kz-upgrade.tar.gz" "$DIR/release/threi-gokz-plugins.tar.gz"

python3 - "$STAGE" "$DIR/release/threi-kz-upgrade.zip" <<'PY'
import os
import sys
import zipfile

stage, output = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as archive:
    for root, _dirs, files in os.walk(stage):
        for name in files:
            path = os.path.join(root, name)
            archive.write(path, os.path.relpath(path, stage))
PY

rm -rf "$STAGE"
