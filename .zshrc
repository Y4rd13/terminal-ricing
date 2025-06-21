# ═══════════════════════════════════════════════════════════════
# 🐚 CONFIGURACIÓN ZSH - KALI LINUX + WEZTERM
# ~/.zshrc
# ═══════════════════════════════════════════════════════════════

# ————————————————————————————————
# 🎯 VARIABLES DE ENTORNO
# ————————————————————————————————

# Editor preferido
if command -v nvim &> /dev/null; then
    export EDITOR="nvim"
    export VISUAL="nvim"
elif command -v vim &> /dev/null; then
    export EDITOR="vim"
    export VISUAL="vim"
else
    export EDITOR="nano"
    export VISUAL="nano"
fi

# PATH para herramientas locales, Cargo y ~/.local/bin
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$HOME/bin:$PATH"

# Ripgrep
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

# Bat (alias de cat)
export BAT_THEME="base16"

# FZF (opciones y comando por defecto)
export FZF_DEFAULT_OPTS='--height 50% --layout=reverse --border --margin=1 --padding=1'
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# The Fuck (reinstalado vía pip)
if command -v thefuck &> /dev/null; then
    eval "$(thefuck --alias)"
fi

# ————————————————————————————————
# 🎨 INFO DEL SISTEMA AL INICIO
# ————————————————————————————————
if command -v fastfetch &> /dev/null; then
    timeout 5s fastfetch 2>/dev/null \
      || echo "⚡ Fastfetch timeout — terminal listo"
elif command -v neofetch &> /dev/null; then
    timeout 5s neofetch 2>/dev/null \
      || echo "⚡ Neofetch timeout — terminal listo"
fi

# ————————————————————————————————
# ⚙️ HISTORIAL & COMPLETADO
# ————————————————————————————————
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY_TIME HIST_IGNORE_SPACE SHARE_HISTORY APPEND_HISTORY

autoload -U compinit
compinit
zstyle ':completion:*' menu select
setopt AUTO_CD GLOB_COMPLETE

# ————————————————————————————————
# 🔧 ALIASES
# ————————————————————————————————

# exa / eza (reemplazo de ls)
if command -v eza &> /dev/null; then
    alias ls="eza --icons --group-directories-first"
    alias ll="eza -la --icons --group-directories-first --git"
    alias la="eza -a --icons --group-directories-first"
    alias tree="eza --tree --icons --group-directories-first"
elif command -v exa &> /dev/null; then
    alias ls="exa --git --icons --group-directories-first"
    alias ll="exa -la --git --icons --group-directories-first"
    alias la="exa -a --icons --group-directories-first"
else
    alias ll="ls -la"
    alias la="ls -la"
fi

# bat (alias de cat)
if command -v bat &> /dev/null; then
    alias cat="bat --paging=always"
    alias catp="bat"
fi

# tldr (ayuda rápida)
if command -v tldr &> /dev/null; then
    alias tldr='tldr --update && tldr'
fi

# find/grep modernos
command -v fd &> /dev/null && alias find="fd"
command -v rg &> /dev/null  && alias grep="rg"

# Monitores
command -v htop &> /dev/null && alias top="htop"
command -v btm  &> /dev/null && alias htop="btm"
alias clock='tty-clock -s -c'

# Git
alias g="git"
alias gs="git status"
alias ga="git add"
alias gaa="git add ."
alias gc="git commit"
alias gcm="git commit -m"
alias gp="git push"
alias gpl="git pull"
alias gl="git log --oneline"
alias glo="git log --oneline --graph --decorate --all"
alias gb="git branch"
alias gch="git checkout"
alias gd="git diff"
alias gds="git diff --staged"

# Navegación rápida
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias home="cd ~"
alias desktop="cd ~/Desktop"
alias downloads="cd ~/Downloads"
alias documents="cd ~/Documents"

# Kali Linux específicos
alias kali-update="sudo apt update && sudo apt upgrade"
alias kali-clean="sudo apt autoclean && sudo apt autoremove"
alias ports="sudo netstat -tuln"
alias myip="curl -s ifconfig.me"
alias localip="ip route get 1 | awk '{print \$NF;exit}'"
alias listening="sudo lsof -i -P -n | grep LISTEN"

# Pentesting
alias nmap-quick="nmap -T4 -F"
alias nmap-full="nmap -T4 -A -v"
alias nmap-vuln="nmap --script vuln"
alias gobuster-common="gobuster dir -w /usr/share/wordlists/dirb/common.txt"
alias nikto-scan="nikto -h"

# Desarrollo
alias python="python3"
alias pip="pip3"
alias serve="python3 -m http.server 8000"
alias server="python3 -m http.server"
alias venv="python3 -m venv"

# Docker
if command -v docker &> /dev/null; then
    alias d="docker"
    alias dc="docker-compose"
    alias dps="docker ps"
    alias di="docker images"
    alias drm="docker rm"
    alias drmi="docker rmi"
    alias dclean="docker system prune -f"
fi

