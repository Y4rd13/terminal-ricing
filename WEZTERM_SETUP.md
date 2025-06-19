# ═══════════════════════════════════════════════════════════════
# 📁 SCRIPTS ADICIONALES PARA TOKYO NIGHT SETUP
# ═══════════════════════════════════════════════════════════════

# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
# 🔧 backup_configs.sh - Script de Backup
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

#!/bin/bash
# backup_configs.sh - Crear backup de todas las configuraciones

BACKUP_DIR="$HOME/tokyo-night-backup/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "🔄 Creando backup completo de configuraciones Tokyo Night..."

# Backup de Fish
if [ -f ~/.config/fish/config.fish ]; then
    cp ~/.config/fish/config.fish "$BACKUP_DIR/fish_config.fish"
    echo "✅ Fish config backed up"
fi

# Backup de Fastfetch
if [ -d ~/.config/fastfetch ]; then
    cp -r ~/.config/fastfetch "$BACKUP_DIR/"
    echo "✅ Fastfetch config backed up"
fi

# Backup de WezTerm
if [ -f ~/.config/wezterm/wezterm.lua ]; then
    cp ~/.config/wezterm/wezterm.lua "$BACKUP_DIR/wezterm.lua"
    echo "✅ WezTerm config backed up"
fi

# Backup de aliases bashrc si existen
if [ -f ~/.bashrc ]; then
    grep -A 20 -B 5 "Tokyo Night" ~/.bashrc > "$BACKUP_DIR/bashrc_tokyo_aliases.txt" 2>/dev/null || true
fi

# Crear archivo de información
cat > "$BACKUP_DIR/backup_info.txt" << EOF
Tokyo Night Backup Information
==============================
Backup Date: $(date)
System: $(uname -a)
Fish Version: $(fish --version 2>/dev/null || echo "Not installed")
Fastfetch Version: $(fastfetch --version 2>/dev/null | head -1 || echo "Not installed")
WezTerm Version: $(wezterm --version 2>/dev/null || echo "Not installed")

Files backed up:
$(ls -la "$BACKUP_DIR")
EOF

echo ""
echo "✅ Backup completado en: $BACKUP_DIR"
echo "📁 Archivos incluidos:"
ls -la "$BACKUP_DIR"

# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
# 🔍 verify_setup.sh - Script de Verificación
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

#!/bin/bash
# verify_setup.sh - Verificar que todo funciona correctamente

echo "🔍 Verificando Tokyo Night Setup..."
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ $1 instalado${NC}"
        return 0
    else
        echo -e "${RED}❌ $1 no encontrado${NC}"
        return 1
    fi
}

check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✅ $1 existe${NC}"
        return 0
    else
        echo -e "${RED}❌ $1 no encontrado${NC}"
        return 1
    fi
}

# Verificar comandos principales
echo "📦 Verificando dependencias:"
check_command "fish"
check_command "fastfetch"
check_command "bat"
check_command "exa"
check_command "rg"
check_command "fzf"
echo ""

# Verificar archivos de configuración
echo "📁 Verificando archivos de configuración:"
check_file "$HOME/.config/fish/config.fish"
check_file "$HOME/.config/fastfetch/config.jsonc"
check_file "$HOME/.config/fastfetch/stable.jsonc"
check_file "$HOME/.config/wezterm/wezterm.lua"
echo ""

# Probar Fastfetch
echo "⚡ Probando Fastfetch:"
if timeout 3s fastfetch --config none >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Fastfetch funciona correctamente${NC}"
else
    echo -e "${YELLOW}⚠️  Fastfetch tiene problemas o es lento${NC}"
fi

if timeout 3s fastfetch --config ~/.config/fastfetch/config.jsonc >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Configuración personalizada funciona${NC}"
else
    echo -e "${YELLOW}⚠️  Configuración personalizada tiene problemas${NC}"
fi
echo ""

