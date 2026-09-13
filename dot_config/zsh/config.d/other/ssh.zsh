function s() {
	# Extract Host entries from SSH config
	local hosts=$(parse_ssh_config | cut -d'|' -f1)

	if [[ -z "$hosts" ]]; then
		echo "❌ No SSH hosts found. Check your ~/.ssh/config or ~/.ssh/config.d/*"
		return 1
	fi

	# Select a host with FZF
	local selected_host=$(echo "$hosts" \
		| fzf --reverse \
			--header="SSH Connections" \
			--preview-window=right:60%:wrap \
			--preview="source ~/.config/zsh/config.d/other/ssh_connection_preview.zsh && ssh_connection_preview {}" \
			--height=80%)

	# If nothing selected, just exit
	[[ -z "$selected_host" ]] && return

	# Connect to the selected host
	ssh "$selected_host"
}

function sshget() {
	emulate -L zsh
	setopt pipefail

	local server="${1:-}"
	local remote_path="${2:-}"
	if [[ -z "$server" || "$server" == -* ]]; then
		print -u2 -- "Usage: sshget <host> [remote-path]"
		return 1
	fi

	# Quote the local argument before it becomes part of the fixed remote command.
	# With no path, resolve the remote user's home directory on the remote host.
	local remote_path_quoted
	if [[ -n "$remote_path" ]]; then
		remote_path_quoted="${(q)remote_path}"
	else
		remote_path_quoted='$HOME'
	fi

	local remote_cmd="remote_path=\$(cd -- $remote_path_quoted && pwd -P) || exit 1
if command -v fd >/dev/null 2>&1; then
	fd -0 --type f --color never . \"\$remote_path\"
else
	find \"\$remote_path\" -type f -print0
fi"

	local file_list
	file_list=$(mktemp "${TMPDIR:-/tmp}/sshget-files.XXXXXX") || return 1

	# Read and retain NUL-delimited paths so spaces, quotes, and newlines survive.
	ssh -T "$server" "$remote_cmd" \
		| fzf --read0 --print0 --multi --height=80% > "$file_list"
	local exit_status=$?
	if (( exit_status != 0 )); then
		rm -f -- "$file_list"
		return "$exit_status"
	fi

	if [[ ! -s "$file_list" ]]; then
		rm -f -- "$file_list"
		return 0
	fi

	local destination="$PWD/sshget"
	mkdir -p -- "$destination" || {
		rm -f -- "$file_list"
		return 1
	}

	# --from0 matches fzf's NUL output; no selected path is re-parsed as shell code.
	rsync -avz --progress --from0 --files-from="$file_list" -- "$server:/" "$destination/"
	exit_status=$?
	rm -f -- "$file_list"
	return "$exit_status"
}

function show_ssh_keys() {
	echo "🔑 Displaying your public SSH keys..."

	# Find all public keys and process each one individually
	local keys=($(find ~/.ssh -type f -name "*.pub" 2> /dev/null))

	if [[ ${#keys[@]} -eq 0 ]]; then
		echo "❌ No public keys found. Generate one with ssh-keygen first."
		return 1
	fi

	# Show each key with header
	local count=0
	echo ""
	echo "=== KEYS FOUND ==="

	for key in "${keys[@]}"; do
		# Make sure the file exists (check again to be safe)
		if [[ ! -f "$key" ]]; then
			continue
		fi

		local keyname=$(basename "$key")
		local keytype=$(head -n 1 "$key" | awk '{print $1}')
		local fingerprint=$(ssh-keygen -lf "$key" 2> /dev/null | awk '{print $2}')

		# Only show if we can actually read it
		if [[ -n "$keytype" ]]; then
			echo ""
			echo -e "\e[1;36m$keyname\e[0m [$keytype] - $fingerprint"
			echo "-----------------------------------------"
			cat "$key"
			echo ""
			((count++))
		fi
	done

	echo "=== $count keys found ==="
	echo ""
	echo "✅ Copy the key you want and paste it into remote:~/.ssh/authorized_keys"
}

function fix_ssh_permissions() {
	echo "🔒 Starting SSH permissions fix"

	# Fix parent dirs
	echo "Setting .ssh dir to 700..."
	chmod 700 ~/.ssh 2> /dev/null
	echo "Setting all subdirs to 700..."
	find ~/.ssh -type d -exec chmod 700 {} \; 2> /dev/null

	# Config files including config.d shit
	echo "Setting config files to 600..."
	find ~/.ssh -type f -name "config*" -exec chmod 600 {} \; 2> /dev/null
	find ~/.ssh/config.d -type f -exec chmod 600 {} \; 2> /dev/null

	# Keys
	echo "Setting private keys to 600..."
	find ~/.ssh -type f -name "id_*" ! -name "*.pub" -exec chmod 600 {} \; 2> /dev/null
	find ~/.ssh -type f -name "identity" -exec chmod 600 {} \; 2> /dev/null

	# Public shit
	echo "Setting public keys to 644..."
	find ~/.ssh -type f -name "*.pub" -exec chmod 644 {} \; 2> /dev/null
	echo "Setting known_hosts to 644..."
	find ~/.ssh -type f -name "known_hosts*" -exec chmod 644 {} \; 2> /dev/null
	echo "Setting authorized_keys to 600..."
	find ~/.ssh -type f -name "authorized_keys" -exec chmod 600 {} \; 2> /dev/null

	echo "✅ SSH permissions fixed."
}
