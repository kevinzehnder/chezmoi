#!/usr/bin/env bash
set -euo pipefail

PROFILE="${ICC_PROFILE_PATH:-/var/lib/colord/icc/HDR WQHD #1 2021-03-16 21-29 2.2 F-S XYZLUT+MTX.icm}"
DISPLAY_INDEX="${ICC_DISPLAY_INDEX:-1}"

# Session startup race guard.
sleep 2

if ! command -v dispwin >/dev/null 2>&1; then
  echo "[niri] dispwin not found (install argyllcms), skipping ICC load" >&2
  exit 0
fi

if [ ! -f "$PROFILE" ]; then
  echo "[niri] ICC profile not found: $PROFILE" >&2
  exit 0
fi

exec dispwin -d "$DISPLAY_INDEX" "$PROFILE"
