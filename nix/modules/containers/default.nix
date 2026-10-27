{ config, ... }:
{
  flake.modules.nixos.homelab-containers = { pkgs, ... }: {
    imports = [
      # config.flake.modules.nixos.homelab-containers-netbird
      config.flake.modules.nixos.homelab-containers-monitoring
      config.flake.modules.nixos.homelab-containers-crowdsec
      config.flake.modules.nixos.homelab-containers-authelia
      config.flake.modules.nixos.homelab-containers-cups
      config.flake.modules.nixos.homelab-containers-ddns-updater
      config.flake.modules.nixos.homelab-containers-dockhand
      config.flake.modules.nixos.homelab-containers-droppedneedle
      config.flake.modules.nixos.homelab-containers-flaresolverr
      config.flake.modules.nixos.homelab-containers-homepage
      config.flake.modules.nixos.homelab-containers-jellyfin
      config.flake.modules.nixos.homelab-containers-lldap
      config.flake.modules.nixos.homelab-containers-navidrome
      config.flake.modules.nixos.homelab-containers-papra
      config.flake.modules.nixos.homelab-containers-prowlarr
      config.flake.modules.nixos.homelab-containers-radarr
      config.flake.modules.nixos.homelab-containers-seerr
      config.flake.modules.nixos.homelab-containers-slskd
      config.flake.modules.nixos.homelab-containers-smb
      config.flake.modules.nixos.homelab-containers-sonarr
      config.flake.modules.nixos.homelab-containers-torrent
      config.flake.modules.nixos.homelab-containers-traefik
    ];
  };
}
