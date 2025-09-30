# shellcheck shell=bash

cmd_zap() {
	local pattern="${1:-}"
	[ -z "$pattern" ] && {
		echo "usage: $APP_NAME zap <keyword>"
		exit 1
	}

	local raw_hits
	raw_hits="$(spinner "Scanning matches for ${pattern:-}…" scan_fs "$pattern")" || raw_hits=""
	[ -z "$raw_hits" ] && {
		echo "No matches for: $pattern"
		return 0
	}

	local lists_dir
	lists_dir="$(mktemp -d -t "${APP_NAME}_sel.XXXXXX")"
	trap 'rm -rf "$lists_dir" 2>/dev/null || true' RETURN

	prepare_leftover_lists "$pattern" "$raw_hits" "$lists_dir"

	local leftovers_paths
	leftovers_paths="$(pick_leftovers "matches for: $pattern" "$lists_dir")" || leftovers_paths=""
	[ -z "$leftovers_paths" ] && {
		echo "No paths selected."
		return 0
	}

	group_leftovers "$leftovers_paths"
	if ask_yes_no "Proceed? [y/N] "; then
		delete_paths
	else
		echo "Skipped the selected path(s) for: $pattern"
	fi
}
