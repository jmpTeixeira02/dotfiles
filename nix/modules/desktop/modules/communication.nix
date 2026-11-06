{
  flake.modules.homeManager.desktop-communication =
    { pkgs, lib, ... }:
    # Can be removed after https://github.com/NixOS/nixpkgs/pull/579595 hits unstable
    # This version is needed for voice calls
    let
      zapfastPkgs =
        import
          (builtins.fetchTarball {
            url = "https://github.com/NixOS/nixpkgs/archive/30fc4472ba178021e07ff9efbb367647317ad453.tar.gz";
            sha256 = "sha256:0c9xl8ryd4xd3lnrhm0vdk9skzb2i44pg7lpcvm9nbcmhb4df3g9";
          })
          {
            inherit (pkgs.stdenv.hostPlatform) system;
          };
    in
    {
      home.packages = [
        zapfastPkgs.zapfast
      ];

      programs.discord = {
        enable = true;
      };
    };
}
