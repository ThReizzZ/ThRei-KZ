#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPCOMP="${SPCOMP:-spcomp64}"
SM_INCLUDE="${SM_INCLUDE:?Set SM_INCLUDE to the SourceMod 1.11 scripting/include directory}"

cd "$DIR/addons/sourcemod/scripting"

for file in gokz-*.sp; do
  plugin="${file%.sp}"
  "$SPCOMP" \
    -i "$SM_INCLUDE" \
    -i include \
    -o "$DIR/addons/sourcemod/plugins/$plugin.smx" \
    "$file"
done

"$SPCOMP" \
  -i "$SM_INCLUDE" \
  -i include \
  -o "$DIR/addons/sourcemod/plugins/GlobalAPI.smx" \
  GlobalAPI.sp

"$SPCOMP" \
  -i "$SM_INCLUDE" \
  -i include \
  -o "$DIR/optional/uploader/threi-kz-uploader.smx" \
  "$DIR/optional/uploader/threi-kz-uploader.sp"