# Utilidades generales
alias h="history"
alias j="jobs"
alias c="clear"
alias e="exit"
alias r="reset"
alias reload="source ~/.zshrc"
alias zshconfig="nvim ~/.zshrc"
alias wezconfig="nvim ~/.config/wezterm/wezterm.lua"

# Fastfetch
alias ff="fastfetch"
alias ff-full="fastfetch --config ~/.config/fastfetch/config.jsonc"
alias ff-stable="fastfetch --config ~/.config/fastfetch/stable.jsonc"
alias ff-min="fastfetch --config ~/.config/fastfetch/minimal.jsonc"
alias ff-test="timeout 3s fastfetch --config ~/.config/fastfetch/config.jsonc || echo 'Fastfetch timeout'"

# Editores
if command -v nvim &> /dev/null; then
    alias vim="nvim"
    alias vi="nvim"
    alias v="nvim"
fi

# ————————————————————————————————
# 🚀 FUNCIONES ÚTILES
# ————————————————————————————————
mkcd() { mkdir -p "$1" && cd "$1"; }

fzf_find() {
    local file
    file=$(fd --type f | fzf --preview 'bat --color=always {}')
    [[ -n "$file" ]] && ${EDITOR:-nvim} "$file"
}

fcd() {
    local dir
    dir=$(fd --type d | fzf --preview 'eza --tree --level=2 {}')
    [[ -n "$dir" ]] && cd "$dir"
}

fh() {
    local cmd
    cmd=$(history | fzf --tac | sed 's/^[ ]*[0-9]*[ ]*//')
    [[ -n "$cmd" ]] && print -z "$cmd"
}

fkill() {
    local pid
    pid=$(ps aux | fzf --multi | awk '{print $2}')
    [[ -n "$pid" ]] && kill "$pid"
}

weather() {
    if [[ $# -eq 0 ]]; then
        curl -s "wttr.in/?format=3"
    else
        curl -s "wttr.in/$1"
    fi
}

up()  { echo "$*" | tr '[:lower:]' '[:upper:]'; }
low() { echo "$*" | tr '[:upper:]' '[:lower:]'; }

backup() { cp "$1" "$1.backup-$(date +%Y%m%d%H%M%S)"; }

extract() {
    if [[ -f $1 ]]; then
        case $1 in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.tar.xz)    tar xJf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "❌ No puedo extraer '$1'";;
        esac
    fi
}

search() {
    if command -v rg &> /dev/null; then
        rg --color=always --line-number --no-heading "$@"
    else
        grep -R --color=always -n "$@"
    fi
}

publicip() {
    echo "🌐 IP Pública: $(curl -s ifconfig.me)"
    echo "📍 Localización: $(curl -s "ipinfo.io/$(curl -s ifconfig.me)")"
}

portscan() {
    [[ $# -eq 0 ]] && { echo "❌ Uso: portscan <IP>"; return 1; }
    nmap -T4 -F "$1"
}

diagnose_fastfetch() {
    echo "🔍 Diagnosticando Fastfetch…"
    command -v fastfetch &>/dev/null && echo "   ✅ $(which fastfetch)" \
      || echo "   ❌ fastfetch no encontrado"
}

# ————————————————————————————————
# 🔌 PLUGINS ZSH
# ————————————————————————————————

# zsh-autosuggestions
if [[ ! -d ~/.zsh/zsh-autosuggestions ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions \
      ~/.zsh/zsh-autosuggestions
fi
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# zsh-syntax-highlighting
if [[ ! -d ~/.zsh/zsh-syntax-highlighting ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
      ~/.zsh/zsh-syntax-highlighting
fi
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# zoxide (cd inteligente)
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
    alias cd="z"
    alias cdi="zi"
fi

# ————————————————————————————————
# ⌨️ KEYBINDINGS ADICIONALES
# ————————————————————————————————
# Ctrl+Space para autosuggest
bindkey '^ ' autosuggest-accept

# ————————————————————————————————
# 🎨 PROMPT
# ————————————————————————————————
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi

# ————————————————————————————————
# 💡 TIPS Y MENSAJES
# ————————————————————————————————
random_tip() {
    local tips=(
        "💡 Tip: Usa 'fcd' para navegar con fzf"
        "💡 Tip: 'bat' resalta archivos"
        "💡 Tip: 'eza --tree' muestra árbol"
        "💡 Tip: 'rg pattern' busca rápido"
        "💡 Tip: 'z directorio' cd inteligente"
        "💡 Tip: Ctrl+Space acepta sugerencias"
        "💡 Tip: 'weather ciudad' clima rápido"
        "💡 Tip: 'extract archivo' descomprime"
        "💡 Tip: 'backup archivo' copia seguridad"
        "💡 Tip: Ctrl+R historial difuso"
        "💡 Tip: Alt+C cd con fzf"
    )
    (( RANDOM % 10 == 0 )) && \
      echo -e "\033[33m${tips[RANDOM % ${#tips[@]}]}\033[0m"
}
random_tip

# ─────────────────────────────────────────────────────────────────

# Carga configuración local si existe
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
