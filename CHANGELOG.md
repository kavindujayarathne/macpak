# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.0.0 (2025-09-23)

### Features
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

- **Cached index for fast searches (`macpak cache refresh`)**
  - Maintains a local `index.tsv` to avoid fetching thousands of packages every run
  - Cache expires every 24h by default
  - Manual refresh available with `macpak cache refresh`

- **System and config health check (`macpak doctor`)**
  - Verifies presence and versions of required/optional dependencies
  - Displays current config values and highlights overrides from `~/.config/macpak/config.sh`
  - Single place to audit environment and tool setup

- **Shell completions**
  - Bash and Zsh completions included

- **Config overrides**
  - Default behaviors set via environment variables can be overridden in `~/.config/macpak/config.sh`
