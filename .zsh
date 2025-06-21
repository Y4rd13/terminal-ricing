# ═══════════════════════════════════════════════════════════════
# 🐚 CONFIGURACIÓN ZSH - KALI LINUX + WEZTERM
# ~/.zshrc
# ═══════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════
# 🎯 VARIABLES DE ENTORNO
# ═══════════════════════════════════════════════════════════════

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

# Path para herramientas locales
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# Configuración de FZF
export FZF_DEFAULT_OPTS='--height 50% --layout=reverse --border --margin=1 --padding=1'
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Configuración de ripgrep
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

# Configuración de bat
export BAT_THEME="base16"

# ═══════════════════════════════════════════════════════════════
# 🎨 INFORMACIÓN DEL SISTEMA
# ═══════════════════════════════════════════════════════════════

# Mostrar info del sistema al iniciar
if command -v fastfetch &> /dev/null; then
    timeout 5s fastfetch 2>/dev/null || echo "⚡ Fastfetch timeout - terminal listo"
elif command -v neofetch &> /dev/null; then
    timeout 5s neofetch 2>/dev/null || echo "⚡ Neofetch timeout - terminal listo"
fi

# ═══════════════════════════════════════════════════════════════
# ⚙️ CONFIGURACIÓN ZSH
# ═══════════════════════════════════════════════════════════════

# Historial
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt APPEND_HISTORY

# Autocompletado
autoload -U compinit
compinit
zstyle ':completion:*' menu select
setopt AUTO_CD
setopt GLOB_COMPLETE

# ═══════════════════════════════════════════════════════════════
# 🔧 ALIASES MODERNOS
# ═══════════════════════════════════════════════════════════════

# ▶ Comandos de listado mejorados
if command -v eza &> /dev/null; then
    alias ls="eza --icons --group-directories-first"
    alias ll="eza -la --icons --group-directories-first --git"
    alias la="eza -a --icons --group-directories-first"
    alias tree="eza --tree --icons --group-directories-first"
    alias lt="eza --tree --level=2 --icons --group-directories-first"
    alias lx="eza -la --icons --sort=extension"
    alias lk="eza -la --icons --sort=size"
    alias lt2="eza --tree --level=3 --icons"
else
    alias ll="ls -la"
    alias la="ls -la"
fi

# ▶ Herramientas modernas
if command -v bat &> /dev/null; then
    alias cat="bat --paging=never"
    alias catp="bat"  # con paginación
fi

command -v fd &> /dev/null && alias find="fd"
command -v rg &> /dev/null && alias grep="rg"
command -v htop &> /dev/null && alias top="htop"
command -v btm &> /dev/null && alias htop="btm"

# ▶ Git shortcuts
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

# ▶ Navegación rápida
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias home="cd ~"
alias desktop="cd ~/Desktop"
alias downloads="cd ~/Downloads"
alias documents="cd ~/Documents"

# ▶ Kali Linux específicos
alias kali-update="sudo apt update && sudo apt upgrade"
alias kali-clean="sudo apt autoclean && sudo apt autoremove"
alias ports="sudo netstat -tuln"
alias myip="curl -s ifconfig.me"
alias localip="ip route get 1 | awk '{print \$NF;exit}'"
alias listening="sudo lsof -i -P -n | grep LISTEN"

# ▶ Herramientas de penetración
alias nmap-quick="nmap -T4 -F"
alias nmap-full="nmap -T4 -A -v"
alias nmap-vuln="nmap --script vuln"
alias gobuster-common="gobuster dir -w /usr/share/wordlists/dirb/common.txt"
alias nikto-scan="nikto -h"

# ▶ Desarrollo
alias python="python3"
alias pip="pip3"
alias serve="python3 -m http.server 8000"
alias server="python3 -m http.server"
alias venv="python3 -m venv"

# ▶ Docker (si está instalado)
if command -v docker &> /dev/null; then
    alias d="docker"
    alias dc="docker-compose"
    alias dps="docker ps"
    alias di="docker images"
    alias drm="docker rm"
    alias drmi="docker rmi"
    alias dclean="docker system prune -f"
fi

# ▶ Utilidades generales
alias h="history"
alias j="jobs"
alias c="clear"
alias e="exit"
alias r="reset"
alias reload="source ~/.zshrc"
alias zshconfig="nvim ~/.zshrc"
alias wezconfig="nvim ~/.config/wezterm/wezterm.lua"

