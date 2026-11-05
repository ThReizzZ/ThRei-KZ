#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPCOMP="${SPCOMP:-spcomp64}"
SM_INCLUDE="${SM_INCLUDE:?Set SM_INCLUDE to the SourceMod 1.11 scripting/include directory}"

cd "$DIR/addons/sourcemod/scripting"

GLOBALAPI_NATIVES="$DIR/addons/sourcemod/scripting/GlobalAPI/api/natives.sp"
GLOBALAPI_MISC="$DIR/addons/sourcemod/scripting/GlobalAPI/misc.sp"

if ! grep -Fq 'AddString("player_name", playerName)' "$GLOBALAPI_NATIVES"; then
  echo "ERROR: GlobalAPI is missing player_name upload (unknown-player regression)" >&2
  exit 1
fi

if ! grep -Fq 'FindClientBySteamId' "$GLOBALAPI_MISC"; then
  echo "ERROR: GlobalAPI is missing FindClientBySteamId helper (unknown-player regression)" >&2
  exit 1
fi

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
