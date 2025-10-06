#!/usr/bin/env bats
load _helpers.bash

@test "macpak doctor runs and shows header + Config" {
	run "${REPO_ROOT}/bin/macpak" doctor
	[ "$status" -eq 0 ]
	[[ "$output" =~ macpak[[:space:]]doctor: ]]
	[[ "$output" =~ Config: ]]
}

@test "macpak doctor marks overrides with '*'" {
	TMPHOME="${TMPDIR_UNDER_TEST}/home"
	mkdir -p "$TMPHOME/.config/macpak"
	cat >"$TMPHOME/.config/macpak/config.sh" <<'EOF'
AUTO_BREWFILE=0
EOF
	HOME="$TMPHOME" run "${REPO_ROOT}/bin/macpak" doctor
	[ "$status" -eq 0 ]
	[[ "$output" =~ \*[[:space:]]+AUTO_BREWFILE= ]]
}

@test "macpak doctor shows (empty) for empty arrays" {
	TMPHOME="${TMPDIR_UNDER_TEST}/home"
	mkdir -p "$TMPHOME/.config/macpak"
	cat >"$TMPHOME/.config/macpak/config.sh" <<'EOF'
ROOTS=()
EOF

	HOME="$TMPHOME" run "${REPO_ROOT}/bin/macpak" doctor
	[ "$status" -eq 0 ]
	[[ "$output" =~ ROOTS=\(empty\) ]]
	[[ "$output" =~ EXCLUDES=\(empty\) ]]
}

@test "macpak doctor runs even with missing hard deps" {
	PATH="/bin:/usr/bin:" run "${REPO_ROOT}/bin/macpak" doctor
	[ "$status" -eq 0 ]
	[[ $output =~ ✗[[:space:]]*brew[[:space:]]*.*MISSING[[:space:]]*\(required\) ]]
	[[ $output =~ ✗[[:space:]]*fzf[[:space:]]*.*MISSING[[:space:]]*\(required\) ]]
}

@test "non-doctor subcommands fail fast when brew/fzf missing" {
	PATH="/bin:/usr/bin" run "${REPO_ROOT}/bin/macpak"
	[ "$status" -ne 0 ]
	[[ $output =~ macpak:[[:space:]]*missing:?[[:space:]]*(brew|fzf) ]]
}
