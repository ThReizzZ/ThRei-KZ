#!/usr/bin/env python3
"""Fail if a GlobalAPI.smx predates the player alias upload fix."""

import struct
import sys
import zlib

DEFAULT_PATH = "addons/sourcemod/plugins/GlobalAPI.smx"
SMX_MAGIC = 0x53504646
REQUIRED = (b"FindClientBySteamId", b"GetClientName")


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def read_section_blob(path: str) -> bytes:
    with open(path, "rb") as handle:
        raw = handle.read()

    if len(raw) < 24:
        fail(f"{path} is too small to be a SourceMod plugin")

    magic, _version, _compression, _disksize, _imagesize, sections, stringtab, dataoffs = (
        struct.unpack_from("<IHBIIBII", raw, 0)
    )
    if magic != SMX_MAGIC:
        fail(f"{path} is not a SourceMod .smx file")

    image = raw[:dataoffs] + zlib.decompress(raw[dataoffs:])
    blob = bytearray()
    for index in range(sections):
        name_offset, data_offset, size = struct.unpack_from("<III", image, 24 + index * 12)
        name_end = image.index(b"\0", stringtab + name_offset)
        name = image[stringtab + name_offset:name_end]
        if name in (b".code", b".data", b".names", b".publics", b".natives"):
            blob.extend(image[data_offset:data_offset + size])
    return bytes(blob)


def main() -> None:
    path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_PATH
    blob = read_section_blob(path)
    missing = [needle.decode() for needle in REQUIRED if needle not in blob]
    if missing:
        fail(
            f"{path} is missing the GlobalAPI player alias fix "
            f"({', '.join(missing)}). Rebuild the plugin before packaging."
        )
    print(f"GlobalAPI alias check OK: {path}")


if __name__ == "__main__":
    main()
