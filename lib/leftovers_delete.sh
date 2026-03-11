# shellcheck shell=bash

# returns 0 if current user can unlink the path (based on parent dir perms)
can_unlink_as_user() {
	local p="$1" d
	[[ -e "$p" || -L "$p" ]] || return 1

	d="$(dirname "$p")"
	[[ -w "$d" && -x "$d" ]] || return 1

	# Directories must be writable to delete their contents
	if [[ -d "$p" && ! -L "$p" ]]; then
		[[ -w "$p" ]] || return 1
	fi

	return 0
}

# Global declarations
declare -a GROUP_USER_WRITABLE=()
declare -a GROUP_PRIVILEGED=()
declare -a GROUP_WORLD_WRITABLE=()

# Input: newline-separated paths (string)
# Effect: populates GROUP_USER_WRITABLE / GROUP_PRIVILEGED / GROUP_WORLD_WRITABLE
#         and prints grouped view.
group_leftovers() {
	local paths="$1" line
	GROUP_USER_WRITABLE=()
	GROUP_PRIVILEGED=()
	GROUP_WORLD_WRITABLE=()

	while IFS= read -r line || [[ -n "$line" ]]; do
		[[ -z "$line" ]] && continue
		if [[ -k "$(dirname "$line")" ]]; then
			GROUP_WORLD_WRITABLE+=("$line")
		elif can_unlink_as_user "$line"; then
			GROUP_USER_WRITABLE+=("$line")
		else
			GROUP_PRIVILEGED+=("$line")
		fi
	done <<<"$paths"

	echo
	echo "Selected paths:"
	if ((${#GROUP_USER_WRITABLE[@]})); then
		echo "  User-writable:"
		nl -ba <<<"$(printf '%s\n' "${GROUP_USER_WRITABLE[@]}")"
	else
		echo "  User-writable: (none)"
	fi
	echo
	if ((${#GROUP_PRIVILEGED[@]})); then
		echo "  Privileged:"
		nl -ba <<<"$(printf '%s\n' "${GROUP_PRIVILEGED[@]}")"
	else
		echo "  Privileged: (none)"
	fi
	if ((${#GROUP_WORLD_WRITABLE[@]})); then
		echo
		echo "  Shared (world-writable dir):"
		nl -ba <<<"$(printf '%s\n' "${GROUP_WORLD_WRITABLE[@]}")"
	fi
	echo
}

# Single deletion function. Acts according to USE_TRASH and other path groups above.
delete_paths() {
	local use_trash=0 p
	local -a trash_failed=() rm_failed=() failed_paths=()

	# Determine if we can actually use trash
	# shellcheck disable=SC2153
	if ((USE_TRASH)) && ((TRASH_OK)); then
		use_trash=1
	elif ((USE_TRASH)) && ! ((TRASH_OK)); then
		echo "Note: USE_TRASH=1 but 'trash' command is unavailable; falling back to permanent remove (rm -rf)." >&2
	fi

	# Handle user-writable items
	if ((${#GROUP_USER_WRITABLE[@]})); then
		if ((use_trash)); then
			if ! trash "${GROUP_USER_WRITABLE[@]}" >/dev/null 2>&1; then
				for p in "${GROUP_USER_WRITABLE[@]}"; do
					if [[ -e "$p" || -L "$p" ]]; then
						trash_failed+=("$p")
					fi
				done
				if ((${#trash_failed[@]})); then
					echo "Warning: the following could not be moved to Trash:" >&2
					nl -ba <<<"$(printf '%s\n' "${trash_failed[@]}")" >&2
					echo
					if ask_yes_no "Remove permanently? [y/N] "; then
						if ! rm -rf -- "${trash_failed[@]}" 2>/dev/null; then
							for p in "${trash_failed[@]}"; do
								if [[ -e "$p" || -L "$p" ]]; then
									rm_failed+=("$p")
								fi
							done
							if ((${#rm_failed[@]})); then
								echo "Error: ${#rm_failed[@]} path(s) could not be removed. May require manual removal:" >&2
								nl -ba <<<"$(printf '%s\n' "${rm_failed[@]}")" >&2
							fi
						fi
					else
						echo "Skipped permanent removal. Handle these paths manually if needed." >&2
					fi
				fi
			fi
		else
			if ! rm -rf -- "${GROUP_USER_WRITABLE[@]}" 2>/dev/null; then
				failed_paths=()
				for p in "${GROUP_USER_WRITABLE[@]}"; do
					if [[ -e "$p" || -L "$p" ]]; then
						failed_paths+=("$p")
					fi
				done
				if ((${#failed_paths[@]})); then
					echo "Error: ${#failed_paths[@]} path(s) could not be removed. May require manual removal:" >&2
					nl -ba <<<"$(printf '%s\n' "${failed_paths[@]}")" >&2
				fi
			fi
		fi
	fi

	# Handle privileged items
	if ((${#GROUP_PRIVILEGED[@]})); then
		echo
		echo "Note: the following require elevation and will be removed:" >&2
		nl -ba <<<"$(printf '%s\n' "${GROUP_PRIVILEGED[@]}")" >&2
		echo

		if ! sudo rm -rf -- "${GROUP_PRIVILEGED[@]}" 2>/dev/null; then
			failed_paths=()
			for p in "${GROUP_PRIVILEGED[@]}"; do
				if [[ -e "$p" || -L "$p" ]]; then
					failed_paths+=("$p")
				fi
			done
			if ((${#failed_paths[@]})); then
				echo "Error: ${#failed_paths[@]} privileged path(s) could not be removed:" >&2
				nl -ba <<<"$(printf '%s\n' "${failed_paths[@]}")" >&2
			fi
		fi
	fi

	# Handle shared paths at the end so the message is visible
	if ((${#GROUP_WORLD_WRITABLE[@]})); then
		echo "Shared paths were found:"
		nl -ba <<<"$(printf '%s\n' "${GROUP_WORLD_WRITABLE[@]}")"
		echo "  These are in shared (world-writable) directories and may belong to other users."
		echo
		if ask_yes_no "Remove with elevated privileges? [y/N] "; then
			if ! sudo rm -rf -- "${GROUP_WORLD_WRITABLE[@]}" 2>/dev/null; then
				failed_paths=()
				for p in "${GROUP_WORLD_WRITABLE[@]}"; do
					if [[ -e "$p" || -L "$p" ]]; then
						failed_paths+=("$p")
					fi
				done
				if ((${#failed_paths[@]})); then
					echo "Error: ${#failed_paths[@]} shared path(s) could not be removed:" >&2
					nl -ba <<<"$(printf '%s\n' "${failed_paths[@]}")" >&2
				fi
			fi
		else
			echo "Skipped. Handle these paths manually if needed." >&2
		fi
	fi

	echo
	echo "$APP_NAME: Process Completed!"
}
