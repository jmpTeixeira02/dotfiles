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
    in
    {
      home.packages = with pkgs; [
        euro-office-desktopeditors
        thunderbird
        gimp
        obs-studio
      ];

      xdg.configFile."GIMP/3.0".source = "${photogimp}/.config/GIMP/3.0";
    };
}
