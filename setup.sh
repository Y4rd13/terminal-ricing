#!/usr/bin/env bash
set -euo pipefail

# ── Constants & colors ──────────────────────────────────────────

VERSION="1.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RST='\033[0m'
BLD='\033[1m'
DIM='\033[2m'
MAG='\033[38;5;47m'       # matrix green
CYN='\033[38;5;34m'       # dark terminal green
YLW='\033[38;5;226m'      # neon yellow
GRN='\033[38;5;46m'       # bright green
RED='\033[38;5;196m'      # neon red
ORG='\033[38;5;208m'      # neon orange
WHT='\033[38;5;255m'      # bright white
GRY='\033[38;5;240m'      # dark gray
LIM='\033[38;5;118m'      # lime green
BGMAG='\033[48;5;22m'     # bg dark green
BGCYN='\033[48;5;28m'     # bg terminal green

# ── Platform profiles ───────────────────────────────────────────

PLATFORMS=(
    "ubuntu-wsl:Ubuntu on WSL2:WSL + WezTerm (Windows side) + ZSH + P10K"
    "linux:Native Linux:Kali/Ubuntu/Debian + WezTerm + ZSH + Starship"
    "arch:Arch / CachyOS:Arch-based + WezTerm + ZSH + Starship (pacman)"
)

# ── Dotfiles per platform ───────────────────────────────────────
# Format: "source_relative:target_absolute:description:requires"
# requires = comma-separated list of commands that must exist, or empty

DOTFILES_UBUNTU_WSL=(
    ".zshrc:~/.zshrc:ZSH config (aliases, functions, plugins, p10k):zsh"
    ".zprofile:~/.zprofile:ZSH profile (runs fastfetch on startup):zsh,fastfetch"
    ".p10k.zsh:~/.p10k.zsh:PowerLevel10k theme config:zsh"
    ".ripgreprc:~/.ripgreprc:Ripgrep defaults (smart-case, colors):rg"
    ".tmux.conf:~/.tmux.conf:Tmux config (prefix Ctrl+a, TPM plugins):tmux"
    ".config/btop/btop.conf:~/.config/btop/btop.conf:Btop system monitor config:btop"
    ".config/fastfetch/config.jsonc:~/.config/fastfetch/config.jsonc:Fastfetch display config:fastfetch"
    ".config/wezterm/wezterm.lua:~/.config/wezterm/wezterm.lua:WezTerm terminal config (runs on Windows side):"
)

DOTFILES_LINUX=(
    ".zshrc:~/.zshrc:ZSH config (aliases, functions, plugins, starship):zsh"
    ".ripgreprc:~/.ripgreprc:Ripgrep defaults (smart-case, colors):rg"
    ".tmux.conf:~/.tmux.conf:Tmux config (prefix Ctrl+a, TPM plugins):tmux"
    ".config/btop/btop.conf:~/.config/btop/btop.conf:Btop system monitor config:btop"
    ".config/fastfetch/config.jsonc:~/.config/fastfetch/config.jsonc:Fastfetch display config:fastfetch"
    ".config/starship.toml:~/.config/starship.toml:Starship prompt theme:starship"
    ".config/wezterm/wezterm.lua:~/.config/wezterm/wezterm.lua:WezTerm terminal config:wezterm"
)

# Arch ships the same dotfiles as the native-linux profile (Starship-based).
DOTFILES_ARCH=(
    ".zshrc:~/.zshrc:ZSH config (aliases, functions, plugins, starship):zsh"
    ".ripgreprc:~/.ripgreprc:Ripgrep defaults (smart-case, colors):rg"
    ".tmux.conf:~/.tmux.conf:Tmux config (prefix Ctrl+a, TPM plugins):tmux"
    ".config/btop/btop.conf:~/.config/btop/btop.conf:Btop system monitor config:btop"
    ".config/fastfetch/config.jsonc:~/.config/fastfetch/config.jsonc:Fastfetch display config:fastfetch"
    ".config/starship.toml:~/.config/starship.toml:Starship prompt theme:starship"
    ".config/wezterm/wezterm.lua:~/.config/wezterm/wezterm.lua:WezTerm terminal config:wezterm"
)

# ── Tools to install ────────────────────────────────────────────
# Format: "name:description:check_cmd:install_cmd"

APT_TOOLS=(
    "zsh:Shell:zsh:sudo apt install -y zsh"
    "eza:Modern ls replacement:eza:sudo apt install -y eza"
    "fzf:Fuzzy finder:fzf:sudo apt install -y fzf"
    "ripgrep:Fast grep (rg):rg:sudo apt install -y ripgrep"
    "fd-find:Fast find (fd):fdfind:sudo apt install -y fd-find"
    "tmux:Terminal multiplexer:tmux:sudo apt install -y tmux"
    "btop:System monitor:btop:sudo apt install -y btop"
    "micro:Terminal text editor:micro:sudo apt install -y micro"
    "build-essential:C compiler (for treesitter):gcc:sudo apt install -y build-essential"
    "curl:HTTP client:curl:sudo apt install -y curl"
    "git:Version control:git:sudo apt install -y git"
    "unzip:Archive extractor:unzip:sudo apt install -y unzip"
)

EXTRA_TOOLS=(
    "fastfetch:System info display:fastfetch:sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch && sudo apt update && sudo apt install -y fastfetch"
    "zoxide:Smart cd:zoxide:curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh"
    "neovim:Text editor/IDE:nvim:curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz && sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz && sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim && rm nvim-linux-x86_64.tar.gz"
)

