# Pacman: search and install packages
function pkinstall() {
	local query="${*:-}"
	if [[ -z "$query" ]]; then
		echo "Usage: pkinstall <search-term>"
		return 1
	fi
	pacman -Ss "$query" --color=always | \
		paste - - | \
		fzf --ansi --multi \
			--header "Select packages to install (TAB to multi-select)" \
			--preview 'pacman --color=always -Si {1}' \
			--preview-window=right:60%:wrap | \
		awk '{print $1}' | \
		xargs -ro sudo pacman -S
}

# Pacman: list installed and optionally remove
function pklist() {
	pacman -Q --color=always | \
		fzf --ansi --multi \
			--header "Select packages to remove (TAB to multi-select)" \
			--preview 'pacman --color=always -Qi {1}' \
			--preview-window=right:60%:wrap | \
		awk '{print $1}' | \
		xargs -ro sudo pacman -Rns
}

# Yay: list AUR packages and optionally remove
function yaylist() {
	yay -Qm --color=always | \
		fzf --ansi --multi \
			--header "Select AUR packages to remove (TAB to multi-select)" \
			--preview 'yay --color=always -Qi {1}' \
			--preview-window=right:60%:wrap | \
		awk '{print $1}' | \
		xargs -ro yay -Rns
}

# Yay: search AUR+repos and install packages
function yayinstall() {
	local query="${*:-}"
	if [[ -z "$query" ]]; then
		echo "Usage: yayinstall <search-term>"
		return 1
	fi
	yay -Ss "$query" --color=always | \
		paste - - | \
		fzf --ansi --multi \
			--header "TAB: multi-select | ctrl-a: AUR | ctrl-r: repos" \
			--bind 'ctrl-a:change-query(^aur/ )' \
			--bind 'ctrl-r:change-query(!^aur/ )' \
			--preview 'yay --color=always -Si {1}' \
			--preview-window=right:60%:wrap | \
		awk '{print $1}' | \
		xargs -ro yay -S
}

# Yay: select specific packages to update
function yayupdate() {
	yay -Qu --color=always 2>/dev/null | \
		fzf --ansi --multi \
			--header "TAB: multi-select | ctrl-a: AUR | ctrl-r: repos" \
			--bind 'ctrl-a:change-query(^aur/ )' \
			--bind 'ctrl-r:change-query(!^aur/ )' \
			--preview 'yay --color=always -Si {1}' \
			--preview-window=right:60%:wrap | \
		awk '{print $1}' | \
		xargs -ro yay -S
}

