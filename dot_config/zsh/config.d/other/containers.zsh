# Return a supported, installed container runtime. Do not execute CONTAINER_RUNTIME.
_container_runtime() {
	case "${CONTAINER_RUNTIME:-}" in
		"")
			if command -v docker >/dev/null 2>&1; then
				print -r -- docker
			elif command -v nerdctl >/dev/null 2>&1; then
				print -r -- nerdctl
			else
				print -u2 -- "No container runtime found (docker or nerdctl). Set CONTAINER_RUNTIME to one of those names."
				return 1
			fi
			;;
		docker|nerdctl)
			if command -v "$CONTAINER_RUNTIME" >/dev/null 2>&1; then
				print -r -- "$CONTAINER_RUNTIME"
			else
				print -u2 -- "Configured container runtime is not installed: $CONTAINER_RUNTIME"
				return 1
			fi
			;;
		*)
			print -u2 -- "Unsupported CONTAINER_RUNTIME: $CONTAINER_RUNTIME (expected docker or nerdctl)"
			return 1
			;;
	esac
}

function containers() {
	local runtime
	runtime=$(_container_runtime) || return 1

	# Check sudo and stop if authentication was cancelled or failed.
	check_sudo_nopass || sudo -v || return 1

	# Command options
	local -a ps_args=(ps)
	[[ "$1" == "-a" ]] && ps_args+=( -a )
	# Set up log commands based on tspin availability
	if command -v tspin > /dev/null 2>&1; then
		local logs="ID=\$(echo {} | awk '{print \$1}'); sudo ${runtime} logs --tail 2000 \$ID | tspin | less -r +G"
		local follow_logs="ID=\$(echo {} | awk '{print \$1}'); sudo ${runtime} logs -f \$ID | tspin"
	else
		local logs="ID=\$(echo {} | awk '{print \$1}'); sudo ${runtime} logs --tail 2000 \$ID | less -r +G"
		local follow_logs="ID=\$(echo {} | awk '{print \$1}'); sudo ${runtime} logs -f \$ID"
	fi
	# Get the header and containers without evaluating a command string.
	local header=$(sudo "$runtime" "${ps_args[@]}" | head -1)
	local containers=$(sudo "$runtime" "${ps_args[@]}" | tail -n +2)
	if [[ -z "$containers" ]]; then
		echo "No containers found"
		return
	fi
	# Run fzf with header line and preview at bottom
	echo "$header"
	echo "$containers" | fzf \
		--preview="ID=\$(echo {} | awk '{print \$1}'); echo -e '\033[1;32mContainer Info:\033[0m'; sudo ${runtime} inspect \$ID | head -30; echo -e '\n\033[1;33mRecent Logs:\033[0m'; sudo ${runtime} logs --tail 10 \$ID" \
		--preview-window=down:60%:wrap \
		--header $'Container Management | CTRL-R: reload\nCTRL-L: logs | CTRL-F: follow logs | CTRL-E: exec\nCTRL-S: start | CTRL-P: stop | CTRL-X: rm' \
		--bind "ctrl-l:execute($logs)" \
		--bind "ctrl-f:execute($follow_logs)" \
		--bind "ctrl-e:execute(ID=\$(echo {} | awk '{print \$1}'); sudo ${runtime} exec -it \$ID sh)" \
		--bind "ctrl-s:execute(ID=\$(echo {} | awk '{print \$1}'); echo \"Starting \$ID...\"; sudo ${runtime} start \$ID; echo \"Reloading...\")+reload(sudo ${runtime} ${ps_args[*]} | tail -n +2)" \
		--bind "ctrl-p:execute(ID=\$(echo {} | awk '{print \$1}'); echo \"Stopping \$ID...\"; sudo ${runtime} stop \$ID; echo \"Reloading...\")+reload(sudo ${runtime} ${ps_args[*]} | tail -n +2)" \
		--bind "ctrl-r:reload(sudo ${runtime} ${ps_args[*]} | tail -n +2)" \
		--bind "ctrl-x:execute(ID=\$(echo {} | awk '{print \$1}'); echo \"Removing \$ID...\"; sudo ${runtime} rm \$ID; echo \"Reloading...\")+reload(sudo ${runtime} ${ps_args[*]} | tail -n +2)"
}

alias c='containers'
alias ca='containers -a'

function images() {
	local runtime
	runtime=$(_container_runtime) || return 1

	check_sudo_nopass || sudo -v || return 1

	local header=$(sudo "$runtime" images | head -1)
	local image_list=$(sudo "$runtime" images | tail -n +2)

	if [[ -z "$image_list" ]]; then
		echo "No images found"
		return
	fi

	# This string runs in fzf's shell; runtime was validated above.
	local pull_new="printf 'New image to pull: '; IFS= read -r img; sudo ${runtime} pull \"\$img\"; printf 'Press any key to continue'; read -r"

	echo "$header"
	echo "$image_list" | fzf \
		--preview="ID=\$(echo {} | awk '{print \$3}'); sudo ${runtime} image inspect \$ID" \
		--preview-window=down:60%:wrap \
		--header $'Image Management | CTRL-R: reload\nCTRL-X: rm | CTRL-U: update image | CTRL-P: pull new' \
		--bind "ctrl-r:reload(sudo ${runtime} images | tail -n +2)" \
		--bind "ctrl-x:execute(ID=\$(echo {} | awk '{print \$3}'); sudo ${runtime} rmi \$ID; echo 'Press any key to continue'; read; echo 'Reloading...'; sleep 1)+reload(sudo ${runtime} images | tail -n +2)" \
		--bind "ctrl-u:execute(REPO=\$(echo {} | awk '{print \$1}'); TAG=\$(echo {} | awk '{print \$2}'); sudo ${runtime} pull \$REPO:\$TAG; read)+reload(sudo ${runtime} images | tail -n +2)" \
		--bind "ctrl-p:execute($pull_new)+reload(sudo ${runtime} images | tail -n +2)"
}
