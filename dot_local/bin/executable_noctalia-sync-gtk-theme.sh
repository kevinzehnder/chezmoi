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

NIRI_THEME_FILE="$HOME/.config/niri/noctalia.kdl"

if [[ "$mode" == "prefer-dark" ]]; then
  gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface gtk-theme "$DARK_GTK" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface icon-theme "$DARK_ICON" 2>/dev/null || true

  gsettings set org.cinnamon.desktop.interface gtk-theme "$DARK_GTK" 2>/dev/null || true
  gsettings set org.cinnamon.desktop.interface icon-theme "$DARK_ICON" 2>/dev/null || true

  cat > "$NIRI_THEME_FILE" <<'KDL'
layout {

    focus-ring {
        active-color   "#7aa2f7"
        inactive-color "#3b4261"
        urgent-color   "#f7768e"
    }

    border {
        active-color   "#7aa2f7"
        inactive-color "#3b4261"
        urgent-color   "#f7768e"
    }

    shadow {
        color "#16161e70"
    }

    tab-indicator {
        active-color   "#7aa2f7"
        inactive-color "#9aa5ce"
        urgent-color   "#f7768e"
    }

    insert-hint {
        color "#7aa2f780"
    }
}

recent-windows {
    highlight {
        active-color "#7aa2f7"
        urgent-color "#f7768e"
    }
}
KDL
else
  gsettings set org.gnome.desktop.interface color-scheme "prefer-light" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface gtk-theme "$LIGHT_GTK" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface icon-theme "$LIGHT_ICON" 2>/dev/null || true

  gsettings set org.cinnamon.desktop.interface gtk-theme "$LIGHT_GTK" 2>/dev/null || true
  gsettings set org.cinnamon.desktop.interface icon-theme "$LIGHT_ICON" 2>/dev/null || true

  cat > "$NIRI_THEME_FILE" <<'KDL'
layout {

    focus-ring {
        active-color   "#c2b8a3"
        inactive-color "#fdf6e3"
        urgent-color   "#dc322f"
    }

    border {
        active-color   "#c2b8a3"
        inactive-color "#fdf6e3"
        urgent-color   "#dc322f"
    }

    shadow {
        color "#e6decb70"
    }

    tab-indicator {
        active-color   "#c2b8a3"
        inactive-color "#c1d9ea"
        urgent-color   "#dc322f"
    }

    insert-hint {
        color "#c2b8a380"
    }
}

recent-windows {
    highlight {
        active-color "#c2b8a3"
        urgent-color "#dc322f"
    }
}
KDL
fi

niri msg action load-config-file >/dev/null 2>&1 || true
