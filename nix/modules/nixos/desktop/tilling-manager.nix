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
    };

    security.polkit.enable = true;
  };
}
