function repeater() {
	if [ "$#" -lt 2 ]; then
		echo "Usage: repeater <seconds> <command>"
		return 1
	fi

	local interval=$1
	shift
	local command="$@"

	while true; do
		echo "--- $(date +"%H:%M:%S") ---"
		eval "$command"
		sleep $interval
	done
}

# Helper function for sudo without password
function check_sudo_nopass() {
	sudo -n true 2> /dev/null
	return $?
}

function needs_reboot() {
	if [[ -f /var/run/reboot-required ]] \
		|| { command -v needs-restarting &> /dev/null && needs-restarting -r 2> /dev/null | rg -q "Reboot is required"; }; then
		return 0
	fi
	return 1
}

function parse_ssh_config() {
	local config_dir="$HOME/.ssh/config.d"
	local main_config="$HOME/.ssh/config"
	local temp_file=$(mktemp)

	# Start with main config
	[[ -f "$main_config" ]] && cat "$main_config" > "$temp_file"

	# Add config.d files if they exist
	if [[ -d "$config_dir" ]]; then
		for conf_file in "$config_dir"/*; do
			[[ -f "$conf_file" ]] && cat "$conf_file" >> "$temp_file"
		done
	fi

	# Extract Host entries, ignore wildcards and patterns with *, ?, !
	grep -i "^Host " "$temp_file" \
		| grep -v "[*?!]" \
		| sed 's/^Host //' \
		| tr ' ' '\n' \
		| tr -d '\r' \
		|
		# Remove any CR characters
		sort -u \
		| while read -r host; do
			# Clean any remaining whitespace
			host=$(echo "$host" | xargs)
			[[ -z "$host" ]] && continue

			# For each host, use ssh -G to get the full expanded config
			local details=$(ssh -G "$host" 2> /dev/null)
			if [[ $? -eq 0 ]]; then
				echo "$host"
			fi
		done

	rm "$temp_file"
}

# Helper function to detect package manager
# Returns the primary package manager for the current system
function get_package_manager() {
	# Try to detect from /etc/os-release first for accuracy
	if [[ -f /etc/os-release ]]; then
		source /etc/os-release
		case "${ID_LIKE:-$ID}" in
			*arch*)
				echo "pacman"
				return 0
				;;
			*debian*|*ubuntu*)
				echo "apt"
				return 0
				;;
			*rhel*|*fedora*|*centos*)
				if command -v dnf &> /dev/null; then
					echo "dnf"
				else
					echo "yum"
				fi
				return 0
				;;
		esac
	fi

	# Fallback to command detection
	if command -v pacman &> /dev/null; then
		echo "pacman"
	elif command -v apt &> /dev/null; then
		echo "apt"
	elif command -v dnf &> /dev/null; then
		echo "dnf"
	elif command -v yum &> /dev/null; then
		echo "yum"
	elif command -v zypper &> /dev/null; then
		echo "zypper"
	else
		echo "unknown"
	fi
}

# Get OS distribution ID
function get_os_id() {
	if [[ -f /etc/os-release ]]; then
		source /etc/os-release
		echo "${ID}"
	else
		echo "unknown"
	fi
}

# Check if running on a specific distro
function is_distro() {
	local distro="$1"
	[[ "$(get_os_id)" == "$distro" ]]
}

# load global devbox
function devbox_global() {
	eval "$(devbox global shellenv --init-hook --omit-nix-env=false)"
}

# zellij
function za() {
	if command -v zellij &> /dev/null; then
		# Check if zellij is already running to avoid nested sessions
		if [ -z "$ZELLIJ" ]; then
			# Start a new Zellij session or attach to an existing one
			zellij attach --create mysession
		fi
	fi
}

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

function install_yazi() {
	zi wait lucid light-mode as"program" from"gh-r" for \
		pick"ya*/yazi" sxyazi/yazi

}
