# ═══════════════════════════════════════════════════════════════
# 🐟 CONFIGURACIÓN FISH SHELL - KALI LINUX + WEZTERM (CORREGIDA)
# ~/.config/fish/config.fish
# ═══════════════════════════════════════════════════════════════

if status is-interactive
    
    # ═══════════════════════════════════════════════════════════════
    # 🎨 INFORMACIÓN DEL SISTEMA
    # ═══════════════════════════════════════════════════════════════
    
    # Mostrar info del sistema al iniciar (con timeout para evitar cuelgues)
    if command -v fastfetch >/dev/null
        timeout 5s fastfetch 2>/dev/null || echo "⚡ Fastfetch timeout - terminal listo"
    else if command -v neofetch >/dev/null
        timeout 5s neofetch 2>/dev/null || echo "⚡ Neofetch timeout - terminal listo"
    end
    
    # ═══════════════════════════════════════════════════════════════
    # 🔧 ALIASES MODERNOS
    # ═══════════════════════════════════════════════════════════════
    
    # ▶ Comandos de listado mejorados
    if command -v eza >/dev/null
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
    end
    
    # ▶ Herramientas modernas
    if command -v bat >/dev/null
        alias cat="bat --paging=never"
        alias catp="bat"  # con paginación
    end
    
    if command -v fd >/dev/null
        alias find="fd"
    end
    
    if command -v rg >/dev/null
        alias grep="rg"
    end
    
    if command -v htop >/dev/null
        alias top="htop"
    end
    
    if command -v btm >/dev/null
        alias htop="btm"  # bottom es aún mejor que htop
    end
    
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
    if command -v docker >/dev/null
        alias d="docker"
        alias dc="docker-compose"
        alias dps="docker ps"
        alias di="docker images"
        alias drm="docker rm"
        alias drmi="docker rmi"
        alias dclean="docker system prune -f"
    end
    
    # ▶ Utilidades generales
    alias h="history"
    alias j="jobs"
    alias c="clear"
    alias e="exit"
    alias r="reset"
    alias reload="source ~/.config/fish/config.fish"
    alias fishconfig="nvim ~/.config/fish/config.fish"
    alias wezconfig="nvim ~/.config/wezterm/wezterm.lua"
    
    # ▶ Fastfetch múltiples configuraciones
    alias ff="fastfetch"
    alias ff-full="fastfetch --config ~/.config/fastfetch/config.jsonc"
    alias ff-stable="fastfetch --config ~/.config/fastfetch/stable.jsonc"
    alias ff-min="fastfetch --config ~/.config/fastfetch/minimal.jsonc"
    alias ff-test="timeout 3s fastfetch --config ~/.config/fastfetch/config.jsonc || echo 'Fastfetch timeout'"
    
    # ▶ Shortcuts para edición
    if command -v nvim >/dev/null
        alias vim="nvim"
        alias vi="nvim"
        alias v="nvim"
    end
    
    # ═══════════════════════════════════════════════════════════════
    # 🚀 FUNCIONES ÚTILES
    # ═══════════════════════════════════════════════════════════════
    
    # ▶ Crear directorio y navegar
    function mkcd
        mkdir -p $argv[1] && cd $argv[1]
    end
    
    # ▶ Buscar archivos con fzf
    function ff
        if command -v fzf >/dev/null
            if command -v fd >/dev/null
                fd --type f | fzf --preview 'bat --color=always {}' | xargs nvim
            else
                find . -type f | fzf --preview 'cat {}' | xargs nvim
            end
        else
            echo "fzf no está instalado"
        end
    end
    
    # ▶ Buscar directorios con fzf
    function fcd
        if command -v fzf >/dev/null
            if command -v fd >/dev/null
                set dir (fd --type d | fzf --preview 'eza --tree --level=2 {}')
            else
                set dir (find . -type d | fzf)
            end
            test -n "$dir" && cd "$dir"
        end
    end
    
    # ▶ Buscar en historial
    function fh
        history | fzf --tac | fish_clipboard_copy
    end
    
    # ▶ Buscar procesos y kill
    function fkill
        ps aux | fzf --multi | awk '{print $2}' | xargs kill
    end
    
    # ▶ Weather info
    function weather
        if test (count $argv) -eq 0
            curl -s "wttr.in/?format=3"
        else
            curl -s "wttr.in/$argv[1]"
        end
    end
    
    # ▶ Convertir a uppercase/lowercase
    function up
        echo $argv | tr '[:lower:]' '[:upper:]'
    end
    
    function low
        echo $argv | tr '[:upper:]' '[:lower:]'
    end
    
    # ▶ Backup rápido
    function backup
        cp "$argv[1]" "$argv[1].backup-(date +%Y%m%d%H%M%S)"
    end
    
    # ▶ Extraer archivos (cualquier formato)
    function extract
        if test -f $argv[1]
            switch $argv[1]
                case '*.tar.bz2'
                    tar xjf $argv[1]
                case '*.tar.gz'
                    tar xzf $argv[1]
                case '*.tar.xz'
                    tar xJf $argv[1]
                case '*.bz2'
                    bunzip2 $argv[1]
                case '*.rar'
                    unrar x $argv[1]
                case '*.gz'
                    gunzip $argv[1]
                case '*.tar'
                    tar xf $argv[1]
                case '*.tbz2'
                    tar xjf $argv[1]
                case '*.tgz'
                    tar xzf $argv[1]
                case '*.zip'
                    unzip $argv[1]
                case '*.Z'
                    uncompress $argv[1]
                case '*.7z'
                    7z x $argv[1]
                case '*.deb'
                    ar x $argv[1]
                case '*.tar.lz'
                    tar xf $argv[1]
                case '*'
                    echo "❌ '$argv[1]' no se puede extraer con esta función"
            end
            echo "✅ Archivo extraído: $argv[1]"
        else
            echo "❌ '$argv[1]' no es un archivo válido"
        end
    end
    
    # ▶ Función para buscar texto en archivos
    function search
        if command -v rg >/dev/null
            rg --color=always --line-number --no-heading $argv
        else
            grep -r --color=always -n $argv .
        end
    end
    
    # ▶ Función para obtener la IP pública
    function publicip
        echo "🌐 IP Pública:"
        curl -s ifconfig.me
        echo ""
        echo "📍 Localización:"
        curl -s "ipinfo.io/(curl -s ifconfig.me)" | jq '.city, .region, .country'
    end
    
    # ▶ Función para diagnosticar problemas con fastfetch
    function diagnose_fastfetch
        echo "🔍 Diagnosticando Fastfetch..."
        echo ""
        
        echo "1. Verificando instalación:"
        if command -v fastfetch >/dev/null
            echo "   ✅ Fastfetch instalado: "(which fastfetch)
            echo "   📦 Versión: "(fastfetch --version 2>/dev/null | head -1)
        else
            echo "   ❌ Fastfetch no encontrado"
            return 1
        end
        
        echo ""
        echo "2. Probando configuración por defecto:"
        timeout 3s fastfetch --config none || echo "   ❌ Timeout con config por defecto"
        
        echo ""
        echo "3. Probando configuración personalizada:"
        timeout 3s fastfetch --config ~/.config/fastfetch/config.jsonc || echo "   ❌ Timeout con config personalizada"
        
        echo ""
        echo "4. Archivos de configuración:"
        if test -f ~/.config/fastfetch/config.jsonc
            echo "   ✅ Config principal encontrada"
        else
            echo "   ❌ Config principal no encontrada"
        end
        
        echo ""
        echo "💡 Usa 'ff-stable' para una versión más rápida"
    end
    
    # ▶ Port scanner rápido
    function portscan
        if test (count $argv) -eq 0
            echo "❌ Uso: portscan <IP>"
            return 1
        end
        echo "🔍 Escaneando puertos principales en $argv[1]..."
        nmap -T4 -F $argv[1]
    end
    
    # ═══════════════════════════════════════════════════════════════
    # 🎯 VARIABLES DE ENTORNO
    # ═══════════════════════════════════════════════════════════════
    
    # Editor preferido
    if command -v nvim >/dev/null
        set -gx EDITOR nvim
        set -gx VISUAL nvim
    else if command -v vim >/dev/null
        set -gx EDITOR vim
        set -gx VISUAL vim
    else
        set -gx EDITOR nano
        set -gx VISUAL nano
    end
    
    # Path para herramientas locales
    set -gx PATH $HOME/.local/bin $HOME/bin $PATH
    
    # Configuración de FZF
    set -gx FZF_DEFAULT_OPTS '--height 50% --layout=reverse --border --margin=1 --padding=1'
    set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
    set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    
    # Configuración de ripgrep
    set -gx RIPGREP_CONFIG_PATH ~/.ripgreprc
    
    # Configuración de bat
    set -gx BAT_THEME "base16"
    
    # ═══════════════════════════════════════════════════════════════
    # 🔧 INICIALIZACIÓN DE HERRAMIENTAS
    # ═══════════════════════════════════════════════════════════════
    
    # Starship prompt (si está instalado)
    if command -v starship >/dev/null
        starship init fish | source
    end
    
    # Zoxide (cd inteligente)
    if command -v zoxide >/dev/null
        zoxide init fish | source
        alias cd="z"
        alias cdi="zi"  # interactive
    end
    
    # fzf integration
    if command -v fzf >/dev/null
        fzf --fish | source
    end
    
    # ═══════════════════════════════════════════════════════════════
    # ⌨️ KEYBINDINGS
    # ═══════════════════════════════════════════════════════════════
    
    # Ctrl+R para buscar en historial con fzf
    if command -v fzf >/dev/null
        bind \cr 'history | fzf --tac | read -l command; and commandline $command'
    end
    
    # Alt+C para cambiar directorio con fzf
    if command -v fzf >/dev/null && command -v fd >/dev/null
        bind \ec 'fd --type d | fzf | read -l dir; and test -n "$dir" && cd $dir; and commandline -f repaint'
    end
    
    # Ctrl+F para buscar archivos - COMENTADO para evitar conflictos
    # bind \cf 'ff'
    
    # Alt+K para kill procesos
    bind \ek 'fkill'
    
    # ═══════════════════════════════════════════════════════════════
    # 🎨 CONFIGURACIÓN DE COLORES
    # ═══════════════════════════════════════════════════════════════
    
    # Colores para ls/eza (si no usa eza)
    set -gx LS_COLORS 'di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30'
    
    # ═══════════════════════════════════════════════════════════════
    # 💡 TIPS Y MENSAJES
    # ═══════════════════════════════════════════════════════════════
    
    # Función para mostrar tips ocasionales
    function random_tip
        set tips \
            "💡 Tip: Usa 'fcd' para navegar directorios con fzf" \
            "💡 Tip: 'bat' muestra archivos con syntax highlighting" \
            "💡 Tip: 'eza --tree' muestra directorios como árbol" \
            "💡 Tip: 'rg pattern' busca texto más rápido que grep" \
            "💡 Tip: 'z directorio' para navegación inteligente" \
            "💡 Tip: Usa Tab para autocompletar comandos" \
            "💡 Tip: 'weather ciudad' para ver el clima" \
            "💡 Tip: 'extract archivo' extrae cualquier formato" \
            "💡 Tip: 'backup archivo' crea una copia de seguridad" \
            "💡 Tip: Ctrl+R para buscar en historial" \
            "💡 Tip: Alt+C para cambiar directorio con fzf"
        
        # Mostrar tip aleatoriamente (1 de cada 10 veces)
        if test (random 1 10) -eq 1
            set random_index (random 1 (count $tips))
            echo (set_color yellow)"$tips[$random_index]"(set_color normal)
        end
    end
    
    # Mostrar tip ocasional
    random_tip
    
