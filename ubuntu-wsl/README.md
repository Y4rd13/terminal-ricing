# Ubuntu on WSL2 — Terminal Setup Guide

Complete guide to set up a modern terminal environment on Windows using WSL2, WezTerm, ZSH, and PowerLevel10k.

**Target environment:** Windows 10/11 → WSL2 → Ubuntu 24.04 → WezTerm + ZSH

## Table of Contents

- [1. Enable WSL2 on Windows](#1-enable-wsl2-on-windows)
- [2. Install Ubuntu](#2-install-ubuntu)
- [3. Install WezTerm on Windows](#3-install-wezterm-on-windows)
- [4. Install Nerd Fonts](#4-install-nerd-fonts)
- [5. Install ZSH](#5-install-zsh)
- [6. Install PowerLevel10k](#6-install-powerlevel10k)
- [7. Install CLI Tools](#7-install-cli-tools)
- [8. Install ZSH Plugins](#8-install-zsh-plugins)
- [9. Deploy Config Files](#9-deploy-config-files)
- [10. Post-Install Verification](#10-post-install-verification)
- [Reference: Aliases](#reference-aliases)
- [Reference: Functions](#reference-functions)
- [Reference: Keybindings](#reference-keybindings)

---

## 1. Enable WSL2 on Windows

Open **PowerShell as Administrator** and run:

```powershell
wsl --install
```

This enables WSL2 and installs Ubuntu by default. If WSL is already installed but using version 1:

```powershell
wsl --set-default-version 2
```

**Reboot** after installation.

Verify WSL2 is active:

```powershell
wsl --list --verbose
```

You should see your distribution with `VERSION 2`.

## 2. Install Ubuntu

If Ubuntu wasn't installed automatically with `wsl --install`:

```powershell
wsl --install -d Ubuntu-24.04
```

Launch Ubuntu from the Start menu. On first run, create your username and password.

Update the system:

```bash
sudo apt update && sudo apt upgrade -y
```

## 3. Install WezTerm on Windows

WezTerm runs on the **Windows side** and connects to WSL.

1. Download the latest `.exe` installer from [wezfurlong.org/wezterm/installation](https://wezfurlong.org/wezterm/installation.html)
2. Run the installer
3. Launch WezTerm

### Configure WezTerm

WezTerm's config lives on the **Windows side** since WezTerm runs as a Windows app. By default, WezTerm on Windows detects WSL and launches it automatically.

The WezTerm config file location on Windows is:

```
%USERPROFILE%\.config\wezterm\wezterm.lua
```

Copy the `wezterm.lua` from this directory:

```powershell
# From PowerShell
mkdir -Force "$env:USERPROFILE\.config\wezterm"
Copy-Item "\\wsl$\Ubuntu\home\YOUR_USERNAME\projects\terminal-ricing\ubuntu-wsl\.config\wezterm\wezterm.lua" "$env:USERPROFILE\.config\wezterm\wezterm.lua"
```

> **Note:** Replace `YOUR_USERNAME` with your WSL username. If using a different distro name, replace `Ubuntu` accordingly.

## 4. Install Nerd Fonts

Nerd Fonts must be installed on **Windows** (since WezTerm runs there).

1. Download **JetBrains Mono Nerd Font** from [nerdfonts.com/font-downloads](https://www.nerdfonts.com/font-downloads)
2. Extract the zip
3. Select all `.ttf` files → Right-click → **Install for all users**

Alternatively, install via the WSL terminal (fonts go to the Linux side, WezTerm can still use them if they're also on Windows):

```bash
mkdir -p ~/.local/share/fonts
cd /tmp
wget https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip JetBrainsMono.zip -d ~/.local/share/fonts/
fc-cache -fv
rm JetBrainsMono.zip
```

> **Important:** The font must be installed on Windows for WezTerm to render it. Install on both sides to be safe.

## 5. Install ZSH

```bash
sudo apt install -y zsh
```

Set ZSH as your default shell:

```bash
chsh -s $(which zsh)
```

Log out and back in (or restart your WSL session) for the change to take effect.

Verify:

```bash
echo $SHELL
# Expected: /usr/bin/zsh
```

## 6. Install PowerLevel10k

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
```

The `.zshrc` in this directory already sources PowerLevel10k. After deploying the config files (step 9), run:

```bash
source ~/.zshrc
```

PowerLevel10k's configuration wizard will launch automatically on first load. If you want to use the included `.p10k.zsh` config instead of running the wizard, just copy it (step 9) and the wizard won't appear.

To reconfigure later:

```bash
p10k configure
```

## 7. Install CLI Tools

### Core tools via apt

```bash
sudo apt install -y \
  eza \
  fzf \
  tmux \
  btop \
  fastfetch \
  curl \
  git \
  unzip \
  wget
```

### zoxide (smart cd)

```bash
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
```

### neovim

```bash
sudo apt install -y neovim
```

Or for the latest version:

```bash
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
rm nvim-linux-x86_64.tar.gz
```

### nvm (Node.js version manager)

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
```

After restarting the shell:

```bash
nvm install --lts
```

### tmux plugin manager (TPM)

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

After deploying `.tmux.conf` (step 9), open tmux and press `Ctrl+a` then `I` (capital i) to install plugins.

### Verify installations

```bash
eza --version
fzf --version
tmux -V
btop --version
fastfetch --version
zoxide --version
nvim --version
```

## 8. Install ZSH Plugins

```bash
# zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions

# zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting
```

Both are already sourced in the `.zshrc` config.

## 9. Deploy Config Files

From this directory, copy each config file to its target location:

```bash
# Set the source directory (adjust if you cloned the repo elsewhere)
SRC=~/projects/terminal-ricing/ubuntu-wsl

# ZSH config
cp "$SRC/.zshrc" ~/.zshrc

# PowerLevel10k config
cp "$SRC/.p10k.zsh" ~/.p10k.zsh

# Ripgrep config
cp "$SRC/.ripgreprc" ~/.ripgreprc

# tmux config
cp "$SRC/.tmux.conf" ~/.tmux.conf

# btop config
mkdir -p ~/.config/btop
cp "$SRC/.config/btop/btop.conf" ~/.config/btop/btop.conf

# fastfetch config
mkdir -p ~/.config/fastfetch
cp "$SRC/.config/fastfetch/config.jsonc" ~/.config/fastfetch/config.jsonc
```

> **Tip:** You can use symlinks instead of copies if you want changes in the repo to take effect immediately:
> ```bash
> ln -sf "$SRC/.zshrc" ~/.zshrc
> ```

## 10. Post-Install Verification

Reload the shell config:

```bash
source ~/.zshrc
```

Run through this checklist:

| Check | Command | Expected |
|-------|---------|----------|
| ZSH is active | `echo $SHELL` | `/usr/bin/zsh` |
| PowerLevel10k loads | (visual) | Styled prompt with git info |
| eza works | `ls` | File listing with icons |
| fzf works | `Ctrl+R` | Fuzzy history search |
| zoxide works | `z` (after visiting dirs) | Smart directory jump |
| tmux works | `tmux` | Terminal multiplexer session |
| btop works | `btop` | System monitor UI |
| fastfetch works | `fastfetch` | System info display |
| Nerd Font renders | (visual) | Icons visible in prompt and `ls` |

---

## Reference: Aliases

### File Listing (eza)

| Alias | Command |
|-------|---------|
| `ls` | `eza --group-directories-first --icons=auto --color=auto` |
| `la` | `eza -a --group-directories-first --icons=auto --color=auto --git` |
| `ll` | `eza -lah` with git, header, time, color-scale |

### Navigation

| Alias | Target |
|-------|--------|
| `..` | `cd ..` |
| `...` | `cd ../..` |
| `....` | `cd ../../..` |
| `cd` | `z` (zoxide smart jump) |
| `cdi` | `zi` (zoxide interactive) |

### Git

| Alias | Command |
|-------|---------|
| `gs` | `git status` |
| `ga` | `git add` |
| `gaa` | `git add .` |
| `gc` | `git commit` |
| `gcm` | `git commit -m` |
| `gp` | `git push` |
| `gpl` | `git pull` |
| `gl` | `git log --oneline` |
| `glo` | `git log --oneline --graph --decorate --all` |
| `gb` | `git branch` |
| `gch` | `git checkout` |
| `gd` | `git diff` |
| `gds` | `git diff --staged` |

### System

| Alias | Purpose |
|-------|---------|
| `reload` | `source ~/.zshrc` |
| `zshconfig` | Edit `~/.zshrc` in neovim |
| `wezconfig` | Edit WezTerm config in neovim |
| `c` | `clear` |
| `e` | `exit` |
| `h` | `history` |

---

## Reference: Functions

| Function | Usage | Purpose |
|----------|-------|---------|
| `mkcd` | `mkcd dirname` | Create directory and cd into it |
| `fzf_find` | `fzf_find` | Find and open files with fzf + bat preview |
| `fcd` | `fcd` | Navigate directories with fzf + eza preview |
| `fh` | `fh` | Search command history with fzf |
| `fkill` | `fkill` | Kill processes with fzf |
| `weather` | `weather [city]` | Show weather info |
| `backup` | `backup file` | Create timestamped backup copy |
| `extract` | `extract file.zip` | Extract any archive format |
| `search` | `search pattern` | Search file contents with ripgrep |
| `publicip` | `publicip` | Show public IP and location |

---

## Reference: Keybindings

### ZSH

| Shortcut | Action |
|----------|--------|
| `Ctrl+F` | Accept autosuggestion |
| `Ctrl+R` | Fuzzy history search (fzf) |
| `Ctrl+T` | Fuzzy file search (fzf) |
| `Alt+C` | Fuzzy cd (fzf) |

### WezTerm

| Shortcut | Action |
|----------|--------|
| `Cmd+Shift+F` | Split pane horizontally |
| `Cmd+Shift+D` | Split pane vertically |
| `Cmd+Arrow` | Navigate between panes |
| `Opt+Arrow` | Resize panes |
| `Ctrl+Shift+Z` | Zoom/unzoom pane |
| `Cmd+Shift+W` | Close current pane |

### tmux

| Shortcut | Action |
|----------|--------|
| `Ctrl+a \|` | Split horizontally |
| `Ctrl+a -` | Split vertically |
| `Ctrl+a I` | Install plugins (TPM) |
