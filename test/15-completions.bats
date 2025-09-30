#!/usr/bin/env bats

load _helpers.bash

@test "bash and zsh completion scripts parse cleanly" {
	run bash -n "${REPO_ROOT}/completions/macpak"
	[ "$status" -eq 0 ]

	run zsh -n "${REPO_ROOT}/completions/_macpak"
	[ "$status" -eq 0 ]
}

@test "bash completion suggests top-level subcommands" {
	. "${REPO_ROOT}/completions/macpak"

	COMP_WORDS=(macpak "")
	COMP_CWORD=1
	COMP_LINE="macpak "
	COMP_POINT=${#COMP_LINE}
	COMPREPLY=()

	_macpak_completion

	[[ " ${COMPREPLY[*]} " =~ " search " ]]
	[[ " ${COMPREPLY[*]} " =~ " list " ]]
	[[ " ${COMPREPLY[*]} " =~ " zap " ]]
	[[ " ${COMPREPLY[*]} " =~ " doctor " ]]
	[[ " ${COMPREPLY[*]} " =~ " cache " ]]
}

@test "bash completion suggests cache refresh" {
	. "${REPO_ROOT}/completions/macpak"

	COMP_WORDS=(macpak cache "")
	COMP_CWORD=2
	COMP_LINE="macpak cache "
	COMP_POINT=${#COMP_LINE}
	COMPREPLY=()

	_macpak_completion

	[[ " ${COMPREPLY[*]} " =~ " refresh " ]]
}
