# shellcheck shell=bash

scan_fs() {
	local name="$1"
	[[ -z "$name" ]] && return 0

	# Build prune group (EXCLUDES must contain absolute paths)
	local -a prune=()
	if ((${#EXCLUDES[@]})); then
		local first=1 x
		prune+=('(')
		for x in "${EXCLUDES[@]}"; do
			[[ $x = /* ]] || continue # ignore non-absolute entries
			x="${x%/}"                # drop trailing slash
			((first)) && first=0 || prune+=(-o)
			prune+=(-path "$x" -o -path "$x/*")
		done
		prune+=(')' -prune -o)
	fi

	local raw_hits=""
	if ((${#prune[@]})); then
		raw_hits=$(find "${ROOTS[@]}" "${prune[@]}" -iname "*$name*" -print 2>/dev/null || true)
	else
		raw_hits=$(find "${ROOTS[@]}" -iname "*$name*" -print 2>/dev/null || true)
	fi

	[[ -n "$raw_hits" ]] && printf '%s\n' "$raw_hits"
}
