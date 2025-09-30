# shellcheck shell=bash

cmd_search() {
	local query="${1-}"
	local list=""

	local use_cache=0
	if [[ -z "$query" ]] || ((USE_CACHE_FOR_QUERY)); then
		use_cache=1
	fi

	if ((use_cache)); then
		local idx
		idx="$(get_index)" || return 1

		if [[ -n "$query" ]]; then
			list="$(grep -i -- "$query" "$idx" || true)"
			[[ -n "$list" ]] || {
				echo "No matches for: $query" >&2
				return 0
			}
		else
			list="$(<"$idx")"
		fi
	else
		local tmp
		tmp="$(mktemp -t "${APP_NAME}_live.XXXXXX")"
		if ! spinner "Searching Homebrew…" live_search_query_to_file "$query" "$tmp"; then
			echo "$APP_NAME: live search failed" >&2
			rm -f "$tmp"
			return 1
		fi
		list="$(<"$tmp")"
		rm -f "$tmp"
		[[ -n "$list" ]] || {
			echo "No matches for: $query" >&2
			return 0
		}
	fi

	local selections
	selections="$(
		echo "$list" |
			fzf --ansi --multi \
				--delimiter=$'\t' --with-nth=1 \
				--header='Enter=install • tab=multi • Ctrl-P=pager' \
				--preview="$PREVIEW_SNIPPET" \
				--preview-window=right,wrap,65% \
				--bind "tab:toggle-down,ctrl-p:execute($PAGER_SNIPPET)"
	)" || {
		echo "$APP_NAME: Exiting" >&2
		return 0
	}
	[[ -z "$selections" ]] && return 0

	local installed_any=0
	while IFS=$'\t' read -r label name; do
		local kind
		if [[ "$label" =~ ^\[cask\] ]]; then kind="cask"; else kind="formula"; fi

		echo
		echo "────────────────────────────────────────────────────────"
		echo "Target: $name [$kind]"
		echo "────────────────────────────────────────────────────────"
		if [[ "$kind" == "cask" ]]; then
			brew info --cask "$name" | sed -n '1,30p'
		else
			brew info --formula "$name" | sed -n '1,30p'
		fi
		echo

		if ! ask_yes_no "Proceed to install '$name'? [y/N] "; then
			echo "Installation Canceled for: $name"
			continue
		fi

		if [[ "$kind" == "cask" ]]; then
			brew install --cask "$name" && installed_any=1 || true
		else
			brew install --formula "$name" && installed_any=1 || true
		fi
	done <<<"$selections"

	echo

	if ((AUTO_BREWFILE && installed_any)); then
		brewfile_dump || {
			echo "$APP_NAME: failed to update Brewfile" >&2
			# return 1
		}
	fi
}
