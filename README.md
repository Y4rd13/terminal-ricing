```
   ██╗   ██╗ ██╗  ██████╗ ██████╗   ██╗ ██████╗
   ╚██╗ ██╔╝ ██║  ██╔══██╗██╔══██╗ ███║ ╚════██╗
    ╚████╔╝  ████████████╔╝██║  ██║ ╚██║  █████╔╝
     ╚██╔╝   ╚════██╔══██╗██║  ██║  ██║  ╚═══██╗
      ██║         ██║██║  ██║██████╔╝ ██║ ██████╔╝
      ╚═╝         ╚═╝╚═╝  ╚═╝╚═════╝  ╚═╝ ╚═════╝

  ┌──────────────────────────────────────────────────────┐
  │  T E R M I N A L   R I C I N G  /// Setup v1.0      │
  └──────────────────────────────────────────────────────┘
```

Configuration files and setup guides for a modern, customized terminal environment across different platforms.

## Platforms

| Directory | Description | Guide |
|-----------|-------------|-------|
| [ubuntu-wsl](./ubuntu-wsl/) | Ubuntu 24.04 on WSL2 with WezTerm (Windows) | Full setup from scratch |
| [linux](./linux/) | Native Linux setup (Kali, Ubuntu, Debian) | WezTerm + ZSH + Starship |
| [claude-code](./claude-code/) | Claude Code + MCP servers + plugins | Setup guide (configs in [claude-config](https://github.com/Y4rd13/claude-config)) |

## What's Inside

Each directory contains:

- **Config files** — dotfiles and `.config/` entries, ready to copy into place (or references to where they live)
- **README.md** — step-by-step setup guide

## Tool Stack

| Tool | Purpose |
|------|---------|
| [WezTerm](https://wezfurlong.org/wezterm/) | GPU-accelerated terminal emulator |
| [ZSH](https://www.zsh.org/) | Shell |
| [PowerLevel10k](https://github.com/romkatv/powerlevel10k) | Prompt theme |
| [LazyVim](https://www.lazyvim.org/) | Neovim IDE configuration |
| [micro](https://micro-editor.github.io/) | Terminal text editor |
| [eza](https://github.com/eza-community/eza) | Modern `ls` replacement |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smart `cd` |
| [tmux](https://github.com/tmux/tmux) | Terminal multiplexer |
| [btop](https://github.com/aristocratos/btop) | System monitor |
| [fastfetch](https://github.com/fastfetch-cli/fastfetch) | System info display |
| [JetBrains Mono Nerd Font](https://www.nerdfonts.com/) | Font with icons |
