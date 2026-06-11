# Arch Linux & CachyOS — Terminal Setup Guide

Complete guide to set up a modern terminal environment on **Arch Linux** and Arch-based
distros (with **CachyOS** as the primary worked example) using WezTerm, ZSH, and Starship.

**Target environment:** Native Arch / CachyOS / EndeavourOS / Manjaro → WezTerm + ZSH + Starship

![Arch Linux](https://img.shields.io/badge/Arch-Linux-1793D1?style=for-the-badge&logo=archlinux&logoColor=white)
![CachyOS](https://img.shields.io/badge/CachyOS-00AA88?style=for-the-badge&logo=linux&logoColor=white)
![WezTerm](https://img.shields.io/badge/WezTerm-4A90E2?style=for-the-badge)
![ZSH Shell](https://img.shields.io/badge/ZSH-Shell-1A2C34?style=for-the-badge)
![Starship](https://img.shields.io/badge/Starship-DD0B78?style=for-the-badge&logo=starship&logoColor=white)

> **Why a separate guide?** Arch-based distros use `pacman` (not `apt`) and the Arch User
> Repository (AUR). Almost the entire tool stack lives in the **official repos**, so setup is
> a single `pacman` command — no PPAs, no manual tarballs, no download-and-unzip for fonts.

## Table of Contents

- [CachyOS notes (read first)](#cachyos-notes-read-first)
- [1. Update the System](#1-update-the-system)
- [2. Install WezTerm](#2-install-wezterm)
- [3. Install the Nerd Font](#3-install-the-nerd-font)
- [4. Install ZSH and Set It as Default](#4-install-zsh-and-set-it-as-default)
- [5. Install CLI Tools](#5-install-cli-tools)
- [6. AUR Helper (optional)](#6-aur-helper-optional)
- [7. Prompt: Starship (default) or PowerLevel10k](#7-prompt-starship-default-or-powerlevel10k)
- [8. ZSH Plugins](#8-zsh-plugins)
- [9. Neovim + LazyVim, tmux + TPM](#9-neovim--lazyvim-tmux--tpm)
- [10. Deploy Config Files](#10-deploy-config-files)
- [11. Post-Install Verification](#11-post-install-verification)
- [Troubleshooting / FAQ](#troubleshooting--faq)
- [Reference: Aliases](#reference-aliases)
- [Reference: Functions](#reference-functions)
- [Reference: Keybindings](#reference-keybindings)

---

## CachyOS notes (read first)

If you're on **CachyOS**, two defaults differ from vanilla Arch:

| Topic | CachyOS | Vanilla Arch |
|-------|---------|--------------|
| Default shell | **fish** — you'll switch to ZSH in [step 4](#4-install-zsh-and-set-it-as-default) | bash |
| AUR helper | **`paru` preinstalled** — [step 6](#6-aur-helper-optional) is a no-op | none (bootstrap it) |
| Repos | CachyOS optimized repos + AUR + Flatpak already configured | official repos only |

Everything else in this guide is identical across Arch-based distros. Where a step is
CachyOS-specific, it's called out with a **CachyOS** note.

## 1. Update the System

Always sync and upgrade first (Arch is a rolling release — partial upgrades are unsupported):

```bash
sudo pacman -Syu
```

> **Vanilla Arch, fresh install:** if you hit signature/keyring errors, refresh the keyring
> first: `sudo pacman -Sy archlinux-keyring && sudo pacman -Su`. CachyOS additionally ships
> `cachyos-keyring`, kept current by the update above.

## 2. Install WezTerm

WezTerm is in the official **`extra`** repo:

```bash
sudo pacman -S --needed wezterm
```

> **Want the latest features (Wayland/Hyprland)?** The repo build can lag upstream. Use the
> AUR build instead once you have an [AUR helper](#6-aur-helper-optional):
> `paru -S wezterm-git`.

### Set WezTerm as the default terminal (optional)

```bash
# X11/most desktops — register and select the alternative
sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/wezterm 50
sudo update-alternatives --set x-terminal-emulator /usr/bin/wezterm
```

On GNOME/KDE you can also set the default terminal from the desktop's Settings, or bind a
keyboard shortcut to `wezterm`.

## 3. Install the Nerd Font

Unlike Debian/Ubuntu, the patched font is a single package in the **`extra`** repo — no
manual download, unzip, or `fc-cache`:

```bash
sudo pacman -S --needed ttf-jetbrains-mono-nerd
```

> WezTerm's config (deployed in [step 10](#10-deploy-config-files)) already requests
> `JetBrainsMono Nerd Font` with sensible fallbacks.

## 4. Install ZSH and Set It as Default

```bash
sudo pacman -S --needed zsh
```

Make it your login shell:

```bash
chsh -s "$(which zsh)"
```

Log out and back in (or reboot) for the change to take effect, then verify:

```bash
echo "$SHELL"
# Expected: /usr/bin/zsh
```

> **CachyOS:** your default shell is **fish**, so this `chsh` step is required to switch to
> ZSH. `echo $SHELL` will keep showing `/usr/bin/fish` until you start a fresh **login**
> session.

## 5. Install CLI Tools

The whole stack is in the official repos. One command:

```bash
sudo pacman -S --needed \
  eza fzf ripgrep fd bat tmux btop micro \
  neovim fastfetch zoxide starship \
  base-devel git curl wget unzip \
  zsh-autosuggestions zsh-syntax-highlighting
```

| Package | Provides | Purpose |
|---------|----------|---------|
| `eza` | `eza` | Modern `ls` (icons, git) |
| `fzf` | `fzf` | Fuzzy finder |
| `ripgrep` | `rg` | Fast grep |
| `fd` | `fd` | Fast find (native name — no `fdfind` rename) |
| `bat` | `bat` | `cat` with syntax highlighting (native name — no `batcat`) |
| `tmux` | `tmux` | Terminal multiplexer |
| `btop` | `btop` | System monitor |
| `micro` | `micro` | Terminal text editor |
| `neovim` | `nvim` | Editor / IDE base (LazyVim) |
| `fastfetch` | `fastfetch` | System info display |
| `zoxide` | `zoxide` | Smart `cd` |
| `starship` | `starship` | Prompt (default for this setup) |
| `base-devel` | `gcc`, `make`, `makepkg`… | C toolchain (nvim-treesitter, AUR builds) |
| `zsh-autosuggestions` / `zsh-syntax-highlighting` | `/usr/share/zsh/plugins/…` | ZSH plugins (sourced by the bundled `.zshrc`) |

### Verify

```bash
eza --version && fzf --version && rg --version && fd --version && bat --version
tmux -V && btop --version && micro --version && nvim --version
fastfetch --version && zoxide --version && starship --version && wezterm --version
```

## 6. AUR Helper (optional)

You **do not need the AUR** for this setup — every tool above is in the official repos. The
AUR is only useful for optional extras (e.g. `wezterm-git`, the `zsh-theme-powerlevel10k`
package).

- **CachyOS:** `paru` is **already installed** — skip this step.
- **Vanilla Arch:** bootstrap `paru` (or `yay`) once:

```bash
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd .. && rm -rf paru
```

After this, `paru -S <package>` installs from the official repos *and* the AUR.

## 7. Prompt: Starship (default) or PowerLevel10k

This setup uses **Starship** by default — it's already installed (step 5) and the bundled
`.zshrc` initializes it automatically. Nothing else to do.

### Optional: PowerLevel10k instead

`zsh-theme-powerlevel10k` is **not** in the official repos. Two ways to add it:

```bash
# A) Clone (matches the path the bundled .zshrc checks for)
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k

# B) AUR (requires an AUR helper from step 6)
paru -S zsh-theme-powerlevel10k
```

The bundled `.zshrc` sources `~/powerlevel10k/powerlevel10k.zsh-theme` **if present** (method
A). If you used the AUR package (method B), source its path instead by adding to `~/.zshrc.local`:

```bash
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
```

Run `p10k configure` to set it up. (When p10k is present it takes over from Starship, since
it loads last.)

## 8. ZSH Plugins

Installed via `pacman` in [step 5](#5-install-cli-tools) (`zsh-autosuggestions`,
`zsh-syntax-highlighting`). The bundled `.zshrc` sources them from Arch's path automatically:

```zsh
/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
```

> If those packages aren't installed, the `.zshrc` falls back to git-cloning the plugins into
> `~/.zsh/` on first run — so the prompt works either way.

## 9. Neovim + LazyVim, tmux + TPM

### LazyVim (Neovim IDE config)

`neovim` and `base-devel` were installed in step 5. Add the LazyVim starter:

```bash
# Back up any existing nvim config/state first
mv ~/.config/nvim{,.bak} 2>/dev/null
mv ~/.local/share/nvim{,.bak} 2>/dev/null
mv ~/.local/state/nvim{,.bak} 2>/dev/null
mv ~/.cache/nvim{,.bak} 2>/dev/null

git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
```

Launch `nvim` — LazyVim auto-installs plugins on first run.

### tmux Plugin Manager (TPM)

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

After deploying `.tmux.conf` ([step 10](#10-deploy-config-files)), open tmux and press
`Ctrl+a` then `I` (capital i) to install plugins.

## 10. Deploy Config Files

You can deploy the dotfiles two ways.

### Option A — the setup wizard (recommended)

From the repo root, run the interactive wizard and pick **Arch / CachyOS**:

```bash
./setup.sh configure
```

It symlinks the configs (backing up any existing files), and can install the `pacman`
packages and git components for you. Run `./setup.sh status` anytime to see what's in place.

### Option B — manual

From this directory, copy or symlink each config to its target:

```bash
SRC=~/projects/terminal-ricing/arch

cp "$SRC/.zshrc"                          ~/.zshrc
cp "$SRC/.ripgreprc"                      ~/.ripgreprc
cp "$SRC/.tmux.conf"                      ~/.tmux.conf
mkdir -p ~/.config/btop ~/.config/fastfetch ~/.config/wezterm
cp "$SRC/.config/btop/btop.conf"          ~/.config/btop/btop.conf
cp "$SRC/.config/fastfetch/config.jsonc"  ~/.config/fastfetch/config.jsonc
cp "$SRC/.config/starship.toml"           ~/.config/starship.toml
cp "$SRC/.config/wezterm/wezterm.lua"     ~/.config/wezterm/wezterm.lua
```

> **Tip:** swap `cp` for `ln -sf` to keep the deployed files in sync with the repo.

### CachyOS logo for fastfetch

The bundled fastfetch config uses the universal `arch` logo. On CachyOS, switch to the
CachyOS logo — first confirm your fastfetch ships it:

```bash
fastfetch --list-logos | grep -i cachy
```

If listed, edit `~/.config/fastfetch/config.jsonc` and set:

```jsonc
"source": "cachyos",
```

## 11. Post-Install Verification

Reload the shell:

```bash
source ~/.zshrc
```

| Check | Command | Expected |
|-------|---------|----------|
| ZSH is active | `echo $SHELL` | `/usr/bin/zsh` |
| Starship prompt | (visual) | Styled prompt with git info |
| eza works | `ls` | File listing with icons |
| fzf history | `Ctrl+R` | Fuzzy history search |
| zoxide works | `z` (after visiting dirs) | Smart directory jump |
| tmux works | `tmux` | Multiplexer session |
| btop works | `btop` | System monitor UI |
| fastfetch works | `fastfetch` | System info + Arch/CachyOS logo |
| micro works | `micro` | Terminal editor |
| neovim works | `nvim` | LazyVim IDE |
| Nerd Font renders | (visual) | Icons visible in prompt and `ls` |

---

## Troubleshooting / FAQ

### `echo $SHELL` still shows fish/bash after `chsh`

`chsh` only affects **new login sessions**. Fully log out and back in (or reboot). Verify the
change was saved:

```bash
grep "$USER" /etc/passwd
# should end in :/usr/bin/zsh
```

CachyOS ships **fish** as the default, so this is expected until you re-login.

### `paru: command not found` (vanilla Arch)

Vanilla Arch has no AUR helper by default. Bootstrap one — see
[step 6](#6-aur-helper-optional). CachyOS ships `paru` preinstalled.

### Icons show as squares / question marks

The Nerd Font isn't installed or WezTerm isn't using it.

1. `sudo pacman -S --needed ttf-jetbrains-mono-nerd`
2. Refresh the font cache: `fc-cache -fv`
3. Confirm WezTerm's font (in `~/.config/wezterm/wezterm.lua`):
   ```lua
   config.font = wezterm.font_with_fallback {
     'JetBrainsMono Nerd Font',
     'Fira Code',
     'monospace',
   }
   ```
4. Restart WezTerm.

### WezTerm: `Error: terminal "wezterm" is unknown` over SSH

The repo build sets `TERM=wezterm`, whose terminfo may be missing on remote hosts. Either
install `wezterm-git`, or add `set -g default-terminal "xterm-256color"` to `.tmux.conf`, or
copy the terminfo: `infocmp -x wezterm | ssh remote -- tic -x -`.

### `fastfetch: command not found` or no logo

Fastfetch is in the official repos: `sudo pacman -S --needed fastfetch`. If the logo looks
wrong, list available logos with `fastfetch --list-logos` and set `"source"` in
`~/.config/fastfetch/config.jsonc` accordingly (`arch`, or `cachyos` on CachyOS).

### Autosuggestions / syntax highlighting don't appear

Install the plugins: `sudo pacman -S --needed zsh-autosuggestions zsh-syntax-highlighting`,
then `source ~/.zshrc`. The bundled `.zshrc` sources them from `/usr/share/zsh/plugins/…`
(with a git-clone fallback to `~/.zsh/`).

### Both Starship and PowerLevel10k seem active

The `.zshrc` initializes Starship, then loads PowerLevel10k **last if it exists** — so p10k
wins when installed. For Starship only, don't install p10k (don't clone `~/powerlevel10k`).
For p10k, see [step 7](#7-prompt-starship-default-or-powerlevel10k).

### `pacman` signature / "invalid or corrupted package" errors

Refresh keyring and mirrors, then retry:

```bash
sudo pacman -Sy archlinux-keyring   # + cachyos-keyring on CachyOS
sudo pacman -Syu
```

### tmux plugins don't load

After deploying `.tmux.conf`: open `tmux`, press `Ctrl+a` then `I` (capital i), wait for TPM
to finish.

---

## Reference: Aliases

### File Listing (eza)

| Alias | Command |
|-------|---------|
| `ls` | `eza --icons --group-directories-first` |
| `ll` | `eza -la --icons --group-directories-first --git` |
| `la` | `eza -a --icons --group-directories-first` |
| `tree` | `eza --tree --icons --group-directories-first` |

### Enhanced Commands

| Alias | Replaces with |
|-------|---------------|
| `cat` | `bat --paging=always` |
| `find` | `fd` |
| `grep` | `rg` |
| `top` | `htop` (if installed) |

### Navigation

| Alias | Target |
|-------|--------|
| `..` / `...` / `....` | `cd ..` / `../..` / `../../..` |
| `home` | `cd ~` |
| `cd` | `z` (zoxide) |
| `cdi` | `zi` (zoxide interactive) |

### Git

| Alias | Command |
|-------|---------|
| `g` / `gs` | `git` / `git status` |
| `ga` / `gaa` | `git add` / `git add .` |
| `gc` / `gcm` | `git commit` / `git commit -m` |
| `gp` / `gpl` | `git push` / `git pull` |
| `gl` / `glo` | `git log --oneline` / `… --graph --decorate --all` |
| `gb` / `gch` | `git branch` / `git checkout` |
| `gd` / `gds` | `git diff` / `git diff --staged` |

### System (Arch / CachyOS)

| Alias | Command | Purpose |
|-------|---------|---------|
| `arch-update` | `sudo pacman -Syu` | Full system upgrade |
| `arch-clean` | `sudo pacman -Rns $(pacman -Qtdq)` | Remove orphan packages |
| `aur-update` | `paru -Sua` | Update AUR packages (if `paru` present) |
| `ports` | `ss -tuln` | Open ports |
| `listening` | `ss -tulnp \| grep LISTEN` | Listening sockets |
| `myip` / `localip` | `curl -s ifconfig.me` / local route IP | Public / local IP |
| `reload` | `source ~/.zshrc` | Reload shell config |

### Fastfetch

| Alias | Command |
|-------|---------|
| `ff` | `fastfetch` |
| `ff-full` | `fastfetch --config ~/.config/fastfetch/config.jsonc` |
| `ff-test` | `fastfetch` with a 3s timeout |

---

## Reference: Functions

| Function | Usage | Purpose |
|----------|-------|---------|
| `mkcd` | `mkcd dir` | Create directory and `cd` into it |
| `fzf_find` | `fzf_find` | Find and open files with fzf + bat preview |
| `fcd` | `fcd` | Navigate directories with fzf + eza preview |
| `fh` | `fh` | Search command history with fzf |
| `fkill` | `fkill` | Kill processes with fzf |
| `weather` | `weather [city]` | Show weather info |
| `backup` | `backup file` | Timestamped backup copy |
| `extract` | `extract file.zip` | Extract any archive format |
| `search` | `search pattern` | Search file contents with ripgrep |
| `publicip` | `publicip` | Show public IP and location |

---

## Reference: Keybindings

### ZSH

| Shortcut | Action |
|----------|--------|
| `Ctrl+Space` | Accept autosuggestion |
| `Ctrl+R` | Fuzzy history search (fzf) |
| `Ctrl+T` | Fuzzy file search (fzf) |
| `Alt+C` | Fuzzy cd (fzf) |

### WezTerm

| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+F` | Split pane horizontally |
| `Ctrl+Shift+D` | Split pane vertically |
| `Ctrl+Shift+Z` | Zoom/unzoom pane |
| `Ctrl+Shift+W` | Close current pane |

### tmux

| Shortcut | Action |
|----------|--------|
| `Ctrl+a \|` | Split horizontally |
| `Ctrl+a -` | Split vertically |
| `Ctrl+a I` | Install plugins (TPM) |

> WezTerm keybindings reflect this repo's `wezterm.lua`. If you changed the leader/mods,
> adjust accordingly.
