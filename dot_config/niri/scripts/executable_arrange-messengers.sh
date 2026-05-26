#!/usr/bin/env bash
set -euo pipefail

# Arrange Signal + WhatsApp windows side-by-side in one workspace.
# Usage: arrange-messengers.sh [workspace]
# Example: arrange-messengers.sh 1

WORKSPACE="${1:-1}"
# Tuned from your current manual placement on 3840x1600:
# Signal (x≈+692,y≈-27), WhatsApp (x≈-733,y≈-23)
SIGNAL_X="${SIGNAL_X:-+692}"
WHATSAPP_X="${WHATSAPP_X:--733}"
Y_OFFSET="${Y_OFFSET:--25}"   # Shared vertical offset

if ! command -v niri >/dev/null 2>&1; then
  echo "niri command not found" >&2
  exit 1
fi

WINDOWS_JSON="$(niri msg -j windows)"

readarray -t MATCHES < <(
  WINDOWS_JSON="$WINDOWS_JSON" python3 - <<'PY'
import json, os

windows = json.loads(os.environ["WINDOWS_JSON"])

signal_candidates = []
whatsapp_candidates = []

for w in windows:
    app = (w.get("app_id") or "").lower()
    title = (w.get("title") or "").lower()
    wid = w.get("id")
    if wid is None:
        continue

    if app == "signal" or "signal" in title:
        signal_candidates.append(w)

    if "whatsapp" in title or "whatsapp" in app:
        whatsapp_candidates.append(w)

# Prefer focused window if multiple, else first
signal = sorted(signal_candidates, key=lambda w: (not w.get("is_focused", False), w.get("id", 0)))
whatsapp = sorted(whatsapp_candidates, key=lambda w: (not w.get("is_focused", False), w.get("id", 0)))

if signal:
    print(f"signal\t{signal[0]['id']}")
if whatsapp:
    print(f"whatsapp\t{whatsapp[0]['id']}")
PY
)

SIGNAL_ID=""
WHATSAPP_ID=""
for row in "${MATCHES[@]:-}"; do
  kind="${row%%$'\t'*}"
  id="${row##*$'\t'}"
  case "$kind" in
    signal) SIGNAL_ID="$id" ;;
    whatsapp) WHATSAPP_ID="$id" ;;
  esac
done

if [[ -z "$SIGNAL_ID" && -z "$WHATSAPP_ID" ]]; then
  echo "No Signal/WhatsApp windows found."
  exit 0
fi

arrange_window() {
  local id="$1"
  local x="$2"

  niri msg action move-window-to-workspace "$WORKSPACE" --window-id "$id" --focus false
  niri msg action move-window-to-floating --id "$id"
  niri msg action center-window --id "$id"
  niri msg action move-floating-window --id "$id" -x "$x" -y "$Y_OFFSET"
}

if [[ -n "$SIGNAL_ID" ]]; then
  arrange_window "$SIGNAL_ID" "$SIGNAL_X"
  echo "Signal -> workspace $WORKSPACE (id=$SIGNAL_ID)"
fi

if [[ -n "$WHATSAPP_ID" ]]; then
  arrange_window "$WHATSAPP_ID" "$WHATSAPP_X"
  echo "WhatsApp -> workspace $WORKSPACE (id=$WHATSAPP_ID)"
fi

echo "Done."
