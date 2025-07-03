# Kevin Zehnder's Dotfiles

[![Managed by chezmoi](https://img.shields.io/badge/managed%20by-chezmoi-blue.svg)](https://www.chezmoi.io/)

This repository contains my personal dotfiles, managed by [chezmoi](https://www.chezmoi.io/).

## Bootstrap on a New Arch Linux Machine

To set up a new Arch Linux system with these dotfiles, run the following command. This will install the necessary dependencies (`git`, `chezmoi`) and then initialize the configuration, running the bootstrap script to install all packages and set up the environment.

```bash
sudo pacman -Syu --needed --noconfirm git chezmoi && sudo chezmoi init --apply https://github.com/kevinzehnder/chezmoi.git
```

### Interactive Setup

For a more controlled setup where you can review changes before they are applied:

1.  **Install dependencies:**
    ```bash
    sudo pacman -Syu --needed --noconfirm git chezmoi
    ```
2.  **Initialize `chezmoi`:**
    ```bash
    chezmoi init https://github.com/kevinzehnder/chezmoi.git
    ```
3.  **Preview the changes:**
    ```bash
    chezmoi diff
    ```
4.  **Apply the configuration:**
    ```bash
    sudo chezmoi apply
    ```
