#!/usr/bin/env bash
set -euo pipefail

entry="${1-}"
[[ -z "$entry" ]] && exit 0

IFS=$'\t' read -r proto state local peer app pid port <<< "$entry"

echo "Port:   ${port:--}"
echo "Proto:  ${proto:--}"
echo "State:  ${state:--}"
echo "Local:  ${local:--}"
echo "Peer:   ${peer:--}"
echo "App:    ${app:--}"
echo "PID:    ${pid:--}"

echo
if [[ "${pid:--}" != "-" ]] && command -v ps >/dev/null 2>&1; then
  echo "=== Process ==="
  ps -fp "$pid" 2>/dev/null || true
  echo
fi

if [[ "${port:--}" != "-" ]]; then
  echo "=== Matching sockets (ss) ==="
  if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
    sudo ss -lntuap 2>/dev/null | grep -E "[:.]${port}([[:space:]]|$)" || true
  else
    ss -lntuap 2>/dev/null | grep -E "[:.]${port}([[:space:]]|$)" || true
  fi
  echo
fi

if [[ "${pid:--}" != "-" ]] && command -v lsof >/dev/null 2>&1; then
  echo "=== Open sockets for PID ${pid} (lsof) ==="
  if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
    sudo lsof -nP -p "$pid" -i 2>/dev/null | head -n 40 || true
  else
    lsof -nP -p "$pid" -i 2>/dev/null | head -n 40 || true
  fi
fi
