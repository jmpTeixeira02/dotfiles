source ~/.nix-profile/share/antigen/antigen.zsh

antigen use oh-my-zsh
antigen bundle command-not-found

command -v git >/dev/null 2>&1 && antigen bundle git
command -v eza >/dev/null 2>&1 && antigen bundle eza
command -v tmux >/dev/null 2>&1 && antigen bundle tmux
command -v kubectl >/dev/null 2>&1 && antigen bundle kubectl

antigen bundle zsh-users/zsh-completions
antigen bundle marlonrichert/zsh-autocomplete@26.08.04
antigen bundle zsh-users/zsh-syntax-highlighting
antigen apply

command -v kubectl > /dev/null 2>&1 && source <(kubectl completion zsh)
