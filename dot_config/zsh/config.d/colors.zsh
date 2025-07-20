# Color Themes
alias light='colorschemeswitcher solarized'
alias dark='colorschemeswitcher dark'
alias gruv='colorschemeswitcher gruvbox'

function colorschemeswitcher() {
	if [ "$1" = "solarized" ]; then
		touch ~/.lightmode

		export BASE16_THEME="solarized-light"
		# [ -f "$ZINIT[PLUGINS_DIR]/tinted-theming---tinted-fzf/bash/base16-$BASE16_THEME.config" ] && source "$ZINIT[PLUGINS_DIR]/tinted-theming---tinted-fzf/bash/base16-$BASE16_THEME.config"
		
		export BAT_THEME="gruvbox-light"
		export LS_COLORS="$(vivid generate solarized-light)"
		change_zellij_theme "solarized-light"
		change_k9s_theme "solarized_light"
	elif [ "$1" = "gruvbox" ]; then
		rm -f ~/.lightmode
		
		export BASE16_THEME="gruvbox-dark"
		# [ -f "$ZINIT[PLUGINS_DIR]/tinted-theming---tinted-fzf/bash/base16-$BASE16_THEME.config" ] && source "$ZINIT[PLUGINS_DIR]/tinted-theming---tinted-fzf/bash/base16-$BASE16_THEME.config"

		export BAT_THEME="gruvbox-dark"
		export LS_COLORS="$(vivid generate gruvbox-dark)"
		change_zellij_theme "gruvbox"
	else
		rm -f ~/.lightmode
		
		# fzf
		export BASE16_THEME="tokyo-night-storm"
		# [ -f "$ZINIT[PLUGINS_DIR]/tinted-theming---tinted-fzf/bash/base16-$BASE16_THEME.config" ] && source "$ZINIT[PLUGINS_DIR]/tinted-theming---tinted-fzf/bash/base16-$BASE16_THEME.config"

		export BAT_THEME="ansi"
		export LS_COLORS="$(vivid generate tokyonight-storm)"
		change_zellij_theme "tokyo-night-dark"
		change_k9s_theme "nord"
	fi
}

function change_zellij_theme() {
	if [ "$#" -ne 1 ]; then
		echo "Usage: change_zellij_theme <new-theme>"
		return 1
	fi

	CONFIG_FILE="$HOME/.config/zellij/config.kdl"
	NEW_THEME="$1"

	if [ ! -f "$CONFIG_FILE" ]; then
		echo "Configuration file not found: $CONFIG_FILE"
		return 1
	fi

	# Use sed to replace the theme line
	sed -i.bak "s/^theme \".*\"$/theme \"$NEW_THEME\"/" "$CONFIG_FILE"
}

function change_k9s_theme() {
	if [ "$#" -ne 1 ]; then
		echo "Usage: change_k9s_theme <new-theme>"
		return 1
	fi
	CONFIG_FILE="$HOME/.config/k9s/config.yaml"
	NEW_THEME="$1"

	if [ ! -f "$CONFIG_FILE" ]; then
		echo "Configuration file not found: $CONFIG_FILE"
		return 1
	fi

	# Use sed to replace the skin line, considering the nested structure
	sed -i.bak 's/^ *skin: .*$/    skin: '"$NEW_THEME"'/' "$CONFIG_FILE"
}

function darkmodechecker() {
	theme=$(gsettings get org.gnome.desktop.interface gtk-theme)
	if [[ "$theme" == *Dark* ]]; then
		dark
	else
		light
	fi
}

# run DarkMode Check if we're not on an SSH connection
if [[ -z "$SSH_CONNECTION" ]]; then
	darkmodechecker
else
	if [[ -f ~/.lightmode ]]; then
		light
	else
		dark
	fi
fi
