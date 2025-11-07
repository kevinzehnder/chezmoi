#
# ZSH completion system configuration
#

# Basic completion settings
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3>7?7:($#PREFIX+$#SUFFIX)/3))numeric)'

# Disable sort when completing git checkout
zstyle ':completion:*:git-checkout:*' sort false

# Completion groups and formatting
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:corrections' format ' %F{green}-- %d (errors: %e) --%f'
zstyle ':completion:*:descriptions' format ' %F{yellow}-- %d --%f'
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
zstyle ':completion:*' format ' %F{yellow}-- %d --%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes

# Case insensitive matching and fuzzy matching
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Ignore specified patterns in completions
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'

# Performance settings
zstyle ':completion:*' use-cache true
zstyle ':completion:*' rehash true

# FZF-tab settings
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:*' show-group none
zstyle ':fzf-tab:*' fzf-flags --bind=tab:accept
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:*' switch-group '<' '>'

# Auto-generate completions with caching
ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$ZSH_CACHE_DIR"

# Function to conditionally generate completion (only if missing or tool updated)
_comp_if_needed() {
    local tool=$1
    local gen_cmd=$2
    local comp_file="$ZSH_CACHE_DIR/_${tool}"
    local tool_path=$(command -v $tool 2>/dev/null)

    if [[ -z "$tool_path" ]]; then
        return  # Tool not installed, skip
    fi

    # Regenerate if completion missing OR tool binary is newer
    if [[ ! -f "$comp_file" ]] || [[ "$tool_path" -nt "$comp_file" ]]; then
        eval "$gen_cmd" > "$comp_file" 2>/dev/null && echo "Generated completion for $tool"
    fi
}

# Generate completions as needed (cached)
_comp_if_needed "atuin" "atuin gen-completions --shell zsh"
_comp_if_needed "gh" "gh completion -s zsh"
_comp_if_needed "kubectl" "kubectl completion zsh"
_comp_if_needed "helm" "helm completion zsh"
_comp_if_needed "k9s" "k9s completion zsh"
_comp_if_needed "devbox" "devbox completion zsh"
_comp_if_needed "rustup" "rustup completions zsh"
_comp_if_needed "kustomize" "kustomize completion zsh"
_comp_if_needed "kubectl-argo-rollouts" "kubectl-argo-rollouts completion zsh"
_comp_if_needed "uv" "uv generate-shell-completion zsh"
_comp_if_needed "uvx" "uvx --generate-shell-completion zsh"
_comp_if_needed "xh" "xh --generate complete-zsh"
_comp_if_needed "nerdctl" "nerdctl completion zsh"


# Add cache dir to fpath for auto-loading
fpath=($ZSH_CACHE_DIR $fpath)

# Custom completions (for tools without auto-generation or manually maintained)
function load_custom_completions() {
    local completion_dir="$HOME/.config/zsh/completions"
    setopt local_options nullglob
    local compfiles=("$completion_dir"/_*)
    if [[ -d $completion_dir ]] && [[ -n $compfiles ]]; then
        for file in "${compfiles[@]}"; do
            zi ice as"completion" lucid
            zi snippet "$file"
        done
    fi
    unsetopt nullglob
}
