#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAGE="$DIR/.release-full"

rm -rf "$STAGE"
mkdir -p "$STAGE"

cp -a "$DIR/addons" "$STAGE/"
rm -rf "$STAGE/addons/sourcemod/scripting"
cp -a "$DIR/cfg" "$STAGE/"
cp -a "$DIR/materials" "$STAGE/"
cp -a "$DIR/models" "$STAGE/"
cp -a "$DIR/sound" "$STAGE/"
cp -a "$DIR/maps" "$STAGE/"

cp "$DIR/INSTALL.md" "$DIR/LICENSE" "$DIR/NOTICE.md" "$STAGE/"
cp "$DIR/install.sh" "$DIR/install.ps1" "$DIR/install.bat" "$STAGE/"

mkdir -p "$DIR/release"
tar -czf "$DIR/release/threi-kz-full.tar.gz" -C "$STAGE" .

python3 - "$STAGE" "$DIR/release/threi-kz-full.zip" <<'PY'
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