# Verificar colores de terminal
echo "🎨 Verificando soporte de colores:"
if [ "$TERM" = "xterm-256color" ] || [ "$TERM" = "screen-256color" ] || [[ "$TERM" == *"256color"* ]]; then
    echo -e "${GREEN}✅ Soporte de 256 colores detectado${NC}"
else
    echo -e "${YELLOW}⚠️  Soporte de colores limitado: $TERM${NC}"
fi
echo ""

# Verificar Fish como shell por defecto
echo "🐚 Verificando shell:"
if [ "$SHELL" = "$(which fish)" ]; then
    echo -e "${GREEN}✅ Fish configurado como shell por defecto${NC}"
else
    echo -e "${YELLOW}⚠️  Fish no es el shell por defecto. Shell actual: $SHELL${NC}"
    echo "   Para cambiar: chsh -s \$(which fish)"
fi
echo ""

# Información del sistema
echo "💻 Información del sistema:"
echo "  OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "  Kernel: $(uname -r)"
echo "  Terminal: $TERM"
echo "  Shell actual: $SHELL"
echo "  Usuario: $USER"
echo ""

echo "✅ Verificación completada!"

# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
# 🔄 update_tokyo.sh - Script de Actualización
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

#!/bin/bash
# update_tokyo.sh - Actualizar todas las dependencias y configuraciones

echo "🔄 Actualizando Tokyo Night Setup..."

# Actualizar repositorios
echo "📦 Actualizando repositorios..."
sudo apt update

# Actualizar dependencias específicas
echo "⬆️  Actualizando dependencias..."
sudo apt upgrade -y \
    fish \
    fastfetch \
    bat \
    exa \
    ripgrep \
    fzf \
    neovim

# Actualizar Fish completions
echo "🐚 Actualizando Fish completions..."
fish -c "fish_update_completions" 2>/dev/null || true

# Verificar WezTerm
if command -v wezterm >/dev/null 2>&1; then
    echo "📟 WezTerm actual: $(wezterm --version)"
    echo "   Visita https://github.com/wez/wezterm/releases para actualizaciones"
fi

echo ""
echo "✅ Actualización completada!"
echo "💡 Reinicia la terminal para aplicar todos los cambios"

# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
# 🎨 colors_test.sh - Probar Colores Tokyo Night
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

#!/bin/bash
# colors_test.sh - Probar la paleta de colores Tokyo Night

echo "🎨 Probando paleta de colores Tokyo Night..."
echo ""

# Colores Tokyo Night
declare -A colors=(
    ["background"]="1a1b26"
    ["foreground"]="c0caf5"
    ["black"]="15161e"
    ["red"]="f7768e"
    ["green"]="9ece6a"
    ["yellow"]="e0af68"
    ["blue"]="7aa2f7"
    ["magenta"]="bb9af7"
    ["cyan"]="7dcfff"
    ["white"]="a9b1d6"
)

# Función para mostrar color
show_color() {
    local name=$1
    local hex=$2
    printf "\033[38;2;$(printf '%d;%d;%d' 0x${hex:0:2} 0x${hex:2:2} 0x${hex:4:2})m"
    printf "%-12s" "$name"
    printf "\033[0m"
    printf " #%s " "$hex"
    printf "\033[48;2;$(printf '%d;%d;%d' 0x${hex:0:2} 0x${hex:2:2} 0x${hex:4:2})m    \033[0m"
    echo ""
}

# Mostrar todos los colores
for color_name in "${!colors[@]}"; do
    show_color "$color_name" "${colors[$color_name]}"
done

echo ""
echo "🌈 Probando colores básicos del terminal:"

# Probar colores ANSI
for i in {0..7}; do
    printf "\033[3${i}m Color $i \033[0m"
done
echo ""

for i in {0..7}; do
    printf "\033[9${i}m Bright $i \033[0m"
done
echo ""

echo ""
echo "✅ Test de colores completado!"

# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
# 🗑️ uninstall.sh - Script de Desinstalación
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

#!/bin/bash
# uninstall.sh - Desinstalar Tokyo Night Setup