# ▶ Fastfetch múltiples configuraciones
alias ff="fastfetch"
alias ff-full="fastfetch --config ~/.config/fastfetch/config.jsonc"
alias ff-stable="fastfetch --config ~/.config/fastfetch/stable.jsonc"
alias ff-min="fastfetch --config ~/.config/fastfetch/minimal.jsonc"
alias ff-test="timeout 3s fastfetch --config ~/.config/fastfetch/config.jsonc || echo 'Fastfetch timeout'"

# ▶ Shortcuts para edición
if command -v nvim &> /dev/null; then
    alias vim="nvim"
    alias vi="nvim"
    alias v="nvim"
fi

# ═══════════════════════════════════════════════════════════════
# 🚀 FUNCIONES ÚTILES
# ═══════════════════════════════════════════════════════════════

# ▶ Crear directorio y navegar
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# ▶ Buscar archivos con fzf
fzf_find() {
    if command -v fzf &> /dev/null; then
        if command -v fd &> /dev/null; then
            local file=$(fd --type f | fzf --preview 'bat --color=always {}')
        else
            local file=$(find . -type f | fzf --preview 'cat {}')
        fi
        [[ -n "$file" ]] && ${EDITOR:-nvim} "$file"
    else
        echo "fzf no está instalado"
    fi
}

# ▶ Buscar directorios con fzf
fcd() {
    if command -v fzf &> /dev/null; then
        if command -v fd &> /dev/null; then
            local dir=$(fd --type d | fzf --preview 'eza --tree --level=2 {}')
        else
            local dir=$(find . -type d | fzf)
        fi
        [[ -n "$dir" ]] && cd "$dir"
    fi
}

# ▶ Buscar en historial
fh() {
    local cmd=$(history | fzf --tac | sed 's/^[ ]*[0-9]*[ ]*//')
    [[ -n "$cmd" ]] && echo "$cmd" | pbcopy 2>/dev/null || echo "$cmd"
}

# ▶ Buscar procesos y kill
fkill() {
    local pid=$(ps aux | fzf --multi | awk '{print $2}')
    [[ -n "$pid" ]] && kill "$pid"
}

# ▶ Weather info
weather() {
    if [[ $# -eq 0 ]]; then
        curl -s "wttr.in/?format=3"
    else
        curl -s "wttr.in/$1"
    fi
}

# ▶ Convertir a uppercase/lowercase
up() {
    echo "$*" | tr '[:lower:]' '[:upper:]'
}

low() {
    echo "$*" | tr '[:upper:]' '[:lower:]'
}

# ▶ Backup rápido
backup() {
    cp "$1" "$1.backup-$(date +%Y%m%d%H%M%S)"
}

# ▶ Extraer archivos (cualquier formato)
extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
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
            *.deb)       ar x "$1"        ;;
            *.tar.lz)    tar xf "$1"      ;;
            *)           echo "❌ '$1' no se puede extraer con esta función" ;;
        esac
        echo "✅ Archivo extraído: $1"
    else
        echo "❌ '$1' no es un archivo válido"
    fi
}

# ▶ Función para buscar texto en archivos
search() {
    if command -v rg &> /dev/null; then
        rg --color=always --line-number --no-heading "$@"
    else
        grep -r --color=always -n "$@" .
    fi
}

# ▶ Función para obtener la IP pública
publicip() {
    echo "🌐 IP Pública:"
    curl -s ifconfig.me
    echo ""
    echo "📍 Localización:"
    curl -s "ipinfo.io/$(curl -s ifconfig.me)" | jq '.city, .region, .country' 2>/dev/null || echo "Error obteniendo localización"
}

