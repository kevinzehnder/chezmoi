# Server profile: portable FZF layout, previews, and Zsh key bindings.

export FZF_DEFAULT_COMMAND='fd --type file --follow --exclude .git --color always 2>/dev/null || find . -type f -not -path "*/.git/*" -print'
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
--bind='ctrl-a:select-all'
--color=bg:-1,fg:-1,hl:-1
--color=bg+:-1,fg+:-1,hl+:-1
--color=info:-1,border:-1,prompt:-1
--color=pointer:-1,marker:-1,spinner:-1,header:-1
"

export FZF_ALT_C_COMMAND='fd --type directory --follow --exclude .git 2>/dev/null || find . -type d -not -path "*/.git/*" -print'
export FZF_ALT_C_OPTS="
--height=75%
--preview-window=down:70%:border
--preview='ls -lah --color=always {}'
"

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="
--height=80%
--preview-window=right:60%:border:wrap
--preview='if [ -d {} ]; then ls -lah --color=always {}; elif command -v bat >/dev/null 2>&1; then bat --style=numbers,changes --wrap=never --color=always {}; else sed -n "1,200p" {}; fi 2>/dev/null'
"

for fzf_binding in \
  /usr/share/fzf/shell/key-bindings.zsh \
  /usr/share/doc/fzf/examples/key-bindings.zsh; do
  if [[ -r "$fzf_binding" ]]; then
    source "$fzf_binding"
    break
  fi
done
