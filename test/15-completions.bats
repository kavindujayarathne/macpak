#!/usr/bin/env bats

load _helpers.bash

_has() {
	local needle="$1"
	shift
	for x in "$@"; do
		[[ "$x" == "$needle" ]] && return 0
	done
	return 1
}

@test "bash and zsh completion scripts parse cleanly" {
	run bash -n "${REPO_ROOT}/completions/macpak"
	[ "$status" -eq 0 ]

	run zsh -n "${REPO_ROOT}/completions/_macpak"
	[ "$status" -eq 0 ]
}

@test "bash completion: top-level suggests flags and subcommands" {
	. "${REPO_ROOT}/completions/macpak"

	COMP_WORDS=(macpak "")
	COMP_CWORD=1
	COMP_LINE="macpak "
	COMP_POINT=${#COMP_LINE}
	COMPREPLY=()

	_macpak_completion

	_has "search" "${COMPREPLY[@]}"
	_has "list" "${COMPREPLY[@]}"
	_has "zap" "${COMPREPLY[@]}"
	_has "doctor" "${COMPREPLY[@]}"
	_has "cache-refresh" "${COMPREPLY[@]}"

	_has "-h" "${COMPREPLY[@]}"
	_has "-v" "${COMPREPLY[@]}"
	_has "--help" "${COMPREPLY[@]}"
	_has "--version" "${COMPREPLY[@]}"
}

@test "bash completion: '-' narrows to flags only" {
	. "${REPO_ROOT}/completions/macpak"

	COMP_WORDS=(macpak -)
	COMP_CWORD=1
	COMP_LINE="macpak -"
	COMP_POINT=${#COMP_LINE}
	COMPREPLY=()

	_macpak_completion

	_has "-h" "${COMPREPLY[@]}"
	_has "-v" "${COMPREPLY[@]}"
	_has "--help" "${COMPREPLY[@]}"
	_has "--version" "${COMPREPLY[@]}"

	! _has "search" "${COMPREPLY[@]}"
	! _has "list" "${COMPREPLY[@]}"
	! _has "zap" "${COMPREPLY[@]}"
	! _has "doctor" "${COMPREPLY[@]}"
	! _has "cache-refresh" "${COMPREPLY[@]}"
}

@test "bash completion: '--' narrows to long flags only" {
	. "${REPO_ROOT}/completions/macpak"

	COMP_WORDS=(macpak --)
	COMP_CWORD=1
	COMP_LINE="macpak --"
	COMP_POINT=${#COMP_LINE}
	COMPREPLY=()

	_macpak_completion

	_has "--help" "${COMPREPLY[@]}"
	_has "--version" "${COMPREPLY[@]}"

	! _has "-h" "${COMPREPLY[@]}"
	! _has "-v" "${COMPREPLY[@]}"
	! _has "search" "${COMPREPLY[@]}"
	! _has "list" "${COMPREPLY[@]}"
	! _has "zap" "${COMPREPLY[@]}"
	! _has "doctor" "${COMPREPLY[@]}"
	! _has "cache-refresh" "${COMPREPLY[@]}"
}

@test "bash completion: partial token narrows to matching subcommands" {
	. "${REPO_ROOT}/completions/macpak"

	COMP_WORDS=(macpak se)
	COMP_CWORD=1
	COMP_LINE="macpak se"
	COMP_POINT=${#COMP_LINE}
	COMPREPLY=()

	_macpak_completion

	_has "search" "${COMPREPLY[@]}"
	! _has "list" "${COMPREPLY[@]}"
	! _has "zap" "${COMPREPLY[@]}"
}