# shellcheck disable=SC2034  # used by name via prompt_multi_select / nameref dispatch
GIT_COMPONENTS=(
    "powerlevel10k:Prompt theme:~/powerlevel10k:git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k"
    "zsh-autosuggestions:ZSH plugin:~/.zsh/zsh-autosuggestions:git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions"
    "zsh-syntax-highlighting:ZSH plugin:~/.zsh/zsh-syntax-highlighting:git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting"
    "tpm:Tmux plugin manager:~/.tmux/plugins/tpm:git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm"
    "lazyvim:Neovim IDE config:~/.config/nvim:git clone https://github.com/LazyVim/starter ~/.config/nvim && rm -rf ~/.config/nvim/.git"
    "nerd-fonts:JetBrains Mono Nerd Font:~/.local/share/fonts/JetBrainsMonoNerdFont-Regular.ttf:mkdir -p ~/.local/share/fonts && cd /tmp && wget -q https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip && unzip -o JetBrainsMono.zip -d ~/.local/share/fonts/ && fc-cache -fv && rm JetBrainsMono.zip"
)

# ── Arch / CachyOS: pacman packages ─────────────────────────────
# Everything below is in the official repos (core/extra) — no AUR needed.
# Format: "name:description:check_cmd:install_cmd" (name == pacman package).

PACMAN_TOOLS=(
    "zsh:Shell:zsh:sudo pacman -S --needed --noconfirm zsh"
    "eza:Modern ls replacement:eza:sudo pacman -S --needed --noconfirm eza"
    "fzf:Fuzzy finder:fzf:sudo pacman -S --needed --noconfirm fzf"
    "ripgrep:Fast grep (rg):rg:sudo pacman -S --needed --noconfirm ripgrep"
    "fd:Fast find:fd:sudo pacman -S --needed --noconfirm fd"
    "bat:cat with syntax highlighting:bat:sudo pacman -S --needed --noconfirm bat"
    "tmux:Terminal multiplexer:tmux:sudo pacman -S --needed --noconfirm tmux"
    "btop:System monitor:btop:sudo pacman -S --needed --noconfirm btop"
    "micro:Terminal text editor:micro:sudo pacman -S --needed --noconfirm micro"
    "base-devel:Build tools (treesitter/AUR):gcc:sudo pacman -S --needed --noconfirm base-devel"
    "git:Version control:git:sudo pacman -S --needed --noconfirm git"
    "curl:HTTP client:curl:sudo pacman -S --needed --noconfirm curl"
    "unzip:Archive extractor:unzip:sudo pacman -S --needed --noconfirm unzip"
)

PACMAN_EXTRA=(
    "fastfetch:System info display:fastfetch:sudo pacman -S --needed --noconfirm fastfetch"
    "zoxide:Smart cd:zoxide:sudo pacman -S --needed --noconfirm zoxide"
    "neovim:Text editor/IDE:nvim:sudo pacman -S --needed --noconfirm neovim"
    "starship:Prompt theme:starship:sudo pacman -S --needed --noconfirm starship"
    "wezterm:Terminal emulator:wezterm:sudo pacman -S --needed --noconfirm wezterm"
    "ttf-jetbrains-mono-nerd:JetBrains Mono Nerd Font::sudo pacman -S --needed --noconfirm ttf-jetbrains-mono-nerd"
    "zsh-autosuggestions:ZSH plugin::sudo pacman -S --needed --noconfirm zsh-autosuggestions"
    "zsh-syntax-highlighting:ZSH plugin::sudo pacman -S --needed --noconfirm zsh-syntax-highlighting"
)

# Components installed outside pacman (git clones). Nerd font + zsh plugins are
# pacman packages on Arch, so they live in PACMAN_EXTRA, not here. PowerLevel10k
# is omitted so the default prompt stays Starship (see arch/README.md).
# shellcheck disable=SC2034  # used by name via prompt_multi_select / nameref dispatch
ARCH_COMPONENTS=(
    "tpm:Tmux plugin manager:~/.tmux/plugins/tpm:git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm"
    "lazyvim:Neovim IDE config:~/.config/nvim:git clone https://github.com/LazyVim/starter ~/.config/nvim && rm -rf ~/.config/nvim/.git"
)

# ── User selections ─────────────────────────────────────────────

SELECTED_PLATFORM=""
PLATFORM_DIR=""
PKG_MGR=""
CONFLICT_POLICY=""
declare -A SEL_DOTFILES=()
declare -A SEL_APT_TOOLS=()
declare -A SEL_EXTRA_TOOLS=()
declare -A SEL_GIT_COMPONENTS=()
declare -A SEL_PACMAN_TOOLS=()
declare -A SEL_PACMAN_EXTRA=()
declare -A SEL_ARCH_COMPONENTS=()
SEL_SET_ZSH_DEFAULT=0

# ── Terminal control ────────────────────────────────────────────

BANNER_END_ROW=0
CONTENT_START_ROW=0

hide_cursor() { printf '\033[?25l'; }
show_cursor() { printf '\033[?25h'; }
clear_screen() { printf '\033[2J\033[H'; }
move_to() { printf '\033[%d;%dH' "$1" "$2"; }
clear_line() { printf '\033[2K'; }
clear_from_cursor() { printf '\033[J'; }
save_pos() { printf '\033[s'; }
restore_pos() { printf '\033[u'; }

cleanup() {
    show_cursor
    stty echo 2>/dev/null || true
}
trap cleanup EXIT

read_key() {
    local key
    IFS= read -rsn1 key 2>/dev/null || true
    if [[ "$key" == $'\x1b' ]]; then
        local seq
        IFS= read -rsn2 -t 0.1 seq 2>/dev/null || true
        case "$seq" in
            '[A') echo "UP" ;;
            '[B') echo "DOWN" ;;
            '[C') echo "RIGHT" ;;
            '[D') echo "LEFT" ;;
            *)    echo "ESC" ;;
        esac
    elif [[ "$key" == "" ]]; then
        echo "ENTER"
    elif [[ "$key" == " " ]]; then
        echo "SPACE"
    elif [[ "$key" == "q" || "$key" == "Q" ]]; then
        echo "QUIT"
    else
        echo "$key"
    fi
}

