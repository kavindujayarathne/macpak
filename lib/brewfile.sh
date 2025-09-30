# shellcheck shell=bash

# Brewfile dump function simply updates the Brewfile
brewfile_dump() {
	if brew bundle dump --file="$BREWFILE_PATH" --force >/dev/null 2>&1; then
		echo "Brewfile has been updated"
	else
		return 1
	fi
}
