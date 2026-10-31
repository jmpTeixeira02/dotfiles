{
  flake.modules.homeManager.desktop-communication =
    { pkgs, lib, ... }:
    let
      # https://github.com/NixOS/nixpkgs/pull/580650
      prPkgs =
        import
          (builtins.fetchTarball {
            url = "https://github.com/NixOS/nixpkgs/archive/dde65bd72899c015696032345a4221ab635ff41e.tar.gz";
            sha256 = "sha256:1gcsj9payr8pjcm4n822236i24jf70l4izjl74w58k51w4ffpy10";
          })
          {
            inherit (pkgs.stdenv.hostPlatform) system;
            config.allowUnfree = true;
          };
    in
    {
      home.packages = with pkgs; [
        zapzap
      ];

      programs.discord = {
        enable = true;
        package = prPkgs.discord;
      };
    };
}
