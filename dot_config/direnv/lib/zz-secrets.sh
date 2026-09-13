# Secret Service integration for direnv.
# Sourced before every .envrc. Items are addressed by two attributes:
#   application=<app>  key=<VAR_NAME>
# GUI: seahorse (collection "Login").  CLI: secret-tool / secret-set.

secret_get() {
  secret-tool lookup application "$1" key "$2"
}

secret_set() { # app key value (value via stdin-safe arg)
  printf '%s' "$3" | secret-tool store --label="$1:$2" application "$1" key "$2"
}

secret_del() {
  secret-tool clear application "$1" key "$2"
}

use_secrets() { # use secrets <application> VAR...
  if ! has secret-tool; then
    log_error "use secrets: secret-tool not installed (libsecret)"
    return 1
  fi
  local app="$1"; shift
  local name value missing=()
  for name in "$@"; do
    value=$(secret_get "$app" "$name")
    if [[ -z "$value" ]]; then
      missing+=("$name")
    else
      export "$name=$value"
    fi
  done
  if ((${#missing[@]})); then
    log_error "missing secrets (application=$app): ${missing[*]}"
    log_error "store with: secret-set $app <VAR>   then: direnv allow"
    return 1
  fi
}
