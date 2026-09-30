This hold the different services hosted as OCI Containers

# Seerr

Seerr does not have any easy way of doing the initial setup via API/Config File, so the setup will need to be manual

1. Select Jellyfin
2. Setup the Admin `URL: http://jellyfin:8096, Username: admin, Email: <sops.email>, Password: <sops.lldap.admin_pass>`
3. Sync Libraries
4. Add Radarr `Default Server: true, Server Name: Homelab, Hostname: radarr, API Key: <sops.media.radarr>, Quality: HD-1080p, Root: /storage, Min. Availability: Released, Enable Scan: true`
5. Add Sonarr `Default Server: true, Server Name: Homelab, Hostname: sonarr, API Key: <sops.media.sonarr>, Quality: HD-1080p, Root: /storage, Enable Scan: true`

## Cheat Sheet

See OCI Container status `sudo systemctl list-units podman-* -all`
Restart OCI Container `sudo systemctl restart <container-name>`
See OCI Container logs `sudo journalctl -u podman-<container-name>`
