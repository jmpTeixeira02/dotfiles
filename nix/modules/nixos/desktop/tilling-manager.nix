{
  flake.modules.nixos.tilling-manager = { pkgs, lib, ... }: {
    programs.niri = {
      enable = true;
    };

    services = {
      displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };
      desktopManager.plasma6.enable = true;
      displayManager.defaultSession = lib.mkForce "plasma";
    };

    security.polkit.enable = true;
  };
}
