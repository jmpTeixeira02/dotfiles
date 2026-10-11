{
  flake.modules.homeManager.git =
    {
      pkgs,
      linkConfig,
      ...
    }:
    let
      work = {
        user.email = "joao.teixeira01@sap.com";
        commit.gpgsign = true;
        tag.gpgSign = false;
      };
      githubOrg = host: org: contents: [
        {
          condition = "hasconfig:remote.*.url:git@${host}:${org}/**";
          inherit contents;
        }
        {
          condition = "hasconfig:remote.*.url:https://${host}/${org}/**";
          inherit contents;
        }
      ];
    in
    {
      home.packages = with pkgs; [
        gh
        gnupg
      ];

      programs.gh = {
        enable = true;
        gitCredentialHelper.enable = true;
      };

      programs.lazygit = {
        enable = true;
        enableZshIntegration = true;
        settings = {
          git = {
            overrideGpg = true;
            commit.signOff = true;
          };
        };
      };

      programs.git = {
        enable = true;
        settings = {
          user.name = "Joao Teixeira";
          user.email = "joaompt2002@hotmail.com";
          init.defaultBranch = "main";
          pull.rebase = true;
        };

        includes = githubOrg "github.com" "openkcm" work ++ githubOrg "github.tools.sap" "*" work;
      };
    };
}