# ── UI helpers ──────────────────────────────────────────────────

info()  { echo -e "  ${CYN}▸${RST} $1"; }
ok()    { echo -e "  ${GRN}✓${RST} $1"; }
warn()  { echo -e "  ${ORG}⚠${RST}  $1"; }
err()   { echo -e "  ${RED}✗${RST} $1"; }
dimm()  { echo -e "  ${GRY}$1${RST}"; }

hr() {
    local char="${1:-─}"
    local color="${2:-$GRY}"
    local w=58
    local line=""
    for ((i=0; i<w; i++)); do line+="$char"; done
    echo -e "  ${color}${line}${RST}"
}

detect_env() {
    DETECTED_OS="Linux"
    if grep -qi microsoft /proc/version 2>/dev/null; then
        DETECTED_OS="WSL"
    elif [[ "${OSTYPE:-}" == "darwin"* ]]; then
        DETECTED_OS="macOS"
    elif [[ "${OSTYPE:-}" == "msys" || "${OSTYPE:-}" == "mingw"* ]]; then
        DETECTED_OS="Windows (Git Bash)"
    fi
    DETECTED_SHELL="$(basename "${SHELL:-unknown}")"
}

draw_banner() {
    detect_env
    clear_screen
    echo ""
    echo -e "  ${MAG}${BLD} ██╗   ██╗ ██╗  ██████╗ ██████╗   ██╗ ██████╗ ${RST}"
    echo -e "  ${MAG}${BLD} ╚██╗ ██╔╝ ██║  ██╔══██╗██╔══██╗ ███║ ╚════██╗${RST}"
    echo -e "  ${LIM}${BLD}  ╚████╔╝  ████████████╔╝██║  ██║ ╚██║  █████╔╝${RST}"
    echo -e "  ${LIM}${BLD}   ╚██╔╝   ╚════██╔══██╗██║  ██║  ██║  ╚═══██╗${RST}"
    echo -e "  ${CYN}${BLD}    ██║         ██║██║  ██║██████╔╝ ██║ ██████╔╝${RST}"
    echo -e "  ${GRY}    ╚═╝         ╚═╝╚═╝  ╚═╝╚═════╝  ╚═╝ ╚═════╝ ${RST}"
    echo ""
    echo -e "  ${GRY}┌──────────────────────────────────────────────────────┐${RST}"
    echo -e "  ${GRY}│${RST}  ${LIM}${BLD}T E R M I N A L   R I C I N G${RST}  ${GRY}///${RST} ${MAG}Setup${RST} ${DIM}v${VERSION}${RST}      ${GRY}│${RST}"
    echo -e "  ${GRY}├──────────────────────────────────────────────────────┤${RST}"
    printf "  ${GRY}│${RST}  ${GRY}SYS${RST} ${WHT}%-12s${RST} ${GRY}SHELL${RST} ${WHT}%-8s${RST} ${GRY}HOME${RST} ${LIM}~/${RST}         ${GRY}│${RST}\n" "$DETECTED_OS" "$DETECTED_SHELL"
    echo -e "  ${GRY}└──────────────────────────────────────────────────────┘${RST}"

    BANNER_END_ROW=15
    CONTENT_START_ROW=16
}

clear_content() {
    move_to "$CONTENT_START_ROW" 1
    clear_from_cursor
    move_to "$CONTENT_START_ROW" 1
}

section_header() {
    local title="$1"
    clear_content
    hr "━" "$MAG"
    echo -e "  ${MAG}${BLD}▌${RST} ${CYN}${BLD}${title}${RST}"
    hr "━" "$MAG"
}

# ── Arrow-key prompts ───────────────────────────────────────────

prompt_yn() {
    local question="$1"
    local detail="${2:-}"
    local selected=0

    echo ""
    echo -e "  ${WHT}${BLD}${question}${RST}"
    [[ -n "$detail" ]] && echo -e "  ${GRY}${detail}${RST}"
    echo ""

    hide_cursor
    while true; do
        save_pos
        clear_line
        if [[ $selected -eq 0 ]]; then
            echo -ne "  ${BGCYN}${BLD} YES ${RST}  ${GRY} NO ${RST}    ${DIM}← → select, enter confirm${RST}"
        else
            echo -ne "  ${GRY} YES ${RST}  ${BGMAG}${BLD} NO ${RST}    ${DIM}← → select, enter confirm${RST}"
        fi
        restore_pos

        local key
        key=$(read_key)
        case "$key" in
            LEFT|RIGHT|h|l) selected=$(( 1 - selected )) ;;
            ENTER)
                show_cursor
                clear_line
                [[ $selected -eq 0 ]] && echo -e "  ${GRN}▸ Yes${RST}" || echo -e "  ${RED}▸ No${RST}"
                return $selected
                ;;
            QUIT) show_cursor; echo -e "\n  ${ORG}Aborted.${RST}\n"; exit 0 ;;
        esac
    done
}

