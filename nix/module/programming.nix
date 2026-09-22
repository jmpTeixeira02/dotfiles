{
  config,
  pkgs,
  linkConfig,
  ...
}:

{
  home.packages = with pkgs; [
    go
    graphviz # Go Profiler dependency
    buf # Protobuf
    nodejs
    python3
    rustc
    cargo
    rust-analyzer

    openjdk

    docker
    docker-compose
    kubernetes-helm
    kubectl
    k3d
    opentofu
    ansible
  ];
}
