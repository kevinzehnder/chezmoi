#!/bin/sh

choice=$(printf '%s\n' 'Rename workspace' 'Remove workspace name' |
    rofi -dmenu -p 'Workspace') || exit 0

case "$choice" in
    'Rename workspace')
        name=$(rofi -dmenu -p 'New name') || exit 0
        [ -n "$name" ] && niri msg action set-workspace-name "$name"
        ;;
    'Remove workspace name')
        niri msg action unset-workspace-name
        ;;
esac
