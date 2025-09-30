# shellcheck shell=bash

is_index_fresh() {
	local modified_time current_timestamp index_age_secs
	modified_time=$(stat -f %m "$INDEX_PATH" 2>/dev/null) || return 1
	current_timestamp=$(date +%s)
	index_age_secs=$((current_timestamp - modified_time))
	((index_age_secs < INDEX_TTL_SECS))
}

build_index() {
	# ensure parent of INDEX_PATH exists
	mkdir -p "$(dirname "$INDEX_PATH")"
	local tmp="${INDEX_PATH}.tmp"
	{
		brew search --casks . | awk -v OFS='\t' -v label='[cask] ' '{ print label $0, $0 }'
		brew search --formulae . | awk -v OFS='\t' -v label='[formula] ' '{ print label $0, $0 }'
	} | sed '/^[[:space:]]*$/d' >"$tmp"
	mv "$tmp" "$INDEX_PATH"
}

get_index() {
	if [[ ! -f "$INDEX_PATH" ]]; then
		if ! spinner "Fetching Homebrew catalog…" build_index; then
			echo "$APP_NAME: no index available (build failed?)" >&2
			return 1
		fi
	else
		if ! is_index_fresh; then
			if ! spinner "Refreshing Homebrew catalog…" build_index; then
				echo "$APP_NAME: using old index (refresh failed)" >&2
			fi
		fi
	fi
	printf "%s" "$INDEX_PATH"
}

# Run a live `brew search <query>` (casks + formulae) and write results to $output
live_search_query_to_file() {
	local query="$1" output="$2"
	{
		{ brew search --casks "$query" 2>/dev/null || true; } |
			awk -v OFS='\t' -v label='[cask] ' '{ print label $0, $0 }'
		{ brew search --formulae "$query" 2>/dev/null || true; } |
			awk -v OFS='\t' -v label='[formula] ' '{ print label $0, $0 }'
	} | sed '/^[[:space:]]*$/d' >"$output"
}
