function crons() {
	local cron_list=$(
		# System crontabs
		for f in /etc/cron.d/* /etc/crontab; do
			[[ -f "$f" ]] && grep -Ev '^#|^$|^SHELL|^PATH|^MAILTO|^HOME|^LOGNAME|^USER' "$f" | sed "s|^|$f: |"
		done
		# User crontabs - needs sudo
		for user in $(getent passwd | cut -d: -f1,6 | grep -v /nologin$ | cut -d: -f1); do
			sudo crontab -l -u "$user" 2> /dev/null | grep -Ev '^#|^$|^SHELL|^PATH|^MAILTO|^HOME|^LOGNAME|^USER' | sed "s/^/$user: /"
		done
	)

	local preview_cmd='
        line={}
        source=$(echo "$line" | cut -d: -f1)
        schedule=$(echo "$line" | cut -d: -f2- | awk "{print \$1,\$2,\$3,\$4,\$5}")
        command=$(echo "$line" | cut -d: -f2- | cut -d" " -f6-)
        echo -e "\033[1;32mSource:\033[0m $source"
        echo -e "\033[1;33mSchedule:\033[0m $schedule"
        echo -e "\033[1;34mCommand:\033[0m $command"
    '

	local selected=$(echo "$cron_list" | fzf --ansi \
		--preview "$preview_cmd" \
		--preview-window=up:3)

	if [[ -n "$selected" ]]; then
		local source=$(echo "$selected" | cut -d: -f1)
		if [[ "$source" =~ ^/etc/ ]]; then
			sudo vim "$source"
		else
			local user=$(echo "$source" | tr -d ' ')
			sudo crontab -e -u "$user"
		fi
	fi
}

function timers() {
	if command -v tspin > /dev/null 2>&1; then
		local follow_logs='sudo journalctl -n 100 -f -u {1} | tspin'
		local logs='sudo journalctl -n 2000 -u {1} | tspin | less -r +G'
	else
		local follow_logs='sudo journalctl -n 100 -f -u {1}'
		local logs='sudo journalctl -n 2000 -e -u {1}'
		# local logs="sudo journalctl -n 2000 -u {1} --no-pager | bat -l syslog -p --pager='less -R +G'"
	fi

	check_sudo_nopass || sudo -v
	systemctl list-timers --all --no-pager \
		| tail -n +2 \
		| head -n -2 \
		| awk '{print $(NF-1)}' \
		| fzf --ansi \
			--preview "sudo SYSTEMD_COLORS=1 systemctl status {} --no-pager" \
			--preview-window=right:60%:wrap \
			--header $'System Timers | CTRL-R: reload\nCTRL-L: journal | CTRL-E: edit\nCTRL-S: start | CTRL-D: stop | CTRL-T: restart' \
			--bind "ctrl-r:reload(systemctl list-timers --all --no-pager | tail -n +2 | head -n -5 | awk '{print \$(NF-1)}')" \
			--bind "ctrl-l:execute($logs)" \
			--bind "ctrl-e:execute(sudo systemctl edit {1})" \
			--bind "ctrl-s:execute(sudo systemctl start {})" \
			--bind "ctrl-d:execute(sudo systemctl stop {})" \
			--bind "ctrl-t:execute(sudo systemctl restart {})"
}

function jctl() {
	if command -v tspin > /dev/null 2>&1; then
		journalctl -n 2000 "$@" | tspin | less -r +G
	else
		journalctl -n 2000 "$@"
	fi
}

function sjctl() {
	if command -v tspin > /dev/null 2>&1; then
		sudo journalctl -n 2000 "$@" | tspin | less -r +G
	else
		sudo journalctl -n 2000 "$@"
	fi
}

# pretty journal
function jf() {
	if command -v tspin > /dev/null 2>&1; then
		sudo journalctl -n 50 -f $@ | tspin
	else
		sudo journalctl -n 50 -f $@
	fi
}

function _units_core() {
	local force_sudo="$1"
	shift

	local enabled=""
	local active=""
	local unit_type=""
	local all_types=""
	local help=""
	local mode="system"

	zparseopts -D -E -a opts \
		e=enabled -enabled=enabled \
		a=active -active=active \
		t:=unit_type -type:=unit_type \
		A=all_types -all-types=all_types \
		u=user -user=user \
		h=help -help=help

	if [[ -n "$help" ]]; then
		cat <<'EOF'
units / sunits - interactive systemd unit browser

Usage:
  units [options]
  sunits [options]

Options:
  -u, --user           Use user units (no sudo)
  -e, --enabled        List unit files (enabled/disabled view)
  -a, --active         List active units only (runtime view)
  -t, --type <type>    Filter by type (service, timer, socket, mount, ...)
  -A, --all-types      Disable default type filter
  -h, --help           Show this help

Defaults:
  units/sunits show: service,socket,timer,target,path
  (to reduce noise from mount/device/swap/automount)

Examples:
  units --user
  units --type timer
  units --all-types
  sunits --type service
EOF
		return 0
	fi

	if [[ -n "$user" ]]; then
		mode="user"
		force_sudo="0"
	fi

	local ctl="systemctl"
	local jctl="journalctl"
	if [[ "$mode" == "user" ]]; then
		ctl="systemctl --user"
		jctl="journalctl --user"
	elif [[ "$force_sudo" == "1" ]]; then
		ctl="sudo systemctl"
		jctl="sudo journalctl"
		check_sudo_nopass || sudo -v
	fi

	local type_filter=""
	local requested_type="${unit_type[-1]#=}"
	if [[ -n "$unit_type" ]]; then
		type_filter="$requested_type"
	elif [[ -z "$all_types" ]]; then
		# Default focused set; excludes noisy low-level unit types unless requested.
		type_filter="service,socket,timer,target,path"
	fi

	local list_cmd
	if [[ -n "$enabled" ]]; then
		list_cmd="$ctl list-unit-files --all --no-pager --plain --legend=false"
		[[ -n "$type_filter" ]] && list_cmd+=" --type=$type_filter"
	else
		list_cmd="$ctl list-units --all --no-pager --plain --legend=false"
		[[ -n "$type_filter" ]] && list_cmd+=" --type=$type_filter"
		[[ -n "$active" ]] && list_cmd+=" --state=active"
	fi

	local list_pipe="$list_cmd | awk '{print \$1}' | sed '/^$/d'"

	local follow_logs
	local logs
	if command -v tspin > /dev/null 2>&1; then
		follow_logs="$jctl -n 100 -f -u {1} | tspin"
		logs="$jctl -n 2000 -u {1} | tspin | less -r +G"
	else
		follow_logs="$jctl -n 100 -f -u {1}"
		logs="$jctl -n 2000 -e -u {1}"
	fi

	local show_status="$ctl status {1} --no-pager"
	local edit_cmd="$ctl edit {1} --full || read -p 'Press enter...'"
	local start_cmd="$ctl start {1} || read -p 'Failed. Press enter...'"
	local stop_cmd="$ctl stop {1} || read -p 'Failed. Press enter...'"
	local restart_cmd="$ctl restart {1} || read -p 'Failed. Press enter...'"
	local enable_cmd="$ctl enable {1} && echo 'Enabled {1}' || echo 'Failed to enable {1}'; read -p 'Press enter...'"
	local disable_cmd="$ctl disable {1} && echo 'Disabled {1}' || echo 'Failed to disable {1}'; read -p 'Press enter...'"

	local title="System Units"
	[[ "$mode" == "user" ]] && title="User Units"
	[[ "$force_sudo" == "1" && "$mode" != "user" ]] && title="System Units (sudo)"

	eval "$list_pipe" \
		| fzf --ansi \
			--preview "$show_status" \
			--preview-window=right:60%:wrap:follow \
			--height=80% \
			--header "$title | CTRL-R: reload\nCTRL-L: journal | CTRL-F: follow logs | CTRL-E: edit\nCTRL-S: start | CTRL-D: stop | CTRL-T: restart\nCTRL-N: enable | CTRL-X: disable" \
			--bind "ctrl-r:reload($list_pipe)" \
			--bind "ctrl-l:execute($logs)" \
			--bind "ctrl-f:execute($follow_logs)" \
			--bind "ctrl-e:execute($edit_cmd)" \
			--bind "ctrl-s:execute($start_cmd)" \
			--bind "ctrl-d:execute($stop_cmd)" \
			--bind "ctrl-t:execute($restart_cmd)" \
			--bind "ctrl-n:execute($enable_cmd)" \
			--bind "ctrl-x:execute($disable_cmd)"
}

function units() {
	_units_core 0 "$@"
}

function sunits() {
	_units_core 1 "$@"
}
