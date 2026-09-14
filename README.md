# dotfiles

[![Managed by chezmoi](https://img.shields.io/badge/managed%20by-chezmoi-blue.svg)](https://www.chezmoi.io/)

Personal dotfiles managed by Chezmoi. The source has one terminal/common base
and two purpose-specific profiles:

- **`server`** — minimal terminal configuration for Debian/Ubuntu and
  RHEL/AlmaLinux/Rocky servers.
- **`workstation`** — Arch Linux development environment. Its optional
  **desktop overlay** supplies Niri, Noctalia, Kitty, Ghostty, and graphical
  user services.

A remote development LXC such as Hicks uses `workstation` with the desktop
overlay disabled. Archtower uses the desktop overlay. Server and workstation
profiles are normally selected by the corresponding Peterpan Ansible role;
manual use can pass the same Chezmoi data:

```bash
chezmoi --override-data '{"dotfiles_profile":"workstation","dotfiles_desktop":true}' init --apply kevinzehnder/chezmoi
```

Profile package installation is a change-triggered Chezmoi script. It installs
required packages but deliberately does not perform a full system upgrade.
