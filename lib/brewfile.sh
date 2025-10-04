# shellcheck shell=bash

# Brewfile dump function simply updates the Brewfile
brewfile_dump() {
	local dir
	dir="$(dirname "$BREWFILE_PATH")"
	mkdir -p "$dir" # ensure directory exists

	if brew bundle dump --file="$BREWFILE_PATH" --force >/dev/null 2>&1; then
		echo "$APP_NAME: Brewfile has been updated"
	else
		return 1
	fi
}
