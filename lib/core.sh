# shellcheck shell=bash

# --- app name ---
readonly APP_NAME=macpak

# --- requirements ---
have() { command -v "$1" >/dev/null 2>&1; }

need() {
	have "$1" || {
		echo "missing: $1" >&2
		exit 1
	}
}

# Allow `macpak doctor` to run even if hard deps are missing (so it can report them)
if [[ "${1-}" != "doctor" ]]; then
	# hard requirements
	need brew
	need fzf
fi

# --- optional requirements ---
# Trash CLI (fallback to rm -rf if missing)
# - On modern macOS (14+), a built-in /usr/bin/trash exists.
# - This check is kept for compatibility with older systems.
TRASH_OK=1
# shellcheck disable=SC2034
command -v trash >/dev/null || TRASH_OK=0

# --- version ---
VERSION="${MACPAK_VERSION:-1.0.0}"
print_version() { printf '%s %s\n' "$APP_NAME" "$VERSION"; }

# --- config (edit to taste or source ~/.config/macpak/config.sh) ---
# shellcheck disable=SC2034
ROOTS=(
	"/Applications"
	"/Library"
	"/private/var/folders"
	"/private/var/root/Library"
	"/private/var/log"
	"/private/var/tmp"
	"/private/var/db/receipts"
	"/opt/homebrew"
	"/usr/local"
	"$HOME"
)

# use config.sh to add paths here, e.g. EXCLUDES=("$HOME/Developer" "$HOME/dotfiles")
# shellcheck disable=SC2034
EXCLUDES=()

# Source user declarations
# shellcheck disable=SC1090
[ -f "$HOME/.config/$APP_NAME/config.sh" ] && . "$HOME/.config/$APP_NAME/config.sh"

USE_TRASH=${USE_TRASH:-1}         # 1 = prefer user Trash (default), 0 = permanent remove
AUTO_BREWFILE=${AUTO_BREWFILE:-1} # 0 to disable Brewfile dump
BREWFILE_PATH=${BREWFILE_PATH:-"$HOME/.config/brewfile/Brewfile"}
# Index file path (default: $XDG_CACHE_HOME/macpak/index.tsv if set, else ~/.cache/macpak/index.tsv)
INDEX_PATH=${INDEX_PATH:-${XDG_CACHE_HOME:-$HOME/.cache}/$APP_NAME/index.tsv}
INDEX_TTL_SECS=${INDEX_TTL_SECS:-86400} # 24h
# Use cached index even when a query is supplied (fast, default=1).
# Set to 0 in ~/.config/macpak/config.sh to force live `brew search` for queries.
USE_CACHE_FOR_QUERY=${USE_CACHE_FOR_QUERY:-1}
# run leftovers scan right after brew uninstall (1=yes, 0=no)
AUTO_SCAN_AFTER_UNINSTALL=${AUTO_SCAN_AFTER_UNINSTALL:-1}

# --- usage ---
#TODO: we have to add version help sort of things under usage
#FIX: for macpak --help this message shows differently.. how the fuck it can be happened
usage() {
	cat <<EOF
$APP_NAME — Interactive wrapper that makes Homebrew much easier to use + zapper for non-brew apps (fzf-powered)
Version: $VERSION

Usage:
  $APP_NAME search [query]         # browse Homebrew catalog with preview; Enter to install
  $APP_NAME list [query]           # browse installed packages; Enter to uninstall
  $APP_NAME zap <keyword>          # sweep and remove non-brew apps with leftovers
  $APP_NAME cache refresh          # rebuild the cached Homebrew index
  $APP_NAME doctor                 # check required/optional tools and config

Env/config (optional; ~/.config/$APP_NAME/config.sh can override):

  # scanning behaviour
  USE_CACHE_FOR_QUERY=0            # default: enabled; set to 0 to disable cache use and always hit brew

  # caching
  INDEX_PATH=""                    # index file path (default: \$XDG_CACHE_HOME/$APP_NAME/index.tsv, else ~/.cache/$APP_NAME/index.tsv)
  INDEX_TTL_SECS=                  # seconds before cached index expires (default: 86400 / 24h)

  # leftovers
  AUTO_SCAN_AFTER_UNINSTALL=0      # default: enabled; set to 0 to disable auto-scan after uninstall

  # deletion behaviour
  USE_TRASH=0                      # default: enabled; set to 0 to force permanent deletion
  EXCLUDES=("")                    # patterns/paths to exclude from zap/uninstall sweeps
  ROOTS=("")                       # search roots for sweeping (default includes /Applications, /Library, etc.)

  # Brewfile integration
  AUTO_BREWFILE=0                  # default: enabled; set to 0 to disable Brewfile auto dump
  BREWFILE_PATH=""                 # Brewfile location (default: ~/.config/brewfile/Brewfile)
EOF
}
