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
        rev = "master";
        sha256 = "sha256-LNopObpXTkYbjqZMkwu0DhdLROuTkE+LYsnwdaICTd0=";
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