echo "🗑️  Desinstalando Tokyo Night Setup..."
echo ""

# Advertencia
echo "⚠️  ADVERTENCIA: Esto eliminará todas las configuraciones de Tokyo Night"
echo "   Se crearán backups antes de eliminar"
echo ""
read -p "¿Estás seguro? (escriba 'yes' para continuar): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Desinstalación cancelada"
    exit 0
fi

# Crear backup antes de desinstalar
echo "📦 Creando backup final..."
BACKUP_DIR="$HOME/tokyo-night-uninstall-backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup de configuraciones
cp ~/.config/fish/config.fish "$BACKUP_DIR/" 2>/dev/null || true
cp -r ~/.config/fastfetch "$BACKUP_DIR/" 2>/dev/null || true
cp ~/.config/wezterm/wezterm.lua "$BACKUP_DIR/" 2>/dev/null || true

echo "✅ Backup creado en: $BACKUP_DIR"

# Restaurar configuraciones originales
echo "🔄 Restaurando configuraciones originales..."

# Buscar backups más recientes y restaurar
if ls ~/.config/fish/config.fish.backup.* 1> /dev/null 2>&1; then
    latest_backup=$(ls -t ~/.config/fish/config.fish.backup.* | head -1)
    cp "$latest_backup" ~/.config/fish/config.fish
    echo "✅ Fish config restaurado desde: $latest_backup"
else
    rm -f ~/.config/fish/config.fish
    echo "✅ Fish config eliminado (no había backup)"
fi

# Limpiar fastfetch
rm -rf ~/.config/fastfetch/
echo "✅ Configuración de Fastfetch eliminada"

# Limpiar WezTerm
if ls ~/.config/wezterm/wezterm.lua.backup.* 1> /dev/null 2>&1; then
    latest_backup=$(ls -t ~/.config/wezterm/wezterm.lua.backup.* | head -1)
    cp "$latest_backup" ~/.config/wezterm/wezterm.lua
    echo "✅ WezTerm config restaurado desde: $latest_backup"
else
    rm -f ~/.config/wezterm/wezterm.lua
    echo "✅ WezTerm config eliminado (no había backup)"
fi

# Limpiar scripts
rm -f ~/.local/bin/tokyo-*
echo "✅ Scripts de utilidad eliminados"

echo ""
echo "✅ Desinstalación completada!"
echo "📁 Backup final guardado en: $BACKUP_DIR"
echo "💡 Reinicia la terminal para aplicar los cambios"

# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
# 📊 benchmark.sh - Benchmark de Performance
# ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

#!/bin/bash
# benchmark.sh - Medir performance de configuraciones

echo "📊 Benchmark Tokyo Night Setup..."
echo ""

# Función para medir tiempo
measure_time() {
    local cmd="$1"
    local desc="$2"
    
    echo -n "⏱️  $desc: "
    local start_time=$(date +%s.%N)
    eval "$cmd" >/dev/null 2>&1
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc)
    echo "${duration}s"
}

# Benchmark Fish startup
measure_time "fish -c 'exit'" "Fish startup"

# Benchmark Fastfetch configurations
measure_time "fastfetch --config none" "Fastfetch (sin config)"
measure_time "fastfetch --config ~/.config/fastfetch/stable.jsonc" "Fastfetch (config estable)"
measure_time "fastfetch --config ~/.config/fastfetch/config.jsonc" "Fastfetch (config completa)"

# Benchmark comandos comunes
measure_time "fish -c 'll'" "Comando 'll' (eza)"
measure_time "fish -c 'bat --version'" "Comando 'bat'"
measure_time "fish -c 'rg --version'" "Comando 'rg'"

echo ""
echo "✅ Benchmark completado!"
echo "💡 Tiempos menores a 0.5s son excelentes"
echo "💡 Tiempos entre 0.5-1s son buenos"
echo "💡 Tiempos mayores a 1s pueden necesitar optimización"