end

# ═══════════════════════════════════════════════════════════════
# 🎉 CONFIGURACIÓN GLOBAL
# ═══════════════════════════════════════════════════════════════

# Deshabilitar greeting de Fish
set fish_greeting ""

# ═══════════════════════════════════════════════════════════════
# 🔧 FUNCIONES DE INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════

# Función para verificar herramientas faltantes
function check_tools
    set tools eza bat fd rg fzf starship zoxide htop
    echo "🔍 Verificando herramientas instaladas:"
    for tool in $tools
        if command -v $tool >/dev/null
            echo "  ✅ $tool"
        else
            echo "  ❌ $tool (no instalado)"
        end
    end
end

# Función para instalar herramientas faltantes (Kali/Debian/Ubuntu)
function install_modern_tools
    echo "📦 Instalando herramientas modernas..."
    
    # Actualizar repositorios
    sudo apt update
    
    # Instalar herramientas disponibles en repos
    sudo apt install -y bat fd-find ripgrep fzf htop
    
    # eza (requiere instalación manual)
    if not command -v eza >/dev/null
        echo "📥 Instalando eza..."
        wget -c https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz -O - | tar xz
        sudo chmod +x eza
        sudo mv eza /usr/local/bin/
    end
    
    # starship
    if not command -v starship >/dev/null
        echo "📥 Instalando starship..."
        curl -sS https://starship.rs/install.sh | sh
    end
    
    # zoxide
    if not command -v zoxide >/dev/null
        echo "📥 Instalando zoxide..."
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    end
    
    echo "✅ Instalación completada. Reinicia la terminal."
end