prompt_select() {
    local question="$1"
    shift
    local options=("$@")
    local selected=0
    local count=${#options[@]}

    echo ""
    echo -e "  ${WHT}${BLD}${question}${RST}"
    echo ""

    hide_cursor
    while true; do
        save_pos
        local i=0
        for opt in "${options[@]}"; do
            clear_line
            if [[ $i -eq $selected ]]; then
                echo -e "    ${CYN}${BLD}▸${RST} ${BGCYN}${BLD} ${opt} ${RST}"
            else
                echo -e "    ${GRY}  ${opt}${RST}"
            fi
            (( i++ )) || true
        done
        clear_line
        echo ""
        clear_line
        echo -ne "  ${DIM}↑↓ select, enter confirm${RST}"
        restore_pos

        local key
        key=$(read_key)
        case "$key" in
            UP|k)   (( selected > 0 )) && (( selected-- )) || true ;;
            DOWN|j) (( selected < count - 1 )) && (( selected++ )) || true ;;
            ENTER)
                show_cursor
                local j=0
                for _ in "${options[@]}"; do clear_line; echo ""; (( j++ )) || true; done
                clear_line; echo ""; clear_line
                restore_pos
                echo -e "  ${GRN}▸ ${options[$selected]}${RST}"
                echo ""
                REPLY=$(( selected + 1 ))
                return 0
                ;;
            QUIT) show_cursor; echo -e "\n  ${ORG}Aborted.${RST}\n"; exit 0 ;;
        esac
    done
}

# Generic multi-select TUI
# Args: title, array_name (items "key:desc:extra"), selection_assoc_array_name, check_fn
prompt_multi_select() {
    local title="$1"
    local -n items_ref=$2
    local -n sel_ref=$3
    local check_fn="${4:-}"

    local total=${#items_ref[@]}
    local menu_size=$(( 1 + total ))
    local cursor=0

    # Init all selected
    for entry in "${items_ref[@]}"; do
        local key="${entry%%:*}"
        sel_ref[$key]=1
    done

    draw_menu() {
        move_to "$CONTENT_START_ROW" 1
        clear_from_cursor

        hr "━" "$MAG"
        echo -e "  ${MAG}${BLD}▌${RST} ${CYN}${BLD}${title}${RST}"
        hr "━" "$MAG"
        echo ""

        # All toggle
        local all_on=1
        for entry in "${items_ref[@]}"; do
            local k="${entry%%:*}"
            [[ "${sel_ref[$k]:-0}" != "1" ]] && all_on=0 && break
        done
        local all_mark="${GRY}○${RST}"
        [[ "$all_on" == "1" ]] && all_mark="${GRN}●${RST}"
        if [[ $cursor -eq 0 ]]; then
            echo -e "    ${CYN}▸${RST} ${all_mark} ${BLD}${WHT}All${RST}"
        else
            echo -e "      ${all_mark} ${GRY}All${RST}"
        fi

        echo ""

        local idx=0
        for entry in "${items_ref[@]}"; do
            IFS=':' read -r key desc extra _ <<< "$entry"
            local mark="${GRY}○${RST}"
            [[ "${sel_ref[$key]:-0}" == "1" ]] && mark="${CYN}●${RST}"

            # Check if already installed
            local status_tag=""
            if [[ -n "$check_fn" ]]; then
                local check_result
                check_result=$($check_fn "$key" "$entry" 2>/dev/null || echo "")
                [[ "$check_result" == "installed" ]] && status_tag=" ${GRY}⟨installed⟩${RST}"
            fi

            local menu_idx=$(( 1 + idx ))
            if [[ $cursor -eq $menu_idx ]]; then
                printf "    ${CYN}▸${RST} %b ${WHT}${BLD}%-26s${RST} ${GRY}%s${RST}%b\n" "$mark" "$key" "$desc" "$status_tag"
            else
                printf "      %b ${GRY}%-26s %s${RST}%b\n" "$mark" "$key" "$desc" "$status_tag"
            fi
            (( idx++ )) || true
        done

        echo ""
        echo -e "  ${DIM}↑↓ move  ␣ toggle  enter confirm  q quit${RST}"
    }

    hide_cursor
    draw_menu

    while true; do
        draw_menu

        local key
        key=$(read_key)
        case "$key" in
            UP|k)   (( cursor > 0 )) && (( cursor-- )) || true ;;
            DOWN|j) (( cursor < menu_size - 1 )) && (( cursor++ )) || true ;;
            SPACE)
                if [[ $cursor -eq 0 ]]; then
                    local all_on=1
                    for entry in "${items_ref[@]}"; do
                        local k="${entry%%:*}"
                        [[ "${sel_ref[$k]:-0}" != "1" ]] && all_on=0 && break
                    done
                    local nv=1; [[ "$all_on" == "1" ]] && nv=0
                    for entry in "${items_ref[@]}"; do
                        local k="${entry%%:*}"
                        sel_ref[$k]=$nv
                    done
                else
                    local si=$(( cursor - 1 ))
                    local entry="${items_ref[$si]}"
                    local k="${entry%%:*}"
                    [[ "${sel_ref[$k]:-0}" == "1" ]] && sel_ref[$k]=0 || sel_ref[$k]=1
                fi
                ;;
            ENTER) show_cursor; return 0 ;;
            QUIT) show_cursor; echo -e "\n  ${ORG}Aborted.${RST}\n"; exit 0 ;;
        esac
    done
}

# ── Check functions for install status ──────────────────────────

check_apt_tool() {
    local key="$1"
    local entry="$2"
    IFS=':' read -r _ _ check_cmd _ <<< "$entry"
    command -v "$check_cmd" &>/dev/null && echo "installed" || echo ""
}

check_extra_tool() {
    check_apt_tool "$1" "$2"
}

check_git_component() {
    local key="$1"
    local entry="$2"
    IFS=':' read -r _ _ check_path _ <<< "$entry"
    local expanded="${check_path/#\~/$HOME}"
    [[ -e "$expanded" ]] && echo "installed" || echo ""
}

check_pacman_tool() {
    local key="$1"
    # Query the local package DB by name (covers tools, fonts and plugins);
    # falls back to a group query for meta-packages like base-devel.
    { pacman -Qq "$key" || pacman -Qqg "$key"; } &>/dev/null && echo "installed" || echo ""
}

