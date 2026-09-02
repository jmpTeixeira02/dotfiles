{
  config,
  pkgs,
  lib,
  ...
}:

{

  virtualisation.oci-containers.containers.flaresolverr = {
    image = "ghcr.io/flaresolverr/flaresolverr:v3.5.0";
    autoStart = true;
    ports = [
      "8191:8191"
    ];
  };
}