# ▶ Port scanner rápido
portscan() {
    if [[ $# -eq 0 ]]; then
        echo "❌ Uso: portscan <IP>"
        return 1
    fi
    echo "🔍 Escaneando puertos principales en $1..."
    nmap -T4 -F "$1"
}

# ▶ Función para diagnosticar problemas con fastfetch
diagnose_fastfetch() {
    echo "🔍 Diagnosticando Fastfetch..."
    echo ""
    
    echo "1. Verificando instalación:"
    if command -v fastfetch &> /dev/null; then
        echo "   ✅ Fastfetch instalado: $(which fastfetch)"
        echo "   📦 Versión: $(fastfetch --version 2>/dev/null | head -1)"
    else
        echo "   ❌ Fastfetch no encontrado"
        return 1
    fi
    
    echo ""
    echo "2. Probando configuración por defecto:"
    timeout 3s fastfetch --config none || echo "   ❌ Timeout con config por defecto"
    
    echo ""
    echo "3. Probando configuración personalizada:"
    timeout 3s fastfetch --config ~/.config/fastfetch/config.jsonc || echo "   ❌ Timeout con config personalizada"
    
    echo ""
    echo "4. Archivos de configuración:"
    if [[ -f ~/.config/fastfetch/config.jsonc ]]; then
        echo "   ✅ Config principal encontrada"
    else
        echo "   ❌ Config principal no encontrada"
    fi
    
    echo ""
    echo "💡 Usa 'ff-stable' para una versión más rápida"
}

# ═══════════════════════════════════════════════════════════════
# 🎨 CONFIGURACIÓN DE COLORES
# ═══════════════════════════════════════════════════════════════

# Colores para ls (si no usa eza)
export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30'

# ═══════════════════════════════════════════════════════════════
# 🔧 INICIALIZACIÓN DE HERRAMIENTAS
# ═══════════════════════════════════════════════════════════════

# PowerLevel10k prompt
source ~/powerlevel10k/powerlevel10k.zsh-theme

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Zoxide (cd inteligente)
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
    alias cd="z"
    alias cdi="zi"  # interactive
fi

# fzf integration
if command -v fzf &> /dev/null; then
    # Para fzf >= 0.48.0
    if fzf --zsh &>/dev/null; then
        source <(fzf --zsh)
    # Para versiones antiguas
    elif [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
        source /usr/share/fzf/key-bindings.zsh
        source /usr/share/fzf/completion.zsh
    elif [[ -f ~/.fzf.zsh ]]; then
        source ~/.fzf.zsh
    fi
fi

# ═══════════════════════════════════════════════════════════════
# ⌨️ KEYBINDINGS
# ═══════════════════════════════════════════════════════════════

# Ctrl+R para buscar en historial con fzf (ya incluido en fzf --zsh)
bindkey '^R' fzf-history-widget

# Alt+C para cambiar directorio con fzf
bindkey '\ec' fzf-cd-widget

# Ctrl+T para buscar archivos
bindkey '^T' fzf-file-widget

# ═══════════════════════════════════════════════════════════════
# 💡 TIPS Y MENSAJES
# ═══════════════════════════════════════════════════════════════

# Función para mostrar tips ocasionales
random_tip() {
    local tips=(
        "💡 Tip: Usa 'fcd' para navegar directorios con fzf"
        "💡 Tip: 'bat' muestra archivos con syntax highlighting"
        "💡 Tip: 'eza --tree' muestra directorios como árbol"
        "💡 Tip: 'rg pattern' busca texto más rápido que grep"
        "💡 Tip: 'z directorio' para navegación inteligente"
        "💡 Tip: Usa Tab para autocompletar comandos"
        "💡 Tip: 'weather ciudad' para ver el clima"
        "💡 Tip: 'extract archivo' extrae cualquier formato"
        "💡 Tip: 'backup archivo' crea una copia de seguridad"
        "💡 Tip: Ctrl+R para buscar en historial"
        "💡 Tip: Alt+C para cambiar directorio con fzf"
    )
    
    # Mostrar tip aleatoriamente (1 de cada 10 veces)
    if (( RANDOM % 10 == 0 )); then
        local random_tip=${tips[$((RANDOM % ${#tips[@]} + 1))]}
        echo -e "\033[33m$random_tip\033[0m"
    fi
}

# Mostrar tip ocasional
random_tip

# ═══════════════════════════════════════════════════════════════
# 🔧 FUNCIONES DE INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════

# Función para verificar herramientas faltantes
check_tools() {
    local tools=(eza bat fd rg fzf starship zoxide htop)
    echo "🔍 Verificando herramientas instaladas:"
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            echo "  ✅ $tool"
        else
            echo "  ❌ $tool (no instalado)"
        fi
    done
}

# Función para instalar herramientas faltantes (Kali/Debian/Ubuntu)
install_modern_tools() {
    echo "📦 Instalando herramientas modernas..."
    
    # Actualizar repositorios
    sudo apt update
    
    # Instalar herramientas disponibles en repos
    sudo apt install -y bat fd-find ripgrep fzf htop
    
    # eza (requiere instalación manual)
    if ! command -v eza &> /dev/null; then
        echo "📥 Instalando eza..."
        wget -c https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz -O - | tar xz
        sudo chmod +x eza
        sudo mv eza /usr/local/bin/
    fi
    
    # starship
    if ! command -v starship &> /dev/null; then
        echo "📥 Instalando starship..."
        curl -sS https://starship.rs/install.sh | sh
    fi
    
    # zoxide
    if ! command -v zoxide &> /dev/null; then
        echo "📥 Instalando zoxide..."
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    fi
    
    echo "✅ Instalación completada. Reinicia la terminal."
}

# ═══════════════════════════════════════════════════════════════
# 🎉 CONFIGURACIÓN FINAL
# ═══════════════════════════════════════════════════════════════

# Cargar configuración local si existe
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
