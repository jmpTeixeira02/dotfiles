# Homelab

This machine is a node that acts as a NAS and contains other services such as a Media server, Homelab Environment with Lab VMs and Printing Server

## Specs
- i7-4790k
- 42GB RAM DDR3
- 256GB Management SSD
- Multiple HDD Storage Drives
    - Use mergerfs to use drives as one in the NAS
- Services 
    - Network Infra (NetBird, Traefik, Adguard, Authelia, DDNS-Updater)
    - ArrStack (Sonarr, Radarr, Prowlarr, qBitTorrent, Bazarr)
    - Immich Server
    - NAS (Samba)
    - Lab VMs
    - Jellyfin
    - Paperless NGX
    - Dashboard
    - Open Printer CUPS
