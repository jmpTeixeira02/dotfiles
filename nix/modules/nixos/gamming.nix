{
  flake.modules.nixos.gamming = { pkgs, ... }: {
    hardware = {
      steam-hardware.enable = true;
    };
    programs = {
      gamemode.enable = true;
      gamescope.enable = true;
      steam = {
        enable = true;
        extraPackages = [ pkgs.mangohud ];
      };
    };
  };
}
