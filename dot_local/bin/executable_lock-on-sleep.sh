#!/usr/bin/env bash
set -euo pipefail

# One D-Bus monitor handles both events; the ICC ramp can be lost after unlock.
dbus-monitor --system \
  "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'" \
  "type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',arg0='org.freedesktop.login1.Session'" \
  2>/dev/null | \
awk '
  /^signal / { event = ""; locked_hint = 0 }
  /member=PrepareForSleep/ { event = "sleep" }
  /member=PropertiesChanged/ { event = "session" }
  /string "LockedHint"/ { if (event == "session") locked_hint = 1 }
  /boolean true/ { if (event == "sleep") print "lock" }
  /boolean false/ { if (event == "session" && locked_hint) print "restore-icc" }
' | while IFS= read -r action; do
  case "$action" in
    lock) loginctl lock-session ;;
    restore-icc)
      sleep 1 # Let the compositor recreate the gamma-control surface.
      "$HOME/.local/bin/apply-icc-vcgt-wayland.sh"
      ;;
  esac
done
