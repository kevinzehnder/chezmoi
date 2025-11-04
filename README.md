# dotfiles

[![Managed by chezmoi](https://img.shields.io/badge/managed%20by-chezmoi-blue.svg)](https://www.chezmoi.io/)

This repository contains my personal dotfiles, managed by [chezmoi](https://www.chezmoi.io/).

## Bootstrap 

To set up a new system with these dotfiles, run the following command. 
This will install the necessary dependencies (`git`, `chezmoi`) and then initialize the configuration, 
running the bootstrap script to install all packages and set up the environment.

```bash
sudo chezmoi init --apply https://github.com/kevinzehnder/chezmoi.git
```

