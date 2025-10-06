# shellcheck shell=bash

# returns 0 if current user can unlink the path (based on parent dir perms)
can_unlink_as_user() {
	local p="$1" d
	[[ -e "$p" || -L "$p" ]] || return 1
	d="$(dirname "$p")"
	[[ -w "$d" && -x "$d" ]]
}

# Globals populated by group_leftovers()
declare -a GROUP_USER_WRITABLE=()
declare -a GROUP_PRIVILEGED=()

# Input: newline-separated paths (string)
# Effect: populates GROUP_USER_WRITABLE / GROUP_PRIVILEGED and prints grouped view.
group_leftovers() {
	local paths="$1" line
	GROUP_USER_WRITABLE=()
	GROUP_PRIVILEGED=()

	while IFS= read -r line || [[ -n "$line" ]]; do
		[[ -z "$line" ]] && continue
		if can_unlink_as_user "$line"; then
			GROUP_USER_WRITABLE+=("$line")
		else
			GROUP_PRIVILEGED+=("$line")
		fi
	done <<<"$paths"

	echo
	echo "Selected paths :"
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
	echo
}

# Single deletion function. Acts according to USE_TRASH and the two groups above.
delete_paths() {
	if ((USE_TRASH)); then
		if ((TRASH_OK)); then
			# User-writable → user Trash; verify disappearance; no sudo on fallback.
			if ((${#GROUP_USER_WRITABLE[@]})); then
				local p
				for p in "${GROUP_USER_WRITABLE[@]}"; do
					if trash "$p" >/dev/null 2>&1; then
						# sanity check: should be gone
						if [[ -e "$p" || -L "$p" ]]; then
							echo "Warning: '$p' still present after trash; removing instead." >&2
							rm -rf "$p" 2>/dev/null || true
						fi
					else
						echo "Warning: could not move '$p' to user Trash; removing instead." >&2
						rm -rf "$p" 2>/dev/null || true
					fi
				done
			fi

			# Privileged → elevated removal (single header)
			if ((${#GROUP_PRIVILEGED[@]})); then
				echo "Note: the following require elevation and will be removed:" >&2
				nl -ba <<<"$(printf '%s\n' "${GROUP_PRIVILEGED[@]}")" >&2
				sudo rm -rf -- "${GROUP_PRIVILEGED[@]}"
			fi

		else
			# Trash requested but unavailable → warn once and do permanent removal semantics.
			echo "Note: USE_TRASH=1 but 'trash' command is unavailable; falling back to permanent remove (rm -rf)." >&2

			if ((${#GROUP_USER_WRITABLE[@]})); then
				rm -rf -- "${GROUP_USER_WRITABLE[@]}" 2>/dev/null || true
			fi
			if ((${#GROUP_PRIVILEGED[@]})); then
				sudo rm -rf -- "${GROUP_PRIVILEGED[@]}"
			fi
		fi

	else
		# Permanent mode: remove everything; only privileged group escalates.
		if ((${#GROUP_USER_WRITABLE[@]})); then
			rm -rf -- "${GROUP_USER_WRITABLE[@]}" 2>/dev/null || true
		fi
		if ((${#GROUP_PRIVILEGED[@]})); then
			sudo rm -rf -- "${GROUP_PRIVILEGED[@]}"
		fi
	fi

	echo "$APP_NAME: leftovers removed."
}
