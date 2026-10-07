# Dotfiles

Nix dotfiles with per-machine profiles. This contains both full NixOS configurations as well as dotfiles link

## Profiles

| Profile   | Platform       |
| --------- | -------------- |
| `home`    | x86_64-linux   |
| `homelab` | x86_64-linux   |
| `work`    | aarch64-darwin |

## Dots Tool

This repo has a cli tool to manage the nix actions, such as install, reload, clean and update instead of relying on shell scripts or big commands. The tool needs to be executed on the root of this repo and get via curl on the release

Run the binary with `-h` to get more information on each command and it's flags

To download via curl `https://github.com/jmpTeixeira02/dotfiles/releases/latest/download/dots-<arch>`

## Install

The command picks the right installer from the host: NixOS hosts (`home`, `homelab`) deploy via `nixos-anywhere`, Home Manager hosts (`wsl`, `work`) run the Determinate Nix installer. The `--host`, `--format-disks` and `--key` flags only take effect on NixOS hosts.

### NixOS Machine Deployment

This setup supports both local and remote deployments. It assumes there is an internet connection, and will wipe all drives

1. Run the NixOS Minimal ISO on the remote machine
2. Set a password `passwd`
3. Execute `./dots install <host> -k`

Note: If you dont have a private key for the host, you need to generate one and update `.sops.yaml` by adding it there and updating the secrets

### Nix

1. Execute `./dots install <host>`

## Reload System

1. Execute `./dots reload -u <host>`

### Post-Setup

Create `$XDG_CONFIG_HOME/zsh/secrets.zsh` for env vars/secrets (API keys, tokens, etc). This file is sourced by zsh but not tracked in git.

## Notes

- Nix also supports remote reloads through the `--target-host <host>` that was used on the install. However the reload scripts do not have it by default
- On NixOS Zsh is set as default shell. For other OSs ZSH needs to be set as default `sudo chsh -s "$(which zsh)"`
