# 🚀 Setup Completo: Terminal Moderno en Kali Linux

Guía completa para configurar un entorno de terminal moderno y personalizado en Kali Linux con WezTerm, Fish shell y herramientas CLI avanzadas.

![Kali Linux Terminal](https://img.shields.io/badge/Kali-Linux-557C94?style=for-the-badge&logo=kalilinux&logoColor=white)
![WezTerm](https://img.shields.io/badge/WezTerm-4A90E2?style=for-the-badge)
![Fish Shell](https://img.shields.io/badge/Fish-Shell-00D2B8?style=for-the-badge)

## 📋 Tabla de Contenidos

- [🎯 Características del Setup](#-características-del-setup)
- [🔧 Instalación de WezTerm](#-instalación-de-wezterm)
- [🛠️ Herramientas CLI Modernas](#️-herramientas-cli-modernas)
- [🐟 Configuración de Fish Shell](#-configuración-de-fish-shell)
- [🎨 Configuración de WezTerm](#-configuración-de-wezterm)
- [🖼️ Configuración de Fastfetch](#️-configuración-de-fastfetch)
- [⚙️ WezTerm como Terminal por Defecto](#️-wezterm-como-terminal-por-defecto)
- [🎭 Temas y Personalización](#-temas-y-personalización)
- [🔗 Aliases y Funciones Útiles](#-aliases-y-funciones-útiles)
- [🚨 Solución de Problemas](#-solución-de-problemas)

## 🎯 Características del Setup

✅ **WezTerm** - Terminal emulador moderno con GPU acceleration  
✅ **Fish Shell** - Shell inteligente con autocompletado  
✅ **Fastfetch** - Info del sistema con logo ASCII de Kali  
✅ **CLI Tools modernos** - eza, bat, ripgrep, fzf, fd  
✅ **Temas personalizados** - Tokyo Night, Catppuccin, Nord  
✅ **Nerd Fonts** - Iconos y ligaduras  
✅ **Hot reload** - Configuración que se actualiza automáticamente  
✅ **Multiplexing** - Paneles y tabs integrados  

## 🔧 Instalación de WezTerm

### Método 1: APT Repository (Recomendado)

```bash
# Agregar clave GPG de WezTerm
curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg

# Agregar repositorio
echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list

# Actualizar e instalar
sudo apt update
sudo apt install wezterm
```

### Método 2: Flatpak (Alternativa)

```bash
# Instalar Flatpak si no está disponible
sudo apt install flatpak

# Agregar Flathub
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Instalar WezTerm
flatpak install flathub org.wezfurlong.wezterm
```

### Método 3: Build desde Código (Para ARM64)

```bash
# Instalar dependencias
sudo apt install build-essential cmake libfreetype6-dev libfontconfig1-dev xclip git

# Instalar Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Clonar y compilar WezTerm
git clone https://github.com/wez/wezterm.git
cd wezterm
cargo build --release
sudo cp target/release/wezterm /usr/local/bin/
```

## 🛠️ Herramientas CLI Modernas

### Instalación de Herramientas

```bash
# Actualizar sistema
sudo apt update

# Instalar herramientas CLI modernas
sudo apt install eza bat fd-find ripgrep fzf htop fastfetch curl git

# Verificar instalación
eza --version
bat --version
fd --version
rg --version
fzf --version
fastfetch --version
```

### Instalar Nerd Fonts

```bash
# Crear directorio para fuentes
mkdir -p ~/.local/share/fonts

# Descargar JetBrains Mono Nerd Font
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip

# Extraer e instalar
unzip JetBrainsMono.zip -d ~/.local/share/fonts/
fc-cache -fv

# Limpiar
rm JetBrainsMono.zip
```

## 🐟 Configuración de Fish Shell

### Instalar Fish Shell

```bash
# Instalar Fish
sudo apt install fish

# Cambiar shell por defecto
chsh -s /usr/bin/fish

# Reiniciar sesión para aplicar cambios
```

### Configuración Completa de Fish

```bash
# Crear directorio de configuración
mkdir -p ~/.config/fish

# Crear archivo de configuración
nano ~/.config/fish/config.fish
```

**Contenido del archivo `~/.config/fish/config.fish`:**

```fish
# ~/.config/fish/config.fish
# Configuración completa de Fish shell para Kali Linux + WezTerm

if status is-interactive
    # 🎨 MOSTRAR INFO DEL SISTEMA
    fastfetch
    
    # 🔧 ALIASES MODERNOS
    alias ls="eza --icons"
    alias ll="eza -la --icons"
    alias la="eza -a --icons"
    alias tree="eza --tree --icons"
    alias lt="eza --tree --level=2 --icons"
    
    alias cat="bat"
    alias find="fd"
    alias grep="rg"
    alias top="htop"
    
    # Git shortcuts
    alias g="git"
    alias gs="git status"
    alias ga="git add"
    alias gc="git commit"
    alias gp="git push"
    alias gl="git log --oneline"
    
    # Navegación rápida
    alias ..="cd .."
    alias ...="cd ../.."
    alias home="cd ~"
    
    # Kali específicos
    alias kali-update="sudo apt update && sudo apt upgrade"
    alias ports="sudo netstat -tuln"
    alias myip="curl ifconfig.me"
    
    # Desarrollo
    alias python="python3"
    alias pip="pip3"
    alias serve="python3 -m http.server 8000"
    
    # 🚀 FUNCIONES ÚTILES
    function mkcd
        mkdir -p $argv[1] && cd $argv[1]
    end
    
    function ff
        fd --type f | fzf | xargs nvim
    end
    
    function fh
        history | fzf | fish_clipboard_copy
    end
    
    function extract
        if test -f $argv[1]
            switch $argv[1]
                case '*.tar.bz2'
                    tar xjf $argv[1]
                case '*.tar.gz'
                    tar xzf $argv[1]
                case '*.zip'
                    unzip $argv[1]
                case '*.rar'
                    unrar x $argv[1]
                case '*'
                    echo "'$argv[1]' no se puede extraer"
            end
        else
            echo "'$argv[1]' no es un archivo válido"
        end
    end
    
    # 🎯 VARIABLES DE ENTORNO
    set -gx EDITOR nvim
    set -gx TERMINAL wezterm
    set -gx PATH $HOME/.local/bin $PATH
    set -gx FZF_DEFAULT_OPTS '--height 40% --layout=reverse --border'
    
    # 🔧 INICIALIZACIÓN DE HERRAMIENTAS
    if command -v starship >/dev/null
        starship init fish | source
    end
    
    # 💡 SHORTCUTS
    bind \cr 'history | fzf | read -l command; and commandline $command'
    bind \ec 'fd --type d | fzf | read -l dir; and cd $dir'
end

# Configurar el greeting de Fish
set fish_greeting ""
```

## 🎨 Configuración de WezTerm

### Crear Configuración de WezTerm

```bash
# Crear directorio de configuración
mkdir -p ~/.config/wezterm

# Crear archivo de configuración
nano ~/.config/wezterm/wezterm.lua
```

**Contenido del archivo `~/.config/wezterm/wezterm.lua`:**

```lua
-- ~/.config/wezterm/wezterm.lua
-- Configuración completa de WezTerm para Kali Linux

local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- 🎨 COLORES Y TEMA
config.color_scheme = 'Tokyo Night'

-- Esquema de colores personalizado (alternativa)
config.colors = {
  foreground = '#c0caf5',
  background = '#1a1b26',
  cursor_bg = '#c0caf5',
  cursor_fg = '#1a1b26',
  cursor_border = '#c0caf5',
  selection_fg = '#c0caf5',
  selection_bg = '#33467c',
  
  ansi = {
    '#15161e', '#f7768e', '#9ece6a', '#e0af68',
    '#7aa2f7', '#bb9af7', '#7dcfff', '#a9b1d6',
  },
  brights = {
    '#414868', '#f7768e', '#9ece6a', '#e0af68',
    '#7aa2f7', '#bb9af7', '#7dcfff', '#c0caf5',
  },
}

-- 🔤 FUENTES
config.font = wezterm.font_with_fallback {
  'JetBrainsMono Nerd Font',
  'Fira Code',
  'monospace',
}
config.font_size = 13
config.line_height = 1.1

-- ✨ EFECTOS VISUALES
config.window_background_opacity = 0.85
config.text_background_opacity = 0.8

-- 🪟 VENTANA
config.window_decorations = "RESIZE"
config.window_close_confirmation = "NeverPrompt"
config.adjust_window_size_when_changing_font_size = false

-- Eliminar barra de tabs
config.enable_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true

-- Padding
config.window_padding = {
  left = 15,
  right = 15,
  top = 15,
  bottom = 15,
}

-- 🖱️ CURSOR
config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 500

-- ⌨️ KEYBINDINGS PERSONALIZADOS
config.keys = {
  -- Split horizontal
  {
    key = 'd',
    mods = 'CMD',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  
  -- Split vertical
  {
    key = 'd',
    mods = 'CMD|SHIFT',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  
  -- Cambiar entre paneles
  {
    key = 'h',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivatePaneDirection 'Left',
  },
  {
    key = 'l',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivatePaneDirection 'Right',
  },
  {
    key = 'k',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivatePaneDirection 'Up',
  },
  {
    key = 'j',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivatePaneDirection 'Down',
  },
  
  -- Zoom del panel
  {
    key = 'z',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.TogglePaneZoomState,
  },
}

-- 🎯 PANELES (para multiplexing)
config.inactive_pane_hsb = {
  saturation = 0.8,
  brightness = 0.7,
}

return config
```

## 🖼️ Configuración de Fastfetch

### Configurar Fastfetch con Logo de Kali

```bash
# Crear directorio de configuración
mkdir -p ~/.config/fastfetch

# Crear archivo de configuración
nano ~/.config/fastfetch/config.jsonc
```

**Contenido del archivo `~/.config/fastfetch/config.jsonc`:**

```json
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "source": "kali",
        "padding": {
            "right": 4
        }
    },
    "display": {
        "separator": ": "
    },
    "modules": [
        {
            "type": "title",
            "format": "{user-name}@{host-name}"
        },
        {
            "type": "separator",
            "string": "-----------"
        },
        {
            "type": "os",
            "format": "OS: {name} {version}"
        },
        {
            "type": "host",
            "format": "Host: {name}"
        },
        {
            "type": "kernel",
            "format": "Kernel: {release}"
        },
        {
            "type": "uptime",
            "format": "Uptime: {time}"
        },
        {
            "type": "packages",
            "format": "Packages: {count} ({manager})"
        },
        {
            "type": "shell",
            "format": "Shell: {name} {version}"
        },
        {
            "type": "terminal",
            "format": "Terminal: {name} {version}"
        },
        {
            "type": "cpu",
            "format": "CPU: {name} ({cores})"
        },
        {
            "type": "gpu",
            "format": "GPU: {name}"
        },
        {
            "type": "memory",
            "format": "Memory: {used} / {total} ({percentage}%)"
        }
    ]
}
```

## ⚙️ WezTerm como Terminal por Defecto

### Método GUI (Recomendado)

```bash
# Abrir configuración de aplicaciones preferidas
exo-preferred-applications
```

1. Ir a **"Utilities"** → **"Terminal Emulator"**
2. Seleccionar **WezTerm**
3. Clic en **"Close"**

### Método CLI

```bash
# Agregar WezTerm a alternatives
sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/wezterm 50

# Configurarlo como por defecto
sudo update-alternatives --set x-terminal-emulator /usr/bin/wezterm

# Configurar shortcut en Xfce
xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Primary><Alt>t" -s "wezterm"
```

## 🎭 Temas y Personalización

### Temas Populares para WezTerm

```lua
-- Cambiar en ~/.config/wezterm/wezterm.lua
-- Solo cambia esta línea por el tema que prefieras:

config.color_scheme = 'Tokyo Night'        -- Oscuro moderno
-- config.color_scheme = 'Catppuccin Mocha'  -- Pastel oscuro
-- config.color_scheme = 'Dracula'           -- Púrpura clásico
-- config.color_scheme = 'Nord'              -- Azul frío
-- config.color_scheme = 'Gruvbox Dark'      -- Retro cálido
-- config.color_scheme = 'One Dark'          -- VSCode style
-- config.color_scheme = 'Solarized Dark'    -- Clásico
```

### Función para Tema Automático Día/Noche

```lua
-- Agregar a wezterm.lua para cambio automático
local function get_appearance()
  if wezterm.gui then
    return wezterm.gui.get_appearance()
  end
  return 'Dark'
end

local function scheme_for_appearance(appearance)
  if appearance:find 'Dark' then
    return 'Tokyo Night'
  else
    return 'Tokyo Night Day'
  end
end

config.color_scheme = scheme_for_appearance(get_appearance())
```

## 🔗 Aliases y Funciones Útiles

### Aliases Principales

```fish
# Listado mejorado
ls          # eza con iconos
ll          # listado largo con iconos
tree        # vista de árbol
lt          # árbol limitado a 2 niveles

# Comandos mejorados
cat         # bat con syntax highlighting
find        # fd búsqueda rápida
grep        # ripgrep súper rápido
top         # htop interactivo

# Git rápido
gs          # git status
ga          # git add
gc          # git commit
gp          # git push
gl          # git log --oneline

# Navegación
..          # cd ..
...         # cd ../..
home        # cd ~

# Kali específicos
kali-update # actualizar sistema
ports       # ver puertos abiertos
myip        # ver IP pública
```

### Funciones Útiles

```fish
mkcd dirname        # Crear directorio y entrar
extract archivo.zip # Extraer cualquier archivo
ff                  # Buscar archivos con fzf
fh                  # Buscar en historial
serve              # Servidor HTTP local en puerto 8000
```

## 🚨 Solución de Problemas

### WezTerm no inicia

```bash
# Verificar instalación
which wezterm
wezterm --version

# Reinstalar si es necesario
sudo apt remove wezterm
sudo apt install wezterm
```

### Fish muestra errores

```bash
# Verificar sintaxis del config
fish -n ~/.config/fish/config.fish

# Resetear configuración
mv ~/.config/fish/config.fish ~/.config/fish/config.fish.backup
```

### Fastfetch no muestra logo de Kali

```bash
# Probar con logo específico
fastfetch --logo kali

# Ver logos disponibles
fastfetch --list-logos | grep -i kali
```

### Nerd Fonts no se ven

```bash
# Verificar instalación de fuentes
fc-list | grep -i "jetbrains"

# Reinstalar fuentes
rm -rf ~/.local/share/fonts/JetBrains*
# Repetir instalación de Nerd Fonts
```

## 📝 Script de Instalación Automática

```bash
#!/bin/bash
# Script de instalación automática
# Guarda como setup.sh y ejecuta: bash setup.sh

echo "🚀 Iniciando setup de terminal moderno en Kali Linux..."

# Actualizar sistema
sudo apt update

# Instalar WezTerm
curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
sudo apt update && sudo apt install wezterm

# Instalar herramientas CLI
sudo apt install fish eza bat fd-find ripgrep fzf htop fastfetch curl git

# Instalar Nerd Fonts
mkdir -p ~/.local/share/fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip
unzip JetBrainsMono.zip -d ~/.local/share/fonts/
fc-cache -fv
rm JetBrainsMono.zip

# Configurar WezTerm como terminal por defecto
sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/wezterm 50
sudo update-alternatives --set x-terminal-emulator /usr/bin/wezterm

# Cambiar a Fish shell
chsh -s /usr/bin/fish

echo "✅ Setup completado. Reinicia la sesión para aplicar todos los cambios."
echo "📁 No olvides copiar las configuraciones de Fish y WezTerm."
```

---

## 🎉 ¡Setup Completo!

Después de seguir esta guía tendrás:

- ✅ Terminal moderno con GPU acceleration
- ✅ Shell inteligente con autocompletado
- ✅ Herramientas CLI súper rápidas
- ✅ Temas personalizables
- ✅ Info del sistema con logo de Kali
- ✅ Shortcuts y aliases útiles

**¡Disfruta tu nuevo entorno de terminal!** 🚀

---

**Creado por:** Tutorial de setup moderno para Kali Linux  
**Versión:** 1.0  
**Compatibilidad:** Kali Linux Rolling, ARM64/x86_64