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

#TODO: here we have to test the empty array (empty

@test "macpak doctor runs even with missing hard deps" {
	mkdir -p "$MOCKBIN"
	echo '#!/bin/sh; exit 127' >"$MOCKBIN/brew"
	echo '#!/bin/sh; exit 127' >"$MOCKBIN/fzf"
	chmod +x "$MOCKBIN/brew" "$MOCKBIN/fzf"

	PATH="$MOCKBIN:$PATH" run "${REPO_ROOT}/bin/macpak" doctor
	[ "$status" -eq 0 ]
	[[ "$output" =~ macpak[[:space:]]doctor: ]]
	[[ "$output" =~ Config: ]]
}
