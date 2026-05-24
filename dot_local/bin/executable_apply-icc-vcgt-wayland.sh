#!/usr/bin/env bash
set -euo pipefail

ICC_PROFILE_PATH="${ICC_PROFILE_PATH:-/var/lib/colord/icc/HDR WQHD #1 2021-03-16 21-29 2.2 F-S XYZLUT+MTX.icm}"
WLR_GAMMACTL_BIN="${WLR_GAMMACTL_BIN:-$HOME/.local/bin/wlr-gammactl-fzn}"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
LUT_FILE="${RUNTIME_DIR}/icc-vcgt-lut-${UID}.txt"
PID_FILE="${RUNTIME_DIR}/wlr-gammactl-fzn.pid"

if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
  echo "[icc-wayland] WAYLAND_DISPLAY not set, skipping" >&2
  exit 0
fi

if [[ ! -f "$ICC_PROFILE_PATH" ]]; then
  echo "[icc-wayland] ICC profile not found: $ICC_PROFILE_PATH" >&2
  exit 0
fi

if [[ ! -x "$WLR_GAMMACTL_BIN" ]]; then
  echo "[icc-wayland] gamma loader not found: $WLR_GAMMACTL_BIN" >&2
  exit 0
fi

python3 - "$ICC_PROFILE_PATH" "$LUT_FILE" <<'PY'
import re, subprocess, sys
icc, out_path = sys.argv[1], sys.argv[2]
text = subprocess.check_output(["iccdump", "-v", "3", "-t", "vcgt", icc], text=True, stderr=subprocess.STDOUT)
channels = [[], [], []]
ch = -1
for line in text.splitlines():
    m = re.match(r"\s*channel #(\d+)", line)
    if m:
        ch = int(m.group(1))
        continue
    m = re.match(r"\s*(\d+):\s*([0-9.]+)", line)
    if m and 0 <= ch <= 2:
        channels[ch].append(float(m.group(2)))

if min(len(c) for c in channels) < 2:
    raise SystemExit("vcgt tag not found or invalid")

n = min(len(c) for c in channels)
with open(out_path, "w", encoding="utf-8") as f:
    for i in range(n):
        f.write(f"{channels[0][i]:.10f} {channels[1][i]:.10f} {channels[2][i]:.10f}\n")
PY

# Restart persistent gamma client (gamma ramp resets when client exits).
if [[ -f "$PID_FILE" ]]; then
  old_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [[ -n "${old_pid:-}" ]] && kill -0 "$old_pid" 2>/dev/null; then
    kill "$old_pid" 2>/dev/null || true
    sleep 0.1
  fi
fi

"$WLR_GAMMACTL_BIN" -f "$LUT_FILE" >/dev/null 2>&1 &
echo $! > "$PID_FILE"

