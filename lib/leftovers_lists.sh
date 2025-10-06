# shellcheck shell=bash

# Build strict/relaxed lists from a single scan result and write them to files.
# Args: 1=name (token), 2=raw_hits (newline-separated), 3=out_dir
prepare_leftover_lists() {
	local name="$1" raw="$2" out="$3"
	local esc regex strict relaxed
	esc="$(printf '%s' "$name" | sed -E 's/[][$.^|?*+(){}\\]/\\&/g')"
	regex="(^|[^[:alnum:]])${esc}([^[:alnum:]]|$)"
	strict="$(printf '%s\n' "$raw" | grep -Ei -- "$regex" | sort -fu || true)"
	relaxed="$(printf '%s\n' "$raw" | sort -fu || true)"
	printf '%s\n' "$strict" >"$out/strict.txt"
	printf '%s\n' "$relaxed" >"$out/relaxed.txt"
}

# FZF picker that lets you toggle between strict/relaxed without recompute.
pick_leftovers() {
	local title="$1" dir="$2"
	local strict="$dir/strict.txt" relaxed="$dir/relaxed.txt"
	cat "$strict" | fzf --multi \
		--header="$title • enter=select • ctrl-s=strict • ctrl-r=relaxed" \
		--prompt='Strict > ' \
		--bind "ctrl-r:reload(cat \"$relaxed\")+change-prompt(Relaxed > )" \
		--bind "ctrl-s:reload(cat \"$strict\")+change-prompt(Strict > )"
}
