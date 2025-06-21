# Terminal Ricing - Kali Linux Setup

Setup completo para terminal moderno en Kali Linux con WezTerm, ZSH y PowerLevel10k.

![Kali Linux Terminal](https://img.shields.io/badge/Kali-Linux-557C94?style=for-the-badge&logo=kalilinux&logoColor=white)
![WezTerm](https://img.shields.io/badge/WezTerm-4A90E2?style=for-the-badge)
![ZSH Shell](https://img.shields.io/badge/ZSH-Shell-1A2C34?style=for-the-badge)
![PowerLevel10k](https://img.shields.io/badge/PowerLevel10k-FF6B35?style=for-the-badge)

## Tabla de Contenidos

- [Características](#características)
- [Instalación de WezTerm](#instalación-de-wezterm)
- [Herramientas CLI](#herramientas-cli)
- [Configuración ZSH](#configuración-zsh)
- [PowerLevel10k Setup](#powerlevel10k-setup)
- [Configuración WezTerm](#configuración-wezterm)
- [Configuración Fastfetch](#configuración-fastfetch)
- [WezTerm por Defecto](#wezterm-por-defecto)
- [Temas](#temas)
- [Aliases y Funciones](#aliases-y-funciones)
- [Solución de Problemas](#solución-de-problemas)

## Características

- **WezTerm** - Terminal emulador con GPU acceleration
- **ZSH Shell** - Shell con autocompletado avanzado
- **PowerLevel10k** - Prompt personalizable
- **Fastfetch** - Info del sistema con logo Kali
- **CLI modernas** - eza, bat, ripgrep, fzf, fd
- **Temas** - Tokyo Night, Catppuccin, Nord
- **Nerd Fonts** - JetBrains Mono con iconos

## Instalación de WezTerm

### Método 1: APT Repository

```bash
# Agregar clave GPG de WezTerm
curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg

# Agregar repositorio
echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list

# Actualizar e instalar
sudo apt update
sudo apt install wezterm
```

### Método 2: Flatpak

```bash
# Instalar Flatpak si no está disponible
sudo apt install flatpak

# Agregar Flathub
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Instalar WezTerm
flatpak install flathub org.wezfurlong.wezterm
```

## Herramientas CLI

### Instalación

```bash
# Actualizar sistema
sudo apt update

# Herramientas CLI modernas
sudo apt install eza bat fd-find ripgrep fzf htop curl git zsh

# Fastfetch - Kali Linux
sudo apt install fastfetch

# Fastfetch - Ubuntu (si no está disponible en repos)
sudo add-apt-repository ppa:zhangsongcui3371/fastfetch
sudo apt update
sudo apt install fastfetch

# Verificar instalación
eza --version
bat --version
fd --version
rg --version
fzf --version
fastfetch --version
zsh --version
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

## Configuración ZSH

### Instalar ZSH

```bash
# Instalar ZSH
sudo apt install zsh

# Cambiar shell por defecto
chsh -s $(which zsh)

# Reiniciar sesión para aplicar cambios
```

### Configuración ZSH

**Crear archivo:** `~/.zshrc`

> Configuración completa con aliases, funciones, keybindings y variables de entorno.

## PowerLevel10k Setup

### Instalación de PowerLevel10k

```bash
# Clonar repositorio
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k

# Agregar a ~/.zshrc
echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >> ~/.zshrc

# Recargar configuración
source ~/.zshrc
```

### Configuración Inicial

```bash
# Ejecutar wizard de configuración
p10k configure
```

**Opciones recomendadas:**

- ✅ Diamond icons
- ✅ Unicode characters
- ✅ 24-bit colors
- ✅ Instant prompt
- ✅ Transient prompt (opcional)

### Comandos Útiles de PowerLevel10k

```bash
p10k configure    # Reconfigurar prompt
p10k reload       # Recargar configuración
p10k display      # Mostrar configuración actual
```

## 🎨 Configuración de WezTerm

### Crear Configuración de WezTerm

**Archivo de configuración:** `~/.config/wezterm/wezterm.lua`

> Configuración completa con tema Tokyo Night, shell ZSH por defecto, keybindings personalizados y efectos visuales.

### Cambios Principales

- `config.default_prog = { '/usr/bin/zsh', '-l' }` - ZSH como shell por defecto
- Tema Tokyo Night configurado
- Keybindings para paneles y navegación
- Efectos de transparencia y blur

## 🖼️ Configuración de Fastfetch

### Configurar Fastfetch con Logo de Kali

**Archivo de configuración:** `~/.config/fastfetch/config.jsonc`

> Configuración con logo de Kali Linux, módulos informativos y colores personalizados.

### Alias de Fastfetch

```bash
ff              # fastfetch normal
ff-full         # configuración completa
ff-min          # configuración mínima
ff-test         # test con timeout
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
```

## 🎭 Temas y Personalización

### Temas Populares para WezTerm

```lua
-- Cambiar en ~/.config/wezterm/wezterm.lua
config.color_scheme = 'Tokyo Night'        -- Oscuro moderno (por defecto)
-- config.color_scheme = 'Catppuccin Mocha'  -- Pastel oscuro
-- config.color_scheme = 'Dracula'           -- Púrpura clásico
-- config.color_scheme = 'Nord'              -- Azul frío
-- config.color_scheme = 'Gruvbox Dark'      -- Retro cálido
-- config.color_scheme = 'One Dark'          -- VSCode style
```

### PowerLevel10k Themes

```bash
# Cambiar estilo de PowerLevel10k
p10k configure

# Estilos populares:
# - Lean (minimalista)
# - Classic (información completa)
# - Rainbow (colorido)
# - Pure (estilo pure prompt)
```

## 🔗 Aliases y Funciones Útiles

### Aliases Principales en ZSH

```bash
# Listado mejorado con eza
ls, ll, la, tree, lt

# Comandos mejorados
cat     # bat con syntax highlighting
find    # fd búsqueda rápida
grep    # ripgrep súper rápido
top     # htop interactivo

# Git shortcuts
gs, ga, gc, gp, gl, gb, gch, gd

# Navegación rápida
.., ..., ...., home, desktop, downloads

# Kali específicos
kali-update, kali-clean, ports, myip, localip

# Herramientas de penetración
nmap-quick, nmap-full, nmap-vuln, gobuster-common

# Docker shortcuts
d, dc, dps, di, drm, drmi, dclean
```

### Funciones Útiles en ZSH

```bash
mkcd dirname        # Crear directorio y entrar
extract archivo.zip # Extraer cualquier archivo
fzf_find           # Buscar archivos con fzf (antes ff)
fcd                # Cambiar directorio con fzf
fh                 # Buscar en historial
fkill              # Kill procesos con fzf
weather ciudad     # Info del clima
backup archivo     # Backup con timestamp
search texto       # Búsqueda en archivos con rg
publicip          # Ver IP pública y localización
portscan IP       # Scan rápido de puertos
```

## 🚨 Solución de Problemas

### Error "unknown option: --zsh" al abrir terminal

```bash
# Problema resuelto en ~/.zshrc con compatibilidad fzf
# El archivo incluye detección automática de versiones
```

### ZSH muestra error de función

```bash
# Problema: conflicto alias 'ff' con función 'ff()'
# Solución: función renombrada a 'fzf_find()' en ~/.zshrc
```

### PowerLevel10k no aparece

```bash
# Verificar instalación
ls ~/powerlevel10k/

# Verificar ~/.zshrc
grep "powerlevel10k" ~/.zshrc

# Reinstalar si es necesario
rm -rf ~/powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
source ~/.zshrc
```

### WezTerm no usa ZSH

```bash
# Verificar wezterm.lua
grep "default_prog" ~/.config/wezterm/wezterm.lua

# Debe contener:
# config.default_prog = { '/usr/bin/zsh', '-l' }
```

### Fastfetch timeout

```bash
# El ~/.zshrc incluye timeout de 5s para evitar cuelgues
# Si persiste, usar:
ff-test    # versión con timeout de 3s
```

## 📝 Script de Instalación Automática

```bash
#!/bin/bash
# Script de instalación automática - setup-zsh.sh

echo "🚀 Iniciando setup ZSH + PowerLevel10k en Kali Linux..."

# Actualizar sistema
sudo apt update

# Instalar WezTerm
curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
sudo apt update && sudo apt install wezterm

# Instalar herramientas CLI + ZSH
sudo apt install zsh eza bat fd-find ripgrep fzf htop fastfetch curl git

# Instalar PowerLevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k

# Instalar Nerd Fonts
mkdir -p ~/.local/share/fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip
unzip JetBrainsMono.zip -d ~/.local/share/fonts/
fc-cache -fv
rm JetBrainsMono.zip

# Configurar WezTerm como terminal por defecto
sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/wezterm 50
sudo update-alternatives --set x-terminal-emulator /usr/bin/wezterm

# Cambiar a ZSH shell
chsh -s $(which zsh)

echo "✅ Setup completado. Configuraciones necesarias:"
echo "📁 Copia ~/.zshrc desde el repositorio"
echo "📁 Copia ~/.config/wezterm/wezterm.lua"
echo "📁 Copia ~/.config/fastfetch/config.jsonc"
echo "🔄 Reinicia la sesión y ejecuta 'p10k configure'"
```

## 📚 Archivos de Configuración

### Estructura de Archivos

```
~/.zshrc                              # Configuración principal ZSH
~/.config/wezterm/wezterm.lua         # Configuración WezTerm
~/.config/fastfetch/config.jsonc      # Configuración Fastfetch
~/.p10k.zsh                          # Config PowerLevel10k (generado automáticamente)
```

### Backup de Configuraciones

```bash
# Crear backup de configuraciones
mkdir -p ~/dotfiles-backup
cp ~/.zshrc ~/dotfiles-backup/
cp -r ~/.config/wezterm ~/dotfiles-backup/
cp -r ~/.config/fastfetch ~/dotfiles-backup/
cp ~/.p10k.zsh ~/dotfiles-backup/ 2>/dev/null || echo "p10k config no existe aún"
```

---

## Setup Completo

**Stack:**

- WezTerm + ZSH + PowerLevel10k
- CLI modernas: eza, bat, rg, fzf, fd
- Tema Tokyo Night
- JetBrains Mono Nerd Font
- Fastfetch con logo Kali

**Post-instalación:**

1. `source ~/.zshrc`
2. `p10k configure`
3. `check_tools`

---

**Versión:** 2.0 - ZSH + PowerLevel10k  
**Compatibilidad:** Kali Linux x86_64
