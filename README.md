<div align="center">

# Sharingan.nvim

[Install](#install) • [Features](#features) • [Keybindings](#keybindings) • [Structure](#project-structure)

![Neovim](https://img.shields.io/badge/Neovim-0.10+-green?style=flat-square&logo=neovim&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)
![Stars](https://img.shields.io/github/stars/ijadux2/sharingan.nvim?style=flat-square)

</div>

---

### Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Install](#install)
- [Keybindings](#keybindings)
- [License](#license)

# Introduction

<a href="https://neovim.io">
  <img src="https://raw.githubusercontent.com/ijadux2/sharingan.nvim/main/assets/screenshot_2026-03-02_04-57-09.png" align="right" />
</a>

> [!info] intro
> A highly customized Neovim configuration built on LazyVim, featuring a powerful
> picker system powered by Snacks.picker and numerous native Lua modules for
> enhanced productivity.

Sharingan is a Neovim configuration framework built on LazyVim, tailored for
users who want a powerful out-of-the-box editing experience with a focus on
productivity and aesthetics. It combines the best of LazyVim's foundation with
custom Lua modules for everyday tasks.

Its design is guided by these principles:

- **Gotta go fast.** Startup and run-time performance are priorities. Sharingan
  uses LazyVim's efficient plugin loading and custom optimizations.
- **Close to metal.** There's less between you and vanilla Neovim by design.
  That's less to grok and less to work around when you tinker.
- **Opinionated, but not stubborn.** Sharingan is about reasonable defaults and
  curated configurations, but use as little or as much of it as you like.
- **Your system, your rules.** You know better! It won't automatically install
  system dependencies. Rely on this README to know what's needed.
- **Modular by design.** Each feature is a separate Lua module, making it easy
  to understand, modify, or remove components.

# Features

- Minimalistic good looks inspired by modern editors, using Catppuccin.
- Built on LazyVim's solid foundation with automatic plugin management.
- A powerful picker system powered by Snacks.picker for files, buffers, git
  files, recent files, commands, keymaps, help tags, and grep search.
- Native Lua modules for common development tasks.
- LSP support via Mason.nvim with nvim-cmp for intelligent code completion.
- Treesitter-powered advanced syntax highlighting.
- File explorer with Snacks.picker and Oil integration.
- Git integration for branch switching, commits, and log viewing.
- System controls for power, media, brightness, and screenshots.
- Web search and text browsing capabilities directly from Neovim.
- Emoji picker with category filtering.
- Todo management and markdown note creation.
- Application launcher for Linux.
- integration with [Neoshell](https://github.com/ijadux2/Neoshell)

# Prerequisites

- **Required:**
  - Neovim >= 0.10.0 (0.10+ recommended)
  - Git
  - ripgrep >= 11.0 (for grep functionality)
- **Optional, but recommended:**
  - `brightnessctl` - Brightness control
  - `wpctl` - PipeWire volume control
  - `playerctl` - Media player control
  - `maim` - Screenshots
  - `xdg-open` - Open URLs
  - `nmcli` - WiFi control
  - `rfkill` - Bluetooth control

> [!info] Neoshell
> See the requirements for neoshell

# Install

```sh
# Backup existing Neovim config
mv ~/.config/nvim ~/.config/nvim.bak

# Clone this repository
git clone https://github.com/ijadux2/sharingan.nvim.git ~/.config/nvim

# Start Neovim
nvim
```

Lazy.nvim will automatically install all plugins on first launch.

Useful commands:

- `LazySync` to synchronize your plugins with LazyVim.
- `Lazy` to open the LazyVim plugin manager UI.
- `:Tangle` to regenerate source files from markdown documentation.

# Keybindings

### General

| Binding   | Action                  |
| --------- | ----------------------- |
| `<Space>` | Leader key              |
| `<Esc>`   | Clear search/highlights |
| `jk`      | Exit insert mode (fast) |
| `H`       | Beginning of line       |
| `L`       | End of line             |
| `J`       | Move line down          |
| `K`       | Move line up            |

### Fuzzy Finder & Pickers

| Binding      | Action               |
| ------------ | -------------------- |
| `<leader>ff` | Fuzzy finder menu    |
| `<leader>fa` | App launcher         |
| `<leader>fg` | Git files            |
| `<leader>fr` | Recent files         |
| `<leader>fc` | Commands             |
| `<leader>fh` | Help tags            |
| `<leader>f/` | Grep search          |
| `<S-e>`      | Emoji picker         |
| `<S-f>`      | Create markdown note |

### Git

| Binding      | Action        |
| ------------ | ------------- |
| `<leader>gg` | Git menu      |
| `<leader>gb` | Switch branch |
| `<leader>gc` | Git commit    |

### System & Power

| Binding      | Action          |
| ------------ | --------------- |
| `<leader>fp` | Power commands  |
| `<leader>fS` | Screenshot menu |
| `<leader>fs` | Web search      |
| `<leader>fb` | Text/browser    |

### Window Navigation

| Binding | Action         |
| ------- | -------------- |
| `<C-h>` | Navigate left  |
| `<C-j>` | Navigate down  |
| `<C-k>` | Navigate up    |
| `<C-l>` | Navigate right |

# Project Structure

```
.
├── init.lua              # Main entry point
├── lazyvim.json          # LazyVim compatibility
├── lazy-lock.json        # Locked plugin versions
├── lua/
│   ├── core/
│   │   ├── options.lua   # Neovim options
│   │   └── keymaps.lua   # Keybindings
│   ├── plugins/
│   │   ├── ui.lua        # UI plugins
│   │   ├── lsp.lua       # LSP configuration
│   │   ├── tools.lua     # Tool plugins
│   │   ├── filetypes.lua # Filetype plugins
│   │   └── extras.lua    # Extra plugins
│   ├── fuzzy.lua         # Fuzzy finder
│   ├── app-launcher.lua  # App launcher
│   ├── emoji.lua         # Emoji picker
│   ├── git.lua           # Git integration
│   ├── power-commands.lua # System controls
│   ├── web-search.lua    # Web search
│   ├── agenda.lua        # Note taking
│   └── ...
└── neovim.md            # Documentation source
```

## Tangle

This configuration uses its own `tangle.lua` module to extract code blocks from
`neovim.md` into the actual Lua files. Run `:Tangle` in Neovim to regenerate
the source files from the markdown documentation.

# License

MIT