# Populate the nameref array with the selected platform's dotfiles.
get_platform_dotfiles() {
    local -n _out=$1
    case "$SELECTED_PLATFORM" in
        ubuntu-wsl) _out=("${DOTFILES_UBUNTU_WSL[@]}") ;;
        linux)      _out=("${DOTFILES_LINUX[@]}") ;;
        arch)       _out=("${DOTFILES_ARCH[@]}") ;;
    esac
}

# ── Symlink / copy engine ───────────────────────────────────────

init_backup_dir() {
    if [[ -z "${BACKUP_DIR:-}" ]]; then
        BACKUP_DIR="$HOME/.terminal-ricing-backup-$(date +%Y%m%d-%H%M%S)"
    fi
}

backup_item() {
    local target="$1"
    init_backup_dir
    mkdir -p "$BACKUP_DIR"
    local rel="${target#$HOME/}"
    local backup_path="$BACKUP_DIR/$rel"
    mkdir -p "$(dirname "$backup_path")"
    if [[ -L "$target" ]]; then
        rm "$target"
    else
        mv "$target" "$backup_path"
        warn "Backed up: ~/${rel}"
    fi
}

handle_conflict() {
    local target="$1"
    local source="$2"

    [[ ! -e "$target" && ! -L "$target" ]] && return 0

    case "$CONFLICT_POLICY" in
        skip)
            dimm "Skipped: ${target/#$HOME/~} (exists)"
            return 1
            ;;
        overwrite)
            backup_item "$target"
            return 0
            ;;
        ask)
            local display="${target/#$HOME/~}"
            echo ""
            echo -e "  ${ORG}${display} already exists${RST}"
            show_cursor
            prompt_select "Action:" "Skip" "Overwrite (backup first)" "Show diff"
            case "$REPLY" in
                1) dimm "Skipped: ${display}"; return 1 ;;
                2) backup_item "$target"; return 0 ;;
                3)
                    echo ""
                    if [[ -L "$target" ]]; then
                        dimm "Current: symlink → $(readlink "$target")"
                        dimm "New:     symlink → ${source}"
                    else
                        diff --color=always "$target" "$source" 2>/dev/null || true
                    fi
                    echo ""
                    prompt_select "Now what?" "Skip" "Overwrite (backup first)"
                    case "$REPLY" in
                        1) dimm "Skipped: ${display}"; return 1 ;;
                        2) backup_item "$target"; return 0 ;;
                    esac
                    ;;
            esac
            ;;
    esac
}

deploy_dotfile() {
    local src="$1"
    local dst="$2"

    if [[ ! -e "$src" ]]; then
        err "Source not found: $src"
        return 1
    fi

    if handle_conflict "$dst" "$src"; then
        mkdir -p "$(dirname "$dst")"
        ln -sf "$src" "$dst"
        ok "Linked: ${CYN}${dst/#$HOME/~}${RST} → ${MAG}${src/#$SCRIPT_DIR\//}${RST}"
    fi
}

# ── Wizard steps ────────────────────────────────────────────────

step_welcome() {
    draw_banner
}

step_platform() {
    section_header "PLATFORM"

    local opts=()
    for p in "${PLATFORMS[@]}"; do
        IFS=':' read -r _key label desc <<< "$p"
        opts+=("${label} — ${desc}")
    done

    prompt_select "Select your platform:" "${opts[@]}"

    case "$REPLY" in
        1) SELECTED_PLATFORM="ubuntu-wsl"; PLATFORM_DIR="$SCRIPT_DIR/ubuntu-wsl"; PKG_MGR="apt" ;;
        2) SELECTED_PLATFORM="linux"; PLATFORM_DIR="$SCRIPT_DIR/linux"; PKG_MGR="apt" ;;
        3) SELECTED_PLATFORM="arch"; PLATFORM_DIR="$SCRIPT_DIR/arch"; PKG_MGR="pacman" ;;
    esac
}

step_conflict_policy() {
    # Check if any target files already exist
    local has_existing=0
    local dotfiles_ref
    get_platform_dotfiles dotfiles_ref

    for entry in "${dotfiles_ref[@]}"; do
        IFS=':' read -r _ target _ _ <<< "$entry"
        local expanded="${target/#\~/$HOME}"
        [[ -e "$expanded" || -L "$expanded" ]] && has_existing=1 && break
    done

    if [[ "$has_existing" == "1" ]]; then
        section_header "CONFLICT POLICY"
        prompt_select "Existing dotfiles detected. How to handle?" \
            "Skip all    — keep existing, only install new" \
            "Overwrite   — backup existing, install all selected" \
            "Ask each    — decide per file"
        case "$REPLY" in
            1) CONFLICT_POLICY="skip" ;;
            2) CONFLICT_POLICY="overwrite" ;;
            3) CONFLICT_POLICY="ask" ;;
        esac
    else
        CONFLICT_POLICY="overwrite"
    fi
}

step_dotfiles() {
    local dotfiles_ref
    get_platform_dotfiles dotfiles_ref

    section_header "DOTFILES"

    for entry in "${dotfiles_ref[@]}"; do
        IFS=':' read -r src target desc requires <<< "$entry"
        local expanded="${target/#\~/$HOME}"
        local basename_src="$(basename "$src")"

        # Check if required tool is installed
        local missing=""
        if [[ -n "$requires" ]]; then
            IFS=',' read -ra req_cmds <<< "$requires"
            for cmd in "${req_cmds[@]}"; do
                if ! command -v "$cmd" &>/dev/null; then
                    missing+="${cmd} "
                fi
            done
        fi

        local extra_info=""
        [[ -n "$missing" ]] && extra_info=" ${ORG}(requires: ${missing})${RST}"

        if prompt_yn "Install ${basename_src}?${extra_info}" "$desc"; then
            SEL_DOTFILES[$src]=1
        else
            SEL_DOTFILES[$src]=0
        fi
    done
}

