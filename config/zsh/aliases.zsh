# Alias
alias vim="nvim"
alias vi="nvim"
alias src="source ~/.zshrc"
alias tree="eza --icons --tree"
alias cat='bat --paging=never'
alias clean_nvim='rm -rf ~/.local/share/nvim'
alias nix_clean="nix-collect-garbage -d"
alias nix_update_store="nix flake update --flake ./nix"

# Lazygit switch dir on exit
lg()
{
    export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir

    lazygit "$@"

    if [ -f $LAZYGIT_NEW_DIR_FILE ]; then
            cd "$(cat $LAZYGIT_NEW_DIR_FILE)"
            rm -f $LAZYGIT_NEW_DIR_FILE > /dev/null
    fi
}
