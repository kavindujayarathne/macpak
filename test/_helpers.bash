setup() {
	# repo root
	REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"

	# temp dir for test artifacts
	TMPDIR_UNDER_TEST="$(mktemp -d -t macpak_test.XXXXXX)"
	export TMPDIR_UNDER_TEST

	# create a mock bin dir that shadows real tools when needed
	MOCKBIN="${TMPDIR_UNDER_TEST}/mockbin"
	mkdir -p "$MOCKBIN"
	export PATH="$MOCKBIN:$PATH"

	# fast deterministic locale
	export LC_ALL=C LANG=C

	# Make sure macpak reads/writes index inside the temp dir
	export XDG_CACHE_HOME="${TMPDIR_UNDER_TEST}/.cache"
	mkdir -p "${XDG_CACHE_HOME}"
}

teardown() {
	rm -rf "${TMPDIR_UNDER_TEST}" 2>/dev/null || true
}
