#!/usr/bin/env bats
load _helpers.bash

_make_mock_brew() {
	cat >"${MOCKBIN}/brew" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "$*" in
  "search --casks .")
    printf '%s\n' "docker-desktop" "aerospace"
    ;;
  "search --formulae .")
    printf '%s\n' "curl" "git"
    ;;
  *)
    echo "unexpected brew invocation: $*" >&2
    exit 64
    ;;
esac
EOF
	chmod +x "${MOCKBIN}/brew"
}

@test "cache refresh builds index file with both casks and formulae" {
	_make_mock_brew
	export INDEX_PATH="${TMPDIR_UNDER_TEST}/index.tsv"

	run "${REPO_ROOT}/bin/macpak" cache refresh
	[ "$status" -eq 0 ]
	[ -f "${INDEX_PATH}" ]

	run grep -c '^\[cask\]' "${INDEX_PATH}"
	[ "$status" -eq 0 ]
	[ "$output" -ge 1 ]

	run grep -c '^\[formula\]' "${INDEX_PATH}"
	[ "$status" -eq 0 ]
	[ "$output" -ge 1 ]
}
