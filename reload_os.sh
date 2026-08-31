if [ -z "$1" ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

export NIX_USER="$1"
sudo nixos-rebuild switch --flake ./nix#${NIX_USER}
