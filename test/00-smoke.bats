#!/usr/bin/env bats
load _helpers.bash

@test "version flags print version" {
	for flag in --version -v version; do
		run "${REPO_ROOT}/bin/macpak" "$flag"
		[ "$status" -eq 0 ]
		[[ "$output" =~ ^macpak[[:space:]]+.+$ ]]
	done
}

@test "MACPAK_VERSION overrides printed version" {
	run env MACPAK_VERSION=9.9.9 "${REPO_ROOT}/bin/macpak" -v
	[ "$status" -eq 0 ]
	[[ "$output" =~ ^macpak[[:space:]]+9\.9\.9$ ]]
}

@test "help flags print usage" {
	for flag in --help -h; do
		run "${REPO_ROOT}/bin/macpak" "$flag"
		[ "$status" -eq 0 ]
		[[ "$output" =~ Usage: ]]
	done
}

@test "no args shows usage" {
	run "${REPO_ROOT}/bin/macpak"
	[ "$status" -eq 0 ]
	[[ "$output" =~ Usage: ]]
}
