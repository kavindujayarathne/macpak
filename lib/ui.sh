# shellcheck shell=bash

spinner() {
	local msg="${1:-Fetching…}"
	shift
	"$@" &
	local pid=$!
	local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏') i=0
	while kill -0 "$pid" 2>/dev/null; do
		printf "\r%s %s" "$msg" "${frames[i++ % ${#frames[@]}]}" >&2
		sleep 0.1
	done
	wait "$pid" 2>/dev/null
	local rc=$?
	printf "\r%-80s\r" "" >&2
	return $rc
}

# --- safe yes/no prompt (reads from the real terminal) ---
ask_yes_no() {
	local answer
	read -r -p "$1" answer </dev/tty || return 1
	answer="$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')"
	case "$answer" in
	y | yes) return 0 ;;
	*) return 1 ;;
	esac
}

# --- fzf snippet variables ---
PREVIEW_SNIPPET='
if [[ {1} == "[cask]"* ]]; then
  brew info --cask {2}
else
  brew info --formula {2}
fi
'

#shellcheck disable=SC2016
PAGER_SNIPPET='
if [[ -n $TMUX ]]; then
  if [[ {1} == "[cask]"* ]]; then
    tmux split-window -v "brew info --cask {2} | LESS=-S less"
  else
    tmux split-window -v "brew info --formula {2} | LESS=-S less"
  fi
else
  if [[ {1} == "[cask]"* ]]; then
    brew info --cask {2} | LESS=-S less
  else
    brew info --formula {2} | LESS=-S less
  fi
fi
'
# shellcheck disable=SC2034
readonly PREVIEW_SNIPPET PAGER_SNIPPET