step_packages() {
    # Build display array with only uninstalled items highlighted
    if [[ "$PKG_MGR" == "pacman" ]]; then
        prompt_multi_select "PACMAN PACKAGES" PACMAN_TOOLS SEL_PACMAN_TOOLS check_pacman_tool
    else
        prompt_multi_select "APT PACKAGES" APT_TOOLS SEL_APT_TOOLS check_apt_tool
    fi
}

step_extra_tools() {
    if [[ "$PKG_MGR" == "pacman" ]]; then
        prompt_multi_select "EXTRA TOOLS" PACMAN_EXTRA SEL_PACMAN_EXTRA check_pacman_tool
    else
        prompt_multi_select "EXTRA TOOLS" EXTRA_TOOLS SEL_EXTRA_TOOLS check_extra_tool
    fi
}

step_git_components() {
    if [[ "$PKG_MGR" == "pacman" ]]; then
        prompt_multi_select "GIT COMPONENTS" ARCH_COMPONENTS SEL_ARCH_COMPONENTS check_git_component
    else
        prompt_multi_select "GIT COMPONENTS" GIT_COMPONENTS SEL_GIT_COMPONENTS check_git_component
    fi
}

step_zsh_default() {
    if command -v zsh &>/dev/null || [[ "${SEL_APT_TOOLS[zsh]:-0}" == "1" || "${SEL_PACMAN_TOOLS[zsh]:-0}" == "1" ]]; then
        section_header "DEFAULT SHELL"
        if [[ "$(basename "${SHELL:-}")" == "zsh" ]]; then
            dimm "ZSH is already your default shell"
            SEL_SET_ZSH_DEFAULT=0
        elif prompt_yn "Set ZSH as default shell?" "Runs: chsh -s \$(which zsh)"; then
            SEL_SET_ZSH_DEFAULT=1
        fi
    fi
}

