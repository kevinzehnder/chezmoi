#
# Environment variables and paths
#

# Editors
export EDITOR='nvim'
export VISUAL='nvim'
export COLORTERM="truecolor"
export NVIM_APPNAME="nvim"

# Golang
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/.go/bin
export GOPATH=$HOME/.go

# FZF settings
export FZF_DEFAULT_COMMAND='fd --type file --follow --exclude .git --color always'
export FZF_PREVIEW_COMMAND='bat --style=numbers,changes --wrap never --color always {} || cat {} || tree -C {}'

export FZF_DEFAULT_OPTS="
--layout=reverse 
--bind='?:toggle-preview' 
--bind='ctrl-space:toggle' 
--info=inline 
--height=50% 
--ansi
--multi 
--prompt='∼ ' 
--pointer='▶' 
--marker='✓' 
--bind 'ctrl-a:select-all'
--color=bg:0,fg:7,hl:3
--color=bg+:8,fg+:7,hl+:11
--color=info:3,border:3,prompt:4
--color=pointer:0,marker:9,spinner:9,header:1
"

export FZF_ALT_C_COMMAND='fd --type directory'
export FZF_ALT_C_OPTS="
--height=75% 
--preview-window down:70% 
--preview-window border 
--preview='eza --color=always -T {}'
"

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="
--height 80% 
--preview-window border 
--preview '($FZF_PREVIEW_COMMAND) 2> /dev/null' 
"

export FZF_COMMON_OPTIONS="
--bind='?:toggle-preview'
--bind='ctrl-space:toggle'
--bind='ctrl-u:preview-page-up'
--bind='ctrl-d:preview-page-down'
--preview-window 'right:60%:hidden:wrap'
--preview '([[ -d {} ]] && tree -C {}) || ([[ -f {} ]] && bat --style=full --color=always {}) || echo {}'"

# Navi settings
export NAVI_FZF_OVERRIDES='--with-nth 3,2,1 --height 70%'
