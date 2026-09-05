{
  config,
  pkgs,
  linkConfig,
  lib,
  ...
}:

{
  options = {
    opencodeProfile = lib.mkOption {
      type = lib.types.enum [
        "home"
        "work"
      ];
      default = "home";
      description = "OpenCode machine config";
    };
  };

  config = {
    home.packages = with pkgs; [
      opencode
    ];

    xdg.configFile = {
      "opencode/opencode.jsonc".source = linkConfig "opencode/opencode.jsonc";
      "opencode/opencode.json".source = linkConfig "opencode/${config.opencodeProfile}.json";
    };
  };
}
