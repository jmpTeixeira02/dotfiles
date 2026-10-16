if [ "$#" -eq 1 ]; then
    PLATFORM="$1"
    if [ "$PLATFORM" != "linux-x86_64" ] && [ "$PLATFORM" != "macos-aarch64" ]; then
        echo "Error: Invalid argument '$PLATFORM'. Must be 'linux-x86_64' or 'macos-aarch64'."
        exit 1
    fi
else
    OS="$(uname -s)"
    ARCH="$(uname -m)"
    case "$OS-$ARCH" in
    Linux-x86_64) PLATFORM="linux-x86_64" ;;
    Darwin-arm64) PLATFORM="macos-aarch64" ;;
    *)
        echo "Error: Unsupported platform $OS-$ARCH. Pass platform manually: $0 <linux-x86_64|macos-aarch64>"
        exit 1
        ;;
    esac
fi

URL="https://github.com/jmpTeixeira02/dotfiles/releases/latest/download/dots-$PLATFORM"

echo "Downloading from: $URL"
curl -SsL -o dots "$URL"

if [ $? -eq 0 ]; then
    chmod +x dots
else
    echo "Error: Download failed."
    exit 1
fi