step_summary() {
    section_header "SUMMARY"
    echo ""
    echo -e "  ${MAG}┌──────────────────────────────────────────────────────┐${RST}"
    echo -e "  ${MAG}│${RST}  ${MAG}${BLD}I N S T A L L   S U M M A R Y${RST}                    ${MAG}│${RST}"
    echo -e "  ${MAG}├──────────────────────────────────────────────────────┤${RST}"

    # Platform
    echo -e "  ${MAG}│${RST}                                                      ${MAG}│${RST}"
    printf "  ${MAG}│${RST}  ${YLW}${BLD}Platform:${RST} %-43s ${MAG}│${RST}\n" "$SELECTED_PLATFORM"

    # Dotfiles
    echo -e "  ${MAG}│${RST}                                                      ${MAG}│${RST}"
    echo -e "  ${MAG}│${RST}  ${CYN}${BLD}Dotfiles${RST}                                            ${MAG}│${RST}"
    for key in "${!SEL_DOTFILES[@]}"; do
        if [[ "${SEL_DOTFILES[$key]}" == "1" ]]; then
            printf "  ${MAG}│${RST}    ${GRN}●${RST} %-48s ${MAG}│${RST}\n" "$(basename "$key")"
        fi
    done

    # Packages — pick the active package-manager's arrays
    echo -e "  ${MAG}│${RST}                                                      ${MAG}│${RST}"
    local pkg_label="APT packages" pkg_arr=APT_TOOLS sel_pkg=SEL_APT_TOOLS
    local extra_arr=EXTRA_TOOLS sel_extra=SEL_EXTRA_TOOLS
    local comp_arr=GIT_COMPONENTS sel_comp=SEL_GIT_COMPONENTS
    if [[ "$PKG_MGR" == "pacman" ]]; then
        pkg_label="Pacman packages"; pkg_arr=PACMAN_TOOLS; sel_pkg=SEL_PACMAN_TOOLS
        extra_arr=PACMAN_EXTRA; sel_extra=SEL_PACMAN_EXTRA
        comp_arr=ARCH_COMPONENTS; sel_comp=SEL_ARCH_COMPONENTS
    fi

    local -n _sp_arr=$pkg_arr; local -n _sp_sel=$sel_pkg
    local pkg_count=0
    for entry in "${_sp_arr[@]}"; do
        local k="${entry%%:*}"
        [[ "${_sp_sel[$k]:-0}" == "1" ]] && (( pkg_count++ )) || true
    done
    printf "  ${MAG}│${RST}  ${CYN}${BLD}%s${RST} ${GRY}(%d selected)${RST}%*s${MAG}│${RST}\n" "$pkg_label" "$pkg_count" $(( 41 - ${#pkg_label} - ${#pkg_count} )) ""

    # Extra tools
    local -n _se_arr=$extra_arr; local -n _se_sel=$sel_extra
    local extra_count=0
    for entry in "${_se_arr[@]}"; do
        local k="${entry%%:*}"
        [[ "${_se_sel[$k]:-0}" == "1" ]] && (( extra_count++ )) || true
    done
    printf "  ${MAG}│${RST}  ${CYN}${BLD}Extra tools${RST} ${GRY}(%d selected)${RST}%*s${MAG}│${RST}\n" "$extra_count" $(( 30 - ${#extra_count} )) ""

    # Components
    local -n _sc_arr=$comp_arr; local -n _sc_sel=$sel_comp
    local git_count=0
    for entry in "${_sc_arr[@]}"; do
        local k="${entry%%:*}"
        [[ "${_sc_sel[$k]:-0}" == "1" ]] && (( git_count++ )) || true
    done
    printf "  ${MAG}│${RST}  ${CYN}${BLD}Git components${RST} ${GRY}(%d selected)${RST}%*s${MAG}│${RST}\n" "$git_count" $(( 27 - ${#git_count} )) ""

    # ZSH default
    echo -e "  ${MAG}│${RST}                                                      ${MAG}│${RST}"
    if [[ "$SEL_SET_ZSH_DEFAULT" == "1" ]]; then
        printf "  ${MAG}│${RST}    ${GRN}●${RST} %-48s ${MAG}│${RST}\n" "Set ZSH as default shell"
    fi

    # Policy
    local policy_label="$CONFLICT_POLICY"
    [[ "$CONFLICT_POLICY" == "skip" ]] && policy_label="Skip all existing"
    [[ "$CONFLICT_POLICY" == "overwrite" ]] && policy_label="Overwrite all (backup)"
    [[ "$CONFLICT_POLICY" == "ask" ]] && policy_label="Ask for each"
    echo -e "  ${MAG}│${RST}                                                      ${MAG}│${RST}"
    printf "  ${MAG}│${RST}  ${YLW}${BLD}Policy:${RST} %-45s ${MAG}│${RST}\n" "$policy_label"
    echo -e "  ${MAG}│${RST}                                                      ${MAG}│${RST}"
    echo -e "  ${MAG}└──────────────────────────────────────────────────────┘${RST}"

    echo ""
    if ! prompt_yn "Proceed with installation?"; then
        echo -e "\n  ${ORG}Aborted. No changes made.${RST}\n"
        exit 0
    fi
}

step_execute() {
    section_header "INSTALLING"
    echo ""

    # ── Packages ────────────────────────────────────────────────
    if [[ "$PKG_MGR" == "pacman" ]]; then
        # Core + extra are all official pacman packages → one transaction.
        local pac_list=""
        for entry in "${PACMAN_TOOLS[@]}" "${PACMAN_EXTRA[@]}"; do
            IFS=':' read -r key _ _ install_cmd <<< "$entry"
            [[ "${SEL_PACMAN_TOOLS[$key]:-0}" == "1" || "${SEL_PACMAN_EXTRA[$key]:-0}" == "1" ]] || continue
            pac_list+=" $(echo "$install_cmd" | grep -oP '(?<=--noconfirm ).*')"
        done
        if [[ -n "$pac_list" ]]; then
            info "Installing pacman packages:${pac_list}"
            # --needed is idempotent; assumes the DB is synced (run pacman -Syu first).
            sudo pacman -S --needed --noconfirm $pac_list && ok "Pacman packages installed" || err "Some pacman packages failed"
        fi
    else
        # APT tools
        local apt_list=""
        for entry in "${APT_TOOLS[@]}"; do
            IFS=':' read -r key _ check_cmd install_cmd <<< "$entry"
            [[ "${SEL_APT_TOOLS[$key]:-0}" != "1" ]] && continue
            if command -v "$check_cmd" &>/dev/null; then
                dimm "Skipped: ${key} (already installed)"
            else
                # Extract package name from install command
                apt_list+=" $(echo "$install_cmd" | grep -oP '(?<=install -y ).*')"
            fi
        done
        if [[ -n "$apt_list" ]]; then
            info "Installing APT packages:${apt_list}"
            sudo apt update -qq
            sudo apt install -y $apt_list && ok "APT packages installed" || err "Some APT packages failed"
        fi

        # Extra tools
        for entry in "${EXTRA_TOOLS[@]}"; do
            IFS=':' read -r key desc check_cmd install_cmd <<< "$entry"
            [[ "${SEL_EXTRA_TOOLS[$key]:-0}" != "1" ]] && continue
            if command -v "$check_cmd" &>/dev/null; then
                dimm "Skipped: ${key} (already installed)"
            else
                info "Installing ${key}..."
                if eval "$install_cmd" &>/dev/null; then
                    ok "Installed: ${key}"
                else
                    err "Failed: ${key}"
                fi
            fi
        done
    fi

    # ── Components (git clones) — choose the platform's component set ──
    local comp_arr_name comp_sel_name
    if [[ "$PKG_MGR" == "pacman" ]]; then
        comp_arr_name=ARCH_COMPONENTS; comp_sel_name=SEL_ARCH_COMPONENTS
    else
        comp_arr_name=GIT_COMPONENTS; comp_sel_name=SEL_GIT_COMPONENTS
    fi
    local -n _comp_arr=$comp_arr_name
    local -n _comp_sel=$comp_sel_name
    for entry in "${_comp_arr[@]}"; do
        IFS=':' read -r key desc check_path install_cmd <<< "$entry"
        [[ "${_comp_sel[$key]:-0}" != "1" ]] && continue
        local expanded="${check_path/#\~/$HOME}"
        if [[ -e "$expanded" ]]; then
            dimm "Skipped: ${key} (already exists)"
        else
            info "Installing ${key}..."
            if eval "$install_cmd" &>/dev/null; then
                ok "Installed: ${key}"
            else
                err "Failed: ${key}"
            fi
        fi
    done

    # Dotfiles
    echo ""
    info "Deploying dotfiles..."
    echo ""
    local dotfiles_ref
    get_platform_dotfiles dotfiles_ref

    for entry in "${dotfiles_ref[@]}"; do
        IFS=':' read -r src target _ _ <<< "$entry"
        [[ "${SEL_DOTFILES[$src]:-0}" != "1" ]] && continue
        local full_src="$PLATFORM_DIR/$src"
        local full_dst="${target/#\~/$HOME}"
        deploy_dotfile "$full_src" "$full_dst"
    done

    # Set ZSH default
    if [[ "$SEL_SET_ZSH_DEFAULT" == "1" ]]; then
        info "Setting ZSH as default shell..."
        chsh -s "$(which zsh)" && ok "ZSH set as default shell" || err "Failed to set ZSH (try manually: chsh -s \$(which zsh))"
    fi
}

step_post_install() {
    echo ""
    hr "═" "$MAG"
    echo ""
    echo -e "  ${MAG}${BLD}  ▓▓▓ SETUP COMPLETE ▓▓▓${RST}"
    echo ""
    hr "═" "$MAG"
    echo ""

    if [[ -n "${BACKUP_DIR:-}" && -d "${BACKUP_DIR:-}" ]]; then
        info "Backups saved to:"
        dimm "  $BACKUP_DIR"
        echo ""
    fi

    echo -e "  ${CYN}Next steps:${RST}"
    dimm "  1. Restart your terminal (or: source ~/.zshrc)"

    if [[ "${SEL_GIT_COMPONENTS[tpm]:-0}" == "1" || "${SEL_ARCH_COMPONENTS[tpm]:-0}" == "1" ]]; then
        dimm "  2. In tmux: Ctrl+a then I to install plugins"
    fi

    if [[ "${SEL_GIT_COMPONENTS[lazyvim]:-0}" == "1" || "${SEL_ARCH_COMPONENTS[lazyvim]:-0}" == "1" ]]; then
        dimm "  3. Run nvim — LazyVim will auto-install plugins"
    fi

    if [[ "$SELECTED_PLATFORM" == "ubuntu-wsl" ]]; then
        echo ""
        dimm "  WezTerm config note:"
        dimm "  Copy wezterm.lua to Windows side:"
        dimm "  %USERPROFILE%\\.config\\wezterm\\wezterm.lua"
    fi

    echo ""
}

# ── Subcommands ─────────────────────────────────────────────────

cmd_configure() {
    step_welcome
    step_platform
    step_conflict_policy
    step_packages
    step_extra_tools
    step_git_components
    step_dotfiles
    step_zsh_default
    step_summary
    step_execute
    step_post_install
}

cmd_status() {
    detect_env
    echo ""
    echo -e "  ${CYN}${BLD}Terminal Ricing — Status${RST}"
    echo ""

    echo -e "  ${WHT}${BLD}Tools:${RST}"
    local tools=("zsh" "eza" "fzf" "rg" "fd" "fdfind" "tmux" "btop" "micro" "fastfetch" "zoxide" "nvim" "starship" "wezterm")
    for cmd in "${tools[@]}"; do
        if command -v "$cmd" &>/dev/null; then
            echo -e "  ${GRN}●${RST} ${WHT}${cmd}${RST}"
        else
            echo -e "  ${GRY}○ ${cmd}${RST}"
        fi
    done

    echo ""
    echo -e "  ${WHT}${BLD}Components:${RST}"
    local components=(
        "powerlevel10k:~/powerlevel10k"
        "zsh-autosuggestions:~/.zsh/zsh-autosuggestions"
        "zsh-syntax-highlighting:~/.zsh/zsh-syntax-highlighting"
        "tpm:~/.tmux/plugins/tpm"
        "lazyvim:~/.config/nvim"
        "nerd-fonts:~/.local/share/fonts/JetBrainsMonoNerdFont-Regular.ttf"
    )
    for c in "${components[@]}"; do
        IFS=':' read -r name path <<< "$c"
        local expanded="${path/#\~/$HOME}"
        if [[ -e "$expanded" ]]; then
            echo -e "  ${GRN}●${RST} ${WHT}${name}${RST}"
        else
            echo -e "  ${GRY}○ ${name}${RST}"
        fi
    done

    echo ""
    echo -e "  ${WHT}${BLD}Dotfiles:${RST}"
    local dotfiles=(".zshrc" ".tmux.conf" ".p10k.zsh" ".ripgreprc" ".config/btop/btop.conf" ".config/fastfetch/config.jsonc" ".config/wezterm/wezterm.lua" ".config/starship.toml")
    for f in "${dotfiles[@]}"; do
        local target="$HOME/$f"
        if [[ -L "$target" ]]; then
            echo -e "  ${GRN}●${RST} ${WHT}${f}${RST} ${GRY}→ $(readlink "$target")${RST}"
        elif [[ -e "$target" ]]; then
            echo -e "  ${ORG}●${RST} ${WHT}${f}${RST} ${GRY}(standalone)${RST}"
        else
            echo -e "  ${GRY}○ ${f}${RST}"
        fi
    done
    echo ""
}

cmd_help() {
    echo ""
    echo -e "  ${CYN}${BLD}Terminal Ricing${RST} ${DIM}v${VERSION}${RST}"
    echo ""
    echo -e "  ${WHT}Usage:${RST}"
    echo -e "    ./setup.sh ${CYN}configure${RST}    Launch interactive setup wizard"
    echo -e "    ./setup.sh ${CYN}status${RST}       Show what's installed"
    echo -e "    ./setup.sh ${CYN}help${RST}         Show this help message"
    echo ""
    echo -e "  ${WHT}Platforms:${RST}"
    echo -e "    ${GRY}ubuntu-wsl${RST}    Ubuntu on WSL2 + WezTerm + ZSH + P10K"
    echo -e "    ${GRY}linux${RST}         Native Linux + WezTerm + ZSH + Starship"
    echo -e "    ${GRY}arch${RST}          Arch / CachyOS + WezTerm + ZSH + Starship (pacman)"
    echo ""
}

# ── Main ────────────────────────────────────────────────────────

main() {
    local cmd="${1:-}"
    case "$cmd" in
        configure) cmd_configure ;;
        status)    cmd_status ;;
        help|--help|-h) cmd_help ;;
        "")
            cmd_help
            echo -e "  ${DIM}Run ${WHT}./setup.sh configure${RST}${DIM} to start the wizard.${RST}"
            echo ""
            ;;
        *) echo -e "  ${RED}Unknown command: ${cmd}${RST}"; echo ""; cmd_help; exit 1 ;;
    esac
}

main "$@"
