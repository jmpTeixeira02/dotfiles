{
  flake.modules.homeManager.encryption =
    {
      pkgs,
      linkConfig,
      ...
    }:
    {
      home.packages = with pkgs; [
        age
        sops
      ];
    };
}
