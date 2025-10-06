# shellcheck shell=bash

cmd_cache_refresh() {
	if ! spinner "Refreshing Homebrew catalog…" build_index; then
		echo "$APP_NAME: cache refresh failed" >&2
		return 1
	fi
	echo "$APP_NAME: index refreshed: $INDEX_PATH"
}
