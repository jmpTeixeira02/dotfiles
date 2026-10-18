{
  flake.modules.homeManager.desktop-gamming =
    { inputs, pkgs, ... }:
    {
      home.packages = with pkgs; [
        vulkan-tools

        heroic
        bottles

        deadlock-mod-manager
      ];

      programs.mangohud = {
        enable = true;
        settings = {
          no_display = true;
          toggle_hud = "Shift_R+F1";
          preset = 3;
          core_load = false;
          gpu_mem_clock = true;
          vram = true;
          gtt = true;
        };
      };
    };
}
