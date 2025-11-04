# dotfiles

[![Managed by chezmoi](https://img.shields.io/badge/managed%20by-chezmoi-blue.svg)](https://www.chezmoi.io/)

Personal dotfiles managed by chezmoi with unified OS detection and package management.

## Supported Systems

- Arch Linux (+ AUR via yay)
- Ubuntu/Debian (apt)
- RHEL/AlmaLinux/Rocky/CentOS (dnf/yum + EPEL)
- Fedora (dnf)

## Bootstrap

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply kevinzehnder
```

## Structure

- `.chezmoidata.yaml` - OS-specific package mappings
- `run_once_before_install-packages.sh.tmpl` - Unified bootstrap using `{{ .chezmoi.osRelease.id }}`


