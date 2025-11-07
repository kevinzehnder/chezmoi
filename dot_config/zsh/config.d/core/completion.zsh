#
# ZSH completion system configuration
#

# Custom completions directory setup
COMPLETIONS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/completions"
mkdir -p "$COMPLETIONS_DIR"

# Add completions directory to fpath for auto-loading
fpath=($COMPLETIONS_DIR $fpath)

# Function to conditionally generate completion (only if missing or tool updated)
_comp_if_needed() {
    local tool=$1
    local gen_cmd=$2
    local comp_file="$COMPLETIONS_DIR/_${tool}"
    local tool_path=$(command -v $tool 2>/dev/null)
    
    # Skip if tool is not installed
    if [[ -z "$tool_path" ]]; then
        return
    fi
    
    # Regenerate if completion missing OR tool binary is newer
    if [[ ! -f "$comp_file" ]] || [[ "$tool_path" -nt "$comp_file" ]]; then
        eval "$gen_cmd" > "$comp_file" 2>/dev/null && echo "Generated completion for $tool"
        # Flag that we've updated a completion
        _COMPLETIONS_UPDATED=1
    fi
}

# Generate completions as needed
_COMPLETIONS_UPDATED=0

# Tool completions
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

# Custom completions loader function
function load_custom_completions() {
    local completion_dir="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/completions"
    
    # Skip if directory doesn't exist
    if [[ ! -d $completion_dir ]]; then
        return
    fi
    
    # Load completions using zinit if available
    if (( ${+functions[zi]} )); then
        setopt local_options nullglob
        local compfiles=("$completion_dir"/_*)
        if [[ -n $compfiles ]]; then
            for file in "${compfiles[@]}"; do
                zi ice as"completion" lucid
                zi snippet "$file"
            done
        fi
        unsetopt nullglob
    # Standard completion loading without zinit
    else
        # Make sure the directory is in fpath
        if [[ ${fpath[(ie)$completion_dir]} -gt ${#fpath} ]]; then
            fpath=($completion_dir $fpath)
        fi
        
        # Rebuild zcompdump if completions were updated
        if [[ $_COMPLETIONS_UPDATED -eq 1 ]]; then
            rm -f "${ZDOTDIR:-$HOME}/.zcompdump"
            compinit
        fi
    fi
}

# Call the function to load custom completions if any were updated
if [[ $_COMPLETIONS_UPDATED -eq 1 ]]; then
    load_custom_completions
fi
