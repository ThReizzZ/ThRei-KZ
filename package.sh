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

cp "$DIR/README.md" "$DIR/INSTALL.md" "$DIR/CHANGELOG.md" "$DIR/VERSION" "$DIR/LICENSE" "$DIR/NOTICE.md" "$STAGE/"
cp "$DIR/install.sh" "$DIR/install.ps1" "$DIR/install.bat" "$STAGE/"

mkdir -p "$DIR/release"
tar -czf "$DIR/release/threi-kz-full.tar.gz" -C "$STAGE" .

rm -rf "$STAGE"
