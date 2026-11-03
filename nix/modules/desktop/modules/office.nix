{
  flake.modules.homeManager.desktop-office =
    {
      inputs,
      pkgs,
      lib,
      ...
    }:
    let
      photogimp = pkgs.fetchFromGitHub {
        owner = "Diolinux";
        repo = "PhotoGIMP";
        rev = "fc61a8f4518eaf18659b749e9464ff32b6607739";
        sha256 = "sha256-JjK9W59xauzjl88aN1666gCJwUbKurrddFt9rGSMONQ=";
      };
      # https://github.com/NixOS/nixpkgs/pull/582388
      pkgs-euro-office =
        import
          (builtins.fetchTarball {
            url = "https://github.com/NixOS/nixpkgs/archive/e4c1726722802cccf69c7f1d32d686754d36b659.tar.gz";
            sha256 = "sha256:15z7s0908a2c103hrzid5l02ifinsg2pnh3kr2rv8mjwgdwq17jp";
          })
          {
            inherit (pkgs.stdenv.hostPlatform) system;
            config.allowUnfree = true; # only if needed
          };
    in
    {
      home.packages = [
        pkgs-euro-office.euro-office-desktopeditors
      ]
      ++ (with pkgs; [
        thunderbird
        gimp
        obs-studio
      ]);
      xdg.configFile."GIMP/3.0".source = "${photogimp}/.config/GIMP/3.0";
    };
}
