# Alias
alias vim="nvim"
alias vi="nvim"
alias src="source $XDG_CONFIG_HOME/zsh/.zshrc"
alias tree="eza --icons --tree"
alias cat='bat --paging=never'
alias clean_nvim='rm -rf ~/.local/share/nvim'

dots() {
    if [ -z "${FLAKE_DOTFILES:-}" ]; then 
        echo "Environment variable FLAKE_DOTFILES is not setup"
        echo "This should be automatically setup on first run of the dotfiles, if not run the binary directly"
        exit 1
    fi
    command $FLAKE_DOTFILES/dots "$@"
}

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
