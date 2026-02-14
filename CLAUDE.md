# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles repo using [Dotbot](https://github.com/anishathalye/dotbot) for symlink management. Configs are symlinked from this repo to `~/.config/` and `~/`.

## Setup

```bash
./install  # runs dotbot with install.conf.yaml
```

This creates symlinks defined in `install.conf.yaml` and initializes git submodules (dotbot itself is a submodule).

## Architecture

- `install.conf.yaml` - Dotbot config: defines all symlinks, clean rules, shell commands
- `zshrc` - Zsh config (oh-my-zsh, starship prompt, plugin loading)
- `env.sh` - Aliases, shell functions, env vars (sourced by zshrc)
- `tmux.conf.local` - Tmux customization (uses [gpakosz/.tmux](https://github.com/gpakosz/.tmux) framework via `config/tmux/.tmux.conf`)
- `config/nvim/` - AstroNvim v4+ config
- `config/kitty/` - Kitty terminal config
- `config/alacritty/` - Alacritty terminal config
- `config/lazygit/` - Lazygit config
- `config/gitui/` - GitUI config

## Neovim (AstroNvim)

Based on AstroNvim v4+. Plugin config lives in `config/nvim/lua/plugins/`. Key files:

- `astrocore.lua` - Core AstroNvim options and keymaps
- `astrolsp.lua` - LSP configuration
- `mason.lua` - Mason-managed tools (LSPs, formatters, linters)
- `user.lua` - Additional user plugins
- `community.lua` - AstroCommunity plugin packs
- `treesitter.lua` - Treesitter parsers

Lazy.nvim lockfile: `config/nvim/lazy-lock.json`

## Tmux

Uses gpakosz/.tmux as base (`config/tmux/` submodule), customized via `tmux.conf.local`. Uses TPM plugins including tmux-resurrect and gruvbox theme. Vim-tmux-navigator keybindings (C-h/j/k/l) are configured.

## Conventions

- Machine-specific zsh config goes in `~/.zshrc.local` (not tracked)
- Default editor: nvim
- Uses eza for ls, starship for prompt, fzf for fuzzy finding
