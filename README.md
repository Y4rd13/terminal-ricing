# Terminal Ricing - Kali Linux Setup

Complete setup for a modern terminal in Kali Linux with WezTerm, ZSH, and PowerLevel10k.

![Kali Linux Terminal](https://img.shields.io/badge/Kali-Linux-557C94?style=for-the-badge&logo=kalilinux&logoColor=white)
![WezTerm](https://img.shields.io/badge/WezTerm-4A90E2?style=for-the-badge)
![ZSH Shell](https://img.shields.io/badge/ZSH-Shell-1A2C34?style=for-the-badge)
![PowerLevel10k](https://img.shields.io/badge/PowerLevel10k-FF6B35?style=for-the-badge)

## Table of Contents

- [Features](#features)
- [WezTerm Installation](#wezterm-installation)
- [CLI Tools Installation](#cli-tools-installation)
- [ZSH Configuration](#zsh-configuration)
- [PowerLevel10k Setup](#powerlevel10k-setup)
- [WezTerm Configuration](#wezterm-configuration)
- [Fastfetch Configuration](#fastfetch-configuration)
- [Set WezTerm as Default](#set-wezterm-as-default)
- [Themes](#themes)
- [Aliases and Functions](#aliases-and-functions)

## Features

- **WezTerm** - GPU-accelerated terminal emulator
- **ZSH Shell** - Advanced shell with autocompletion
- **PowerLevel10k** - Customizable prompt
- **Fastfetch** - System info with Kali logo
- **Modern CLI tools** - eza, bat, ripgrep, fzf, fd, tmux, btop
- **Themes** - Tokyo Night, Catppuccin, Nord, Dracula
- **Nerd Fonts** - JetBrains Mono with icons

## WezTerm Installation

### Method 1: APT Repository

```bash
# Add WezTerm GPG key
curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg

# Add repository
echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list

# Update and install
sudo apt update
sudo apt install wezterm
```

### Method 2: Flatpak

```bash
# Install Flatpak if not available
sudo apt install flatpak

# Add Flathub
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install WezTerm
flatpak install flathub org.wezfurlong.wezterm
```

## CLI Tools Installation

### Essential Tools

```bash
# Update system
sudo apt update

# Modern CLI tools
sudo apt install eza bat fd-find ripgrep fzf htop curl git zsh tmux exa btop

# Install cargo (Rust package manager)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Install tldr-py (better man pages)
pip3 install tldr

# Fastfetch - Kali Linux
sudo apt install fastfetch

# Fastfetch - Ubuntu (if not available in repos)
sudo add-apt-repository ppa:zhangsongcui3371/fastfetch
sudo apt update
sudo apt install fastfetch

# Verify installation
eza --version
bat --version
fd --version
rg --version
fzf --version
fastfetch --version
zsh --version
tmux -V
btop --version
```

### Install Nerd Fonts

```bash
# Create fonts directory
mkdir -p ~/.local/share/fonts

# Download JetBrains Mono Nerd Font
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip

# Extract and install
unzip JetBrainsMono.zip -d ~/.local/share/fonts/
fc-cache -fv

# Clean up
rm JetBrainsMono.zip
```

## ZSH Configuration

### Install ZSH

```bash
# Install ZSH
sudo apt install zsh

# Change default shell
chsh -s $(which zsh)

# Restart session to apply changes
```

### ZSH Configuration

**Replace your `~/.zshrc` file with the one from this repository.**

The configuration includes:

- Complete aliases and functions
- Key bindings
- Environment variables
- Plugin management (autosuggestions, syntax highlighting)
- PowerLevel10k integration

## PowerLevel10k Setup

### PowerLevel10k Installation

```bash
# Clone repository
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k

# Source is already included in the repository .zshrc file
# Reload configuration
source ~/.zshrc
```

### Initial Configuration

```bash
# Run configuration wizard
p10k configure
```

**Recommended options:**

- ✅ Diamond icons
- ✅ Unicode characters
- ✅ 24-bit colors
- ✅ Instant prompt
- ✅ Transient prompt (optional)

### Useful PowerLevel10k Commands

```bash
p10k configure    # Reconfigure prompt
p10k reload       # Reload configuration
p10k display      # Show current configuration
```

## 🎨 WezTerm Configuration

### Create WezTerm Configuration

**Replace `~/.config/wezterm/wezterm.lua` with the file from this repository.**

The configuration includes:

- Dracula theme (Tokyo Night available)
- ZSH as default shell
- Custom keybindings for panes and navigation
- Transparency and blur effects
- tmux integration
- Startup behavior with btop sidebar

### Key Features

- `config.default_prog = { '/usr/bin/zsh', '-l' }` - ZSH as default shell
- Dracula theme configured
- Keybindings for panels and navigation
- Transparency and blur effects
- Automatic btop sidebar on startup

## 🖼️ Fastfetch Configuration

### Configure Fastfetch with Kali Logo

**Replace `~/.config/fastfetch/config.jsonc` with the file from this repository.**

The configuration includes:

- Kali Linux logo
- Informative modules
- Custom colors
- Clean layout

### Fastfetch Aliases

```bash
ff              # normal fastfetch
ff-full         # complete configuration
ff-min          # minimal configuration
ff-test         # test with timeout
```

## ⚙️ Set WezTerm as Default Terminal

### GUI Method (Recommended)

```bash
# Open preferred applications settings
exo-preferred-applications
```

1. Go to **"Utilities"** → **"Terminal Emulator"**
2. Select **WezTerm**
3. Click **"Close"**

### CLI Method

```bash
# Add WezTerm to alternatives
sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/wezterm 50

# Set as default
sudo update-alternatives --set x-terminal-emulator /usr/bin/wezterm
```

## 🎭 Themes and Customization

### Popular WezTerm Themes

**Replace in `~/.config/wezterm/wezterm.lua` from this repository:**

```lua
-- Available themes in the configuration file:
config.color_scheme = 'Dracula'           -- Purple classic (default)
-- config.color_scheme = 'Tokyo Night'    -- Dark modern
-- config.color_scheme = 'Catppuccin Mocha' -- Dark pastel
-- config.color_scheme = 'Nord'           -- Cool blue
-- config.color_scheme = 'Gruvbox Dark'   -- Warm retro
-- config.color_scheme = 'One Dark'       -- VSCode style
```

### PowerLevel10k Themes

```bash
# Change PowerLevel10k style
p10k configure

# Popular styles:
# - Lean (minimalist)
# - Classic (complete information)
# - Rainbow (colorful)
# - Pure (pure prompt style)
```

## 🔗 Aliases and Functions

### Main Aliases in ZSH

Based on the actual `.zshrc` configuration file:

#### File Listing (eza/exa)

```bash
ls          # eza with icons and grouped directories
ll          # detailed list with git info
la          # show all files including hidden
tree        # tree view with icons
```

#### Enhanced Commands

```bash
cat         # bat with syntax highlighting
find        # fd for fast file search
grep        # ripgrep (rg) super fast search
top         # htop interactive process viewer
```

#### Git Shortcuts

```bash
g           # git
gs          # git status
ga          # git add
gaa         # git add all
gc          # git commit
gcm         # git commit -m
gp          # git push
gpl         # git pull
gl          # git log --oneline
glo         # git log --oneline --graph --decorate --all
gb          # git branch
gch         # git checkout
gd          # git diff
gds         # git diff --staged
```

#### Quick Navigation

```bash
..          # cd ..
...         # cd ../..
....        # cd ../../..
home        # cd ~
desktop     # cd ~/Desktop
downloads   # cd ~/Downloads
documents   # cd ~/Documents
```

#### Kali Linux Specific

```bash
kali-update     # apt update && upgrade
kali-clean      # apt autoclean && autoremove
ports           # netstat -tuln
myip            # curl ifconfig.me
localip         # show local IP
listening       # show listening ports
```

#### Penetration Testing

```bash
nmap-quick      # nmap -T4 -F
nmap-full       # nmap -T4 -A -v
nmap-vuln       # nmap --script vuln
gobuster-common # gobuster with common wordlist
nikto-scan      # nikto -h
```

#### Development

```bash
python      # python3
pip         # pip3
serve       # python HTTP server on port 8000
server      # python HTTP server
venv        # python3 -m venv
```

#### Docker (if available)

```bash
d           # docker
dc          # docker-compose
dps         # docker ps
di          # docker images
drm         # docker rm
drmi        # docker rmi
dclean      # docker system prune -f
```

#### System Utilities

```bash
h           # history
j           # jobs
c           # clear
e           # exit
r           # reset
reload      # source ~/.zshrc
zshconfig   # edit ~/.zshrc
wezconfig   # edit wezterm config
```

#### Fastfetch

```bash
ff          # fastfetch
ff-full     # complete configuration
ff-stable   # stable configuration
ff-min      # minimal configuration
ff-test     # fastfetch with timeout
```

#### Editors

```bash
vim         # nvim (if available)
vi          # nvim (if available)
v           # nvim (if available)
```

### Useful Functions in ZSH

Based on the actual `.zshrc` configuration:

```bash
mkcd dirname        # Create directory and enter
fzf_find           # Find files with fzf
fcd                # Change directory with fzf
fh                 # Search history with fzf
fkill              # Kill processes with fzf
weather city       # Weather information
backup file        # Backup with timestamp
extract file.zip   # Extract any archive
search text        # Search in files with rg
publicip          # Show public IP and location
portscan IP       # Quick port scan
up text           # Convert to uppercase
low text          # Convert to lowercase
diagnose_fastfetch # Diagnose fastfetch issues
```

## Additional Configuration Files

The repository includes these configuration files ready to use:

### tmux Configuration

**File:** `~/.tmux.conf`

- TPM plugin manager
- Custom prefix (Ctrl+a)
- Split shortcuts (| and -)

### Starship Configuration

**File:** `~/.config/starship.toml`

- Tokyo Night theme
- Custom format with git integration
- Performance optimized

### Ripgrep Configuration

**File:** `~/.ripgreprc`

- Smart case search
- Hidden file support
- Color configuration

### btop Configuration

**File:** `~/.config/btop/btop.conf`

- Dracula theme
- Optimized performance settings
- Custom layout

---

## Quick Setup

**Stack:**

- WezTerm + ZSH + PowerLevel10k
- Modern CLI: eza, bat, rg, fzf, fd, tmux, btop
- Dracula/Tokyo Night themes
- JetBrains Mono Nerd Font
- Fastfetch with Kali logo

**Post-installation:**

1. Replace all config files with repository versions
2. `source ~/.zshrc`
3. `p10k configure`
4. Restart terminal

---

**Version:** 3.0 - Complete Modern Terminal Setup  
**Compatibility:** Kali Linux x86_64
