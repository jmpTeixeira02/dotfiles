{
  config,
  pkgs,
  linkConfig,
  ...
}:
let
  ts-grammars = pkgs.vimPlugins.nvim-treesitter.withAllGrammars;
in
{
  programs.neovim = {
    enable = true;
    plugins = [ ts-grammars ];
    initLua = builtins.readFile "${config.paths.configPath}/nvim/init.lua";
  };

  home.packages = with pkgs; [
    tectonic
    imagemagick_light
    ghostscript
    mermaid-cli

    # Lua
    lua-language-server
    stylua
    luarocks

    # Bash
    bash-language-server
    shellcheck
    shfmt

    # GoLang
    gopls
    gofumpt
    gotools
    gomodifytags
    impl
    golangci-lint
    delve

    # Python
    pyright
    ruff
    python3Packages.debugpy

    # Rust
    bacon
    lldb

    # JS/TS
    vtsls
    vscode-js-debug
    (writeShellScriptBin "js-debug-adapter" ''exec ${vscode-js-debug}/bin/js-debug "$@"'')
    prettier
    prettierd

    # JSON
    vscode-langservers-extracted # jsonls

    # YAML
    yaml-language-server

    # TOML
    taplo

    # NIX
    nil
    nixfmt
    statix

    # Markdown
    marksman
    markdownlint-cli2
    markdown-toc

    # Terraform
    terraform-ls
    tflint

    # Ansible
    ansible-language-server
    ansible-lint

    # CMake
    neocmakelsp
    cmake-format
    cmake-lint
    cmake

    # Docker
    dockerfile-language-server
    docker-compose-language-service
    hadolint

    # Helm
    helm-ls

    # Java
    jdt-language-server

    # SQL
    sqlfluff

    # Treesitter
    tree-sitter
  ];

  xdg.configFile = {
    "nvim/lua".source = linkConfig "nvim/lua";
    "nvim/spell".source = linkConfig "nvim/spell";
    "nvim/lazyvim.json".source = linkConfig "nvim/lazyvim.json";
    "nvim/lazy-lock.json".source = linkConfig "nvim/lazy-lock.json";
    "nvim/.neoconf.json".source = linkConfig "nvim/.neoconf.json";
  };
}
