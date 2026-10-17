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
          fps = true;
          frametime = true;
          frame_timing = true;
          gpu_stats = true;
          cpu_stats = true;
        };
      };
    };
}
