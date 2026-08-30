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

    home.file = {
      ".config/opencode/opencode.jsonc".source = linkConfig "opencode/opencode.jsonc";
      ".config/opencode/opencode.json".source = linkConfig "opencode/${config.opencodeProfile}.json";
    };
  };
}
