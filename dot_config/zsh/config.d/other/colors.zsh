# Color Themes
alias light='colorschemeswitcher solarized'
alias dark='colorschemeswitcher dark'
alias gruv='colorschemeswitcher gruvbox'

function set_chezmoi_theme_mode() {
	local mode="$1"
	local data_file="$HOME/.local/share/chezmoi/.chezmoidata.yaml"

	[[ -f "$data_file" ]] || return 0
	command -v perl >/dev/null 2>&1 || return 0

	# Update only `theme.mode` in chezmoi data (single source of truth for rendered theme configs).
	perl -0777 -i -pe 's/(theme:\n(?:\s*#.*\n)?\s*mode:\s*")[^"]+("\s*)/${1}'"$mode"'${2}/s' "$data_file"
}

function apply_theme_templates() {
	command -v chezmoi >/dev/null 2>&1 || return 0

	chezmoi apply --exclude=scripts \
		"$HOME/.config/zellij/config.kdl" \
		"$HOME/.config/btop/btop.conf" \
		"$HOME/.config/k9s/config.yaml" \
		"$HOME/.config/television/config.toml" \
		>/dev/null 2>&1 || true
}

function colorschemeswitcher() {
	local scheme="${1:-dark}"
	local no_apply="${2:-}"

	if [ "$scheme" = "solarized" ]; then
		touch ~/.lightmode

		export BASE16_THEME="solarized-light"
		export BAT_THEME="gruvbox-light"
		if command -v vivid >/dev/null 2>&1; then
			export LS_COLORS="$(vivid generate solarized-light)"
		fi
		set_chezmoi_theme_mode "light"
	elif [ "$scheme" = "gruvbox" ]; then
		rm -f ~/.lightmode

		export BASE16_THEME="gruvbox-dark"
		export BAT_THEME="gruvbox-dark"
		if command -v vivid >/dev/null 2>&1; then
			export LS_COLORS="$(vivid generate gruvbox-dark)"
		fi
		set_chezmoi_theme_mode "gruvbox"
	else
		rm -f ~/.lightmode

		export BASE16_THEME="tokyo-night-storm"
		export BAT_THEME="ansi"
		if command -v vivid >/dev/null 2>&1; then
			export LS_COLORS="$(vivid generate tokyonight-storm)"
		fi
		set_chezmoi_theme_mode "dark"
	fi

	if [[ "$no_apply" != "--no-apply" ]]; then
		apply_theme_templates
	fi
}

function darkmodechecker() {
	if command -v gsettings >/dev/null 2>&1; then
		theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null)
		if [[ "$theme" == *Dark* ]]; then
			colorschemeswitcher dark --no-apply
		else
			colorschemeswitcher solarized --no-apply
		fi
	else
		# Fallback to file-based detection if gsettings is unavailable
		if [[ -f ~/.lightmode ]]; then
			colorschemeswitcher solarized --no-apply
		else
			colorschemeswitcher dark --no-apply
		fi
	fi
}

# run DarkMode Check if we're not on an SSH connection
if [[ -z "$SSH_CONNECTION" ]]; then
	darkmodechecker
else
	if [[ -f ~/.lightmode ]]; then
		colorschemeswitcher solarized --no-apply
	else
		colorschemeswitcher dark --no-apply
	fi
fi
