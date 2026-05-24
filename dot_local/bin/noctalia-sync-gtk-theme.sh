#!/usr/bin/env bash
set -euo pipefail

LIGHT_GTK="Osaka-Light-Solarized"
LIGHT_ICON="Papirus-Light"
DARK_GTK="Tokyonight-Dark-Storm"
DARK_ICON="Papirus-Dark"

mode=""
arg="${1:-}"

case "$arg" in
  dark|Dark|1|true|on)
    mode="prefer-dark"
    ;;
  light|Light|0|false|off)
    mode="prefer-light"
    ;;
esac

# If hook gave no explicit mode, wait briefly for Noctalia to finish writing gsettings,
# then mirror whatever color-scheme is currently set.
if [[ -z "$mode" ]]; then
  sleep 0.4
  mode="$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'" || true)"
fi

if [[ "$mode" == "prefer-dark" ]]; then
  gsettings set org.gnome.desktop.interface gtk-theme "$DARK_GTK" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface icon-theme "$DARK_ICON" 2>/dev/null || true

  gsettings set org.cinnamon.desktop.interface gtk-theme "$DARK_GTK" 2>/dev/null || true
  gsettings set org.cinnamon.desktop.interface icon-theme "$DARK_ICON" 2>/dev/null || true
else
  gsettings set org.gnome.desktop.interface gtk-theme "$LIGHT_GTK" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface icon-theme "$LIGHT_ICON" 2>/dev/null || true

  gsettings set org.cinnamon.desktop.interface gtk-theme "$LIGHT_GTK" 2>/dev/null || true
  gsettings set org.cinnamon.desktop.interface icon-theme "$LIGHT_ICON" 2>/dev/null || true
fi
