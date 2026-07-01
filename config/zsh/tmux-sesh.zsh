# Create TMUX Sessions on Dir
function _sesh_sessions_(){
    sesh list -t -c -H -d
}

function _sesh_all_(){
    sesh list -z
}

function _sesh_connect_(){
    sesh connect "$1"
}

function _sesh_kill_(){
    tmux kill-session -t "$1"
}


function sesh-connect-session() {
    _select_and_handle_ "Select a TMUX Session" _sesh_sessions_ _sesh_connect_
}
zle     -N             sesh-connect-session

function sesh-new-session() {
    _select_and_handle_ "Start a TMUX Session" _sesh_all_ _sesh_connect_
}
zle     -N             sesh-new-session

function sesh-kill-session() {
    _select_and_handle_ "Kill a TMUX Session" _sesh_sessions_ _sesh_kill_
}
zle     -N             sesh-kill-session




# Create TMUX Windows on Infra Session
function _kubectl_contexts_(){
    kubectl config get-contexts -o name
}

function _kubectl_switch_context_(){
    kubectl config use-context "$1" > /dev/null
    tmux rename-window "$1"
}

function kubectl-switch-context() {
    _select_and_handle_ "Select Kubectl Context" _kubectl_contexts_ _kubectl_switch_context_
}
zle     -N             kubectl-switch-context
bindkey '^[k' kubectl-switch-context # Alt-k






# Run a selection prompt and run an action on an item
function _select_and_handle_(){
    local title="$1"
    local target="$2"
    local action="$3"

    exec </dev/tty
    exec >&1

    local session=$($target | fzf --height 40% --reverse --border-label "$title" --border --prompt ">  ")

    zle reset-prompt > /dev/null 2>&1 || true
    [[ -z "$session" ]] && return

    "$action" "$session"
} 
