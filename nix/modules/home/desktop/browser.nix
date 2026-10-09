{
  flake.modules.homeManager.desktop-browser =
    { inputs, ... }:
    {
      imports = [
        inputs.zen-browser.homeModules.beta
      ];

      programs.zen-browser = {
        enable = true;
        setAsDefaultBrowser = true;
      };
    };
}
