{
  flake.modules.homeManager.desktop-gamming =
    { inputs, pkgs, ... }:
    {
      home.packages = with pkgs; [
        vulkan-tools
        mangohud

        heroic
        bottles

        deadlock-mod-manager
      ];
    };
}
