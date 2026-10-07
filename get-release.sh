if [ "$#" -ne 1 ]; then
    echo "Error: Exactly one argument is required."
    echo "Usage: $0 <linux-x86_64|macos-aarch64>"
    exit 1
fi

ARCH="$1"

if [ "$ARCH" != "linux-x86_64" ] && [ "$ARCH" != "macos-aarch64" ]; then
    echo "Error: Invalid argument '$ARCH'. Must be 'linux-x86_64' or 'macos-aarch64'."
    exit 1
fi

URL="https://github.com/jmpTeixeira02/dotfiles/releases/latest/download/dots-$ARCH"

echo "Downloading from: $URL"
curl -L -o dots "$URL"

if [ $? -eq 0 ]; then
    chmod +x dots
else
    echo "Error: Download failed."
    exit 1
fi
