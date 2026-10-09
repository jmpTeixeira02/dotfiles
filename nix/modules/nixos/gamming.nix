{
  flake.modules.nixos.gamming = { pkgs, ... }: {
    hardware = {
      bluetooth.enable = true;
      steam-hardware.enable = true;
      graphics = {
        enable = true;
        enable32Bit = true;
      };
    };
    programs = {
      gamemode.enable = true;
      gamescope.enable = true;
      steam.enable = true;
    };
  };
}
