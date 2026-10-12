{
  flake.modules.homeManager.desktop-file-manager =
    {
      inputs,
      pkgs,
      config,
      linkConfig,
      ...
    }:
    {
      home.packages = with pkgs; [
        nautilus
        libheif
        libheif.out
      ];

      services.udiskie.enable = true;
    };
}
