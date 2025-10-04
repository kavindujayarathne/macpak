# shellcheck shell=bash

cmd_list() {
	local query="${1-}"

	# Build installed list (label + hidden raw name)
	local list_c list_f list
	list_c="$(brew list --cask | awk -v OFS='\t' -v label='[cask] ' '{print label $0, $0}')" || list_c=""
	list_f="$(brew list --formula | awk -v OFS='\t' -v label='[formula] ' '{print label $0, $0}')" || list_f=""
	list="$(printf "%s\n%s\n" "$list_c" "$list_f" | sed '/^[[:space:]]*$/d' | sort -f)"

	[[ -n "$list" ]] || {
		echo "$APP_NAME: nothing installed"
		return 1
	}

	# Optional prefilter
	if [[ -n "$query" ]]; then
		list="$(printf '%s\n' "$list" | grep -i -- "$query" || true)"
		[[ -n "$list" ]] || {
			echo "$APP_NAME: no installed items matching: $query"
			return 0
		}
	fi

	# Choose one or more to uninstall
	local selections
	selections="$(
		printf '%s\n' "$list" |
			fzf --ansi --multi \
				--delimiter=$'\t' --with-nth=1 \
				--header='Enter=uninstall • tab=multi • Ctrl-P=pager' \
				--preview="$PREVIEW_SNIPPET" \
				--preview-window=right,wrap,65% \
				--bind "tab:toggle-down,ctrl-p:execute($PAGER_SNIPPET)"
	)" || {
		echo "$APP_NAME: exiting" >&2
		return 0
	}
	[[ -z "$selections" ]] && return 0

	local uninstalled_any=0

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

		if ! ask_yes_no "Proceed to uninstall '$name'? [y/N] "; then
			echo "$APP_NAME: uninstallation canceled for: $name"
			continue
		fi

		if [[ "$kind" == "cask" ]]; then
			if brew uninstall --cask "$name"; then uninstalled_any=1; fi
		else
			if brew uninstall --formula "$name"; then uninstalled_any=1; fi
		fi

		if ((AUTO_SCAN_AFTER_UNINSTALL)); then
			echo
			local raw_hits
			raw_hits="$(spinner "Scanning leftovers for: ${name:-}…" scan_fs "$name")" || raw_hits=""
			[[ -z "$raw_hits" ]] && {
				echo "$APP_NAME: no leftovers found for: $name"
				continue
			}

			local lists_dir
			lists_dir="$(mktemp -d -t "${APP_NAME}_sel.XXXXXX")"
			trap 'rm -rf "$lists_dir" 2>/dev/null || true' RETURN

			prepare_leftover_lists "$name" "$raw_hits" "$lists_dir"

			local leftovers_paths
			leftovers_paths="$(pick_leftovers "leftovers for: $name" "$lists_dir")" || leftovers_paths=""
			[[ -z "$leftovers_paths" ]] && {
				echo "$APP_NAME: no leftovers selected."
				continue
			}

			# Grouped preview + delete flow
			group_leftovers "$leftovers_paths"
			if ask_yes_no "Proceed? [y/N] "; then
				delete_paths
			else
				echo "$APP_NAME: skipped leftovers for: $name"
			fi
		fi
	done <<<"$selections"

	echo

	if ((AUTO_BREWFILE && uninstalled_any)); then
		brewfile_dump || {
			echo "$APP_NAME: failed to update Brewfile" >&2
			return 1
		}
	fi
}
