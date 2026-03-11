# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.1] - 2026-03-12

### Changed

- **Spinner shown while Brewfile is updating**
  - `macpak search` and `macpak list` now display a spinner with "Updating Brewfile…" instead of
    silently pausing while `brew bundle dump` runs
  - A confirmation message is printed once the update completes, or an error is reported on failure

### Fixed

- **Skip install for already-installed packages in `macpak search`**
  - Selecting a package that is already installed no longer attempts a brew install, preventing
    an unnecessary Brewfile update from being triggered when nothing was actually installed

## [1.1.0] - 2026-02-26

### Added

- **Shared path detection in leftover cleanup**
  - Paths inside shared (world-writable) directories like `/Users/Shared` are now detected and
    grouped separately during leftover cleanup
  - Users are prompted to remove them with elevated privileges or skip for manual removal
  - When only shared paths are found, the initial confirmation prompt is skipped and macpak proceeds
    directly to handle them

### Changed

- **`macpak list` now shows only explicitly installed formulas**
  - Uses `--installed-on-request` flag so auto-installed dependencies are excluded from the list

- **Improved leftover deletion flow**
  - Trash failures are now reported in batch with a confirmation prompt before falling back to
    permanent removal (rm -rf)
  - Failed removals are collected and reported with clear error messages instead of being silently
    ignored

- **Updated default scan paths (ROOTS)**
  - Removed `/private/var/folders` and `/private/var/tmp` (self-cleaning directories)
  - Added `/private/etc` and `/Users/Shared`

### Fixed

- **Permission check in `can_unlink_as_user()`**
  - Previously only checked parent directory permissions. Now also verifies that target directories
    themselves are writable, since a non-empty directory without write permission cannot be removed
    without elevation

- **Privileged removal error handling**
  - Failed `sudo rm -rf` removals are now detected and reported instead of being silently ignored

## [1.0.0] - 2025-10-05

### Added

- **Interactive search (`macpak search`)**
  - Browse the full Homebrew catalog with an fzf-powered interface
  - Preview package details (equivalent to `brew info`) inline
  - Filter results by `[cask]` or `[formula]`
  - Install single or multiple packages directly from the list
  - Optional split-pane preview in tmux (`Ctrl+P`) with vi-style navigation
  - Automatic Brewfile update after installs

- **Interactive package management (`macpak list`)**
  - View all installed packages in an fzf-powered list
  - Filter installed items by `[cask]` or `[formula]`
  - Uninstall single or multiple packages directly from the interface
  - Automatic leftover scan after uninstall with two modes:
    - **Strict** – regex-filtered list of probable leftovers
    - **Relaxed** – broader, raw list
  - Choose to delete permanently or move leftovers to Trash
  - Brewfile automatically updated after removals

- **Zap non-brew apps (`macpak zap`)**
  - Locate and remove applications installed outside of Homebrew
  - Detect and list all related leftovers for safe cleanup
  - Interactive selection of what to delete or keep
  - Configurable deletion: Trash (default) or permanent removal

- **Cached index for fast searches (`macpak cache-refresh`)**
  - Maintains a local `index.tsv` to avoid fetching thousands of packages every run
  - Cache expires every 24h by default
  - Manual refresh available with `macpak cache-refresh`

- **System and config health check (`macpak doctor`)**
  - Verifies presence and versions of required/optional dependencies
  - Displays current config values and highlights overrides from `~/.config/macpak/config.sh`
  - Single place to audit environment and tool setup

- **Shell completions**
  - Bash and Zsh completions included

- **Config overrides**
  - Default behaviors set via environment variables can be overridden in `~/.config/macpak/config.sh`
