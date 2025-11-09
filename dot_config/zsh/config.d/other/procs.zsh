# procs large view
function procsl() {
	check_sudo_nopass || sudo -v
	sudo procs --use-config=large
}

# open ports
function ports() {
	check_sudo_nopass || sudo -v

	# Check if we're on non-x86_64 or procs doesn't exist
	if [[ "$(uname -m)" != "x86_64" ]] || ! command -v procs &> /dev/null; then
		# Fallback to portz implementation
		if ! ss_out=$(sudo ss -tulpn4 | rg "LISTEN|ESTABLISHED"); then
			echo "no active ports found"
			return 1
		fi
		echo "$ss_out" | fzf --ansi --header='Active Ports [LISTEN/ESTABLISHED]'
		return 0
	fi

	# Main implementation with procs
	if ! ss_out=$(sudo ss -Htupln | rg "LISTEN|ESTABLISHED"); then
		echo "no active ports found"
		return 1
	fi

	echo "$ss_out" \
		| tr ',' '\n' \
		| rg "pid=([0-9]+)" \
		| choose 1 -f "=" \
		| xargs sudo procs --or {} --color always --sorta TcpPort \
		| fzf --ansi \
			--preview "sudo ss -tulpn | rg {1}" \
			--preview-window=down \
			--height=100% \
			--layout=reverse \
			--header='Active Ports [LISTEN/ESTABLISHED]'
}

# interactive kill thru procs and FZF
function psk() {
    check_sudo_nopass || sudo -v
    sudo procs | tspin | fzf \
        --bind='ctrl-r:reload(procs --use-config=large | tspin)' \
        --header='[CTRL-R] reload [ENTER] kill' \
        --height=100% \
        --layout=reverse \
        | awk '{print $1}' | xargs -r sudo kill -9
}
