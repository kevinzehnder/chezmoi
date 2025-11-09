# procs large view
function procsl() {
	check_sudo_nopass || sudo -v
	sudo procs --use-config=large
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

function ports() {
    check_sudo_nopass || sudo -v
	sudo procs --sorta tcp --json | gojq '.[] | select(.TCP != "[]")'
}
