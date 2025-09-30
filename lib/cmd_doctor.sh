# shellcheck shell=bash

cmd_doctor() {
	echo "macpak doctor:"
	echo

	# ----- tools -----
	if have brew; then
		echo " ✓ brew         — found: $(brew --version 2>/dev/null | head -n1)"
	else
		echo " ✗ brew         — MISSING (required) → install Homebrew from https://brew.sh"
	fi

	if have fzf; then
		echo " ✓ fzf          — found: $(fzf --version 2>/dev/null | head -n1)"
	else
		echo " ✗ fzf          — MISSING (required) → brew install fzf"
	fi

	# runtime shell (bash)
	if [[ -n ${BASH_VERSION-} ]]; then
		echo " ✓ bash         — using: ${BASH} (version: ${BASH_VERSION})"
	else
		echo " ◦ bash         — not running under bash? SHELL=${SHELL:-unknown}"
	fi

	echo

	# if have git; then
	# 	echo " ✓ git          — found (prettier version strings)"
	# else
	# 	echo " ◦ git          — optional → brew install git"
	# fi

	if [[ "${USE_TRASH:-1}" == "1" ]]; then
		if [[ -x /usr/bin/trash ]]; then
			echo " ✓ trash        — system /usr/bin/trash available (safe deletes)"
		elif have trash; then
			echo " ✓ trash        — found (safe deletes)"
		else
			echo " ◦ trash        — optional for safe deletes → brew install trash  (or macOS 14+ /usr/bin/trash)"
		fi
	else
		echo " ◦ trash        — optional; USE_TRASH=0 (permanent deletion mode)"
	fi

	if have tmux; then
		echo " ✓ tmux         — found (split-pane pager in previews)"
	else
		echo " ◦ tmux         — optional → brew install tmux"
	fi

	# ----- config -----
	echo
	echo "Config:"

	show_cfg() {
		# $1 = VAR name, $2 = default value (string; for arrays: newline-joined list)
		local name=$1 def=${2-__NO_DEFAULT__}
		local mark='•' val is_array=0

		# detect array, capture current value
		local decl
		if decl=$(declare -p "$name" 2>/dev/null) && [[ $decl == "declare -a"* ]]; then
			is_array=1
			val="$(eval 'printf "%s\n" ${'"$name"'[@]+"${'"$name"'[@]}"}')"
		else
			val="${!name}"
		fi

		# expand defaults (so "$HOME" in defaults matches expanded values)
		if [[ "$def" != "__NO_DEFAULT__" ]]; then
			local def_expanded
			eval 'def_expanded="'"$def"'"'
			[[ "$val" != "$def_expanded" ]] && mark='*'
		fi

		# print
		if ((is_array)); then
			if [[ -n "$val" ]]; then
				printf " %s %s=\n" "$mark" "$name"
				while IFS= read -r line; do
					printf "   - %s\n" "$line"
				done <<<"$val"
			else
				printf " %s %s=(empty)\n" "$mark" "$name"
			fi
		else
			printf " %s %s=%s\n" "$mark" "$name" "$val"
		fi
	}

	# If you don’t want to add DEF_* vars, pass the literal default here matching your code defaults.
	show_cfg USE_TRASH 1
	show_cfg AUTO_BREWFILE 1
	show_cfg BREWFILE_PATH "$HOME/.config/brewfile/Brewfile"
	show_cfg INDEX_PATH "${XDG_CACHE_HOME:-$HOME/.cache}/$APP_NAME/index.tsv"
	show_cfg INDEX_TTL_SECS 86400
	show_cfg USE_CACHE_FOR_QUERY 1
	show_cfg AUTO_SCAN_AFTER_UNINSTALL 1

	show_cfg ROOTS "$(printf '%s\n' \
		"/Applications" "/Library" "/private/var/folders" "/private/var/root/Library" \
		"/private/var/log" "/private/var/tmp" "/private/var/db/receipts" \
		"/opt/homebrew" "/usr/local" "$HOME")"

	show_cfg EXCLUDES ""

	echo
	echo "Legend: '*' means the value was overridden via ~/.config/$APP_NAME/config.sh"
	echo
	echo "Done."
	return 0
}
