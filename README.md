# Dotfiles

Nix Home Manager-based dotfiles with per-machine profiles.

## Profiles

| Profile | Platform       |
| ------- | -------------- |
| `home`  | x86_64-linux   |
| `homelab`  | x86_64-linux   |
| `work`  | aarch64-darwin |

## Nix Setup

### NixOS Machine Deployment
This setup supports both local and remote deployments. It assumes there is an internet connection, and will wipe all drives

1. Run the NixOS Minimal ISO on the remote machine
2. Set a temporary password `passwd`. This will be wiped on the install
3. Execute `./setup.sh <machine> <ip>`

Note: If you dont have a private key for the host, you need to generate one and update `.sops.yaml` by adding it there and updating the secrets


### Nix Install
1. Execute `./setup.sh`


##  Homemanager Setup
This step will install all the selected dependencies and sync it's configuration files through system links. Whenever there is a change in any of those the following command will propagate those changes

```sh
# Apply profile
sh reload.sh <profile>
```

### Post-Setup

Create `$XDG_CONFIG_HOME/zsh/secrets.zsh` for env vars/secrets (API keys, tokens, etc). This file is sourced by zsh but not tracked in git.
