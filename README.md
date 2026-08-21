# Dotfiles

Nix Home Manager-based dotfiles with per-machine profiles.

## Profiles

| Profile | Platform       |
| ------- | -------------- |
| `home`  | x86_64-linux   |
| `work`  | aarch64-darwin |

## Setup

```sh
# Install Nix (Determinate installer)
sh setup.sh

# Apply profile
sh reload.sh <profile>

# Update flake inputs
sh update.sh

# Garbage collect old generations
sh clean.sh
```

## Post-install

Create `~/.config/zsh/secrets.zsh` for env vars/secrets (API keys, tokens, etc). This file is sourced by zsh but not tracked in git.
