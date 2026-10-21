# Container helpers for the lightweight server Zsh profile.
# The runtime can be overridden with CONTAINER_RUNTIME=docker or nerdctl.
_container_runtime() {
  case "${CONTAINER_RUNTIME:-}" in
    "")
      # Prefer Docker when both runtimes are installed: hosts may also have
      # containerd/nerdctl for other workloads, while their app stack uses Docker.
      if command -v docker >/dev/null 2>&1; then
        print -r -- docker
      elif command -v nerdctl >/dev/null 2>&1; then
        print -r -- nerdctl
      else
        print -u2 -- "No container runtime found (nerdctl or docker)."
        return 1
      fi
      ;;
    nerdctl|docker)
      if command -v "$CONTAINER_RUNTIME" >/dev/null 2>&1; then
        print -r -- "$CONTAINER_RUNTIME"
      else
        print -u2 -- "Configured container runtime is not installed: $CONTAINER_RUNTIME"
        return 1
      fi
      ;;
    *)
      print -u2 -- "Unsupported CONTAINER_RUNTIME: $CONTAINER_RUNTIME (expected nerdctl or docker)"
      return 1
      ;;
  esac
}

alias d='sudo docker'
alias dcomp='sudo docker compose'
alias n='sudo nerdctl'
alias ncomp='sudo nerdctl compose'

function containers() {
  local runtime output header container_list
  local -a ps_args=(ps)

  runtime=$(_container_runtime) || return 1
  [[ "${1:-}" == "-a" ]] && ps_args+=(-a)
  check_sudo_nopass || sudo -v || return 1

  output=$(sudo "$runtime" "${ps_args[@]}") || return 1
  local colorizer=cat
  (( $+commands[tspin] )) && colorizer=tspin
  header=$(print -r -- "$output" | head -n 1)
  container_list=$(print -r -- "$output" | tail -n +2)
  if [[ -z "$container_list" ]]; then
    print 'No containers found'
    return 0
  fi

  print -r -- "$header"
  print -r -- "$container_list" | fzf \
    --preview="id=\$(print -r -- {} | awk '{print \$1}'); echo 'Container info:'; sudo ${runtime} inspect \$id | head -30; echo; echo 'Recent logs:'; sudo ${runtime} logs --tail 10 \$id | ${colorizer}" \
    --preview-window=down:60%:wrap \
    --header=$'Container Management | CTRL-R: reload\nCTRL-L: logs | CTRL-F: follow logs | CTRL-E: exec\nCTRL-S: start | CTRL-P: stop | CTRL-X: remove' \
    --bind="ctrl-r:reload(sudo ${runtime} ${ps_args[*]} | tail -n +2)" \
    --bind="ctrl-l:execute(id=\$(print -r -- {} | awk '{print \$1}'); sudo ${runtime} logs --tail 2000 \$id | ${colorizer} | less -R +G)" \
    --bind="ctrl-f:execute(id=\$(print -r -- {} | awk '{print \$1}'); sudo ${runtime} logs -f \$id | ${colorizer})" \
    --bind="ctrl-e:execute(id=\$(print -r -- {} | awk '{print \$1}'); sudo ${runtime} exec -it \$id sh)" \
    --bind="ctrl-s:execute(id=\$(print -r -- {} | awk '{print \$1}'); sudo ${runtime} start \$id)+reload(sudo ${runtime} ${ps_args[*]} | tail -n +2)" \
    --bind="ctrl-p:execute(id=\$(print -r -- {} | awk '{print \$1}'); sudo ${runtime} stop \$id)+reload(sudo ${runtime} ${ps_args[*]} | tail -n +2)" \
    --bind="ctrl-x:execute(id=\$(print -r -- {} | awk '{print \$1}'); sudo ${runtime} rm \$id)+reload(sudo ${runtime} ${ps_args[*]} | tail -n +2)"
}

alias c='containers'
alias ca='containers -a'
