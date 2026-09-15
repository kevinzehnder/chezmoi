# Server profile: portable FZF layout, previews, and Zsh key bindings.

export FZF_DEFAULT_COMMAND='fd --type file --follow --exclude .git --color always 2>/dev/null || fdfind --type file --follow --exclude .git --color always 2>/dev/null || find . -type f -not -path "*/.git/*" -print'
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

export FZF_ALT_C_COMMAND='fd --type directory --follow --exclude .git 2>/dev/null || fdfind --type directory --follow --exclude .git 2>/dev/null || find . -type d -not -path "*/.git/*" -print'
export FZF_ALT_C_OPTS="
--height=75%
--preview-window=down:70%:border
--preview='ls -lah --color=always {}'
"

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="
--height=80%
--preview-window=right:60%:border:wrap
--preview='if [ -d {} ]; then ls -lah --color=always {}; elif command -v bat >/dev/null 2>&1; then bat --style=numbers,changes --wrap=never --color=always {}; elif command -v batcat >/dev/null 2>&1; then batcat --style=numbers,changes --wrap=never --color=always {}; else sed -n "1,200p" {}; fi 2>/dev/null'
"

for fzf_binding in \
  /usr/share/fzf/shell/key-bindings.zsh \
  /usr/share/doc/fzf/examples/key-bindings.zsh; do
  if [[ -r "$fzf_binding" ]]; then
    source "$fzf_binding"
    break
  fi
done

# Lightweight file workflows shared by workstations and servers. Keep these
# here rather than importing config.d: they need only fzf, fd/fdfind, and an
# optional bat/batcat previewer.
_server_fzf_file_list() {
  if (( $+commands[fd] )); then
    command fd --type file --follow --exclude .git --color=never
  elif (( $+commands[fdfind] )); then
    command fdfind --type file --follow --exclude .git --color=never
  else
    command find . -type f -not -path "*/.git/*" -print
  fi
}

_server_fzf_preview='if command -v bat >/dev/null 2>&1; then bat --style=numbers,changes --wrap=never --color=always {}; elif command -v batcat >/dev/null 2>&1; then batcat --style=numbers,changes --wrap=never --color=always {}; else sed -n "1,200p" {}; fi 2>/dev/null'
_server_fzf_match_preview='if command -v bat >/dev/null 2>&1; then bat --style=numbers,changes --wrap=never --color=always {1}; elif command -v batcat >/dev/null 2>&1; then batcat --style=numbers,changes --wrap=never --color=always {1}; else sed -n "1,200p" {1}; fi 2>/dev/null'

_server_fzf_select_files() {
  _server_fzf_file_list | fzf --ansi --multi --height=80% \
    --preview "$_server_fzf_preview" \
    --preview-window=right:60%:border:wrap \
    --header '?: toggle preview | TAB: select multiple files'
}

# CTRL-P inserts selected paths at the prompt, ready to be used by the command
# being composed. CTRL-F opens the selected file(s) in $EDITOR.
_server_fzf_insert_files() {
  emulate -L zsh
  zle -I

  local selected file
  selected="$(_server_fzf_select_files)" || {
    zle reset-prompt
    return 0
  }
  [[ -n "$selected" ]] || {
    zle reset-prompt
    return 0
  }

  while IFS= read -r file; do
    LBUFFER+="${(q)file} "
  done <<< "$selected"
  zle reset-prompt
}
zle -N _server_fzf_insert_files
bindkey '^P' _server_fzf_insert_files

_server_fzf_open_files() {
  emulate -L zsh
  zle -I

  local selected
  selected="$(_server_fzf_select_files)" || {
    zle reset-prompt
    return 0
  }
  [[ -n "$selected" ]] || {
    zle reset-prompt
    return 0
  }

  local -a files editor
  files=("${(@f)selected}")
  editor=("${(z)${EDITOR:-vim}}")
  "${editor[@]}" "${files[@]}"
  zle reset-prompt
}
zle -N _server_fzf_open_files
bindkey '^F' _server_fzf_open_files

# Search file contents with ripgrep, select a match, and open it at the line.
# Usage: fs [directory]
fs() {
  emulate -L zsh
  local search_dir="${1:-.}"
  local selected file remainder line

  if (( ! $+commands[rg] )); then
    print -u2 'fs requires ripgrep (rg)'
    return 127
  fi

  selected="$(rg --column --line-number --no-heading --color=never --smart-case '' "$search_dir" 2>/dev/null | \
    fzf --ansi --height=80% --delimiter=: --nth=3.. \
      --preview "$_server_fzf_match_preview" \
      --preview-window=right:60%:border:wrap:+{2}-/2)" || return 0
  [[ -n "$selected" ]] || return 0

  file="${selected%%:*}"
  remainder="${selected#*:}"
  line="${remainder%%:*}"
  local -a editor
  editor=("${(z)${EDITOR:-vim}}")
  "${editor[@]}" "+${line}" "$file"
}
