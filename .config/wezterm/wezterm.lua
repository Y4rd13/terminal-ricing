-- CONFIGURACIÓN COMPLETA DE RICING PARA WEZTERM
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.set_environment_variables = {
  PATH = os.getenv("HOME").."/.cargo/bin:"..
         os.getenv("HOME").."/.local/bin:"..
         os.getenv("PATH"),
}

-- 🐚 SHELL CONFIGURATION
-- Arranca tmux (o zsh si no hay sesión)
-- config.default_prog = {
--  'tmux', 'new-session', '-A', '-s', 'main',
--  '--', '/usr/bin/zsh', '-l',
-- }
config.default_prog = { '/usr/bin/zsh', '-l' }


-- 🎨 COLORES Y TEMA
config.color_scheme = 'Dracula' -- 'Tokyo Night'
config.bold_brightens_ansi_colors = true
config.force_reverse_video_cursor = true

-- ═══════════════════════════════════════════════════════════════
-- Gradiente en el fondo
config.window_background_gradient = {
  orientation = 'Vertical',
  colors = {
    '#1a1b26',
    '#16161e',
  },
  interpolation = 'Linear',
  blend = 'Rgb',
}

config.macos_window_background_blur = 20

-- 🔤 FUENTES
config.font = wezterm.font_with_fallback {
  'JetBrainsMono Nerd Font',
  'Fira Code',
  'monospace',
}
config.font_size = 13
config.line_height = 1.1

-- ✨ EFECTOS VISUALES
config.window_background_opacity = 0.92
config.text_background_opacity = 1.0


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
    key = 'f',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  
  -- Split vertical
  {
    key = 'd',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  
  -- Cambiar entre paneles
  {
    key = 'LeftArrow',
    mods = 'CTRL',
    action = wezterm.action.ActivatePaneDirection 'Left',
  },
  {
    key = 'RightArrow',
    mods = 'CTRL',
    action = wezterm.action.ActivatePaneDirection 'Right',
  },
  {
    key = 'UpArrow',
    mods = 'CTRL',
    action = wezterm.action.ActivatePaneDirection 'Up',
  },
  {
    key = 'DownArrow',
    mods = 'CTRL',
    action = wezterm.action.ActivatePaneDirection 'Down',
  },
  
  -- Zoom del panel
  {
    key = 'z',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.TogglePaneZoomState,
  },

  -- ═══════════════════════════════════════════════════════════════
  -- 📏 REDIMENSIONAR PANELES
  -- ═══════════════════════════════════════════════════════════════
  
  {
    key = 'LeftArrow',
    mods = 'OPT',
    action = wezterm.action.AdjustPaneSize { 'Left', 5 },
  },
  {
    key = 'RightArrow',
    mods = 'OPT',
    action = wezterm.action.AdjustPaneSize { 'Right', 5 },
  },
  {
    key = 'UpArrow',
    mods = 'OPT',
    action = wezterm.action.AdjustPaneSize { 'Up', 5 },
  },
  {
    key = 'DownArrow',
    mods = 'OPT',
    action = wezterm.action.AdjustPaneSize { 'Down', 5 },
  },
  
  -- ═══════════════════════════════════════════════════════════════
  -- ❌ CERRAR PANELES
  -- ═══════════════════════════════════════════════════════════════
  
  {
    key = 'w',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.CloseCurrentPane { confirm = true },
  },
}

-- 🎯 PANELES (para multiplexing)
config.inactive_pane_hsb = {
  saturation = 0.8,
  brightness = 0.7,
}

-- ═══════════════════════════════════════════════════════════════
-- 📐 TAMAÑO Y POSICIÓN DE VENTANA
-- ═══════════════════════════════════════════════════════════════

-- Tamaño inicial (en columnas y filas)
config.initial_cols = 170  -- Ancho en columnas (caracteres)
config.initial_rows = 30   -- Alto en filas (líneas)

-- O alternativamente, abrir maximizada
-- config.window_decorations = "NONE"
-- config.native_macos_fullscreen_mode = false

-- Para centrar la ventana al abrir
config.window_frame = {
  font = wezterm.font { family = 'JetBrainsMono Nerd Font', weight = 'Bold' },
  font_size = 12.0,
}

-- Comportamiento responsive al redimensionar
config.adjust_window_size_when_changing_font_size = false
config.use_resize_increments = false

-- ═══════════════════════════════════════════════════════════════
-- Tmux Integration
-- ═══════════════════════════════════════════════════════════════
table.insert(config.keys, {
  key  = 'T',
  mods = 'CTRL|SHIFT',
  action = wezterm.action.SplitHorizontal {
    domain = 'CurrentPaneDomain',
    args   = { 'tmux', 'new-session', '-A', '-s', 'main' },
  },
})

-- ═══════════════════════════════════════════════════════════════
-- GUI Startup Behavior
-- ═══════════════════════════════════════════════════════════════
wezterm.on('gui-startup', function(cmd)
  local mux    = wezterm.mux
  local tab, pane, window = mux.spawn_window(cmd or {})

  -- 2) Split hacia la derecha un ancho de 80 columnas y lanzar btop
  pane:split {
    direction = 'Right',
    size      = 80,          -- 80 columnas exactas
    args      = { 'btop' },
  }
end)

return config